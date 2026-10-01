/*
 * ADC Functions
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include "common.h"
#include "adc.h"

volatile uint8_t adc_sampling = 0;
volatile uint8_t voltage_sampling = 1;
volatile int16_t current_test[10];
volatile uint8_t current_testing = 0;
volatile uint8_t test_count = 0;
volatile uint8_t discard_next = 1;
volatile uint8_t adc_channel = 0; // 0 = voltage, 1 = current
volatile uint16_t sample_index = 0;




void adc_init() {
	ADMUX = (1 << REFS0); // AVcc reference, ADC0
	ADCSRA = (1 << ADEN) | (1 << ADIE) | (1 << ADATE) | (4 << ADPS0); // ADPS1 = prescaler 16
	ADCSRB = (1 << ADTS0) | (1 << ADTS1); // Timer0 Compare Match A trigger
	DIDR0 = 0x03; // Disable digital input buffer on ADC0 and ADC1
	
	

	ADMUX = (ADMUX & 0xF0) | 1; // Start with ADC0
	ADCSRA |= (1 << ADSC); // Start conversion
	
	ACSR = (1 << ACIE);        // Enable comparator interrupt
	ACSR |= (1 << ACIS1);      // Falling edge triggers interrupt
	ACSR &= ~(1 << ACIS0);
	
	DDRD &= ~((1 << PD6) | (1 << PD7));
	PORTD &= ~((1 << PD6) | (1 << PD7)); // Disable pull-ups
}

ISR(ADC_vect) {
	
	if (current_testing) {
		current_test[test_count] = ADC;
		test_count++;
		if (test_count >= 50) {
			ADCSRA &= ~(1 << ADATE);
			test_count = 0;
			current_testing = 0;
			ADMUX = (ADMUX & 0xF0) | 0;
		}
		}else {
	if (adc_channel == 0) {
		adc_voltage_samples[sample_index] = ADC;
		} else {
		adc_current_samples[sample_index] = ADC;
	}

	sample_index++;

	if (sample_index >= SAMPLE_SIZE) {
		sample_index = 0;
		if (adc_channel == 0) {
			if(low_current) {
			adc_channel = 2;        // switch to current
			ADMUX = (ADMUX & 0xF0) | 2;  // ADC1 = current
			} else {
				adc_channel = 1;        // switch to current
				ADMUX = (ADMUX & 0xF0) | 1;
			}
		} else {
			adc_channel = 0;        // switch to voltage
			ADMUX = (ADMUX & 0xF0) | 0;  // ADC0 = voltage
			sampling_done = 1;
		}
		// Now the first sample on the new channel will be accurate
		// because we allowed auto-trigger to run for the full SAMPLE_SIZE
	}
	}
}

ISR(ANALOG_COMP_vect) {
	// Zero crossing detected — start ADC sampling from this point
	TCNT0 = 0;               // Reset Timer0
	sample_count = 0;
	voltage_sampling = 1;
	sampling_done = 0;

	// Enable ADC auto-trigger to start sampling
	ADCSRA |= (1 << ADATE);

	// Optionally disable comparator interrupt during sampling to avoid retriggers
	ACSR &= ~(1 << ACIE);
}


int16_t adc_convert_mv(uint16_t adc_val) {
	float v_adc = ((float)adc_val / 1023) * Vcc;   // V at ADC pin
	float v_signal = v_adc - 2.1f;                         // remove DC offset (can be negative)
	float v_source = v_signal * (587/27); 
	v_source = v_source *1000;                 // undo divider -> volts at source (peak)
	return v_source;
}

int16_t adc_convert_ma_high(uint16_t value) {
	return (((value * Vcc * (float)(1000)/1023) - 2100) / 4.7) *1 / 0.25; //for high current sensor
}

int16_t adc_convert_ma_low(uint16_t value) {
	return (((value * Vcc * (float)(1000)/1023) - 2100) / 10)*1/ 0.25; //for low current sensor
}

void test_current() {
	current_testing = 1;
	ADMUX = (ADMUX & 0xF0) | 1;
	ADCSRA |= (1 << ADATE);
	while(current_testing);
	for(uint8_t i = 0;i<10;i++) {
		current_test[i] = adc_convert_ma_high(current_test[i]);
	}
	float test_Irms = 0.0f;
	for (int i = 0; i < 10; i++) {
		float v = current_test[i] / 1000.0f; // convert mV -> V or mA -> A
		test_Irms += v * v;
	}
	test_Irms = square_root(test_Irms / 10);
	if (test_Irms > 0.2828) {
		low_current = 0;
		} else {
		low_current = 1;
		
	}
}
