/*
 * lab_1_c.c
 *
 * Created: 7/04/2026 09:36:50
 * Author : joe05
/*
 *              PB2 incrementa el contador   
 *              PB3 decrementa el contador   
/**************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>

/**************/
// Function prototypes
void setup(void);
uint8_t boton(uint8_t pin);
void mostrarContador(uint8_t valor);

/**************/
// Main Function
int main(void)
{
	uint8_t counter = 0;
	
	setup();
	mostrarContador(counter);
	
	while (1) 
	{
		// Incrementar con boton en PB2 
		if (boton(PB2))
		{
			counter++;
			mostrarContador(counter);

			// esperar a que suelte el boton
			while (!(PINB & (1 << PB2)));
			_delay_ms(20);
		}

		// Decrementar con boton en PB3 (D11)
		if (boton(PB3))
		{
			counter--;
			mostrarContador(counter);

			// esperar a que suelte el boton
			while (!(PINB & (1 << PB3)));
			_delay_ms(20);
		}
	}
}

/**************/
// NON-Interrupt subroutines
void setup(void)
{
	// Desactivamos USART
	UCSR0B = 0x00;

	//salidas
	DDRD |= 0b11111100;
	PORTD &= ~0b11111100;
	DDRB |= (1 << PB0) | (1 << PB1);
	PORTB &= ~((1 << PB0) | (1 << PB1));

	// D10-D11 habilitamos pull up 
	DDRB &= ~((1 << PB2) | (1 << PB3));
	PORTB |= (1 << PB2) | (1 << PB3);
}

uint8_t boton(uint8_t pin)
{
	// detectar interaccion con el boton
	if (!(PINB & (1 << pin)))
	{
		_delay_ms(20);

		if (!(PINB & (1 << pin)))
		{
			return 1;
		}
	}
	return 0;
}

void mostrarContador(uint8_t valor)
{
	// Bits 0-5 del contador 
	PORTD = (PORTD & 0b00000011) | ((valor & 0b00111111) << 2);

	// Bits 6-7 del contador
	PORTB = (PORTB & 0b11111100) | ((valor >> 6) & 0b00000011);
}

/**************/
// Interrupt routines

