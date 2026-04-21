/*
 * PWM2.h
 *
 * Created: 14/04/2026 15:15:58
 *  Author: joe05
 */ 

#ifndef PWM2_H_
#define PWM2_H_

#include <avr/io.h>
#include <stdint.h>

void PWM2_init(void);
void PWM2_setDuty(uint8_t duty);

#endif /* PWM2_H_ */