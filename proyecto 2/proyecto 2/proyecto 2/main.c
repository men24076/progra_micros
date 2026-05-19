///*
// * main.c
// *
// * Created: 21/04/26
// * Author: Jose Méndez
// * Description: Archivo para configurar el main en tipo C.

#define F_CPU 16000000UL //16Mhz frecuencia

#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

#include "config/config.h"
#include "adc/adc.h"
#include "servo/servo.h"
#include "eeprom_manager/eeprom_manager.h"
#include "uart/uart.h"

#define MANUAL_DEADBAND 5 //Evita ruido del pot, solo actualiza si cambia mínimo 5 grados

typedef enum //modos del sistema, siendo manual eeprom y uart
{
	MODE_MANUAL = 0,
	MODE_EEPROM = 1,
	MODE_UART = 2
} SystemMode;

SystemMode current_mode = MODE_MANUAL; //Empezamos en modo manual

uint8_t current_angles[NUM_SERVOS] = {0, 0, 0, 0}; //Angulos iniciales

uint8_t save_index = 0; //Estado en el que se va a guardar en la eeprom

char uart_buffer[20]; //Guarda el comando enviado
uint8_t uart_index = 0; //Posición dwl buffer que se guarda


void LED_init(void)
{
	LED_DDR |= (1 << LED_PIN);
	LED_PORT &= ~(1 << LED_PIN); //Led apagada y configurada como salida
}

void LED_on(void)
{
	LED_PORT |= (1 << LED_PIN); //Led encendida
}

void LED_off(void)
{
	LED_PORT &= ~(1 << LED_PIN); //Led apagada
}

void LED_updateMode(void)
{
	if (current_mode == MODE_MANUAL) //Si esta en modo manual, led prendida siempre
	{
		LED_on();
	}
	else
	{
		LED_off();
	}
}

void LED_intermitente(uint8_t times) //Led titileante
{
	for (uint8_t i = 0; i < times; i++)
	{
		LED_on();
		_delay_ms(120);
		LED_off();
		_delay_ms(120);
	}
}



uint8_t ADC_angle(uint16_t adc_value) //lectura del potenciometro en rados
{
	if (adc_value > 1023)
	{
		adc_value = 1023;
	}

	return ((uint32_t)adc_value * 180) / 1023;
}


void servos_eeprom(void) //Al cargar estados en eeprom, esto manda a los 4 servos a la posición que deben
{
	for (uint8_t i = 0; i < NUM_SERVOS; i++)
	{
		Servo_angle(i, current_angles[i]);
	}
}

void runManualMode(void) //Modo manual
{
	for (uint8_t i = 0; i < NUM_SERVOS; i++) //Recorre los 4 servos
	{
		uint16_t adc_value = ADC_read(i); //lee el pot
		uint8_t new_angle = ADC_angle(adc_value); //lectura a gradis
		uint8_t diff;

		if (new_angle > current_angles[i])
		{
			diff = new_angle - current_angles[i];
		}
		else
		{
			diff = current_angles[i] - new_angle;
		}

		if (diff >= MANUAL_DEADBAND) //evita ruido del pot, solo mueve si cambia bastante
		{
			current_angles[i] = new_angle;
			Servo_angle(i, current_angles[i]); //mueve el servo
		}
	}
}

void UART_sendNumber(uint16_t number) //mandamos en uart en donde esta el servo
{
	if (number >= 100) //Divide la posición para que se pueda leer de corrido si es de 3 numeros
	{
		UART_sendChar((number / 100) + '0');
		UART_sendChar(((number / 10) % 10) + '0');
		UART_sendChar((number % 10) + '0');
	}
	else if (number >= 10) //lo mismo pero de 2 números
	{
		UART_sendChar((number / 10) + '0');
		UART_sendChar((number % 10) + '0');
	}
	else
	{
		UART_sendChar(number + '0'); //solo se manda un digito
	}
}

void saveCurrentState(void)
{
	EEPROM_SaveState(save_index, current_angles); //Guardamos los estados

	//en las siguientes lineas, mandamos el número de estado en el que se guardo, y si ya llego al máx regresa a estado 1
	UART_sendString("Guardado estado ");
	UART_sendChar('1' + save_index);
	UART_sendString("\r\n");

	save_index++;

	if (save_index >= NUM_STATES)
	{
		save_index = 0;
	}

	LED_intermitente(3); //titilea para confirmar el guardado
	LED_updateMode(); //vuelve al estado en el que estaba el Led
}

