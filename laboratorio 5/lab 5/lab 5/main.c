/*
 * prelab.c
 *
 * Created: 14/04/2026 8:29:10
 * Author : joe05
 */ 

#define F_CPU 16000000UL
//Inculimos todos los archivos PWM que habiamos utilizado antes
#include <avr/io.h>
#include <stdint.h>
#include <avr/interrupt.h>
#include "PWM/PWM1.h"
#include "PWM/PWM2.h"
#include "PWM/PWMmanual.h"

// ADC
void ADC_init(void);
uint16_t ADC_read(uint8_t canal); //Funcion para leer un valor analogico

// COnvertimos el valor adc a cada uno de los rangos uitles
uint16_t mapADCtoServo1(uint16_t adcValor);
uint8_t mapADCtoServo2(uint16_t adcValor);
uint8_t mapADCtoLED(uint16_t adcValor);

int main(void)
{
	uint16_t adcServo1; //guardamos las lecturas analogicas de los pots
	uint16_t adcServo2;	//guardamos las lecturas analogicas de los pots
	uint16_t adcLED;	//guardamos las lecturas analogicas de los pots

	uint16_t pulsoServo1; //Guardamos los vvalores úitles
	uint8_t dutyServo2;	  //Guardamos los vvalores úitles
	uint8_t dutyLED;	  //Guardamos los vvalores úitles

	ADC_init();

	// Servo 1 en D9 con PWM1
	PWM1A_init(PWM1_NO_INVERTIDO, 39999, 8);

	// Servo 2 en D3 con PWM2
	PWM2_init();

	// LED en D8 con PWM manual
	PWMmanual_init();

	sei(); //Habilitamos interrupciones

	while (1)
	{
		adcServo1 = ADC_read(0);   // A0
		adcServo2 = ADC_read(1);   // A1
		adcLED    = ADC_read(2);   // A2

		pulsoServo1 = mapADCtoServo1(adcServo1); //Convertimos el valor de ADC a rango de timer 1
		dutyServo2  = mapADCtoServo2(adcServo2); //Convertimos el valor de ADC a timer 2
		dutyLED     = mapADCtoLED(adcLED);		 //Convertimos el valor de ADC a 0 a 100

		PWM1A_setPulse(pulsoServo1);  // D9 //Cabmiamos el ancho de pulso. por lo cual cambia la posición del servo
		PWM2_setDuty(dutyServo2);     // D3	//Cabmiamos el ancho de pulso. por lo cual cambia la posición del servo
		PWMmanual_setDuty(dutyLED);   // D8	//Cabmiamos el ancho de pulso. por lo cual cambia la intesidad del LED
	}
}

void ADC_init(void)
{
	ADMUX = 0;
	ADCSRA = 0;

	// Referencia 5V
	ADMUX |= (1 << REFS0);

	// Habilitar ADC
	ADCSRA |= (1 << ADEN);

	// Prescaler 128
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_read(uint8_t canal) //leemos el canal ADC y lo convierte
{
	ADMUX &= 0xF0; //Borramos los bits del canal de la parte Alta
	ADMUX |= (canal & 0x0F); //ponemos los bits en el canal que se requiere

	ADCSRA |= (1 << ADSC); //Convertimos

	while (ADCSRA & (1 << ADSC));

	return ADC; //Devuelve el valor
}

uint16_t mapADCtoServo1(uint16_t adcValor) //Convierte el valor del servo 1
{

	return (uint16_t)(1000UL + ((uint32_t)adcValor * 4000UL) / 1023UL); //Rango util del servo
}

uint8_t mapADCtoServo2(uint16_t adcValor) //ADC a timer 2
{

	return (uint8_t)(8 + ((uint32_t)adcValor * 31UL) / 1023UL); //rango util del servo
}

uint8_t mapADCtoLED(uint16_t adcValor) //ADC a duty para LED
{
	// 0a 1023 / 0 a100
	return (uint8_t)(((uint32_t)adcValor * 100UL) / 1023UL);
}