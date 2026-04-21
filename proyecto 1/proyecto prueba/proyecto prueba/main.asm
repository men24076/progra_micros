.include "M328PDEF.inc"

.equ TMR0_VALUE=6
.equ TMR1_VALUE=0x85EE
.equ MAX_MODES=6

.equ MODE_HORA=0
.equ MODE_FECHA=1
.equ MODE_CFG_HORA=2
.equ MODE_CFG_FECHA=3
.equ MODE_CFG_ALARMA=4
.equ MODE_RING=5

.def PUNTO=R25

.dseg
MULTIPLEXOR:      .byte 1
DISP_VALUE:       .byte 1

UN_MIN:           .byte 1
DEC_MIN:          .byte 1
UN_HORA:          .byte 1
DEC_HORA:         .byte 1

UN_DIA:           .byte 1
DEC_DIA:          .byte 1
UN_MES:           .byte 1
DEC_MES:          .byte 1

UN_MIN_ALARMA:    .byte 1
DEC_MIN_ALARMA:   .byte 1
UN_HORA_ALARMA:   .byte 1
DEC_HORA_ALARMA:  .byte 1

TIEMPO:           .byte 1
MODE:             .byte 1
CONTAR:           .byte 1
MULTIPLEXION:     .byte 1

BTN_F_UP:         .byte 1
BTN_F_DN:         .byte 1
BTN_H_UP:         .byte 1
BTN_H_DN:         .byte 1

ALARMA:           .byte 1

.cseg
.org 0x0000
    jmp START
.org PCI0addr
    jmp PINB_ISR
.org PCI2addr
    jmp PIND_ISR
.org OVF1addr
    jmp TMR1_ISR
.org OVF0addr
    jmp TMR0_ISR

table7seg:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

START:
    cli
    ldi R16,LOW(RAMEND)
    out SPL,R16
    ldi R16,HIGH(RAMEND)
    out SPH,R16

    ; Apagar UART para usar D0 y D1
    ldi R16,0x00
    sts UCSR0B,R16

    ; Puerto B
    ; PB0 = D8 modo (entrada)
    ; PB1 = D9 LED hora (salida)
    ; PB2 = D10 LED fecha (salida)
    ; PB3 = D11 hora + (entrada)
    ; PB4 = D12 hora - (entrada)
    ; PB5 = D13 buzzer (salida)
    ldi R16,(1<<DDB1)|(1<<DDB2)|(1<<DDB5)
    out DDRB,R16
    ldi R16,(1<<PB0)|(1<<PB3)|(1<<PB4)
    out PORTB,R16

    ; Puerto C
    ; PC0..PC5 = A..F
    ldi R16,0b00111111
    out DDRC,R16
    clr R16
    out PORTC,R16

    ; Puerto D
    ; PD0 = D0 fecha + (entrada)
    ; PD1 = D1 fecha - (entrada)
    ; PD2 = D2 DP (salida)
    ; PD3 = D3 D1 (salida)
    ; PD4 = D4 D2 (salida)
    ; PD5 = D5 D3 (salida)
    ; PD6 = D6 D4 (salida)
    ; PD7 = D7 G (salida)
    ldi R16,0b11111100
    out DDRD,R16
    ldi R16,0b00000011
    out PORTD,R16

    rcall INIT_TMR1
    rcall INIT_TMR0

    clr PUNTO
    clr R16
    sts MULTIPLEXOR,R16
    sts DISP_VALUE,R16

    sts UN_MIN,R16
    sts DEC_MIN,R16
    sts UN_HORA,R16
    sts DEC_HORA,R16
    sts DEC_DIA,R16
    sts DEC_MES,R16

    sts UN_MIN_ALARMA,R16
    sts DEC_MIN_ALARMA,R16
    sts UN_HORA_ALARMA,R16
    sts DEC_HORA_ALARMA,R16

    sts TIEMPO,R16
    sts MODE,R16
    sts CONTAR,R16
    sts MULTIPLEXION,R16
    sts BTN_F_UP,R16
    sts BTN_F_DN,R16
    sts BTN_H_UP,R16
    sts BTN_H_DN,R16
    sts ALARMA,R16

    ldi R16,0x01
    sts UN_DIA,R16
    sts UN_MES,R16

    ; Interrupciones
    ldi R16,(1<<TOIE1)
    sts TIMSK1,R16
    ldi R16,(1<<TOIE0)
    sts TIMSK0,R16

    ; PCINT0: PB0, PB3, PB4
    ; PCINT2: PD0, PD1
    ldi R16,(1<<PCIE0)|(1<<PCIE2)
    sts PCICR,R16
    ldi R16,(1<<PCINT0)|(1<<PCINT3)|(1<<PCINT4)
    sts PCMSK0,R16
    ldi R16,(1<<PCINT16)|(1<<PCINT17)
    sts PCMSK2,R16

    sei

