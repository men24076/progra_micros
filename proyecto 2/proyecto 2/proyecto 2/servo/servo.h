/*
 * servo.h
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el servo en tipo H.
 */
#ifndef SERVO_H_
#define SERVO_H_

#include <stdint.h>

void Servo_init(void); //Función de configuración de timers y pines
void Servo_angle(uint8_t servo, uint8_t angle); //Función para mover el servo
uint8_t Servo_save(uint8_t servo); //Función para guardar el angulo en la EEPROM

#endif