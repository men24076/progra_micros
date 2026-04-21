/*
 * lab 6.c
 *
 * Created: 21/04/2026 10:17:06
 * Author : joe05
 */ 

#define F_CPU 16000000UL
#define BAUD 9600
#define UBRR_VALUE ((F_CPU/16/BAUD)-1)

#include <avr/io.h>

// ===== UART INIT =====
void UART_init(void)
{
	UBRR0H = (UBRR_VALUE >> 8);
	UBRR0L = UBRR_VALUE;

	// Habilitar TX y RX
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);

	// 8 bits, 1 stop, sin paridad
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

// Transmitir data
void UART_tx(char data)
{
	while (!(UCSR0A & (1 << UDRE0))); // Espera buffer vacío
	UDR0 = data;
}

// Recibir data
char UART_rx(void)
{
	while (!(UCSR0A & (1 << RXC0))); // Espera dato recibido
	return UDR0;
}


int main(void)
{
	UART_init();

	// Puerto B como salida (d8-d12)
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4);

	// Puerto D como salida (d5-d7)
	DDRD |= (1 << PD5) | (1 << PD6) | (1 << PD7);

	while (1)
	{
		// enviar carácter
		UART_tx('A');

		// delay
		for (volatile long i = 0; i < 500000; i++);

		//recibir carácter y mostrarlo
		char dato = UART_rx();

		// Limpiar salidas usadas
		PORTB &= ~((1 << PB0)|(1 << PB1)|(1 << PB2)|(1 << PB3)|(1 << PB4));
		PORTD &= ~((1 << PD5)|(1 << PD6)|(1 << PD7));

		//Prender leds
		if (dato & (1 << 0)) PORTB |= (1 << PB4);

		
		if (dato & (1 << 1)) PORTB |= (1 << PB3);

		
		if (dato & (1 << 2)) PORTB |= (1 << PB2);

		
		if (dato & (1 << 3)) PORTB |= (1 << PB1);

		
		if (dato & (1 << 4)) PORTB |= (1 << PB0);

		
		if (dato & (1 << 5)) PORTD |= (1 << PD7);

		
		if (dato & (1 << 6)) PORTD |= (1 << PD6);

		
		if (dato & (1 << 7)) PORTD |= (1 << PD5);
	}
}