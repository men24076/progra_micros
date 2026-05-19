/*
 * uart.c
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el uart en tipo C.
 */
#include "uart.h"
#include "../config/config.h"

#include <avr/io.h>

#define BAUD 9600 //Baud rate a 9600
#define UBRR_VALUE ((F_CPU / 16 / BAUD) - 1) //Determina el valor del UBBR para que vaya a 9600

void UART_init(void)
{
	UBRR0H = (uint8_t)(UBRR_VALUE >> 8); //Parte alta y baja del ubbr
	UBRR0L = (uint8_t)UBRR_VALUE;

	UCSR0B = (1 << RXEN0) | (1 << TXEN0); //Activamos recepción y transmisión en la uart

	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); //Sin paridad y un stop bit
}

uint8_t UART_available(void)
{
	return (UCSR0A & (1 << RXC0)); //Indicamos que ya llego un dato
}

char UART_read(void)
{
	return UDR0; //leemos el dato recibido
}

void UART_sendChar(char data)
{
	while (!(UCSR0A & (1 << UDRE0))); //Esperamos a que este vacío para enviar un dato

	UDR0 = data; //Dato enviado
}

void UART_sendString(const char *str) //Envia un texto completo a través del puntero
{
	while (*str)
	{
		UART_sendChar(*str);
		str++; //Envia caractéres hasta que se acaben
	}
}