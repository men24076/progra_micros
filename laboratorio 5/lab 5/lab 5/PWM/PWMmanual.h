/*
 * PWMmanual.h
 *
 * Created: 19/04/2026 21:54:48
 *  Author: joe05
 */ 

#ifndef PWMMANUAL_H_
#define PWMMANUAL_H_

#include <avr/io.h>
#include <stdint.h>

void PWMmanual_init(void); //definimos los parametros de los que depende cada funcion
void PWMmanual_setDuty(uint8_t duty); //definimos los parametros de los que depende cada funcion

#endif