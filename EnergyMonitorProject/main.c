/*
 * Implementation for blabalbla finish description when project is done
 *
 * Authors: Team 8 (Elia Stolk, Soriyana Hor, Rachel Pan, Harry McCormick)
 */ 

#include "common.h"
#include "uart.h"
#include "adc.h"
#include "power.h"
#include "timer.h"
#include <util/delay.h>
#include <avr/io.h>
#include <avr/interrupt.h>


void init() {
	uart_init(F_CPU, BAUD);
	timer0_init();
	timer1_init();
	timer2_init();
	adc_init();
	displayinit();
	sei();
}


int main(void)
{
	init();
	
	while (1) {
		
		calculate_power();
		uart_transmit_string("P: ");
		uart_transmit_float((float)P_measured, 3);
		uart_transmit_string(" W, Vrms: ");
		uart_transmit_float((float)Vrms, 3);
		uart_transmit_string(" V, Ipeak: ");
		uart_transmit_float((float)Ipeak, 3);
		uart_transmit_string(" A");
		new_line();
		//display_values();
		
	}
}