MAIN_LOOP:
VERIFY_MODE0:
    lds R16,MODE
    cpi R16,0x00
    brne VERIFY_MODE1
    rjmp MODE_0
VERIFY_MODE1:
    cpi R16,0x01
    brne VERIFY_MODE2
    rjmp MODE_1
VERIFY_MODE2:
    cpi R16,0x02
    brne VERIFY_MODE3
    rjmp MODE_2
VERIFY_MODE3:
    cpi R16,0x03
    brne VERIFY_MODE4
    rjmp MODE_3
VERIFY_MODE4:
    cpi R16,0x04
    brne VERIFY_MODE5
    rjmp MODE_4
VERIFY_MODE5:
    cpi R16,0x05
    brne MULTIPLEXAR
    rjmp MODE_5

MULTIPLEXAR:
    rjmp MULTIPLEXACION

;================ MOSTRAR =================
MOSTRAR:
    ; A..F -> PORTC
    lds R16,DISP_VALUE
    ldi ZH,HIGH(table7seg<<1)
    ldi ZL,LOW(table7seg<<1)
    add ZL,R16
    lpm R17,Z

    mov R16,R17
    andi R16,0b00111111
    out PORTC,R16

    ; PORTD: mantener pull-up en PD0 y PD1
    ldi R16,0b00000011

    ; G
    sbrc R17,6
    ori R16,(1<<PD7)

    ; Dígito activo según MULTIPLEXOR
    lds R18,MULTIPLEXOR
    cpi R18,0
    brne DIG1
    ori R16,(1<<PD3)
    rjmp CHECK_DP
DIG1:
    cpi R18,1
    brne DIG2
    ori R16,(1<<PD4)
    rjmp CHECK_DP
DIG2:
    cpi R18,2
    brne DIG3
    ori R16,(1<<PD5)
    rjmp CHECK_DP
DIG3:
    ori R16,(1<<PD6)

CHECK_DP:
    ; dos puntos en los dos dígitos del centro
    lds R18,MULTIPLEXOR
    cpi R18,1
    breq USE_DP
    cpi R18,2
    breq USE_DP
    rjmp NO_DP
USE_DP:
    tst PUNTO
    breq NO_DP
    ori R16,(1<<PD2)
NO_DP:
    out PORTD,R16

    rcall ACTUALIZAR_PORTB
    rjmp MAIN_LOOP

ACTUALIZAR_PORTB:
    ; mantener pull-ups en PB0, PB3, PB4
    ldi R16,(1<<PB0)|(1<<PB3)|(1<<PB4)

    lds R17,MODE
    cpi R17,MODE_FECHA
    breq LED_FECHA
    cpi R17,MODE_CFG_FECHA
    breq LED_FECHA
    ; resto -> LED hora
    ori R16,(1<<PB1)
    rjmp CHECK_BUZZER
LED_FECHA:
    ori R16,(1<<PB2)

CHECK_BUZZER:
    lds R17,ALARMA
    cpi R17,0x01
    brne SALIDA_B
    ori R16,(1<<PB5)
SALIDA_B:
    out PORTB,R16
    ret

;================ MODOS =================
MODE_0:
    rcall ACTUALIZAR_RELOJ_SI_TOCA
    rcall REVISAR_ALARMA
    rcall APAGAR_ALARMA_SI_BOTON
    rjmp MULTIPLEXAR

MODE_1:
    rcall ACTUALIZAR_RELOJ_SI_TOCA
    rcall REVISAR_ALARMA
    rcall APAGAR_ALARMA_SI_BOTON
    rjmp MULTIPLEXAR

MODE_2:
    rcall PROCESAR_CFG_HORA
    rjmp MULTIPLEXAR

MODE_3:
    rcall PROCESAR_CFG_FECHA
    rjmp MULTIPLEXAR

MODE_4:
    rcall PROCESAR_CFG_ALARMA
    rjmp MULTIPLEXAR

MODE_5:
    ; alarma activa
    rcall APAGAR_ALARMA_SI_BOTON
    rjmp MULTIPLEXAR

;================ SUBRUTINAS DE LOGICA =================
ACTUALIZAR_RELOJ_SI_TOCA:
    cli
    lds R16,CONTAR
    cpi R16,0x01
    brne ARST_NO
    clr R16
    sts CONTAR,R16
    sei
    rjmp SUMAR_MINUTO
ARST_NO:
    sei
    ret

SUMAR_MINUTO:
    lds R17,UN_MIN
    lds R18,DEC_MIN
    lds R19,UN_HORA
    lds R20,DEC_HORA
    lds R21,UN_DIA
    lds R22,DEC_DIA
    lds R23,UN_MES
    lds R24,DEC_MES

    inc R17
    cpi R17,10
    breq SUM_DEC_MIN
    rjmp GUARDAR_TIEMPO
SUM_DEC_MIN:
    clr R17
    inc R18
    cpi R18,6
    breq SUM_UN_HORA
    rjmp GUARDAR_TIEMPO
SUM_UN_HORA:
    clr R18
    inc R19
    cpi R19,4
    breq VERIFY_24
    cpi R19,10
    breq SUM_DEC_HORA
    rjmp GUARDAR_TIEMPO
SUM_DEC_HORA:
    clr R19
    inc R20
VERIFY_24:
    cpi R19,4
    brne GUARDAR_TIEMPO
    cpi R20,2
    brne GUARDAR_TIEMPO

    clr R19
    clr R20
    ; sumar fecha
    rcall SUMAR_DIA_LOGICA
    lds R21,UN_DIA
    lds R22,DEC_DIA
    lds R23,UN_MES
    lds R24,DEC_MES

GUARDAR_TIEMPO:
    sts UN_MIN,R17
    sts DEC_MIN,R18
    sts UN_HORA,R19
    sts DEC_HORA,R20
    sts UN_DIA,R21
    sts DEC_DIA,R22
    sts UN_MES,R23
    sts DEC_MES,R24
    ret

SUMAR_DIA_LOGICA:
    lds R16,UN_DIA
    lds R17,DEC_DIA
    lds R18,UN_MES
    lds R19,DEC_MES

    cpi R19,1
    breq SD_TRES_FINALES
    rjmp SD_NUEVE_PRIMEROS

SD_TRES_FINALES:
    cpi R18,1
    breq SD_30
    rjmp SD_31

SD_NUEVE_PRIMEROS:
    cpi R18,2
    breq SD_28
    cpi R18,4
    breq SD_30
    cpi R18,6
    breq SD_30
    cpi R18,9
    breq SD_30
    rjmp SD_31

SD_28:
    inc R16
    cpi R16,9
    breq SD_V28
    cpi R16,10
    brne SD_SAVE
    clr R16
    inc R17
SD_V28:
    cpi R16,9
    brne SD_SAVE
    cpi R17,2
    brne SD_SAVE
    ldi R16,1
    clr R17
    rjmp CAMBIO_MES_SD

SD_30:
    inc R16
    cpi R16,1
    breq SD_V30
    cpi R16,10
    brne SD_SAVE
    clr R16
    inc R17
SD_V30:
    cpi R16,1
    brne SD_SAVE
    cpi R17,3
    brne SD_SAVE
    ldi R16,1
    clr R17
    rjmp CAMBIO_MES_SD

SD_31:
    inc R16
    cpi R16,2
    breq SD_V31
    cpi R16,10
    brne SD_SAVE
    clr R16
    inc R17
SD_V31:
    cpi R16,2
    brne SD_SAVE
    cpi R17,3
    brne SD_SAVE
    ldi R16,1
    clr R17

CAMBIO_MES_SD:
    inc R18
    cpi R18,3
    breq SD_V12
    cpi R18,10
    brne SD_SAVE
    clr R18
    inc R19
SD_V12:
    cpi R18,3
    brne SD_SAVE
    cpi R19,1
    brne SD_SAVE
    ldi R18,1
    clr R19

SD_SAVE:
    sts UN_DIA,R16
    sts DEC_DIA,R17
    sts UN_MES,R18
    sts DEC_MES,R19
    ret

REVISAR_ALARMA:
    lds R16,UN_MIN
    lds R17,UN_MIN_ALARMA
    cp R16,R17
    brne RA_EXIT
    lds R16,DEC_MIN
    lds R17,DEC_MIN_ALARMA
    cp R16,R17
    brne RA_EXIT
    lds R16,UN_HORA
    lds R17,UN_HORA_ALARMA
    cp R16,R17
    brne RA_EXIT
    lds R16,DEC_HORA
    lds R17,DEC_HORA_ALARMA
    cp R16,R17
    brne RA_EXIT
    ldi R16,0x01
    sts ALARMA,R16
    ldi R16,MODE_RING
    sts MODE,R16
RA_EXIT:
    ret

APAGAR_ALARMA_SI_BOTON:
    cli
    lds R16,BTN_F_UP
    cpi R16,0x01
    breq APAGAR_AHORA
    lds R16,BTN_F_DN
    cpi R16,0x01
    breq APAGAR_AHORA
    lds R16,BTN_H_UP
    cpi R16,0x01
    breq APAGAR_AHORA
    lds R16,BTN_H_DN
    cpi R16,0x01
    breq APAGAR_AHORA
    sei
    ret
APAGAR_AHORA:
    clr R16
    sts ALARMA,R16
    sts BTN_F_UP,R16
    sts BTN_F_DN,R16
    sts BTN_H_UP,R16
    sts BTN_H_DN,R16
    sts MODE,R16
    sei
    ret

PROCESAR_CFG_HORA:
    cli
    lds R16,BTN_F_UP
    cpi R16,0x01
    brne PCH_2
    clr R16
    sts BTN_F_UP,R16
    sei
    rjmp INC_MINUTO
PCH_2:
    sei
    cli
    lds R16,BTN_F_DN
    cpi R16,0x01
    brne PCH_3
    clr R16
    sts BTN_F_DN,R16
    sei
    rjmp DEC_MINUTO
PCH_3:
    sei
    cli
    lds R16,BTN_H_UP
    cpi R16,0x01
    brne PCH_4
    clr R16
    sts BTN_H_UP,R16
    sei
    rjmp INC_HORA
PCH_4:
    sei
    cli
    lds R16,BTN_H_DN
    cpi R16,0x01
    brne PCH_EXIT
    clr R16
    sts BTN_H_DN,R16
    sei
    rjmp DEC_HORA
PCH_EXIT:
    sei
    ret

PROCESAR_CFG_FECHA:
    cli
    lds R16,BTN_F_UP
    cpi R16,0x01
    brne PCF_2
    clr R16
    sts BTN_F_UP,R16
    sei
    rjmp INC_DIA
PCF_2:
    sei
    cli
    lds R16,BTN_F_DN
    cpi R16,0x01
    brne PCF_3
    clr R16
    sts BTN_F_DN,R16
    sei
    rjmp DEC_DIA
PCF_3:
    sei
    cli
    lds R16,BTN_H_UP
    cpi R16,0x01
    brne PCF_4
    clr R16
    sts BTN_H_UP,R16
    sei
    rjmp INC_MES
PCF_4:
    sei
    cli
    lds R16,BTN_H_DN
    cpi R16,0x01
    brne PCF_EXIT
    clr R16
    sts BTN_H_DN,R16
    sei
    rjmp DEC_MES
PCF_EXIT:
    sei
    ret

PROCESAR_CFG_ALARMA:
    cli
    lds R16,BTN_F_UP
    cpi R16,0x01
    brne PCA_2
    clr R16
    sts BTN_F_UP,R16
    sei
    rjmp INC_MIN_ALARMA
PCA_2:
    sei
    cli
    lds R16,BTN_F_DN
    cpi R16,0x01
    brne PCA_3
    clr R16
    sts BTN_F_DN,R16
    sei
    rjmp DEC_MIN_ALARMA
PCA_3:
    sei
    cli
    lds R16,BTN_H_UP
    cpi R16,0x01
    brne PCA_4
    clr R16
    sts BTN_H_UP,R16
    sei
    rjmp INC_HORA_ALARMA
PCA_4:
    sei
    cli
    lds R16,BTN_H_DN
    cpi R16,0x01
    brne PCA_EXIT
    clr R16
    sts BTN_H_DN,R16
    sei
    rjmp DEC_HORA_ALARMA
