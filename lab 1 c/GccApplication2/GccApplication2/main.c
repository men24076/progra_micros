/*
 * NombreProgra.c
 *
 * Created: 9/4 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#define 
#include ""
/****************************************/
// Function prototypes

/****************************************/
// Main Function
int main(void)
{
	uint8_t duty = 127;
	setup();
	initPWM0();
	while(1)
	{
	updateDutyCycle0A(duty);
	updateDutyCycle0B(duty);
		
	}
	
}
/****************************************/
// NON-Interrupt subroutines
void setup ()
{
	CLKPR = (1<<CLKPCE)
	CLKPR = (1<<CLKPCE2)
	
}
void initPWM0()
{
	//Configurar salidas
	DDRD |= (1<<DDD6) | (1<<DD5)
	
	TCCR0A = 0;
	TCCR0B + 0;
	//NO INVERTIDO OCR0A E INVERTIDO OCR0B
	TCCR0A |=(1<<COM0A1); //INVERTIDO PD6
	TCCR0A |=(1<<COM0B1)| (1<<COM0B0); //INVERTIDO PD5
	
	TCCR0A |= (1<<WGM01) | (1<<WGM00); // FAST PWM
	
	TCCR0B |= (1<<CS01); // PRESCALER = 8
}
void updateDutyCycle0A(uint8_t ciclo)
{
	OCR0A = ciclo;
}
/****************************************/
// Interrupt routines

