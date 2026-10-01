/*
 * UART Functions
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#include "common.h"
#include "uart.h"
#include <avr/io.h>
#include <string.h>


// INITIALISATION
void uart_init(unsigned long cpu_freq, int baud_rate) {
	UBRR0 = (cpu_freq / baud_rate) / 16 - 1;  // Calculate baud rate and set register
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);  // Enable transmit and receive
	UCSR0C = (1<<UCSZ01)|(1<<UCSZ00);  // set frame format: 8 data bits, 1 stop bit
}


// HELPER FUNCTIONS
char int_to_ascii(uint8_t num) {
	return num + 48;
}

void new_line() {
	uart_transmit(13);
}


// UART FUNCTIONS
void uart_transmit(uint8_t data) {
	while (!(UCSR0A & (1 << UDRE0))) {}  // wait for empty transmit buffer
	UDR0 = data;  // send data to buffer
}

void uart_transmit_int(int16_t num) {
	if (num == 0) {
		uart_transmit('0');
		return;
	}
	if (num < 0) {
		uart_transmit(45);
		num = -num;
	}
	
	uint8_t digits[5];  // Maximum digits for uint16_t is 5 (65535)
	uint8_t index = 0;
	
	while (num > 0 && index < 5) {
		digits[index++] = num % 10;
		num /= 10;
	}
		for (int i = index; i > 0; i--) {
			uart_transmit(int_to_ascii(digits[i - 1]));
		}
	}

void uart_transmit_float(float num, uint8_t dp) {
	if (dp > 4) dp = 4;  // max value for dp is 4
	uart_transmit_int((uint16_t) num);  // transmit the whole numbers
	
	uint16_t decimals = (num - (uint16_t) num) * power(10, dp);  // extract decimals and convert to whole numbers
	uart_transmit('.');
	float decimals_float = (num - (uint16_t) num);
	if(decimals_float < 0.1) {
		uart_transmit_int(0);
	}
	if (decimals_float < 0.01) {
		uart_transmit_int(0);
	}
	if (decimals_float < 0.001) {
		uart_transmit_int(0);
	}
	uart_transmit_int(decimals);  // transmit the decimals at dp decimal places
}

void uart_transmit_string(char message[]) {
	for (int index = 0; index < strlen(message); index++) {
		uart_transmit(message[index]);
	}
}
