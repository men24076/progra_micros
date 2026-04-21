/*
 * prelab.h
 *
 * Created: 14/04/2026 8:29:10
 * Author : joe05
 */ 
#ifndef PWM1_H_
#define PWM1_H_ //Definimos pw1_H

#include <avr/io.h>
#include <stdint.h>

#define PWM1_NO_INVERTIDO   0 //Variable no invertida
#define PWM1_INVERTIDO      1 //Variable invertida

void PWM1A_init(uint8_t invertido, uint16_t top, uint16_t prescaler); //indicamos los parámetros que recibe cada función
void PWM1A_setPulse(uint16_t pulse);								  //indicamos los parámetros que recibe cada función

#endif 