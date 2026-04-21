/*
 * PWMmanual.c
 *
 * Created: 19/04/2026 21:55:30
 *  Author: joe05
 */ 
#include "PWMmanual.h"
#include <avr/interrupt.h>

volatile uint8_t pwm_manual_duty = 0;

void PWMmanual_init(void)
{
	// D8 = PB0
	DDRB |= (1 << DDB0);

	// LED apagado al inicio
	PORTB &= ~(1 << PORTB0);

	// Timer0 en modo CTC
	TCCR0A = 0;
	TCCR0B = 0;
	TIMSK0 = 0;

	TCCR0A |= (1 << WGM01);

	// Interrupción cada 50 us
	// F_CPU = 16 MHz
	// Prescaler = 8 -> 2 MHz
	// 50 us -> 100 cuentas -> OCR0A = 99
	OCR0A = 99;

	// Habilitar interrupción compare match A
	TIMSK0 |= (1 << OCIE0A);

	// Prescaler = 8
	TCCR0B |= (1 << CS01);
}

void PWMmanual_setDuty(uint8_t duty)
{
	if (duty > 100)
	{
		duty = 100;
	}

	pwm_manual_duty = duty;
}

ISR(TIMER0_COMPA_vect)
{
	static uint8_t contador = 0;

	// Inicio del periodo
	if (contador == 0)
	{
		if (pwm_manual_duty > 0)
		{
			PORTB |= (1 << PORTB0);
		}
		else
		{
			PORTB &= ~(1 << PORTB0);
		}
	}

	// Cuando llega al duty, apaga el LED
	if ((contador == pwm_manual_duty) && (pwm_manual_duty < 100))
	{
		PORTB &= ~(1 << PORTB0);
	}

	contador++;

	if (contador >= 100)
	{
		contador = 0;
	}
}