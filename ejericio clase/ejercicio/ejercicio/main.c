/*
 * ejercicio.c
 *
 * Created: 23/04/2026 14:36:33
 * Author : joe05
 */ 

/**************/
// Encabezado (Libraries)
#include "uart/UART.h"

/**************/
// Function prototypes
void init_UART();
void writeChar(char c);
void writeString(char* string);
/**************/
// Main Function
int main(void)
{
	cli();
	DDRB|=(1<<DDB5);
	DDRD|=(1<<DDD5);
	PORTB &= ~(1<<PORTB5);
	PORTD &= ~(1<<PORTD5);
	init_UART();
	sei();
	writeChar('H');
	writeChar('o');
	writeChar('l');
	writeChar('a');
	while (1)
	{
	}
}

/**************/
// NON-Interrupt subroutines
void writeChar(char c)
{
	while(!(UCSR0A & (1<<UDRE0)));
	
	UDR0=c;
}
void writeString(char* string)
{
	for(uint8_t i=0; string[i] !='\0';i++)
	{
		writeChar(string[i]);
	}
}

/**************/
// Interrupt routines
ISR(USART_RX_vect)
{
	uint8_t bufferRX=UDR0;
	writeChar((bufferRX));
	if (bufferRX=='a')
	{
		PORTB|= (1<<PORTB5);
		PORTD|= (1<<PORTD5);
	}
	if (bufferRX=='b')
	{
		PORTB &= ~(1<<PORTB5);
		PORTD &= ~(1<<PORTD5);
	}
}

// UCSR0B = 0x00; //desactivar usart
