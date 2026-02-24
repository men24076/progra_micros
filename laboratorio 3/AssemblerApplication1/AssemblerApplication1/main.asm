;
; AssemblerApplication1.asm
;
; Created: 17/02/2026 2:00
; Author : joe05
;


.include "M328PDEF.inc"

.dseg
.org SRAM_START
ticks_10ms: .byte 1      //Guardamos el contador de los ticks en la SRAM
contador:   .byte 1      //Contador hexadecimal de 0 a 15.

.cseg
.org 0x0000
    RJMP RESET //Iniciamos en el reset

.org 0x001C //dirección del compare match
    RJMP TMR0_ISR  //luego del recet brinca a la interrupción


//Reset
RESET:
    //pila
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16


//DISPLAY: PC0 a PC5 
    LDI     R16, 0b0011_1111
    OUT     DDRC, R16
    CLR     R16
    OUT     PORTC, R16

 //La ultima parte del display esta conectada a B0
    SBI     DDRB, DDB0
    CBI     PORTB, PB0

  //Limpiamos tanto los ticks como el contador para que comience en 0.
    CLR     R16
    STS     ticks_10ms, R16
    STS     contador, R16


    LDI     R16, 0b00000010 //Seteamos el timer en compare match
    OUT     TCCR0A, R16
    LDI     R16, 0b00000101 //subimos el valor de 1024 al prescaler
    OUT     TCCR0B, R16
    LDI     R16, 155 //utilizamos 155 ticks para que termine en 10ms
    OUT     OCR0A, R16 //Reinicia al llegar a 155.
    CLR     R16
    OUT     TCNT0, R16 //Reiniciamos el timer

    ; limpiar las banderas poniendole uno al bit.
    LDI     R16, 0b00000010
    OUT     TIFR0, R16

 
    LDI     R16, 0b00000010 //activa el output compare match A
    STS     TIMSK0, R16

    //Muestra el valor inicial 0 
    LDS     R20, contador 
    RCALL   mostrar_display_contador //Llamamos a la subrutina

    SEI //Habilitamos las interrupciones en el programa


MAIN_LOOP:
    RJMP MAIN_LOOP


//ISR compare match A
TMR0_ISR:
    PUSH    R16 //guardamos los valores de r16 a r22 en la pila
    PUSH    R17
    PUSH    R20
    PUSH    R21
    PUSH    R22
    IN      R17, SREG //guardamos el status reg en r17
    PUSH    R17 // para comparar en un futuro lo guardamos en la pila tmb

    
    LDS     R16, ticks_10ms //Guardamos la variable en 417
    INC     R16 //Incrementamos
    CPI     R16, 100
    BRLO    GUARDAR_TICK  //Guarda el tick solamente hasta contar a 100 osea a 1s

    //Si llega a 1 segundo limpia y lo guarda en la RAM para empezar otravez a contar
    CLR     R16
    STS     ticks_10ms, R16

   
    LDS     R20, contador //Cargamos el contador en r20
    INC     R20 //Incrementamos 1 
    ANDI    R20, 0x0F //Le sumamos eso para que no pase de 15
    STS     contador, R20 //subimos el valor del contador actual al data space

    //actualizar display
    RCALL   mostrar_display_contador
    RJMP    FIN_ISR

GUARDAR_TICK:
    STS     ticks_10ms, R16 //guardamos el tick actual

FIN_ISR:
    POP     R17 //Utilizamos el r17 viejo al iugal que todaslas demas
    OUT     SREG, R17 //Recuperamos los flags anterior a la interrupción
    POP     R22
    POP     R21
    POP     R20
    POP     R17
    POP     R16
    RETI



mostrar_display_contador:
    LDI     ZH, HIGH(tabla7seg<<1)
    LDI     ZL, LOW(tabla7seg<<1)
    ADD     ZL, R20
    ADC     ZH, R1
    LPM     R21, Z


    MOV     R22, R21
    ANDI    R22, 0b0011_1111
    OUT     PORTC, R22

    CBI     PORTB, PB0
    SBRC    R21, 6
    SBI     PORTB, PB0
    RET


tabla7seg:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07
    .db 0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

