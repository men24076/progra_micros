#include "PWM2.h"

void PWM2_init(void)
{
	// D3 = PD3 = OC2B
	DDRD |= (1 << DDD3);

	TCCR2A = 0;
	TCCR2B = 0;

	// Fast PWM
	TCCR2A |= (1 << WGM20) | (1 << WGM21);

	// No invertido en OC2B
	TCCR2A |= (1 << COM2B1);

	// Prescaler 1024 (~61 Hz)
	TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);
}

void PWM2_setDuty(uint8_t duty)
{
	OCR2B = duty;
}