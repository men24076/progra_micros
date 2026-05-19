/*
 * servo.c
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el servo en tipo C.
 */
#include "servo.h"
#include "../config/config.h"

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>

#define SERVO_MIN_US 600 // minimo tiks en el servo
#define SERVO_MAX_US 2400 //máximo tiks en el servo

volatile uint8_t servo_angle[NUM_SERVOS] = {0, 0, 0, 0}; //Iniciamos con los angulos en 90

volatile uint16_t servo3_pulse_us = 600; //Guardamos para que los servos 3 y 4 comiencen en 0
volatile uint16_t servo4_pulse_us = 600;

volatile uint16_t timer2_time_us = 0;

static uint16_t angleToPulse(uint8_t angle)
{
	if (angle > 180) angle = 180; //No permite que el angulo se pase de 180

	return SERVO_MIN_US +
	((uint32_t)angle * (SERVO_MAX_US - SERVO_MIN_US)) / 180; //Sumamos 600 a en angulo por la diferencia del minimo partido 180 para convertir a microsegundos los grados
}

void Servo_init(void)
{
	DDRB |= (1 << PB1) | (1 << PB2) | (1 << PB3); //Ponemos donde están todos los servos siendo d9 d10
	DDRD |= (1 << PD3); //Esta en d3

//timer 1 con servo 1 y 2 a través del modo fast
	TCCR1A = 0;
	TCCR1B = 0;

	TCCR1A |= (1 << COM1A1) | (1 << COM1B1); //Activamos pwm en d9 y d10
	TCCR1A |= (1 << WGM11); //Fast PWM

	TCCR1B |= (1 << WGM13) | (1 << WGM12); //Top en ICR1
	TCCR1B |= (1 << CS11); //Prescaler de 8

	ICR1 = 39999; //20ms lo cual tiene una frecuencia de 50hz

	OCR1A = 3000; //pulso de 90 grados para comenzar
	OCR1B = 3000;

//timer 2 con servo 3 y 4 a través de interrupciones
	TCCR2A = 0;
	TCCR2B = 0;

	TCCR2A |= (1 << WGM21); //Timer en modo ctc
	TCCR2B |= (1 << CS21); //Prescaler de 8

	OCR2A = 19; //Interrupción cada 10 micro segundos

	TIMSK2 |= (1 << OCIE2A); //Habilitamos las interrupciones por comparación

	sei();
}

void Servo_angle(uint8_t servo, uint8_t angle)
{
	uint16_t pulse;

	if (servo >= NUM_SERVOS) return;
	if (angle > 180) angle = 180;

	servo_angle[servo] = angle; //Guardamos el angulo actual
	pulse = angleToPulse(angle); //Convertimos el angulo a microsegundos otravez

	if (servo == 0)
	{
		OCR1A = pulse * 2; //Multiplica por 2 y cuenta de 0.5 micros
	}
	else if (servo == 1) //misma logica
	{
		OCR1B = pulse * 2;
	}
	else if (servo == 2)
	{
		servo3_pulse_us = pulse; //Guarda el pulso para saber cuando apagar d3
	}
	else if (servo == 3)
	{
		servo4_pulse_us = pulse; //misma logica
	}
}

uint8_t Servo_save(uint8_t servo)
{
	if (servo >= NUM_SERVOS) return 90;

	return servo_angle[servo]; //guarda el ángulo del servo, y si no existe lo regresa a 90
}

ISR(TIMER2_COMPA_vect)
{
	timer2_time_us += 10; //La interrupción ocurre cada 10 micros entonces aumenta el contador

	if (timer2_time_us >= 20000) //Reinicia la pwm cuando ya pasaron 20 ms
	{
		timer2_time_us = 0;

		PORTD |= (1 << PD3); //enciende servo 3 y 4
		PORTB |= (1 << PB3);
	}

	if (timer2_time_us >= servo3_pulse_us) //apaga el servo 1 vez supera los pulsos del mismo
	{
		PORTD &= ~(1 << PD3);
	}

	if (timer2_time_us >= servo4_pulse_us)
	{
		PORTB &= ~(1 << PB3);
	}
}