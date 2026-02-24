;
; AssemblerApplication24.asm
;
; Created: 17/02/2026 10:36:48
; Author : joe05
;




.dseg
.org SRAM_START
flag_up:        .byte 1
flag_down:      .byte 1
prev_state:     .byte 1
delay_inc:        .byte 1
delay_dec:      .byte 1

.cseg
.org 0x0000
    RJMP RESET

.org 0x0006                ; PCINT0_vect
    RJMP ISR_PB_CHANGE

.org 0x0020                ; TIMER0_OVF_vect
    RJMP ISR_T0_TICK



RESET: //Reset es lo primero que se ejecuta 
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16 //el stack crece hacia abajo

    CLR     R16

    //D2 A D5 SALIDAS
    IN      R16, DDRD
    ORI     R16, 0b00111100
    OUT     DDRD, R16

    IN      R16, PORTD
    ANDI    R16, 0b11000011
    OUT     PORTD, R16
//PULL UP A B1 Y B2
    CBI     DDRB, 1
    CBI     DDRB, 2
    SBI     PORTB, 1
    SBI     PORTB, 2

  //Limpiamos variables y flags
    CLR     R16
    STS     flag_up, R16
    STS     flag_down, R16
    STS     delay_inc, R16
    STS     delay_dec, R16
	//Guardamos el estado inicial del puerto b en r16
    IN      R16, PINB
    ANDI    R16, 0b00000110
    STS     prev_state, R16 //guardamos el estado en el dataspace

    //Timer normal no PWM
    LDI     R16, 0x00
    OUT     TCCR0A, R16
    LDI     R16, (1<<CS01)|(1<<CS00)
    OUT     TCCR0B, R16
    LDI     R16, (1<<TOV0)
    OUT     TIFR0, R16
    LDI     R16, (1<<TOIE0)
    STS     TIMSK0, R16

   //Configuramos PCINT on change apra PB1 y PB2
    LDI     R16, (1<<PCINT1)|(1<<PCINT2)
    STS     PCMSK0, R16

    LDI     R16, (1<<PCIF0)
    OUT     PCIFR, R16

    LDI     R16, (1<<PCIE0)
    STS     PCICR, R16

    CLR     R17              

    SEI


MAIN_LOOP:

 //Incremento
    LDS     R16, flag_up
    TST     R16
    BREQ    CHECK_DOWN

    CLR     R16
    STS     flag_up, R16

    INC     R17
    ANDI    R17, 0x0F
    RCALL   MOSTRAR_CONTADOR

CHECK_DOWN:

 //Xecremento
    LDS     R16, flag_down
    TST     R16
    BREQ    MAIN_LOOP

    CLR     R16
    STS     flag_down, R16

    DEC     R17
    ANDI    R17, 0x0F
    RCALL   MOSTRAR_CONTADOR

    RJMP    MAIN_LOOP


//actualización de LEDS
MOSTRAR_CONTADOR:
    IN      R16, PORTD
    ANDI    R16, 0b11000011
    MOV     R18, R17
    LSL     R18
    LSL     R18
    ANDI    R18, 0b00111100
    OR      R16, R18
    OUT     PORTD, R16
    RET


//ISR
ISR_PB_CHANGE:
    PUSH    R16
    PUSH    R17
    PUSH    R18
    IN      R16, SREG
    PUSH    R16

    IN      R16, PINB
    ANDI    R16, 0b00000110

    LDS     R17, prev_state
    MOV     R18, R17
    EOR     R18, R16

    //boton de subie
    SBRS    R18, 1
    RJMP    CHECK_ISR_DOWN
    SBRC    R16, 1
    RJMP    CHECK_ISR_DOWN
    LDS     R17, delay_inc
    TST     R17
    BRNE    CHECK_ISR_DOWN
    LDI     R17, 1
    STS     flag_up, R17
    LDI     R17, 20
    STS     delay_inc, R17

CHECK_ISR_DOWN:

   //Boton de bajar
    SBRS    R18, 2
    RJMP    SAVE_STATE
    SBRC    R16, 2
    RJMP    SAVE_STATE
    LDS     R17, delay_dec
    TST     R17
    BRNE    SAVE_STATE
    LDI     R17, 1
    STS     flag_down, R17
    LDI     R17, 20
    STS     delay_dec, R17

SAVE_STATE:
    STS     prev_state, R16

    POP     R16
    OUT     SREG, R16
    POP     R18
    POP     R17
    POP     R16
    RETI


//TIMER DE LAS INTERRUPCIONES
ISR_T0_TICK:
    PUSH    R16
    IN      R16, SREG
    PUSH    R16

    LDI     R16, (1<<TOV0)
    OUT     TIFR0, R16

    LDS     R16, delay_inc
    TST     R16
    BREQ    CHECK_COOLDOWN2
    DEC     R16
    STS     delay_inc, R16

CHECK_COOLDOWN2:
    LDS     R16, delay_dec
    TST     R16
    BREQ    END_T0
    DEC     R16
    STS     delay_dec, R16

END_T0:
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI