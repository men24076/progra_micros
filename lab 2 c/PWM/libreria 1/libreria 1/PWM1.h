/*
 * libreria 1.c
 *
 * Created: 14/04/2026 8:50
 * Author : joe05
 */ 

#ifndef PWM1_H_
#define PWM1_H_

#include <avr/io.h>
#include <stdint.h>

#define PWM1_NO_INVERTIDO   0
#define PWM1_INVERTIDO      1

void PWM1A_init(uint8_t invertido, uint16_t top, uint16_t prescaler);
void PWM1A_setPulse(uint16_t pulse);

void PWM1B_init(uint8_t invertido, uint16_t top, uint16_t prescaler);
void PWM1B_setPulse(uint16_t pulse);

#endif /* PWM1_H_ */
