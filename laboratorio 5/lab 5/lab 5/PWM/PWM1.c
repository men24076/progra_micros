/*
 * prelab.c
 *
 * Created: 14/04/2026 8:29:10
 * Author : joe05
 */ 
#include "PWM1.h"

static void PWM1_configPrescaler(uint16_t prescaler) //Funcion para configurar el prescaler
{
	switch (prescaler) //Configuramos cada uno de los prescaleres, desde 1 hasta 1024
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
		TCCR1B |= (1 << CS11);
		break;
	}
}

void PWM1A_init(uint8_t invertido, uint16_t top, uint16_t prescaler) //Funcion que recibe si es invertido, el valor máixmo del timer, y el prescaler
{
	DDRB |= (1 << DDB1);   // Sacamos el PWM  por el pin D9

	TCCR1A = 0;
	TCCR1B = 0;

	// Fast PWM, TOP en ICR1
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM12) | (1 << WGM13);

	if (invertido) //Configuramos la señal para que haga lo opuesto al modo normal
	{
		TCCR1A |= (1 << COM1A1) | (1 << COM1A0);
	}
	else //Configuramos la salida para que no sea invertida es decir iniciar en high y ponerse en low al final del contador
	{
		TCCR1A |= (1 << COM1A1);
		TCCR1A &= ~(1 << COM1A0);
	}

	ICR1 = top; //Valor máximo del contador del timer

	PWM1_configPrescaler(prescaler);
}

void PWM1A_setPulse(uint16_t pulse) //Cambiamos el ancho del pulso
{
	OCR1A = pulse;
}