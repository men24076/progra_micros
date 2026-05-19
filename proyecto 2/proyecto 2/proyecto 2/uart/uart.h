/*
 * uart.h
 *
 * Created: 21/04/26
 * Author: Jose Méndez
 * Description: Archivo para configurar el uart en tipo h.
 */
#ifndef UART_H_
#define UART_H_

#include <stdint.h>

void UART_init(void); //Comunicación serial
uint8_t UART_available(void);//Revisa si llego un dato
char UART_read(void); //lee el dato
void UART_sendChar(char data); //mandar una letra
void UART_sendString(const char *str); //manda el texto completo

#endif