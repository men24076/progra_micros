;
; primera progra proyecto.asm
;
; Created: 24/02/2026 14:26:21
; Author : joe05
;

.include "M328PDEF.inc"

.dseg
.org SRAM_START
d_10:      .byte 1 //CONTADOR DE 99 TICKS DE 10MS
unidad:     .byte 1 //Segundos en unidades
decenas:      .byte 1 //Decenas de segundo

.cseg
.org 0x0000
RJMP RESET //Guardamos reset en la posición 0, para que arranque en reset

.org 0x001C 
RJMP ISR_T0 //Saltamos al ISR

RESET:
 //Configuración de la pila
    LDI     R20, LOW(RAMEND)
    OUT     SPL, R20
    LDI     R20, HIGH(RAMEND)
    OUT     SPH, R20

    RJMP SETUP
	//Salta al setup

//Deshabilitamos el USART para poder habilitar PD0 Y PD1
LDI     R20, 0x00
STS     UCSR0B, R20

//Guardamos todos los números de 0 a 9 
TS7: 
 .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

SETUP:
