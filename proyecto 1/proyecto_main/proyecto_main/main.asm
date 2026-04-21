//
// NombreProgra.asm
//
// Creado: 
// Autor : 
// Descripción: Ejemplo en clase con Pedro. maquina de estados

/**************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
//Definimos las constantes que vamos a utilizar
.equ	T0_OCR		= 14 // 14 ticks para poder contadar cada 1ms
.equ    T1_VALUE    = 0xC2F7 //Modo normal empiza a contar desde aqui
.equ	MAX_MODES	= 6 // Cantidad máxima de estados de la maquina
//Modos:
.equ MODE_HORA = 0
.equ MODE_FECHA = 1
.equ MODE_CFG_HORA= 2
.equ MODE_CFG_FECHA= 3
.equ MODE_CFG_ALARMA = 4
.equ MODE_OFF
.def	MODE		= R20 // Variable que sabe en que estado estamos
.def	COUNTER		= R21 // Contador de tiempo
.def	DEBOUNCE	= R22 // Es una bandera de revision del boton
.def	PUNTITOS	= R23//defien si los puntitos están encendidos o apagados

.cseg
.org 0x0000

	JMP		START
.org	PCI2addr // Interrupcion de pinchange para el puerto D
	JMP		PIND_ISR

.org	OVF1addr // Interrupción para el timer 1
	JMP		TIMER1_ISR


START:
 /**************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/**************/
// Configuracion MCU
SETUP:
	
	// Ponemos el reloj en 1 MHz
	CLI
	LDI		R16, (1<< CLKPCE)
	STS		CLKPR, R16
	LDI		R16, (1<< CLKPS2)
	STS		CLKPR, R16

	// Entradas y salidas
	// Botones con pullup
	SBI		DDRB, DDB0
	SBI		DDRB, DDB1
	CBI		PORTB, PORTB0
	CBI		PORTB, PORTB1

	// Leds inicialmente apagadas
	CBI		DDRC, DDC0
	CBI		DDRC, DDC1
	CBI		DDRC, DDC2
	CBI		DDRC, DDC3

	SBI		PORTC, PORTC0
	SBI		PORTC, PORTC1
	SBI		PORTC, PORTC2
	SBI		PORTC, PORTC3

	CBI		DDRD, DDD2
	CBI		DDRD, DDD3
	SBI		PORTD, PORTD2
	SBI		PORTD, PORTD3

	CALL	INIT_TIMER1

	// Inicializamos variables
	CLR		MODE
	CLR		COUNTER
	CLR		ACTION

	// Habilitar interrupciones timer1
	LDI		R16, (1 << TOIE1)
	STS		TIMSK1, R16

	// Habilitar interrupciones para PD2 Y PD3
	LDI		R16, (1 << PCIE2)
	STS		PICR, R16

	LDI		R16, (1 << PCINT19) | (1 << PCINT18)
	STS		PCIR, R16
	
	SEI
/**************/
// Loop Infinito
MAIN_LOOP:
	OUT		PORTC, COUNTER
	OUT		PORTB, MODE

	CPI		MODE, 0
	BREQ	INC_MODE
	CPI		MODE, 1
	BREQ	DEC_MODE
	CPI		MODE, 2
	BREQ	AUTO_INC_MODE
	CPI		MODE, 3
	BREQ	AUTO_DEC_MODE

    RJMP    MAIN_LOOP

INC_MODE:
	CPI 	ACTION,0x01
	BRNE	EXIT_IM
	INC		COUNTER
	ANDI	COUNTER, 0x0F
	CLR		ACTION

EXIT_IM:
	RJMP	MAIN_LOOP

DEC_MODE:
	CPI 	ACTION,0x01
	BRNE	EXIT_DM
	DEC		COUNTER
	ANDI	COUNTER, 0x0F
	CLR		ACTION

EXIT_DM:
	RJMP	MAIN_LOOP

AUTO_INC_MODE:
	CPI 	ACTION,0x01
	BRNE	EXIT_AIM
	INC		COUNTER
	ANDI	COUNTER, 0x0F
	CLR		ACTION

EXIT_AIM:
	RJMP	MAIN_LOOP

AUTO_DEC_MODE:
	CPI 	ACTION,0x01
	BRNE	EXIT_ADM
	INC		COUNTER
	ANDI	COUNTER, 0x0F
	CLR		ACTION

EXIT_ADM:
	RJMP	MAIN_LOOP
/**************/
// NON-Interrupt subroutines

INIT_TIMER1:
	LDI		R16, 0x00
	STS		TCCR1A, R16
	LDI		R16, (1 << CS11) | (1 << CS10)
	STS		TCCR18, R16
	LDI		R16, HIGH(T1VALUE)
	STS		TCNT1H, R16
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16
	RET

/**************/
// Interrupt routines

PIND_ISR:

	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	SBIC	PIND, PIND2
	RJMP	CONTINUAR
	INC		MODE
	CPI		MODE, MAX_MODES
	BRNE	CONTINUAR
	CLR		MODE

CONTINUAR:
	CPI		MODE, 0
	BREQ	INC_MODE_ISR
	CPI		MODE, 1
	BREQ	DEC_MODE_ISR
	CPI		MODE, 2
	BREQ	AUNTO_INC_MODE_ISR
	CPI		MODE, 3
	BREQ	AUTO_DEC_MODE_ISR
	RJMP	EXIT_PIND_ISR

INC_MODE_ISR:
	SBIC	PIND, PIND3
	BREQ	EXIT_PIND_ISR
	LDI		ACTION,	0X01
	RJMP	EXIT_PIND_ISR

DEC_MODE_ISR:
	SBIC	PIND, PIND3
	BREQ	EXIT_PIND_ISR
	LDI		ACTION,	0X01
	RJMP	EXIT_PIND_ISR

AUTO_INC_MODE_ISR:
	RJMP	EXIT_PIND_ISR

AUTO_DEC_MODE_ISR:
	RJMP	EXIT_PIND_ISR

EXIT_PIND_ISR:
	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI

TIMER1_ISR:

	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	INC		COUNTER
	ANDI	COUNTER, 0x0F
	LDI		R16, HIGH(T1VALUE)
	STS		TCNT1H, R16
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16

	CPI		MODE, 0
	BREQ	EXIT_TIMER1_ISR
	CPI		MODE, 1
	BREQ	EXIT_TIMER1_ISR
	CPI		MODE, 2
	BREQ	MODE2_ISR
	CPI		MODE, 3
	BREQ	MODE3_ISR
	RJMP	EXIT-TIMER1_ISR

MODE2_ISR:
	LDI		ACTION, 0x01
	RJMP	EXIT_TIMER1_ISR

MODE3_ISR:
	LDI		ACTION, 0x01
	RJMP	EXIT_TIMER1_ISR
	
EDIT_TIMER1_ISR:

	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI
/**************/