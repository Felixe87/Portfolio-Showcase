/*
 * Common functions and variables
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#ifndef _COMMON_H
#define _COMMON_H

#define F_CPU 2000000UL
#define BAUD 9600
#define Vcc 5.0f
#define SAMPLE_SIZE 50 //6 cycles per signal
#define UPSAMPLE_FACTOR 3
#define SAMPLES_PER_CYCLE 25
#define OUTPUT_LEN ((SAMPLE_SIZE - 1) * UPSAMPLE_FACTOR + 1)

#include <stdint.h>  // for uint8_t and similar file types

extern float P_measured;
extern float Vrms;
extern float Ipeak;
extern float energy;
extern volatile int16_t adc_voltage_samples[SAMPLE_SIZE];
extern volatile int16_t adc_current_samples[SAMPLE_SIZE];
extern volatile uint8_t sampling_done;
extern volatile uint8_t low_current;
extern volatile uint8_t calculation_done;
extern volatile uint8_t sample_count;
extern volatile uint8_t displaying;

float square_root(float n);

uint32_t power(uint32_t base, uint8_t exponent);

float round_float(float num, uint8_t dp);

#endif

