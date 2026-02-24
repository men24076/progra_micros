;
; AssemblerApplication2.asm
;
; Created: 3/02/2026 15:11:08
; Author : joe05
;

//Prelab Jose Mendez

.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
 /**************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/**************/
// Configuracion MCU
SETUP:
	//Colocamos nuestras entradas
	 //push button que activo en el bit 5 del DDRD, el cual aumenta el contador
	// push button que activo en el bit 4 del DDRD, el cual disminuye el contador
		SBI PORTD, PORTD4
		SBI PORTD, PORTD5

	// (SEGUNDO CONTADOR) pushbuttons en PD6 y PD7 con pull-up
		SBI PORTD, PORTD6
		SBI PORTD, PORTD7

	//Se configuran únicamente las salidas, al tener ya definidas las entradas predeterminadamente.
	//Para no explicar los patrones una y otra vez, el set bit in determina que esos bits son entradas, mientras que el clear bit en los puertos determina que los valores comiencen en 0.
	SBI DDRB, DDB0
	CBI PORTB, PORTB0
	SBI DDRB, DDB1
	CBI PORTB, PORTB1
	SBI DDRB, DDB2
	CBI PORTB, PORTB2
	SBI DDRB, DDB3
	CBI PORTB, PORTB3

	// (SEGUNDO CONTADOR) LEDs en PC0..PC3
	SBI DDRC, DDC0
	CBI PORTC, PORTC0
	SBI DDRC, DDC1
	CBI PORTC, PORTC1
	SBI DDRC, DDC2
	CBI PORTC, PORTC2
	SBI DDRC, DDC3
	CBI PORTC, PORTC3

//Aseguramos tener en 0 todos los pines que vamos a utilizar, sobre todo R16 que es el que se va a ingresar a port 
	CLR R16 
	CLR R17 
	CLR R18
	OUT PORTB, R16 

	; (SEGUNDO CONTADOR) usamos R22 como contador 2
	CLR R22
	OUT PORTC, R22


// Loop Infinito
MAIN_LOOP:
	CALL CONTADOR1
	CALL CONTADOR2
	RJMP MAIN_LOOP


CONTADOR1:
	IN R17, PIND  //Lectura del pin D en r17
	ANDI R17, 0b00110000 //A travès de la función andi se realiza un filtro o máscara para que solo se lea el bit 4 y el bit 5
	CPI R17, 0b00110000 //si no hay ningun botón presionado, la z flag se prende por lo cual se queda en el main loop
	BREQ C1_END
	CALL DELAY //Ejecutamos el delay para asegurar que no haya rebote
	IN R18, PIND // se repite el proceso, en esta ocasión después del antirebote.
	ANDI R18, 0b00110000 
	CP R18, R17 //compara los valores nuevamente para asegurar que no fue debido al antirebote 
	BRNE C1_END // si el valor leido en ambos flancos es 0 regresa al main loop 
	MOV R17, R18 //guarda el valor en r17 como el estado actual 
//EN los siguientes procesos, se utiliza CPI para ver cual de los dos botones se apachó 
C1_INCREASE_LOOP:
	CPI R17, 0b00100000 
	BRNE C1_DECREASE_LOOP //Si ya saltò, se compara la entrada y si no es increase es decrease
	INC R16 //Incrementa la cuenta
	ANDI R16, 0b00001111 //Nuevamente, un filtro o máscara para leer solo los LEDS que estamos utilizando.
	OUT PORTB, R16 //Muestra en el puerto B la cuenta que se lleva
	RJMP C1_END
C1_DECREASE_LOOP:
	CPI R17, 0b00010000
	BRNE C1_END //Se realiza la verificaciòn otravez, en este caso si no era increase ni decrease se regresa al main loop 
	DEC R16 //Se disminuye el contador
	ANDI R16, 0b00001111 
	OUT PORTB, R16 //Muestra en el puerto B la cuenta que se lleva
	RJMP C1_END

C1_END:
	RET

CONTADOR2:
	IN R23, PIND
	ANDI R23, 0b11000000
	CPI R23, 0b11000000
	BREQ C2_END
	CALL DELAY
	IN R24, PIND
	ANDI R24, 0b11000000
	CP R24, R23
	BRNE C2_END
	MOV R23, R24

C2_INCREASE_LOOP:
	
	CPI R23, 0b10000000
	BRNE C2_DECREASE_LOOP
	INC R22
	ANDI R22, 0b00001111
	OUT PORTC, R22
	RJMP C2_END

C2_DECREASE_LOOP:

	CPI R23, 0b01000000
	BRNE C2_END
	DEC R22
	ANDI R22, 0b00001111
	OUT PORTC, R22
	RJMP C2_END

C2_END:
	RET


//Delay antirebote
DELAY:
    LDI R19, 7         
D0:
    LDI R20, 0xFF
DEL0:
    LDI R21, 0xFF
DEL1:
    DEC R21
    BRNE DEL1
    DEC R20
    BRNE DEL0
    DEC R19
    BRNE D0
    RET