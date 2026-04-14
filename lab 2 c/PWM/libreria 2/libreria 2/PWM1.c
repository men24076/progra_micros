#include "PWM1.h"

static void PWM1_configPrescaler(uint16_t prescaler)
{
	switch (prescaler)
	{
		case 1:
		TCCR1B |= (1 << CS10);
		break;

		case 8:
		TCCR1B |= (1 << CS11);
		break;

		case 64:
		TCCR1B |= (1 << CS11) | (1 << CS10);
		break;

		case 256:
		TCCR1B |= (1 << CS12);
		break;

		case 1024:
		TCCR1B |= (1 << CS12) | (1 << CS10);
		break;

		default:
		TCCR1B |= (1 << CS11);   //  prescaler 8
		break;
	}
}

void PWM1A_init(uint8_t invertido, uint16_t top, uint16_t prescaler)
{
	DDRB |= (1 << DDB1);   // PB1 =  salida

	TCCR1A = 0;
	TCCR1B = 0;

	// Modo Fast PWM con TOP en ICR1
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM12) | (1 << WGM13);

	if (invertido)
	{
		TCCR1A |= (1 << COM1A1) | (1 << COM1A0);
	}
	else
	{
		TCCR1A |= (1 << COM1A1);
	}

	ICR1 = top;
	PWM1_configPrescaler(prescaler);
}

void PWM1A_setPulse(uint16_t pulse)
{
	OCR1A = pulse;
}

void PWM1B_init(uint8_t invertido, uint16_t top, uint16_t prescaler)
{
	DDRB |= (1 << DDB2);   // PB2 =  salida

	TCCR1A = 0;
	TCCR1B = 0;

	// Modo Fast PWM con TOP en ICR1
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM12) | (1 << WGM13);

	if (invertido)
	{
		TCCR1A |= (1 << COM1B1) | (1 << COM1B0);
	}
	else
	{
		TCCR1A |= (1 << COM1B1);
	}

	ICR1 = top;
	PWM1_configPrescaler(prescaler);
}

void PWM1B_setPulse(uint16_t pulse)
{
	OCR1B = pulse;
}