PCA_EXIT:
    sei
    ret

INC_MINUTO:
    lds R17,UN_MIN
    lds R18,DEC_MIN
    inc R17
    cpi R17,10
    brne GIM
    clr R17
    inc R18
    cpi R18,6
    brne GIM
    clr R18
GIM:
    sts UN_MIN,R17
    sts DEC_MIN,R18
    ret

DEC_MINUTO:
    lds R17,UN_MIN
    lds R18,DEC_MIN
    dec R17
    cpi R17,255
    brne GDM
    ldi R17,9
    dec R18
    cpi R18,255
    brne GDM
    ldi R18,5
GDM:
    sts UN_MIN,R17
    sts DEC_MIN,R18
    ret

INC_HORA:
    lds R17,UN_HORA
    lds R18,DEC_HORA
    inc R17
    cpi R17,4
    breq IH_V24
    cpi R17,10
    breq IH_SUMDEC
    rjmp GIH
IH_SUMDEC:
    clr R17
    inc R18
IH_V24:
    cpi R17,4
    brne GIH
    cpi R18,2
    brne GIH
    clr R17
    clr R18
GIH:
    sts UN_HORA,R17
    sts DEC_HORA,R18
    ret

DEC_HORA:
    lds R17,UN_HORA
    lds R18,DEC_HORA
    dec R17
    cpi R17,255
    breq DH_DEC
    rjmp GDH
DH_DEC:
    ldi R17,9
    dec R18
    cpi R18,255
    brne GDH
    ldi R17,3
    ldi R18,2
GDH:
    sts UN_HORA,R17
    sts DEC_HORA,R18
    ret

INC_MES:
    lds R17,UN_MES
    lds R18,DEC_MES
    inc R17
    cpi R17,3
    breq IM_V12
    cpi R17,10
    breq IM_SUMDEC
    rjmp GMEI
IM_SUMDEC:
    clr R17
    inc R18
IM_V12:
    cpi R17,3
    brne GMEI
    cpi R18,1
    brne GMEI
    ldi R17,1
    clr R18
GMEI:
    sts UN_MES,R17
    sts DEC_MES,R18
    ret

DEC_MES:
    lds R17,UN_MES
    lds R18,DEC_MES
    cpi R17,1
    brne DM_N
    cpi R18,0
    brne DM_N
    ldi R17,2
    ldi R18,1
    rjmp GMED
DM_N:
    dec R17
    cpi R17,255
    brne GMED
    ldi R17,9
    dec R18
GMED:
    sts UN_MES,R17
    sts DEC_MES,R18
    ret

INC_DIA:
    rcall SUMAR_DIA_LOGICA
    ret

DEC_DIA:
    lds R16,UN_DIA
    lds R17,DEC_DIA
    lds R18,UN_MES
    lds R19,DEC_MES

    cpi R16,1
    brne DD_NORMAL
    cpi R17,0
    brne DD_NORMAL

    cpi R19,1
    breq DD_TRES_F
    rjmp DD_NUEVE_P
DD_TRES_F:
    cpi R18,1
    breq DD_30
    rjmp DD_31
DD_NUEVE_P:
    cpi R18,2
    breq DD_28
    cpi R18,4
    breq DD_30
    cpi R18,6
    breq DD_30
    cpi R18,9
    breq DD_30
    rjmp DD_31
DD_28:
    ldi R16,8
    ldi R17,2
    rjmp DD_SAVE
DD_30:
    ldi R16,0
    ldi R17,3
    rjmp DD_SAVE
DD_31:
    ldi R16,1
    ldi R17,3
    rjmp DD_SAVE
DD_NORMAL:
    dec R16
    cpi R16,255
    brne DD_SAVE
    ldi R16,9
    dec R17
DD_SAVE:
    sts UN_DIA,R16
    sts DEC_DIA,R17
    sts UN_MES,R18
    sts DEC_MES,R19
    ret

INC_MIN_ALARMA:
    lds R17,UN_MIN_ALARMA
    lds R18,DEC_MIN_ALARMA
    inc R17
    cpi R17,10
    brne GIMA
    clr R17
    inc R18
    cpi R18,6
    brne GIMA
    clr R18
GIMA:
    sts UN_MIN_ALARMA,R17
    sts DEC_MIN_ALARMA,R18
    ret

