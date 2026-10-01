/*
 * display.h
 *
 * Author: Harry McCormick
 */ 

#ifndef DISPLAY_H_
#define DISPLAY_H_

#include <stdint.h>
#include <avr/io.h>


void displayinit();

void seperateAndLoadCharacters(uint16_t number,  uint8_t decimal_pos);

void separateAndLoadFloat(float value);

void sendNextCharacterToDisplay();

void display_values();

#endif