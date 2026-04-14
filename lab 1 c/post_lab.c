/*
 * Post_lab.c
 *
 * Created: 6/04/26
 * Author: Jose Méndez
 * Description: Incluye pre, durante y post lab */
// Encabezado
#define F_CPU 16000000 //Frecuencia en 16MHz
#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h> //Datos de 8 bits

/**************/
// Funciones
void setup(void);
void setupADC(void);
void setupDisplay(void);

uint8_t leerADC8(void);
void mostrarContador(uint8_t valor);
void mostrarDisplay(uint8_t valor);

void apagarDigitos(void);
void encenderDigito1(void);
void encenderDigito2(void);
void segmentosHex(uint8_t nibble);

/**************/
// Tabla que muestra los numeros del display en modalidad hexadecimal
const uint8_t hexTable[16] =
{
	0x3F, // 0
	0x06, // 1
	0x5B, // 2
	0x4F, // 3
	0x66, // 4
	0x6D, // 5
	0x7D, // 6
	0x07, // 7
	0x7F, // 8
	0x6F, // 9
	0x77, // A
	0x7C, // b
	0x39, // C
	0x5E, // d
	0x79, // E
	0x71  // F
};

/**************/
// Main
int main(void)
{
	uint8_t counter = 0; //variable de contador inicia en 0, al igual que e valor leido en ADC.
	uint8_t adcValue = 0;

	// estados anteriores de los botones 
	uint8_t lastPB2 = 1;
	uint8_t lastPB3 = 1;

	setup(); //Llamamos a las funciones de configuracion
	setupADC();
	setupDisplay();

	mostrarContador(counter); //Muestra el valor actual del contador en los LEDS

	while (1) //ciclo infinito
	{
		// leemos el valor de ADC constantemente
		adcValue = leerADC8();

		// comparamos el valor del ADC con el contador en LEDS
		if (adcValue >= counter)
		{
			PORTB |= (1 << PB4);   // encendemos el led de alarma
		}
		else
		{
			PORTB &= ~(1 << PB4);  // se apaga la alarma
		}

		// multiplexado
		for (uint8_t i = 0; i < 10; i++)
		{
			mostrarDisplay(adcValue);
		}

		// leemos los botones constantemente
		uint8_t currentPB2 = (PINB & (1 << PB2));
		uint8_t currentPB3 = (PINB & (1 << PB3));

		// detectamos si el boton fue presionado
		if ((lastPB2 == 1) && (currentPB2 == 0))
		{
			_delay_ms(10); //Antirebote
			if (!(PINB & (1 << PB2))) //Revisamos si el boton esta presionado
			{
				counter++; //suma
				mostrarContador(counter);
			}
		}

		// detectamos si el boton fue presionado
		if ((lastPB3 == 1) && (currentPB3 == 0))
		{
			_delay_ms(10); //antirebote
			if (!(PINB & (1 << PB3)))  //revisamos si verdaderamente fue presionado
			{
				counter--; //resta
				mostrarContador(counter);
			}
		}

		//comparamos nuevamente el valor del ADC con el contador 
		if (adcValue >= counter)
		{
			PORTB |= (1 << PB4); //prendemos alarma
		}
		else
		{
			PORTB &= ~(1 << PB4); //apagamos alarma
		}

		// guardar estado anterior
		lastPB2 = currentPB2;
		lastPB3 = currentPB3;
	}
}

/**************/
// Setup general
void setup(void)
{
	// Desactivar USART 
	UCSR0B = 0x00;

	// =========================
	// LEDs contador PD2-PD7 y PB0-PB1
	// =========================
	DDRD |= 0b11111100;
	PORTD &= ~0b11111100;
	DDRB |= (1 << PB0) | (1 << PB1);
	PORTB &= ~((1 << PB0) | (1 << PB1));

	// =========================
	// Botones PB2-PB3 con pull-up
	// =========================
	DDRB &= ~((1 << PB2) | (1 << PB3));
	PORTB |= (1 << PB2) | (1 << PB3);

	// =========================
	// LED alarma -> PB4 (D12)
	// =========================
	DDRB |= (1 << PB4);
	PORTB &= ~(1 << PB4);
}

/**************/
// Mostrar contador en LEDs
void mostrarContador(uint8_t valor)
{
	// bits 0-5 en PD2-PD7
	PORTD = (PORTD & 0b00000011) | ((valor & 0b00111111) << 2);

	// bits 6-7 en PB0-PB1
	PORTB = (PORTB & 0b11111100) | ((valor >> 6) & 0b00000011);
}

/**************/
// ADC
void setupADC(void)
{
	ADMUX = 0; //Limpiamos el registro de ADMUX
	ADMUX |= (1 << REFS0); //AVcc es la referencia del ADC
	ADMUX |= (1 << ADLAR); // leemos los 8 bits significativos de adch
	ADMUX |= 0b00000110; // ADC6

	// Enable ADC, prescaler 128
	ADCSRA = 0; //limpiamos el registro de control del ADC
	ADCSRA |= (1 << ADEN); //habilitamos el ADC
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); //prescaler en 128
}

uint8_t leerADC8(void) //devolvemos el valor ADC en 8 bits
{
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADCH;
}

/**************/
// Display
void setupDisplay(void)
{
	// A-F en PC0-PC5
	DDRC |= 0b00111111;
	PORTC &= ~0b00111111;

	// G en PB5
	DDRB |= (1 << PB5);
	PORTB &= ~(1 << PB5);

	// D1 Y D2 EN PD0 Y PD1
	DDRD |= (1 << PD0) | (1 << PD1);
	PORTD &= ~((1 << PD0) | (1 << PD1));
}

void apagarDigitos(void) //  ambos displays apagados
{
	PORTD &= ~((1 << PD0) | (1 << PD1));
}

void encenderDigito1(void) // display 1 encendido
{
	PORTD |= (1 << PD1);
	PORTD &= ~(1 << PD0);
}

void encenderDigito2(void) //display 2 encendido
{
	PORTD |= (1 << PD0);
	PORTD &= ~(1 << PD1);
}

void segmentosHex(uint8_t nibble)
{
	uint8_t patron = hexTable[nibble & 0x0F];

	// A-F -> PC0-PC5
	PORTC = (PORTC & 0b11000000) | (patron & 0b00111111); //limpiamos los bits del 0 al 5 y ponemos el patron

	// G -> PB5
	if (patron & (1 << 6)) // si el patron lo requiere tambien se enciende el segmento 6
	{
		PORTB |= (1 << PB5);
	}
	else 
	{
		PORTB &= ~(1 << PB5);
	}
}

void mostrarDisplay(uint8_t valor)
{
	uint8_t alto = (valor >> 4) & 0x0F; //guardamos los valores altos
	uint8_t bajo = valor & 0x0F;//guardamos los valores bajos

	apagarDigitos();
	segmentosHex(alto);
	encenderDigito1();
	_delay_us(400);

	apagarDigitos();
	segmentosHex(bajo);
	encenderDigito2();
	_delay_us(400);

	apagarDigitos();
}