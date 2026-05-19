/*
 * config.h
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el archivo en tipo h.
 */
#ifndef CONFIG_H_
#define CONFIG_H_

#define F_CPU 16000000UL //definimos la frecuencia a 16mhz

#define NUM_SERVOS 4 //4 servos
#define NUM_STATES 4 //4 estados

#define LED_DDR DDRB //Configuramos el led como salida en el portB
#define LED_PORT PORTB
#define LED_PIN PB5

#endif