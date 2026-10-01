#include <stdint.h>
#include <avr/io.h>

#include "adc.h"
#include "common.h"
#include "power.h"

int16_t converted_mv[SAMPLE_SIZE];
int16_t converted_ma[SAMPLE_SIZE];
float v_upsampled[OUTPUT_LEN];
float i_upsampled[OUTPUT_LEN];
volatile uint16_t ticks = 0;


// CALCULATIONS
float calculate_rms(float *samples, int len) {
	float sum_sq = 0.0f;
	for (int i = 0; i < len; i++) {
		float v = samples[i] / 1000.0f; // convert mV -> V or mA -> A
		sum_sq += v * v;
	}
	return square_root(sum_sq / len);
}

void remove_dc_offset(int16_t* data) {
	long sum = 0;
	for (int i = 0; i < SAMPLE_SIZE; i++) {
		sum += data[i];
	}
	int16_t mean = sum / SAMPLE_SIZE;

	for (int i = 0; i < SAMPLE_SIZE; i++) {
		data[i] = data[i] - mean;
	}
}

void linear_interpolate_float(const int16_t* input, float* output, int factor) {
	int out_idx = 0;

	for (int i = 0; i < SAMPLE_SIZE - 1; i++) {
		float start = (float)input[i];
		float end = (float)input[i + 1];

		// Copy the starting sample
		output[out_idx++] = start;

		// Interpolate intermediate points
		for (int j = 1; j < factor; j++) {
			float t = (float)j / factor;
			float val = start + t * (end - start);
			output[out_idx++] = val;
		}
	}

	// Copy the last sample
	output[out_idx] = (float)input[SAMPLE_SIZE - 1];
}

static float cubicInterpolate(float y0, float y1, float y2, float y3, float t) {
	float a = -0.5f*y0 + 1.5f*y1 - 1.5f*y2 + 0.5f*y3;
	float b = y0 - 2.5f*y1 + 2.0f*y2 - 0.5f*y3;
	float c = -0.5f*y0 + 0.5f*y2;
	float d = y1;
	return a*t*t*t + b*t*t + c*t + d;
}

// Interpolates 'input' int16 array into float 'output' array
// factor = upsampling factor
// output_len should be (input_len-1)*factor + 1
void cubic_interpolate_int16(const int16_t* input, float* output, int input_len, int factor) {
	int out_idx = 0;

	for (int i = 0; i < input_len - 1; i++) {
		float y0 = (i == 0) ? (float)input[0] : (float)input[i-1];
		float y1 = (float)input[i];
		float y2 = (float)input[i+1];
		float y3 = (i+2 < input_len) ? (float)input[i+2] : (float)input[input_len-1];

		for (int j = 0; j < factor; j++) {
			float t = (float)j / factor;
			output[out_idx++] = cubicInterpolate(y0, y1, y2, y3, t);
		}
	}

	// Copy last point
	output[out_idx] = (float)input[input_len - 1];
}

void remove_dc_offset_float(float* data, int len) {
	float sum = 0.0f;
	for (int i = 0; i < len; i++) {
		sum += data[i];
	}
	float mean = sum / (float)len;
	for (int i = 0; i < len; i++) {
		data[i] -= mean;
	}
}

void calculate_power() {
	ACSR |= (1 << ACIE); //Enable comparator interrupt
	TIMSK0 |= (1 << OCIE0A); //Enable timer0 comp a interrupt
	test_current();

	// Select correct ADC channel before next measurement
	if (low_current) {
		ADMUX = (ADMUX & 0xF0) | 2;  // low current channel (ADC2)
		} else {
		ADMUX = (ADMUX & 0xF0) | 1;  // high current channel (ADC1)
	}

	// Re-enable comparator interrupt to start new sampling
	ACSR = (1 << ACIE);
	ACSR |= (1 << ACIS1);
	ACSR &= ~(1 << ACIS0);
	//sampling_done = 1;
	while (!sampling_done);

	// Now calculate real power:
	for (int i = 0; i < SAMPLE_SIZE; i++) {
		converted_mv[i] = adc_convert_mv(adc_voltage_samples[i]);
		if(low_current) {
			converted_ma[i] = adc_convert_ma_low(adc_current_samples[i]);
			} else {
			converted_ma[i] = adc_convert_ma_high(adc_current_samples[i]);
		}
		
	}

	remove_dc_offset(converted_mv);
	remove_dc_offset(converted_ma);

	linear_interpolate_float(converted_mv, v_upsampled, UPSAMPLE_FACTOR);
	linear_interpolate_float(converted_ma, i_upsampled, UPSAMPLE_FACTOR);

	remove_dc_offset_float(v_upsampled, OUTPUT_LEN);
	remove_dc_offset_float(i_upsampled, OUTPUT_LEN);
	uint8_t shift_samples = 47;

	float power_sum = 0.0f;
	for (int i = 0; i < 100; i++) {
		int idx_i = i + shift_samples;
		if (idx_i < 0 || idx_i >= OUTPUT_LEN) continue;

		float v = v_upsampled[i] / 1000.0f;  // mV to V
		float i_ = i_upsampled[idx_i] / 1000.0f; // mA to A
		power_sum += v * i_;
	}

	P_measured = power_sum / (100);
	//P_measured = P_measured+0.1;
	Vrms = calculate_rms(v_upsampled, OUTPUT_LEN);
	float Irms = calculate_rms(i_upsampled, OUTPUT_LEN);
	Ipeak = Irms * square_root(2) * 1000;
	uint16_t ticks = TCNT1;
	TCNT1 = 0; //Reset timer1
	float time_elapsed = (float)ticks * 256.0f / F_CPU;
	energy += P_measured * time_elapsed;
	/*P_measured = 3.145;
	Vrms = 12.6;
	Ipeak = 595.8;
	energy = 30.678;*/
	
	/*for (int i = 0; i < SAMPLE_SIZE; i++) {
		adc_voltage_samples[i] = 0;
		adc_current_samples[i] = 0;
	}
	
	for (int i = 0; i < SAMPLE_SIZE; i++) {
		converted_ma[i] = 0;
		converted_mv[i] = 0;
	}*/

	for (int i = 0; i < OUTPUT_LEN; i++) {
		v_upsampled[i] = 0.0f;
		i_upsampled[i] = 0.0f;
	}
	sampling_done = 0;
	calculation_done = 1;
	ADCSRA &= ~(1 << ADATE);   // Stop ADC auto trigger
	TIMSK0 &= ~(1 << OCIE0A); //Disable timer0 comp a interrupt
}


