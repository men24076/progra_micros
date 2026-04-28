/*  
 * lab 6.c
 *
 * Created: 21/04/2026 10:17:06
 * Author : joe05
 */ 

#define F_CPU 16000000UL
#define BAUD 9600 //baud rate a 9600
#define UBRR_VALUE 103 //Velocidad del uart

#include <avr/io.h>

// ===== UART INIT =====
void UART_init(void)
{
	UBRR0H = (UBRR_VALUE >> 8); //parta alta del baud rate
	UBRR0L = UBRR_VALUE; //parte baja del baud rate

	// Habilitar TX y RX
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);

	// 8 bits, 1 stop, sin paridad
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

// Transmitir data
void UART_tx(char data)
{
	while (!(UCSR0A & (1 << UDRE0))); // Espera a que el buffer este vacío
	UDR0 = data; //El micro transmite esta info por uart
}

// Recibir data
char UART_rx(void)
{
	while (!(UCSR0A & (1 << RXC0))); // Espera dato recibido
	return UDR0; //devuelve el dato recibido
}

//Envio de cadena
void cadena(char txt[])
{
	while (*txt != '\0')
	{
		UART_tx(*txt);
		txt++; //Manda el texto entero mientras el caracter no sea un vacío
	}
}

// Iniciamos el ADC
void ADC_init(void)
{
	ADMUX = 0;
	ADMUX |= (1 << REFS0); // Referencia AVcc
	ADMUX |= 0b00000000;   // Canal ADC0 = A0

	ADCSRA = 0;
	ADCSRA |= (1 << ADEN); // Habilitar ADC
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Prescaler 128
}

//Lectura de adc
uint16_t ADC_read(void)
{
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC)); // Esperar a que termine
	return ADC;
}

//Enviamos número
void UART_printNumber(uint16_t num)
{
	char buffer[5]; //buffer de 5 digitos
	uint8_t i = 0;

	if (num == 0) //Solo envia el npumero 0
	{
		UART_tx('0');
		return;
	}

	while (num > 0) //mientras que el numero sea mayor a 0 separa los digitos
	{
		buffer[i] = (num % 10) + '0';
		num /= 10; //En esta cadena mandamos digito trás digito con el %, mientras que con el num/= eliminamos el último digito
		i++; 
	}

	while (i > 0)
	{
		i--;
		UART_tx(buffer[i]); //Esta funcion se encarga de mandar los números en orden
	}
}

int main(void)
{
	UART_init();
	ADC_init();

	//  salidas: (d8-d12)
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4);

	// salidas: (d5-d7)
	DDRD |= (1 << PD5) | (1 << PD6) | (1 << PD7);

	while (1) //Programa repetido para siempre
	{
		cadena("\r\nMenu:\r\n"); //Usando la función de cadena mandamos el menú
		cadena("1. Leer Potenciometro\r\n");
		cadena("2. Enviar Ascii\r\n");
		cadena("Seleccione una opcion: ");

		char opcion = UART_rx();
		UART_tx(opcion);
		cadena("\r\n"); //Recibimos y enseañmos el dígto o la opción escogida

		if (opcion == '1') //Mostramos el valor del potenciometro
		{
			uint16_t pot = ADC_read();

			cadena("Valor del potenciometro: ");
			UART_printNumber(pot);
			cadena("\r\n");
		}
		else if (opcion == '2') //Mostramos el caracter
		{
			cadena("Ingrese un caracter: ");
			char dato = UART_rx();
			UART_tx(dato);
			cadena("\r\n");

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
		else
		{
			cadena("Opcion no valida\r\n");
		}

		for (volatile long i = 0; i < 300000; i++);
	}
}