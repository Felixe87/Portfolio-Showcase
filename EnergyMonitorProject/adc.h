/*
 * ADC Functions
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#ifndef _ADC_H
#define _ADC_H

#include <stdint.h>

void adc_init();
int16_t adc_convert_mv(uint16_t value);
int16_t adc_convert_ma_high(uint16_t value);
int16_t adc_convert_ma_low(uint16_t value);
static float calculate_rms_from_adc_counts(uint16_t *adc_buf, uint8_t len, uint8_t use_low_sensor);
void adc_warmup_dummy(void);

#endif