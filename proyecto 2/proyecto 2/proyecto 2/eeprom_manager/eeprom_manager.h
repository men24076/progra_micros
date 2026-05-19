/*
 * eeprom_manager.h
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el eeprom en tipo H.
 */
#ifndef EEPROM_MANAGER_H_
#define EEPROM_MANAGER_H_

#include <stdint.h>

void EEPROM_Manager_init(void); //Revisamos que los valores sean válidos
void EEPROM_SaveState(uint8_t state, uint8_t angles[4]); //Guarda el estado
void EEPROM_LoadState(uint8_t state, uint8_t angles[4]); //Sube el estado

#endif