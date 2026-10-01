#ifndef POWER_H
#define POWER_H

#include <stdint.h>


// Calculations



float calculate_rms(float *samples, int len);


void remove_dc_offset(int16_t* signal);

void linear_interpolate_float(const int16_t* input, float* output, int factor);


static float cubicInterpolate(float y0, float y1, float y2, float y3, float t);

void cubic_interpolate_int16(const int16_t* input, float* output, int input_len, int factor);

void remove_dc_offset_float(float* data, int len);

#endif