void loadState(uint8_t state) //Cargamos el estado en el que esta el servo
{
	EEPROM_LoadState(state, current_angles);

	servos_eeprom(); //mueve los servos

	current_mode = MODE_EEPROM; //Cambia a EEPROM
	LED_updateMode();

	UART_sendString("Cargado estado "); //mandamos que se cambio el estado por serial
	UART_sendChar('1' + state);
	UART_sendString("\r\n");
}

// =========================
// COMANDOS ADAFRUIT / UART
// =========================

void processServoCommand(char *cmd) //Lo siguiente es para mover los servos desde adafruit
{
	uint8_t servo = 0;
	uint16_t angle = 0;

	if (cmd[0] != 'S' && cmd[0] != 's') //Python manda S(numero de servo):angulo del servo
	{
		return;
	}

	servo = cmd[1] - '1'; //Corrige para que entienda que estamos usando servo 0 1 2 y 3 no 1234

	if (servo >= NUM_SERVOS)
	{
		return;
	}

	if (cmd[2] != ':')
	{
		return;
	}

	for (uint8_t i = 3; cmd[i] != '\0'; i++) //lee el angulo
	{
		if (cmd[i] >= '0' && cmd[i] <= '9') //Acepta solo numeros
		{
			angle = (angle * 10) + (cmd[i] - '0'); //Convierte a un solo número
		}
	}

	if (angle > 180)
	{
		angle = 180;
	}

	current_angles[servo] = angle;
	Servo_angle(servo, current_angles[servo]); //Guardamos el angulo y luego mueve el servo

	current_mode = MODE_UART;
	LED_updateMode(); //Se apaga el LED

	//mandamos el ángulo en el que esta el servo
	UART_sendString("Servo ");
	UART_sendChar('1' + servo);
	UART_sendString(" = ");
	UART_sendNumber(angle);
	UART_sendString("\r\n");
}

void processUART(void)
{
	if (!UART_available())
	{
		return; //Si no han llegado datos se sale
	}

	char command = UART_read();

	if (uart_index > 0) //Se recibió un comando
	{
		// Si llega otra S, reiniciamos el comando para evitar que quede algo como SS1:45
		if (command == 'S' || command == 's')
		{
			current_mode = MODE_UART; //Cambia a UART desde que empieza a recibir un comando de Adafruit
			LED_updateMode();

			uart_buffer[0] = command;
			uart_index = 1;
			return;
		}

		if (command == '\n' || command == '\r')
		{
			uart_buffer[uart_index] = '\0';
			processServoCommand(uart_buffer); //Una vez llega el dato hasta enter se procesa
			uart_index = 0;
		}
		else
		{
			if (uart_index < 19) //Si no ha llegado a enter sigue guardando caracteres
			{
				uart_buffer[uart_index] = command;
				uart_index++;

				// Procesa comandos tipo S1:45 aunque no llegue ENTER
				if (uart_index >= 4)
				{
					if ((uart_buffer[0] == 'S' || uart_buffer[0] == 's') && uart_buffer[2] == ':')
					{
						if (command >= '0' && command <= '9')
						{
							uart_buffer[uart_index] = '\0';
							processServoCommand(uart_buffer);
						}
					}
				}
			}
			else
			{
				uart_index = 0;
			}
		}

		return;
	}

	//Llego un dato
	if (command == 'S' || command == 's') //Guarda la s en el primer espacio
	{
		current_mode = MODE_UART; //Cambia a UART desde que empieza a recibir un comando de Adafruit
		LED_updateMode();

		uart_buffer[0] = command;
		uart_index = 1;
		return;
	}

	// Cargar estados EEPROM
	if (command == '1')
	{
		loadState(0);
	}
	else if (command == '2')
	{
		loadState(1);
	}
	else if (command == '3')
	{
		loadState(2);
	}
	else if (command == '4')
	{
		loadState(3);
	}

	// Volver a modo manual
	else if (command == 'M' || command == 'm')
	{
		current_mode = MODE_MANUAL;
		LED_updateMode();

		UART_sendString("Modo manual\r\n");
	}

	// Guardar estado desde Adafruit
	// Python debe mandar G cuando se active el feed PB-TX
	else if (command == 'G' || command == 'g')
	{
		saveCurrentState();
	}
}

// =========================
// MAIN
// =========================

int main(void)
{
	ADC_init();
	Servo_init();
	EEPROM_Manager_init();
	UART_init();
	LED_init();

	current_mode = MODE_MANUAL;
	LED_updateMode();

	while (1)
	{
		while (UART_available()) //lee todos los caracteres que hayan llegado por serial
		{
			processUART(); //Revisa si llego un comando por serial
		}

		if (current_mode == MODE_MANUAL) //Corre el modo manual y deja utilizar pots
		{
			runManualMode();
		}

		_delay_ms(1);
	}
}