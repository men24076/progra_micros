/*
 * prelab.c
 *
 * Created: 14/04/2026 8:29:10
 * Author : joe05
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <stdint.h>
#include "PWM/PWM1.h"

void ADC_init(void);
uint16_t ADC_read(uint8_t canal);
uint16_t mapADCtoServo(uint16_t adcValor);

int main(void)
{
	uint16_t adcValor = 0;
	uint16_t pulsoServo = 3000;

	ADC_init();

	// Servo en D9 = OC1A
	// TOP = 39999 para 20 ms con prescaler 8
	PWM1A_init(PWM1_NO_INVERTIDO, 39999, 8);

	while (1)
	{
		adcValor = ADC_read(0);                 // A0
		pulsoServo = mapADCtoServo(adcValor);   // 2000 a 4000
		PWM1A_setPulse(pulsoServo);
	}
}

void ADC_init(void)
{
	ADMUX = 0;
	ADCSRA = 0;

	// Referencia AVcc
	ADMUX |= (1 << REFS0);

	// Habilitar ADC
	ADCSRA |= (1 << ADEN);

	// Prescaler 128 -> 16MHz/128 = 125kHz
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_read(uint8_t canal)
{
	// Limpiamos selección anterior
	ADMUX &= 0xF0;

	// Seleccionamos canal ADC0..ADC7
	ADMUX |= (canal & 0x0F);

	// Inicia conversión
	ADCSRA |= (1 << ADSC);

	// Espera a que termine
	while (ADCSRA & (1 << ADSC));

	// ADC es de 10 bits
	return ADC;
}

uint16_t mapADCtoServo(uint16_t adcValor)
{
	// Mapea 0..1023 a 2000..4000
	// 2000 = 1 ms
	// 3000 = 1.5 ms
	// 4000 = 2 ms
	return (uint16_t)(2000UL + ((uint32_t)adcValor * 2000UL) / 1023UL);
}

