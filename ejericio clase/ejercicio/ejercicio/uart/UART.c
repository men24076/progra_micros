/*
 * CFile1.c
 *
 * Created: 23/04/2026 14:39:28
 *  Author: joe05
 */ 
#include "UART.h" 
void init_UART()
{
	//Configurar pines
	DDRD &=~(1<<DDD0);//D0=RX entrada
	DDRD |=(1<<DDD0);//D1=TX salida
	//Normal speed
	UCSR0A=0;
	//Habilitar interrupcion de RX, habilitar RX y TX
	UCSR0B =(1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);
	// Pongo que vamos a usar 8 bits, modo asincrono, 1 stop bit y sin paridad
	UCSR0C =(1<<UCSZ01)|(1<<UCSZ00);
	// Cargar UBRR0
	UBRR0=103;
	
}
