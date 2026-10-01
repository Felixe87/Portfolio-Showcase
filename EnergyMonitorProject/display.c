/*
 * display.c
 *
 * Author: Harry McCormick
 */ 

#include <stdint.h>
#include <avr/io.h>
#include "display.h"
#include "common.h"


uint8_t const sevenFigArray[] = {0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111}; // Bit patterns for numbers 0 to 9 for seven segment display

static volatile uint8_t disp_characters[4] = {0, 0, 0, 0};
static volatile uint8_t disp_position = 0;
static volatile int8_t decimal_pos = -1;  // -1 for no decimal point


void displayinit() {
	DDRD |= ((1 << PD4) | (1 << PD5) | (1 << PD6) | (1 << PD7));
	DDRC |= ((1 << PC3) | (1 << PC4) | (1 << PC5));
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3);
}

void seperateAndLoadCharacters(uint16_t number,  uint8_t decimal_pos) {
	disp_characters[0] = number / 1000;
	disp_characters[1] = (number / 100) % 10;
	disp_characters[2] = (number / 10) % 10;
	disp_characters[3] = number % 10;
}

void separateAndLoadFloat(float value)
{
	if (value < 0.0f) value = 0.0f;
	if (value > 9999.0f) value = 9999.0f;

	uint32_t scaled;
	
	if (value < 10.0f) {       // 1.xxx
		scaled = (uint32_t)(value * 1000.0f + 0.5f);
		decimal_pos = 0;
		} else if (value < 100.0f) { // xx.xx
		scaled = (uint32_t)(value * 100.0f + 0.5f);
		decimal_pos = 1;
		} else if (value < 1000.0f) { // xxx.x
		scaled = (uint32_t)(value * 10.0f + 0.5f);
		decimal_pos = 2;
		} else {                    // xxxx
		scaled = (uint32_t)(value + 0.5f);
		decimal_pos = -1;
	}

	// Split digits
	disp_characters[0] = (scaled / 1000) % 10;
	disp_characters[1] = (scaled / 100) % 10;
	disp_characters[2] = (scaled / 10) % 10;
	disp_characters[3] = scaled % 10;

	// Blank leading zeros except the one just before decimal
	for (uint8_t i = 0; i < 3; i++) {
		if (i < decimal_pos && disp_characters[i] == 0)
		disp_characters[i] = 0xFF;
		else
		break;
	}
}

void sendNextCharacterToDisplay(void) {
	// Turn all digits off before loading data
	PORTD |= ((1 << PD4) | (1 << PD5) | (1 << PD6) | (1 << PD7));

	// Load bit pattern
	uint8_t digit = disp_characters[disp_position];
	uint8_t bitPattern;

	if (digit == 0xFF) {
		bitPattern = 0x00;  // blank
		} else {
		bitPattern = sevenFigArray[digit];
		if (disp_position == decimal_pos)
		bitPattern |= (1 << 7);
	}

	// Shift bits into 74HC595
	for (int8_t i = 7; i >= 0; i--) {
		if (bitPattern & (1 << i))
		PORTC |= (1 << PC4);
		else
		PORTC &= ~(1 << PC4);
		PORTC |= (1 << PC3);
		PORTC &= ~(1 << PC3);
	}

	// Latch data
	PORTC |= (1 << PC5);
	PORTC &= ~(1 << PC5);

	// Turn on the correct digit (assuming PD2 = leftmost)
	switch (disp_position) {
		case 0: PORTD &= ~(1 << PD4); break;
		case 1: PORTD &= ~(1 << PD5); break;
		case 2: PORTD &= ~(1 << PD6); break;
		case 3: PORTD &= ~(1 << PD7); break;
	}

	// Move to next position
	disp_position = (disp_position + 1) & 0x03;
}

void display_values(){
	displaying = 1;
	TIMSK2 |= (1 << OCIE2A);  // enable compare match A interrupt enable
	TCNT2 = 0;
	while(displaying);
}