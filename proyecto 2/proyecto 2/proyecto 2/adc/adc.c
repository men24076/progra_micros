/*
 * adc.c
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el adc en tipo C.
 */
#include "adc.h"
#include <avr/io.h>

void ADC_init(void)
{
	ADMUX = (1 << REFS0); //Referencia en 5V

	ADCSRA = (1 << ADEN) |
	(1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); //Habilitamos el ADC con prescaler de 128
}

uint16_t ADC_read(uint8_t channel) //Leemos el potenciometro
{
	channel &= 0x07; 

	ADMUX = (ADMUX & 0xF0) | channel; //Seleccionamos el canal del adc, ya sea a0 a1 a2 o a3

	ADCSRA |= (1 << ADSC); //conversión del adc

	while (ADCSRA & (1 << ADSC)); //espera la conversión

	return ADC;
}