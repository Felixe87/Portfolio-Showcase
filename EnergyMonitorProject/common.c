/*
 * Common functions and variables
 * !!!!Global defines are located in the .h file!!!!
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#include "common.h"

float P_measured;
float Vrms;
float Ipeak;
float energy;
volatile int16_t adc_voltage_samples[SAMPLE_SIZE];
volatile int16_t adc_current_samples[SAMPLE_SIZE];
volatile uint8_t sampling_done = 0;
volatile uint8_t calculation_done = 0;
volatile uint8_t low_current = 0;
volatile uint8_t sample_count = 0;
volatile uint8_t displaying = 0;

uint32_t power(uint32_t base, uint8_t exponent) {
	// borrowed from the internet, so I can avoid including <math.h> to save memory
	// however I have modified it to be simpler, only taking uint8_t exponents because I don't expect large values
	uint32_t result = 1;
	while (exponent > 0) {
		if (exponent & 1) result *= base;  // black magic idk
		base *= base;
		exponent >>= 1;
	}
	return result;
}

float square_root(float n) {
	if (n < 0.0f)
	return -1.0f;  // error value

	if (n == 0.0f || n == 1.0f)
	return n;

	float x = n * 0.5f;       // initial guess
	const float epsilon = 1e-6f;
	float guess = n;          // starting point

	// Newton–Raphson iteration
	while (1) {
		float new_guess = 0.5f * (guess + n / guess);
		if (new_guess == guess || (new_guess - guess < epsilon && new_guess - guess > -epsilon))
		break;
		guess = new_guess;
	}
	return guess;
}

float round_float(float num, uint8_t dp) {
	float factor = 1.0f;
	for (uint8_t i = 0; i < dp; i++) factor *= 10.0f;
	return (uint32_t)(num * factor + 0.5f) / factor;
}