DEC_MIN_ALARMA:
    lds R17,UN_MIN_ALARMA
    lds R18,DEC_MIN_ALARMA
    dec R17
    cpi R17,255
    brne GDMA
    ldi R17,9
    dec R18
    cpi R18,255
    brne GDMA
    ldi R18,5
GDMA:
    sts UN_MIN_ALARMA,R17
    sts DEC_MIN_ALARMA,R18
    ret

INC_HORA_ALARMA:
    lds R17,UN_HORA_ALARMA
    lds R18,DEC_HORA_ALARMA
    inc R17
    cpi R17,4
    breq IHA_V24
    cpi R17,10
    breq IHA_SUMDEC
    rjmp GIHA
IHA_SUMDEC:
    clr R17
    inc R18
IHA_V24:
    cpi R17,4
    brne GIHA
    cpi R18,2
    brne GIHA
    clr R17
    clr R18
GIHA:
    sts UN_HORA_ALARMA,R17
    sts DEC_HORA_ALARMA,R18
    ret

DEC_HORA_ALARMA:
    lds R17,UN_HORA_ALARMA
    lds R18,DEC_HORA_ALARMA
    dec R17
    cpi R17,255
    breq DHA_DEC
    rjmp GDHA
DHA_DEC:
    ldi R17,9
    dec R18
    cpi R18,255
    brne GDHA
    ldi R17,3
    ldi R18,2
GDHA:
    sts UN_HORA_ALARMA,R17
    sts DEC_HORA_ALARMA,R18
    ret

;================ MULTIPLEXACION =================
MULTIPLEXACION:
    cli
    lds R16,MULTIPLEXION
    cpi R16,0x01
    brne NO_MULTIPLEXAR
    clr R16
    sts MULTIPLEXION,R16
    sei
    rjmp MULTIPLEXAR_VALORES
NO_MULTIPLEXAR:
    sei
    rjmp EXIT_MULTIPLEXACION

MULTIPLEXAR_VALORES:
    lds R16,MODE
    cpi R16,MODE_HORA
    breq VAL_HORA
    cpi R16,MODE_FECHA
    breq VAL_FECHA
    cpi R16,MODE_CFG_HORA
    breq VAL_HORA
    cpi R16,MODE_CFG_FECHA
    breq VAL_FECHA
    cpi R16,MODE_CFG_ALARMA
    breq VAL_ALARMA
    cpi R16,MODE_RING
    breq VAL_HORA
    rjmp EXIT_MULTIPLEXACION

VAL_HORA:
    rjmp MOSTRAR_HORA
VAL_FECHA:
    rjmp MOSTRAR_FECHA
VAL_ALARMA:
    rjmp MOSTRAR_HORA_ALARMA

MOSTRAR_HORA:
    lds R16,MULTIPLEXOR
    cpi R16,0
    breq MH0
    cpi R16,1
    breq MH1
    cpi R16,2
    breq MH2
    rjmp MH3
MH0:
    lds R17,UN_MIN
    ldi R16,1
    rjmp MHG
MH1:
    lds R17,DEC_MIN
    ldi R16,2
    rjmp MHG
MH2:
    lds R17,UN_HORA
    ldi R16,3
    rjmp MHG
MH3:
    lds R17,DEC_HORA
    ldi R16,0
MHG:
    sts DISP_VALUE,R17
    sts MULTIPLEXOR,R16
    rjmp EXIT_MULTIPLEXACION

MOSTRAR_FECHA:
    lds R16,MULTIPLEXOR
    cpi R16,0
    breq MF0
    cpi R16,1
    breq MF1
    cpi R16,2
    breq MF2
    rjmp MF3
MF0:
    lds R17,UN_MES
    ldi R16,1
    rjmp MFG
MF1:
    lds R17,DEC_MES
    ldi R16,2
    rjmp MFG
MF2:
    lds R17,UN_DIA
    ldi R16,3
    rjmp MFG
MF3:
    lds R17,DEC_DIA
    ldi R16,0
MFG:
    sts DISP_VALUE,R17
    sts MULTIPLEXOR,R16
    rjmp EXIT_MULTIPLEXACION

MOSTRAR_HORA_ALARMA:
    lds R16,MULTIPLEXOR
    cpi R16,0
    breq MA0
    cpi R16,1
    breq MA1
    cpi R16,2
    breq MA2
    rjmp MA3
