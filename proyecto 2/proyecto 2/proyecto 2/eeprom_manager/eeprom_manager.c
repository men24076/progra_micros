/*
 * eeprom_manager.c
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el eeprom en tipo C.
 */
#include "eeprom_manager.h"
#include "../config/config.h"

#include <avr/eeprom.h>
#include <stdint.h>

uint8_t EEMEM ee_states[NUM_STATES][NUM_SERVOS]; //matriz de los valores guardados en la eeprom

void EEPROM_Manager_init(void)
{
	uint8_t value; //Guardamos el valor leido en la eeprom

	for (uint8_t state = 0; state < NUM_STATES; state++) //Recorre los 4 estados que se pueden guardar
	{
		for (uint8_t servo = 0; servo < NUM_SERVOS; servo++) //Recorre cada 1 de los 4 servos
		{
			value = eeprom_read_byte(&ee_states[state][servo]); //lee la ubivavión de la eeprom

			if (value > 180)
			{
				eeprom_update_byte(&ee_states[state][servo], 90); //Si hay un valor mayor a 90 lo regresa a 180
			}
		}
	}
}

void EEPROM_SaveState(uint8_t state, uint8_t angles[4])
{
	if (state >= NUM_STATES) return; //regresa a estado 0 si se pasa de numero de estados

	for (uint8_t servo = 0; servo < NUM_SERVOS; servo++) //Guarda los 4 servos
	{
		if (angles[servo] > 180) angles[servo] = 180;

		eeprom_update_byte(&ee_states[state][servo], angles[servo]); //Guarda el angulo en eeprom
	}
}

void EEPROM_LoadState(uint8_t state, uint8_t angles[4]) //Carga el estado desde la eeprom
{
	if (state >= NUM_STATES) return;

	for (uint8_t servo = 0; servo < NUM_SERVOS; servo++) //lee los angulos del estado que se escogio
	{
		angles[servo] = eeprom_read_byte(&ee_states[state][servo]); //funcion con los angulos a mostrar

		if (angles[servo] > 180)
		{
			angles[servo] = 90;
		}
	}
}