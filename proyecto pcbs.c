/*
 * MightyMouse.c
 *
 * Proyecto Final PCBs
 * Author : joe05
 */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

//Velocidad utilizada para ambos motores
#define VELOCIDAD 180

//Funciones utilizadas para inicializar los motores, PWM y bluetooth
void motores_init(void);
void PWM_init(void);
void BLE_init(void);

//Funciones para realizar cada uno de los movimientos
void adelante(void);
void atras(void);
void izquierda(void);
void derecha(void);
void detener(void);

//Funcion para recibir los datos enviados por el HM-10
char BLE_recibir(void);


int main(void)
{
	char comando; //Guardamos la letra recibida por bluetooth

	motores_init(); //Configuramos los pines utilizados para controlar el sentido de los motores
	PWM_init();     //Configuramos PWM para controlar la velocidad
	BLE_init();     //Configuramos D2 para recibir los datos del HM-10

	detener(); //Iniciamos con los motores apagados

	while (1)
	{
		comando = BLE_recibir(); //Esperamos una letra enviada desde el telefono

		//Dependiendo de la letra recibida realizamos un movimiento diferente
		switch (comando)
		{
			case 'F':
			case 'f':
				adelante();
				break;

			case 'B':
			case 'b':
				atras();
				break;

			case 'L':
			case 'l':
				izquierda();
				break;

			case 'R':
			case 'r':
				derecha();
				break;

			case 'S':
			case 's':
				detener();
				break;

			default:
				break;
		}
	}
}


//Configuramos los pines que controlan el sentido de los motores
void motores_init(void)
{
	DDRD |= (1 << PD7); //D7 como salida para Motor 1

	//D8, D9 y D10 como salidas
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
}


//Configuramos Timer 0 para generar PWM en D5 y D6
void PWM_init(void)
{
	//D5 y D6 como salidas PWM
	DDRD |= (1 << PD5) | (1 << PD6);

	//Configuramos Fast PWM para las dos salidas del Timer 0
	TCCR0A = (1 << COM0A1) |
			(1 << COM0B1) |
			(1 << WGM01)  |
			(1 << WGM00);

	//Prescaler de 64
	TCCR0B = (1 << CS01) | (1 << CS00);

	//Iniciamos los motores con duty de 0
	OCR0A = 0;
	OCR0B = 0;
}


//Movemos ambos motores hacia adelante
void adelante(void)
{
	//Motor 1
	PORTD |= (1 << PD7);   //D7 = 1
	PORTB &= ~(1 << PB0);  //D8 = 0

	//Motor 2
	PORTB |= (1 << PB1);   //D9 = 1
	PORTB &= ~(1 << PB2);  //D10 = 0

	//Aplicamos PWM a ambos motores
	OCR0B = VELOCIDAD; //D5 PWM Motor 1
	OCR0A = VELOCIDAD; //D6 PWM Motor 2
}


//Invertimos ambos motores para mover el robot hacia atras
void atras(void)
{
	//Motor 1
	PORTD &= ~(1 << PD7); //D7 = 0
	PORTB |= (1 << PB0);  //D8 = 1

	//Motor 2
	PORTB &= ~(1 << PB1); //D9 = 0
	PORTB |= (1 << PB2);  //D10 = 1

	OCR0B = VELOCIDAD;
	OCR0A = VELOCIDAD;
}


//Un motor gira hacia atras y el otro hacia adelante para girar a la izquierda
void izquierda(void)
{
	//Motor 1 hacia atras
	PORTD &= ~(1 << PD7);
	PORTB |= (1 << PB0);

	//Motor 2 hacia adelante
	PORTB |= (1 << PB1);
	PORTB &= ~(1 << PB2);

	OCR0B = VELOCIDAD;
	OCR0A = VELOCIDAD;
}


//Un motor gira hacia adelante y el otro hacia atras para girar a la derecha
void derecha(void)
{
	//Motor 1 hacia adelante
	PORTD |= (1 << PD7);
	PORTB &= ~(1 << PB0);

	//Motor 2 hacia atras
	PORTB &= ~(1 << PB1);
	PORTB |= (1 << PB2);

	OCR0B = VELOCIDAD;
	OCR0A = VELOCIDAD;
}


//Ponemos el PWM en 0 para detener los dos motores
void detener(void)
{
	OCR0A = 0;
	OCR0B = 0;

	//Dejamos las entradas de direccion en 0
	PORTD &= ~(1 << PD7);

	PORTB &= ~((1 << PB0) |
			   (1 << PB1) |
			   (1 << PB2));
}


//Configuramos D2 como entrada para recibir los datos enviados por el HM-10
void BLE_init(void)
{
	DDRD &= ~(1 << PD2); //D2 como entrada

	PORTD |= (1 << PD2); //Activamos resistencia Pull-up
}


//Leemos manualmente la comunicacion serial enviada por el HM-10 a 9600 baud
char BLE_recibir(void)
{
	uint8_t dato = 0; //Guardamos los 8 bits recibidos

	//La linea normalmente esta en 1, esperamos hasta recibir el bit de inicio que es 0
	while (PIND & (1 << PD2));

	//Esperamos para llegar aproximadamente al centro del primer bit
	_delay_us(156);

	//Leemos los 8 bits enviados por bluetooth
	for (uint8_t i = 0; i < 8; i++)
	{
		if (PIND & (1 << PD2))
		{
			dato |= (1 << i); //Guardamos un 1 si D2 esta en alto
		}

		_delay_us(104); //Tiempo aproximado de cada bit para 9600 baud
	}

	_delay_us(104); //Esperamos el bit de parada

	return dato; //Devolvemos la letra recibida
}