MA0:
    lds R17,UN_MIN_ALARMA
    ldi R16,1
    rjmp MAG
MA1:
    lds R17,DEC_MIN_ALARMA
    ldi R16,2
    rjmp MAG
MA2:
    lds R17,UN_HORA_ALARMA
    ldi R16,3
    rjmp MAG
MA3:
    lds R17,DEC_HORA_ALARMA
    ldi R16,0
MAG:
    sts DISP_VALUE,R17
    sts MULTIPLEXOR,R16
    rjmp EXIT_MULTIPLEXACION

EXIT_MULTIPLEXACION:
    rjmp MOSTRAR

;================ TIMERS =================
INIT_TMR1:
    clr R16
    sts TCCR1A,R16
    ldi R16,(1<<CS12)
    sts TCCR1B,R16
    ldi R16,HIGH(TMR1_VALUE)
    sts TCNT1H,R16
    ldi R16,LOW(TMR1_VALUE)
    sts TCNT1L,R16
    ret

INIT_TMR0:
    clr R16
    out TCCR0A,R16
    ldi R16,(1<<CS02)
    out TCCR0B,R16
    ldi R16,TMR0_VALUE
    out TCNT0,R16
    ret

;================ ISR =================
PINB_ISR:
    push R16
    in   R16,SREG
    push R16
    push R17

    rcall DELAY_BTN_B
    in   R16,PINB

    ; modo PB0
    sbrs R16,PB0
    rjmp PB_MODE
PB_HUP_CHECK:
    sbrs R16,PB3
    rjmp PB_HUP
PB_HDN_CHECK:
    sbrs R16,PB4
    rjmp PB_HDN
    rjmp PB_EXIT

PB_MODE:
    lds R17,MODE
    inc R17
    cpi R17,MAX_MODES
    brlo PB_MODE_SAVE
    clr R17
PB_MODE_SAVE:
    sts MODE,R17
    rjmp PB_EXIT

PB_HUP:
    ldi R17,0x01
    sts BTN_H_UP,R17
    rjmp PB_EXIT

PB_HDN:
    ldi R17,0x01
    sts BTN_H_DN,R17

PB_EXIT:
    pop R17
    pop R16
    out SREG,R16
    pop R16
    reti

PIND_ISR:
    push R16
    in   R16,SREG
    push R16
    push R17

    rcall DELAY_BTN_D
    in   R16,PIND

    sbrs R16,PD0
    rjmp PD_FUP
PD_FDN_CHECK:
    sbrs R16,PD1
    rjmp PD_FDN
    rjmp PD_EXIT

PD_FUP:
    ldi R17,0x01
    sts BTN_F_UP,R17
    rjmp PD_EXIT

PD_FDN:
    ldi R17,0x01
    sts BTN_F_DN,R17

PD_EXIT:
    pop R17
    pop R16
    out SREG,R16
    pop R16
    reti

TMR0_ISR:
    push R16
    in   R16,SREG
    push R16
    ldi R16,TMR0_VALUE
    out TCNT0,R16
    ldi R16,0x01
    sts MULTIPLEXION,R16
    pop R16
    out SREG,R16
    pop R16
    reti

TMR1_ISR:
    push R16
    in   R16,SREG
    push R16
    ldi R16,HIGH(TMR1_VALUE)
    sts TCNT1H,R16
    ldi R16,LOW(TMR1_VALUE)
    sts TCNT1L,R16

    ; parpadeo dos puntos
    tst PUNTO
    brne P_OFF
    ldi PUNTO,0x01
    rjmp P_DONE
P_OFF:
    clr PUNTO
P_DONE:

    ; 120 medios segundos = 60 segundos
    lds R16,TIEMPO
    inc R16
    cpi R16,120
    brne T1_SAVE
    ldi R16,0x01
    sts CONTAR,R16
    clr R16
T1_SAVE:
    sts TIEMPO,R16

    pop R16
    out SREG,R16
    pop R16
    reti

DELAY_BTN_B:
    ldi R18,8
DB1:
    ldi R19,255
DB2:
    dec R19
    brne DB2
    dec R18
    brne DB1
    ret

DELAY_BTN_D:
    ldi R18,8
DD1:
    ldi R19,255
DD2:
    dec R19
    brne DD2
    dec R18
    brne DD1
    ret