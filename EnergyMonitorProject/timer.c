



#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "timer.h"
#include "common.h"
#include "display.h"

volatile uint8_t counter = 0;
uint16_t volatile count = 0;
volatile uint8_t display_mode = 0;
volatile float display_val = 0;
volatile float time_elapsed = 0;

ISR(TIMER0_COMPA_vect) {
	
}


ISR(TIMER2_COMPA_vect) {
	counter++;
	
	// Only update display if still displaying
	if (displaying) {
		
		switch (display_mode) {
			case 0: 
			display_val = Vrms;
			PORTB |= (1 << PB0);
			 break;
			case 1: 
			display_val = Ipeak;
			PORTB &= ~(1 << PB0);
			PORTB |= (1 << PB1);
			 break;
			case 2: 
			display_val = P_measured;
			PORTB &= ~(1 << PB1);
			PORTB |= (1 << PB2);
			 break;
			case 3:
			 display_val = energy;
			 PORTB &= ~(1 << PB2);
			 PORTB |= (1 << PB3);
			  break;
		}
		display_val = round_float(display_val, 3);
		separateAndLoadFloat(display_val);
		sendNextCharacterToDisplay();
	}

	// Advance mode counter
	if(counter >= 100) {
		counter = 0;
		display_mode++;
		if(display_mode >= 4) {
			display_mode = 0;
			TIMSK1 &= ~(1 << OCIE1A); // stop timer interrupt
			displaying = 0;
			// Turn off all digits
			PORTD |= ((1 << PD4) | (1 << PD5) | (1 << PD6) | (1 << PD7));
			PORTB &= ~(1 << PB3);
			
		}
	}
}


void timer0_init(){
	//Initialise and configure timer0 to count to 120 us - for adc/power calculation
	TCCR0A &= ~(1 << WGM00); //Set to CTC mode
	TCCR0A |= (1 << WGM01);  //Set to CTC mode
	TCCR0B = (1 << CS00);  // No prescaler
	OCR0A = 240;
	TCNT0 = 0;
}

void timer1_init(){
	//Initialise and configure timer1 to count to 10 ms - for energy calculation
	TCCR1A = 0;                // Normal mode
	TCCR1B = (1 << CS12);      // Prescaler = 256
	TCNT1 = 0; // reset timer1

}

void timer2_init(){//- for display
	TCCR2A = (1 << WGM21);  // CTC mode
	TCCR2B = (1 << CS22) | (1 << CS20); // Prescaler = 128
	OCR2A = 155;             // Compare value for 10 ms
	TCNT2 = 0;
}



