/*
 * UART functions
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#ifndef UART_H
#define UART_H

#include <stdint.h>  // for uint8_t and similar file types

// INITIALISATION
void uart_init(unsigned long cpu_freq, int baud_rate);


// HELPER FUNCTIONS
char int_to_ascii(uint8_t num);

void new_line();


// UART FUNCTIONS
void uart_transmit(uint8_t data);

void uart_transmit_int(int16_t num);

void uart_transmit_float(float num, uint8_t dp);

void uart_transmit_string(char message[]);

#endif