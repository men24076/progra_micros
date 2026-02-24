;
; post_lab.asm
;
; Created: 20/02/2026 18:39:23
; Autor : Jose Méndez
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
   
    CLR     R2

   // Guardamos D1, A, F y D3 en PC
    SBI     DDRC, DDC0
    SBI     DDRC, DDC1
    SBI     DDRC, DDC2
    SBI     DDRC, DDC4

    //Guardamos D, E y B en PB
    SBI     DDRB, DDB0
    SBI     DDRB, DDB1
    SBI     DDRB, DDB2

     //Guardamos G, C y DP en PD
    SBI     DDRD, DDD5
    SBI     DDRD, DDD6
    SBI     DDRD, DDD7

    //Apagamos los segmentos, SIN EMBARGO HAY LÓGICA INVERSA Y SE USA SBI
   SBI   PORTC, PC1
   SBI   PORTC, PC2
   SBI   PORTB, PB2
   SBI   PORTB, PB0
   SBI   PORTB, PB1
   SBI   PORTD, PD6
   SBI   PORTD, PD5
   SBI   PORTD, PD7

    //Comenzamos con D3 prendido y D1 apagado
    CBI     PORTC, PC0       ; D1
    SBI     PORTC, PC4       ; D3

    CLR     R20 //Limpiamos r20
    STS     d_10,  R20 //subimos 0 al STS 
    STS     unidad, R20 //subimos 0 al STS 
    STS     decenas,  R20 //subimos 0 al STS 

    //TIMER
    LDI     R20, (1<<WGM01) //Activamos el modo ctc
    OUT     TCCR0A, R20

    LDI     R20, (1<<CS02)|(1<<CS00) //Seteamos el prescaler en 1024
    OUT     TCCR0B, R20

    LDI     R20, 155 
    OUT     OCR0A, R20 //155 ticks para 10 ms con prescaler de 1024

    CLR     R20
    OUT     TCNT0, R20 //Reiniciamos el contador

    LDI     R20, (1<<OCF0A)
    OUT     TIFR0, R20 //Limpiamos la bandera de interrupciòn

    LDI     R20, (1<<OCIE0A)
    STS     TIMSK0, R20 //Habilitamos compare match A

    SEI

MAIN_LOOP:
    RJMP MAIN_LOOP


ISR_T0:
   //Guardamos r20-r22 en la pila
    PUSH    R20
    PUSH    R21
    PUSH    R22
	//Guardamos el status reg en r22 y lo subimos a la pila
    IN      R22, SREG
    PUSH    R22

    //Cuenta los ticks cada 10 ms y avanza hasta contar 1 seguno
    LDS     R20, d_10
    INC     R20
    CPI     R20, 100
    BRLO    GUARDAR_10

    //al contar un segundo se reinicia y regresa
    CLR     R20
    STS     d_10, R20

    //Carga las unidades que hay actualmente y las incrementa
    LDS     R20, unidad
    INC     R20
    CPI     R20, 10
    BRLO    GUARDAR_UNIDADES //Al llegar a 10 hay overflow y salta a decimas

    ; Reinicia las unidades
    CLR     R20
    STS     unidad, R20

    //Cuenta de decimas
    LDS     R20, decenas
    INC     R20
    CPI     R20, 6
    BRLO    GUARDAR_DECENAS

    //Al llegar a 60, se reinicia
    CLR     R20
    STS     decenas, R20
    RJMP    MOSTRAR
//Guarda la decima en la que vamos
GUARDAR_DECENAS:
    STS     decenas, R20
    RJMP    MOSTRAR
//Guarda la unidad actual
GUARDAR_UNIDADES:
    STS     unidad, R20
    RJMP    MOSTRAR
//Guarda el valor actual de 10ms
GUARDAR_10:
    STS     d_10, R20


MOSTRAR:
    //Comenzamos con el D3 encendido
    CBI     PORTC, PC0
    SBI     PORTC, PC4

    LDS     R20, unidad //Cargamos del registro unidad la cuenta actual
    RCALL   DECOD_7SEG
    RCALL   ESCRIBIR_7SEG //LLamoamos a las otras funcoiones
    RCALL   DELAY

    //mostramos decenas
    SBI     PORTC, PC0
    CBI     PORTC, PC4

    LDS     R20, decenas //Cargamos del registro de decenas la cuenta actual
    RCALL   DECOD_7SEG
    RCALL   ESCRIBIR_7SEG //llamamos a las otras funciones
    RCALL   DELAY

    POP     R22
    OUT     SREG, R22

    POP     R22
    POP     R21
    POP     R20
    RETI //Regresamos todos los registros que habíamos cargado en la pila




ESCRIBIR_7SEG:
    
	//Resumamos esto en que cada pin se prende si el bit asignado a cada uno está en 1.
    //A
    SBRC    R20, 0
    CBI     PORTC, PC1
    SBRS    R20, 0 
    SBI     PORTC, PC1

    //B
    SBRC    R20, 1
    CBI     PORTB, PB2
    SBRS    R20, 1
    SBI     PORTB, PB2

    //C
    SBRC    R20, 2
    CBI     PORTD, PD6
    SBRS    R20, 2
    SBI     PORTD, PD6

    //D
    SBRC    R20, 3
    CBI     PORTB, PB0
    SBRS    R20, 3
    SBI     PORTB, PB0

    //E
    SBRC    R20, 4
    CBI     PORTB, PB1
    SBRS    R20, 4
    SBI     PORTB, PB1

	//F
    SBRC    R20, 5
    CBI     PORTC, PC2
    SBRS    R20, 5
    SBI     PORTC, PC2

    //G
    SBRC    R20, 6
    CBI     PORTD, PD5
    SBRS    R20, 6
    SBI     PORTD, PD5

    RET



DECOD_7SEG:
    PUSH    ZL
    PUSH    ZH

    LDI     ZH, HIGH(TS7)//Cargamos en Z alto los valores obtenidos para mostrar digitos
    LDI     ZL, LOW(TS7) //Cargamos en Z bajo los valores obtenidos para mostrar digitos

    ADD     ZL, R20 //Hacemos el add normal para que agregue la parte al byte bajo
    ADC     ZH, R2 //Hacemos el add on carry para que lleve el valor al byte alto

    LPM     R20, Z //Cargamos en R20 el byte que esta en el registro Z.

    POP     ZH
    POP     ZL
    RET



DELAY:
    LDI     R23, 25
R1_LOOP:
    LDI     R24, 180
R2_LOOP:
    DEC     R24
    BRNE    R2_LOOP
    DEC     R23
    BRNE    R1_LOOP
    RET