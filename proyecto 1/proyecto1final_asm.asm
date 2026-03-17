/*
* Proyecto_1.asm
*
* Creado: 28/02/2026 15:11:30
* Autor : Jose Mendez
*/

/****************************************/
//*

.include "M328PDEF.inc"

//Constantes
.equ    TMR0_VALUE      = 240 //Valor de inicio de timer 0
.equ    TMR1_VALUE      = 0xF85F //valor de inicio de timer 1
.equ    MODO_MAX        = 7 //Número de modos

.equ    ANT_MODO_MAX    = 8 //antirebote de boton de modo
.equ    ANT_MAS_MAX     = 8	//antirebote de boton aumento
.equ    ANT_MENOS_MAX   = 8	//antirebote de boton decremento
.equ    ANT_CAMBIO_MAX  = 8 //antirebote de boton de cambio rapido

//Action Flags
.equ    AF_REV         = 0 //Si detecta que el bit 0 de action flags se activa realiza scan al display
.equ    AF_MINUTO       = 1 //Si detecta que el bit 1 de action flags paso un minuto
.equ    AF_MAS          = 2	//Si detecta que el bit 2 de action flags se incrementa la cuenta
.equ    AF_MENOS        = 3	//Si detecta que el bit 3 de action flags se decrementa la cuenta

//Mode flags
.equ    MF_CLOCK        = 0 //Si el bit 0 esta activado va al modo clock
.equ    MF_DATE         = 1	//Si el bit 1 esta activado va al modo fecha
.equ    MF_SET_MIN      = 2	//Si el bit 2 esta activado va al modo cambio de minutos
.equ    MF_SET_HOR      = 3	//Si el bit 3 esta activado va al modo cambio de horas
.equ    MF_SET_MES      = 4	//Si el bit 4 esta activado va al modo cambio de mes
.equ    MF_SET_DIA      = 5	//Si el bit 5 esta activado va al modo cambio de fecha
.equ    MF_SET_AMIN     = 6	//Si el bit 6 esta activado va al modo cambio alarma min
.equ    MF_SET_AHOR     = 7	//Si el bit 7 esta activado va al modo cambio alarma horas

.def    PUNTO           = R25 //R25 controlará al punto para que titilee

//SRAM
.dseg
BLOQ_MODO       :   .byte 1 //Bloqueo de botones para evitar rebote
BLOQ_MAS        :   .byte 1	//Bloqueo de botones para evitar rebote
BLOQ_MENOS      :   .byte 1	//Bloqueo de botones para evitar rebote
BLOQ_CAMBIO     :   .byte 1 //Bloqueo de botones para evitar rebote

CNT_MODO        :   .byte 1 //Contador de tiempo rápido para evaluar que el boton siga pulsado
CNT_MAS         :   .byte 1	//Contador de tiempo rápido para evaluar que el boton siga pulsado
CNT_MENOS       :   .byte 1	//Contador de tiempo rápido para evaluar que el boton siga pulsado
CNT_CAMBIO      :   .byte 1 //Contador de tiempo rápido para evaluar que el boton siga pulsado

DIG_ACT         :   .byte 1 //guarda si el digito esta en d1 d2 d3 o d4
VALOR_DIG       :   .byte 1	//sube el valor que se va a poner en el display

MIN_U           :   .byte 1 //guarda en unidades los minutos
MIN_D           :   .byte 1	//guarda en decenas los minutos
HOR_U           :   .byte 1	//guarda en unidades las horas
HOR_D           :   .byte 1	//guarda en decenas las horas 

DIA_U           :   .byte 1 //guarda en unidades el día
DIA_D           :   .byte 1	//guarda en decenas el día
MES_U           :   .byte 1	//guarda en unidades el mes
MES_D           :   .byte 1	//guarda en decenas el mes

ALM_MIN_U       :   .byte 1 //Minutos de la alarma
ALM_MIN_D       :   .byte 1
ALM_HOR_U       :   .byte 1 //Horas de la alarma
ALM_HOR_D       :   .byte 1

MODO_ACT        :   .byte 1 //numero de modo actual
MODE_FLAGS      :   .byte 1 //modo actual en bis
ACTION_FLAGS    :   .byte 1 //eventos en bits
F_ALARMA        :   .byte 1 //alarma activa si o no

TICK_05S        :   .byte 1 //contador de ticks de timer 1 para ver cuando pase un minuto
BTN_ESTADO    :   .byte 1 //Guarda el estado de los botones de aumento y decremente

.cseg
.org 0x0000
    JMP RESET
.org PCI0addr
    JMP ISR_PB
.org PCI2addr
    JMP ISR_PD
.org OVF1addr
    JMP ISR_T1
.org OVF0addr
    JMP ISR_T0
; =========================================================
; TABLA MAX DIA POR MES 
; =========================================================
TABLA_MAX_DIA:
    .DB 0x31, 0x28, 0x31, 0x30, 0x31, 0x30 //Guardamos el máximo de cada mes
    .DB 0x31, 0x31, 0x30, 0x31, 0x30, 0x31
; =========================================================
; TABLA 7 SEG
; =========================================================
TABLA7SEG:
    .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07
    .DB 0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

; =========================================================
; RESET
; =========================================================
RESET:
		// Ponemos el reloj en 1 MHz
	CLI
	LDI		R16, (1<< CLKPCE)
	STS		CLKPR, R16
	LDI		R16, (1<< CLKPS2)
	STS		CLKPR, R16

    CLI

    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

    RCALL   SETUP_IO //Configuracion de puertos
    RCALL   SETUP_RAM //Iniciamos las variables de la ram
    RCALL   SETUP_T0 //configuración del timer 0
    RCALL   SETUP_T1 //Configuración de timer 1
    RCALL   SETUP_INT //Configuración de las interrupciones

    SEI

; =========================================================
; MAIN LOOP
; =========================================================
MAIN_LOOP:
    LDS     R16, MODE_FLAGS //PROBAMOS CONSTANTEMENTE EL MODO EN EL QUE ESTA 

    SBRC    R16, MF_CLOCK 
    RJMP    RUT_MODO0

    SBRC    R16, MF_DATE
    RJMP    RUT_MODO1

    SBRC    R16, MF_SET_MIN
    RJMP    RUT_MODO2

    SBRC    R16, MF_SET_HOR
    RJMP    RUT_MODO3

    SBRC    R16, MF_SET_MES
    RJMP    RUT_MODO4

    SBRC    R16, MF_SET_DIA
    RJMP    RUT_MODO5

    SBRC    R16, MF_SET_AMIN
    RJMP    RUT_MODO6

    SBRC    R16, MF_SET_AHOR
    RJMP    RUT_MODO7

    RJMP    MULTIPLEX

// =========================================================
// CONFIGURACION
// =========================================================
SETUP_IO:
    //PB0 modo, PB1 boton de cambio, PB2 LED1, PB3 LED2, PB4 LED3, PB5 buzzer
    LDI     R16, (1<<DDB2)|(1<<DDB3)|(1<<DDB4)|(1<<DDB5)
    OUT     DDRB, R16
    LDI     R16, (1<<PB0)|(1<<PB1)
    OUT     PORTB, R16

    //PC0-PC5 segmentos a-f en orden
    LDI     R16, (1<<DDC0)|(1<<DDC1)|(1<<DDC2)|(1<<DDC3)|(1<<DDC4)|(1<<DDC5)
    OUT     DDRC, R16
    CLR     R16
    OUT     PORTC, R16
	//USART
	CLR     R16
    STS     UCSR0B, R16
    //PD0 menos PD1 mas PD2 dp, PD3 a PD6 digitos D1,D2,D3,D4, PD7 G
    LDI     R16, (1<<DDD2)|(1<<DDD3)|(1<<DDD4)|(1<<DDD5)|(1<<DDD6)|(1<<DDD7)
    OUT     DDRD, R16
    LDI     R16, (1<<PD0)|(1<<PD1)|(1<<PD3)|(1<<PD4)|(1<<PD5)|(1<<PD6)
    OUT     PORTD, R16
    RET

    

SETUP_RAM:
//Limpiamos los puntitos
    CLR     PUNTO
//Empezamos con 0 en el digito actual
    LDI     R16, 0b00001110
    STS     DIG_ACT, R16
	//LIMPIAMOS REGISTROS
    CLR     R16
    STS     MIN_U, R16
    STS     MIN_D, R16
    STS     HOR_U, R16
    STS     HOR_D, R16
    STS     DIA_D, R16
    STS     MES_D, R16
    STS     VALOR_DIG, R16

    STS     ALM_MIN_U, R16
    STS     ALM_MIN_D, R16
    STS     ALM_HOR_U, R16
    STS     ALM_HOR_D, R16

    STS     MODO_ACT, R16
    STS     MODE_FLAGS, R16
    STS     ACTION_FLAGS, R16
    STS     F_ALARMA, R16
    STS     TICK_05S, R16

    STS     BLOQ_MODO, R16
    STS     BLOQ_MAS, R16
    STS     BLOQ_MENOS, R16
    STS     BLOQ_CAMBIO, R16
    STS     CNT_MODO, R16
    STS     CNT_MAS, R16
    STS     CNT_MENOS, R16
    STS     CNT_CAMBIO, R16
	//Empezamos el dia en 1 y el mes en 1
    LDI     R16, 1
    STS     DIA_U, R16
    STS     MES_U, R16
	//Estado inicial de los botones
    IN      R16, PIND
    ANDI    R16, 0b00000011
    STS     BTN_ESTADO, R16

    RCALL   ACTUALIZAR_MODE_FLAGS
    RET

SETUP_INT:
    LDI     R16, (1<<TOIE1) //HAbilitamos interrupciones por overflow timer 1
    STS     TIMSK1, R16

    LDI     R16, (1<<TOIE0) //Habilitamos interrupciones por overflow en timer 0 
    STS     TIMSK0, R16

    LDI     R16, (1<<PCIE2)|(1<<PCIE0) //Habilitamos interrupciones por pin change
    STS     PCICR, R16

    LDI     R16, (1<<PCINT16)|(1<<PCINT17) //guardamos interrupciones en pd0 y pd1
    STS     PCMSK2, R16

    LDI     R16, (1<<PCINT0)|(1<<PCINT1) //guardamos interrupciones en pb0 y pb1
    STS     PCMSK0, R16
    RET

SETUP_T0: 
    CLR     R16
    OUT     TCCR0A, R16 //modo normal
    LDI     R16, (1<<CS02) //Prescaler en 256
    OUT     TCCR0B, R16
    LDI     R16, TMR0_VALUE //cargamos el valor de inicio
    OUT     TCNT0, R16
    RET

SETUP_T1:
    CLR     R16
    STS     TCCR1A, R16 //modo normal
    LDI     R16, (1<<CS12) //prescaler en 256
    STS     TCCR1B, R16 
    LDI     R16, HIGH(TMR1_VALUE)
    STS     TCNT1H, R16
    LDI     R16, LOW(TMR1_VALUE)
    STS     TCNT1L, R16 //Valor para que comience contando el timer 1
    RET

//Mode flags
ACTUALIZAR_MODE_FLAGS:
    CLR     R16
    LDS     R17, MODO_ACT
//Prende el bit correspondiente de las flags de modo
AMF_MODE0:
    CPI     R17, 0
    BRNE    AMF_MODE1
    LDI     R16, (1<<MF_CLOCK)
    RJMP    AMF_SAVE

AMF_MODE1:
    CPI     R17, 1
    BRNE    AMF_MODE2
    LDI     R16, (1<<MF_DATE)
    RJMP    AMF_SAVE

AMF_MODE2:
    CPI     R17, 2
    BRNE    AMF_MODE3
    LDI     R16, (1<<MF_SET_MIN)
    RJMP    AMF_SAVE

AMF_MODE3:
    CPI     R17, 3
    BRNE    AMF_MODE4
    LDI     R16, (1<<MF_SET_HOR)
    RJMP    AMF_SAVE

AMF_MODE4:
    CPI     R17, 4
    BRNE    AMF_MODE5
    LDI     R16, (1<<MF_SET_MES)
    RJMP    AMF_SAVE

AMF_MODE5:
    CPI     R17, 5
    BRNE    AMF_MODE6
    LDI     R16, (1<<MF_SET_DIA)
    RJMP    AMF_SAVE

AMF_MODE6:
    CPI     R17, 6
    BRNE    AMF_MODE7
    LDI     R16, (1<<MF_SET_AMIN)
    RJMP    AMF_SAVE

AMF_MODE7:
    LDI     R16, (1<<MF_SET_AHOR)

AMF_SAVE:
    STS     MODE_FLAGS, R16
    RET

; =========================================================
; DISPLAY
; =========================================================
MOSTRAR:
    LDS     R16, VALOR_DIG 
    LDI     ZH, HIGH(TABLA7SEG<<1)
    LDI     ZL, LOW(TABLA7SEG<<1)
    ADD     ZL, R16
    CLR     R17
    ADC     ZH, R17
    LPM     R17, Z

    MOV     R18, R17
    ANDI    R18, 0b00111111
    OUT     PORTC, R18

    LDI     R18, 0b00000011
    MOV     R19, PUNTO
    OR      R18, R19

    LDS     R19, DIG_ACT
    LSL     R19
    LSL     R19
    LSL     R19
    ANDI    R19, 0b01111000
    OR      R18, R19

    SBRC    R17, 6
    ORI     R18, 0b10000000

    OUT     PORTD, R18


    LDI     R18, 0b00000011

    LDS     R19, MODO_ACT
//Configuración para encender LEDS
MLED_MODE0:
    CPI     R19, 0 //Compara si el modo es 0 para encender su respectiva LED
    BRNE    MLED_MODE1
    RJMP    MLED_ALARMA_CHECK //Si es el modo, revisa la alarma

MLED_MODE1:
    CPI     R19, 1 //Compara si el modo es 1 para encender su respectiva LED
    BRNE    MLED_MODE2
    ORI     R18, 0b00010000
    RJMP    MLED_ALARMA_CHECK //Si es el modo, revisa la alarma

MLED_MODE2:
    CPI     R19, 2
    BRNE    MLED_MODE3
    ORI     R18, 0b00000100
    RJMP    MLED_ALARMA_CHECK

MLED_MODE3:
    CPI     R19, 3
    BRNE    MLED_MODE4
    ORI     R18, 0b00001000
    RJMP    MLED_ALARMA_CHECK

MLED_MODE4:
    CPI     R19, 4
    BRNE    MLED_MODE5
    ORI     R18, 0b00010100
    RJMP    MLED_ALARMA_CHECK

MLED_MODE5:
    CPI     R19, 5
    BRNE    MLED_MODE6
    ORI     R18, 0b00011000
    RJMP    MLED_ALARMA_CHECK

MLED_MODE6:
    CPI     R19, 6
    BRNE    MLED_MODE7
    ORI     R18, 0b00001100
    RJMP    MLED_ALARMA_CHECK

MLED_MODE7:
    ORI     R18, 0b00011100

MLED_ALARMA_CHECK:
    LDS     R19, F_ALARMA //Carga en r19 el estado de la bandera de alarma
    CPI     R19, 0
    BREQ    MOSTRAR_LED
    ORI     R18, 0b00100000 //Enciende el buzzer

MOSTRAR_LED:
    OUT     PORTB, R18 //Regresa a PORTB los registros iniciales, o si esta encendida la alarma
    RJMP    MAIN_LOOP

CARGAR_TIEMPO_FECHA: //Guardamos los registros de la RAM en registros noramles
    LDS     R17, MIN_U
    LDS     R18, MIN_D
    LDS     R19, HOR_U
    LDS     R20, HOR_D
    LDS     R21, DIA_U
    LDS     R22, DIA_D
    LDS     R23, MES_U
    LDS     R24, MES_D
    RET

GUARDAR_TIEMPO_FECHA: //Subimos los valores actuales a la RAM
    STS     MIN_U, R17
    STS     MIN_D, R18
    STS     HOR_U, R19
    STS     HOR_D, R20
    STS     DIA_U, R21
    STS     DIA_D, R22
    STS     MES_U, R23
    STS     MES_D, R24
    RET

APAGAR_ALARMA: //Guardamos 0 en el valor de la alarma
    CLR     R16
    STS     F_ALARMA, R16
    RET

REVISAR_ALARMA: //Compara la hora actual con la hora configurada en la alarma
    LDS     R16, MIN_U
    LDS     R26, ALM_MIN_U
    CP      R16, R26
    BRNE    RA_FIN

    LDS     R16, MIN_D
    LDS     R26, ALM_MIN_D
    CP      R16, R26
    BRNE    RA_FIN

    LDS     R16, HOR_U
    LDS     R26, ALM_HOR_U
    CP      R16, R26
    BRNE    RA_FIN

    LDS     R16, HOR_D
    LDS     R26, ALM_HOR_D
    CP      R16, R26
    BRNE    RA_FIN

    LDI     R16, 1
    STS     F_ALARMA, R16

RA_FIN:
    RET
; =========================================================
; OBTENER_MAX_DIA
; =========================================================
OBTENER_MAX_DIA:
    MOV     R18, R23 //Copiamos la unidad del mes
    CPI     R24, 1 //Compara la decena del mes
    BRNE    OMD_INDEX_OK //vamos a la tabla a buscar el mes del 1 al 9
    LDI     R19, 10
    ADD     R18, R19 //si no, suma al numero 10 para encontrar mes del 10-12

OMD_INDEX_OK:
    //Restamos el numero de mes a la posición pues la tabla va de 0 a 11
    DEC     R18

    //Buscamos en la tabla el mes y el dia
    LDI     ZH, HIGH(TABLA_MAX_DIA<<1)
    LDI     ZL, LOW(TABLA_MAX_DIA<<1)
    ADD     ZL, R18
    CLR     R19
    ADC     ZH, R19

    //Leemos el valor entero de el dia es decir decenas y unidades
    LPM     R16, Z

    //El valor leido lo sepraramos en decenas y unidades
    MOV     R17, R16
    ANDI    R16, 0x0F //extramemos el valor bajo del numero
    SWAP    R17
    ANDI    R17, 0x0F //Extraemos el valor alto del número
    RET
; =========================================================
; SUMAR_FECHA
; =========================================================
SUMAR_FECHA:
    ; ---------------------------------
    ; 1) sumar 1 al dia en BCD
    ; ---------------------------------
    INC     R21 //Incrementamos el día
    CPI     R21, 10 
    BRLO    SF_VERIFICAR_MAX //Si llega a 10, deja de aumentar unidades y aumenta decenas
    CLR     R21
    INC     R22

SF_VERIFICAR_MAX:

    RCALL   OBTENER_MAX_DIA //ya sabemos el día máximo al que puede llegar el mes
    CP      R22, R17 //compara el valor del día para ver si ya llegó al máximo
    BRLO    SF_FIN //Si el dia es menor al máximo, termina 
    BRNE    SF_CAMBIAR_MES //Si el día es mayor cambia el mes
//lo mismo pero con unidades
    CP      R21, R16 
    BRLO    SF_FIN
    BREQ    SF_FIN

SF_CAMBIAR_MES:
    //Reiniciamos el día para que comience en 1
    LDI     R21, 1
    CLR     R22

   //Incrementa el mes
    INC     R23 //incrementa unidad del mes
    CPI     R23, 10 //Comparación para ver si sigue siendo menor que 10
    BRLO    SF_REV_DICIEMBRE //Si es menor, revisa si es diciembre
    CLR     R23 //Si es mayor limpia unidades e incrementa decenas
    INC     R24

SF_REV_DICIEMBRE:
    CPI     R24, 1 //revisamos si la décima es 1
    BRNE    SF_FIN //Si no es 1 termina
    CPI     R23, 3 //Si la unidad es 3 y la decimma es 1 reinicia la unidad a 1 y limpia la decima
    BRNE    SF_FIN 

    LDI     R23, 1
    CLR     R24

SF_FIN:
    RET
; =========================================================
; ajusstar dia segun mes
; =========================================================
AJUSTAR_DIA_SEGUN_MES:
    //Cargar dia actual
    LDS     R21, DIA_U
    LDS     R22, DIA_D

    //Cargar mes actual
    LDS     R23, MES_U
    LDS     R24, MES_D

    //Obtener maximo del mes actual
    RCALL   OBTENER_MAX_DIA   

    //Comparar día con decena máxima
    CP      R22, R17
    BRLO    ADM_FIN          
    BRNE    ADM_CORREGIR      //Si la decena es mayor corrige

    //Si las decenas son iguales compara las unidades
    CP      R21, R16
    BRLO    ADM_FIN
    BREQ    ADM_FIN

ADM_CORREGIR:
    //Pone el máximo del mes
    MOV     R22, R17
    MOV     R21, R16
    STS     DIA_U, R21
    STS     DIA_D, R22

ADM_FIN:
    RET
; =========================================================
; MODO 0 = reloj normal
; =========================================================
RUT_MODO0:
    LDS     R16, ACTION_FLAGS //Leemos banderas
    SBRS    R16, AF_MINUTO //si ya paso 1 minuto, salta 
    RJMP    M0_BOTONES 

    CBR     R16, (1<<AF_MINUTO) //limpiamos la flag
    STS     ACTION_FLAGS, R16

    RCALL   CARGAR_TIEMPO_FECHA //llamamos a los registros de minutos y horas

    INC     R17
    CPI     R17, 10 //incrementamos la unidad y comparamos con 10
    BRNE    M0_GUARDAR //Si no son iguales, se va a M0 guardar, si son iguales reinicia lau nidad
    CLR     R17

    INC     R18 //Aumenta la hora
    CPI     R18, 6 //Compara y si llega a 60 min reinicia y aumenta la hora
    BRNE    M0_GUARDAR
    CLR     R18

    INC     R19 //Aumenta la unidad de días 
    CPI     R19, 10
    BRNE    M0_REV24 //Si no ha habido overflow revisa que no haya cambio de día
    CLR     R19
    INC     R20

M0_REV24: //Comparar si llego a 24 para regresarlo a 00
    CPI     R20, 2 
    BRNE    M0_GUARDAR
    CPI     R19, 4
    BRNE    M0_GUARDAR
    CLR     R19
    CLR     R20

    PUSH    R17
    PUSH    R18
    PUSH    R19
    PUSH    R20
    RCALL   SUMAR_FECHA
    POP     R20
    POP     R19
    POP     R18
    POP     R17

M0_GUARDAR: //guardamos el tiempo actual en la SRAM
    RCALL   GUARDAR_TIEMPO_FECHA 
    RCALL   REVISAR_ALARMA //Revisamos alarma

M0_BOTONES:
    LDS     R16, ACTION_FLAGS //Revisamos las flags
    SBRC    R16, AF_MAS //Si no esta activo salta a revisar el boton menos
    RJMP    M0_SILENCIO

    SBRS    R16, AF_MENOS//Si no esta activo se va al multiplex
    RJMP    M0_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RCALL   APAGAR_ALARMA //LImpia las flags y apaga la alarma
    RJMP    MULTIPLEX

M0_SILENCIO:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16 //Limpia los flags y manda a la rutina de apagar flags
    RCALL   APAGAR_ALARMA

M0_FIN:
    RJMP    MULTIPLEX

; =========================================================
; MODO 1 = mostrar fecha 
; =========================================================
RUT_MODO1: //Esta rutina solo limpia los flags 
    LDS     R16, ACTION_FLAGS
    CBR     R16, (1<<AF_MAS)|(1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    MULTIPLEX

; =========================================================
; MODO 2 = ajustar minutos
; =========================================================
RUT_MODO2:
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS //Revisa el flag de más 
    RJMP    M2_SUBIR_CHECK

    SBRS    R16, AF_MENOS //Revisa el flag de menos
    RJMP    M2_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16 
    RJMP    M2_BAJAR

M2_SUBIR_CHECK: //Subrutina de flag de mas para aumentar
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M2_SUBIR

M2_FIN:
    RJMP    MULTIPLEX

M2_SUBIR: //Cargamos dsde la RAM el valor de min unidades y decenas, y bajo la misma logica de antes aumentamos decenas y unidades
    LDS     R17, MIN_U
    LDS     R18, MIN_D
    INC     R17
    CPI     R17, 10
    BRNE    M2_GUARDA1
    CLR     R17
    INC     R18
    CPI     R18, 6
    BRNE    M2_GUARDA1
    CLR     R18
M2_GUARDA1: //GUardamos el valor en la RAM
    STS     MIN_U, R17
    STS     MIN_D, R18
    RJMP    MULTIPLEX

M2_BAJAR://Cargamos dsde la RAM el valor de min unidades y decenas, y bajo la misma logica de antes aumentamos decenas y unidades
    LDS     R17, MIN_U
    LDS     R18, MIN_D
    CPI     R17, 0
    BRNE    M2_DEC_UNID
    LDI     R17, 9
    CPI     R18, 0
    BRNE    M2_DEC_DEC
    LDI     R18, 5
    RJMP    M2_GUARDA2
M2_DEC_DEC:
    DEC     R18
    RJMP    M2_GUARDA2
M2_DEC_UNID:
    DEC     R17
M2_GUARDA2:
    STS     MIN_U, R17
    STS     MIN_D, R18
    RJMP    MULTIPLEX

; =========================================================
; MODO 3 = ajustar horas
; =========================================================
RUT_MODO3: //Misma lógica que M2
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS 
    RJMP    M3_SUBIR_CHECK

    SBRS    R16, AF_MENOS
    RJMP    M3_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    M3_BAJAR

M3_SUBIR_CHECK:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M3_SUBIR

M3_FIN:
    RJMP    MULTIPLEX

M3_SUBIR://Aumenta unidades y hasta que haya overflow decenas
    LDS     R17, HOR_U
    LDS     R18, HOR_D
    INC     R17
    CPI     R17, 10
    BRNE    M3_REVINC
    CLR     R17
    INC     R18
M3_REVINC: //Revisa que no haya overflow en la hora
    CPI     R18, 2
    BRNE    M3_GUARDA1
    CPI     R17, 4
    BRNE    M3_GUARDA1
    CLR     R17
    CLR     R18
M3_GUARDA1: //Guarda el valor después de las ubida
    STS     HOR_U, R17
    STS     HOR_D, R18
    RJMP    MULTIPLEX

M3_BAJAR: 
    LDS     R17, HOR_U
    LDS     R18, HOR_D
    CPI     R17, 0
    BRNE    M3_DEC_UNI //Si es distinto a 0, resta normal
    CPI     R18, 0 //Si es 0 revisa la decena
    BRNE    M3_DEC_TENS
	LDI     R18, 2 //Si la hora entera es 00, baja a 23, si no resta a la decena
    LDI     R17, 3 
    
    RJMP    M3_GUARDA2
M3_DEC_TENS: //Si la unidad era 0 y la decena no pone la unidad en 9
    LDI     R17, 9
    DEC     R18
    RJMP    M3_REVDEC
M3_DEC_UNI:
    DEC     R17 //Decrementa la unidad
M3_REVDEC: //Solo revisamos que si esta en 2 la decena no se salte hasta 24
    CPI     R18, 2
    BRNE    M3_GUARDA2
    CPI     R17, 4
    BRLO    M3_GUARDA2
    LDI     R17, 3
M3_GUARDA2: //Guarda el registro en la sram
    STS     HOR_U, R17
    STS     HOR_D, R18
    RJMP    MULTIPLEX

; =========================================================
; MODO 4 = ajustar mes
; =========================================================
RUT_MODO4: //Funciona igual al modo anterior pero con el mes
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS
    RJMP    M4_SUBIR_CHECK

    SBRS    R16, AF_MENOS
    RJMP    M4_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    M4_BAJAR

M4_SUBIR_CHECK:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M4_SUBIR

M4_FIN:
    RJMP    MULTIPLEX

M4_SUBIR:
    LDS     R17, MES_U
    LDS     R18, MES_D
    INC     R17
    CPI     R17, 10
    BRNE    M4_REVINC
    CLR     R17
    INC     R18
M4_REVINC:
    CPI     R18, 1
    BRNE    M4_GUARDA1 //Si llega al 13 se limpia r18 y se queda en enero
    CPI     R17, 3
    BRNE    M4_GUARDA1
    LDI     R17, 1
    CLR     R18
M4_GUARDA1:
    STS     MES_U, R17
    STS     MES_D, R18
    RCALL   AJUSTAR_DIA_SEGUN_MES
    RJMP    MULTIPLEX

M4_BAJAR:
    LDS     R17, MES_U
    LDS     R18, MES_D
    CPI     R18, 0
    BRNE    M4_DEC_UNI10
    CPI     R17, 1 //si es 0 se regresa a 12
    BRNE    M4_DEC_UNI10
    LDI     R17, 2
    LDI     R18, 1
    RJMP    M4_GUARDA2

M4_DEC_UNI10:
    CPI     R17, 0
    BRNE    M4_DEC_UNI
    LDI     R17, 9
    DEC     R18
    RJMP    M4_GUARDA2
M4_DEC_UNI:
    DEC     R17

M4_GUARDA2:
    STS     MES_U, R17
    STS     MES_D, R18
    RCALL   AJUSTAR_DIA_SEGUN_MES
    RJMP    MULTIPLEX

; =========================================================
; MODO 5 = ajustar dia
; =========================================================
RUT_MODO5: //FUNCIONA IGUAL QUE LA RUTINA DE MODO 4
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS
    RJMP    M5_SUBIR_CHECK

    SBRS    R16, AF_MENOS
    RJMP    M5_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    M5_BAJAR

M5_SUBIR_CHECK:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M5_SUBIR

M5_FIN:
    RJMP    MULTIPLEX

M5_SUBIR:
    LDS     R16, DIA_U
    LDS     R17, DIA_D
    LDS     R18, MES_U
    LDS     R19, MES_D

    CPI     R19, 1
    BREQ    M5_1012_INC
    RJMP    M5_0109_INC

M5_1012_INC: //Revisa de los meses del 10 al 12
    CPI     R18, 1
    BRNE    M5_31_INC
    RJMP    M5_30_INC

M5_0109_INC: //Revisa de los meses del 1 al 9
    CPI     R18, 2
    BREQ    M5_28_INC
    CPI     R18, 4
    BREQ    M5_30_INC
    CPI     R18, 6
    BREQ    M5_30_INC
    CPI     R18, 9
    BREQ    M5_30_INC
    RJMP    M5_31_INC

M5_28_INC: //incrementa febrero hasta 28
    INC     R16
    CPI     R16, 10
    BRNE    M528_REV
    CLR     R16
    INC     R17
M528_REV: //revisa que no se pase de 28
    CPI     R17, 2
    BRNE    M5_GUARDA1
    CPI     R16, 9
    BRNE    M5_GUARDA1
    LDI     R16, 1
    CLR     R17
    RJMP    M5_GUARDA1

M5_30_INC: //incrementa hasta 30
    INC     R16
    CPI     R16, 10
    BRNE    M530_REV
    CLR     R16
    INC     R17
M530_REV: //evita que se pase de 30
    CPI     R17, 3
    BRNE    M5_GUARDA1
    CPI     R16, 1
    BRNE    M5_GUARDA1
    LDI     R16, 1
    CLR     R17
    RJMP    M5_GUARDA1

M5_31_INC: //incrementa hasta 31
    INC     R16
    CPI     R16, 10
    BRNE    M531_REV
    CLR     R16
    INC     R17
M531_REV: //evita que se pase de 31
    CPI     R17, 3
    BRNE    M5_GUARDA1
    CPI     R16, 2
    BRNE    M5_GUARDA1
    LDI     R16, 1
    CLR     R17

M5_GUARDA1: //guarda la fehca escogida
    STS     DIA_U, R16
    STS     DIA_D, R17
    STS     MES_U, R18
    STS     MES_D, R19
    RJMP    MULTIPLEX

M5_BAJAR: //baja la fecha
    LDS     R16, DIA_U
    LDS     R17, DIA_D
    LDS     R18, MES_U
    LDS     R19, MES_D

    CPI     R17, 0
    BRNE    M5_DEC_NORMAL
    CPI     R16, 1
    BRNE    M5_DEC_NORMAL

    CPI     R19, 1
    BREQ    M5_1012_DEC
    RJMP    M5_0109_DEC

M5_1012_DEC: //revisa que sea mes entre el 10 y el 12
    CPI     R18, 1
    BRNE    M5_CARGA31
    RJMP    M5_CARGA30

M5_0109_DEC: //revisa que sea entre mes del 1 al 9
    CPI     R18, 2
    BREQ    M5_CARGA28
    CPI     R18, 4
    BREQ    M5_CARGA30
    CPI     R18, 6
    BREQ    M5_CARGA30
    CPI     R18, 9
    BREQ    M5_CARGA30
    RJMP    M5_CARGA31

M5_CARGA28: //Carga el valor de 28
    LDI     R16, 8
    LDI     R17, 2
    RJMP    M5_GUARDA2

M5_CARGA30: //Carga el valor de 30
    LDI     R16, 0
    LDI     R17, 3
    RJMP    M5_GUARDA2

M5_CARGA31: //Carga el valor de 31
    LDI     R16, 1
    LDI     R17, 3
    RJMP    M5_GUARDA2

M5_DEC_NORMAL: //decrementa de 0 a 9
    CPI     R16, 0
    BRNE    M5_DEC_UNI
    LDI     R16, 9
    DEC     R17
    RJMP    M5_GUARDA2
M5_DEC_UNI: //decrementa normal las unidades
    DEC     R16

M5_GUARDA2: //Guarda valor si hubo decremento
    STS     DIA_U, R16
    STS     DIA_D, R17
    STS     MES_U, R18
    STS     MES_D, R19
    RJMP    MULTIPLEX

; =========================================================
; MODO 6 = ajustar min alarma
; =========================================================
RUT_MODO6: //Funciona exactamente igual que los minutos normales
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS
    RJMP    M6_SUBIR_CHECK

    SBRS    R16, AF_MENOS
    RJMP    M6_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    M6_BAJAR

M6_SUBIR_CHECK:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M6_SUBIR

M6_FIN:
    RJMP    MULTIPLEX

M6_SUBIR:
    LDS     R17, ALM_MIN_U
    LDS     R18, ALM_MIN_D
    INC     R17
    CPI     R17, 10
    BRNE    M6_GUARDA1
    CLR     R17
    INC     R18
    CPI     R18, 6
    BRNE    M6_GUARDA1
    CLR     R18
M6_GUARDA1:
    STS     ALM_MIN_U, R17
    STS     ALM_MIN_D, R18
    RJMP    MULTIPLEX

M6_BAJAR:
    LDS     R17, ALM_MIN_U
    LDS     R18, ALM_MIN_D
    CPI     R17, 0
    BRNE    M6_DEC_UNI
    LDI     R17, 9
    CPI     R18, 0
    BRNE    M6_DEC_DEC
    LDI     R18, 5
    RJMP    M6_GUARDA2
M6_DEC_DEC:
    DEC     R18
    RJMP    M6_GUARDA2
M6_DEC_UNI:
    DEC     R17
M6_GUARDA2:
    STS     ALM_MIN_U, R17
    STS     ALM_MIN_D, R18
    RJMP    MULTIPLEX

; =========================================================
; MODO 7 = ajustar hora alarma //Funciona exactamente igual que las horas normales
; =========================================================
RUT_MODO7:
    LDS     R16, ACTION_FLAGS
    SBRC    R16, AF_MAS
    RJMP    M7_SUBIR_CHECK

    SBRS    R16, AF_MENOS
    RJMP    M7_FIN

    CBR     R16, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R16
    RJMP    M7_BAJAR

M7_SUBIR_CHECK:
    CBR     R16, (1<<AF_MAS)
    STS     ACTION_FLAGS, R16
    RJMP    M7_SUBIR

M7_FIN:
    RJMP    MULTIPLEX

M7_SUBIR:
    LDS     R17, ALM_HOR_U
    LDS     R18, ALM_HOR_D
    INC     R17
    CPI     R17, 10
    BRNE    M7_REVINC
    CLR     R17
    INC     R18
M7_REVINC:
    CPI     R18, 2
    BRNE    M7_GUARDA1
    CPI     R17, 4
    BRNE    M7_GUARDA1
    CLR     R17
    CLR     R18
M7_GUARDA1:
    STS     ALM_HOR_U, R17
    STS     ALM_HOR_D, R18
    RJMP    MULTIPLEX

M7_BAJAR:
    LDS     R17, ALM_HOR_U
    LDS     R18, ALM_HOR_D
    CPI     R17, 0
    BRNE    M7_DEC_NORMAL
    CPI     R18, 0
    BRNE    M7_DEC_TENS
    LDI     R17, 3
    LDI     R18, 2
    RJMP    M7_GUARDA2
M7_DEC_TENS:
    LDI     R17, 9
    DEC     R18
    RJMP    M7_REVDEC
M7_DEC_NORMAL:
    DEC     R17
M7_REVDEC:
    CPI     R18, 2
    BRNE    M7_GUARDA2
    CPI     R17, 4
    BRLO    M7_GUARDA2
    LDI     R17, 3
M7_GUARDA2:
    STS     ALM_HOR_U, R17
    STS     ALM_HOR_D, R18
    RJMP    MULTIPLEX

; =========================================================
; MULTIPLEX
; =========================================================
MULTIPLEX:
    LDS     R16, ACTION_FLAGS
    SBRS    R16, AF_REV //Hacemos revision al display
    RJMP    MOSTRAR //Se muestra lo que ya estaba antes

    CBR     R16, (1<<AF_REV) //Se borra el bit de revision
    STS     ACTION_FLAGS, R16 //Se sube a las flags de acciones

    LDS     R16, MODE_FLAGS //Cargamos todas las flags

    SBRC    R16, MF_CLOCK //Muestra la hora siempre que las flags de clock,config min u hora esten encendidas
    RJMP    MUX_HORA
    SBRC    R16, MF_SET_MIN
    RJMP    MUX_HORA
    SBRC    R16, MF_SET_HOR
    RJMP    MUX_HORA

    SBRC    R16, MF_DATE //Muestra la fecha siempre que las flags de fecha,config mes o dia esten encendidas
    RJMP    MUX_FECHA
    SBRC    R16, MF_SET_MES
    RJMP    MUX_FECHA
    SBRC    R16, MF_SET_DIA
    RJMP    MUX_FECHA

    SBRC    R16, MF_SET_AMIN //Muestra la hora de la alarma cuando se este configurando la misma
    RJMP    MUX_ALARMA
    SBRC    R16, MF_SET_AHOR
    RJMP    MUX_ALARMA

    RJMP    MUX_HORA

MUX_HORA:
    LDS     R16, DIG_ACT //Lee el digito en el que hay que multiplexar
    CPI     R16, 0b00001110 //1
    BREQ    MXH_1
    CPI     R16, 0b00001101//2
    BREQ    MXH_2
    CPI     R16, 0b00001011//3
    BREQ    MXH_3
    RJMP    MXH_0 //Si no es ninguno, tiene que ser el 0

MXH_0://Si es el digito 0 sube el valor de el numero a unidades
    LDI     R16, 0b00001110
    LDS     R17, MIN_U
    RJMP    MXH_SAVE
MXH_1://Si es el digito 1 sube el valor del numero a decenas
    LDI     R16, 0b00001101
    LDS     R17, MIN_D
    RJMP    MXH_SAVE
MXH_2://Si es el digito 2 sube el valor del numero a unidades de hora
    LDI     R16, 0b00001011
    LDS     R17, HOR_U
    RJMP    MXH_SAVE
MXH_3://Si es el digito 3 sube el valor del numero a decenas de hora
    LDI     R16, 0b00000111
    LDS     R17, HOR_D

MXH_SAVE://Sube el digito a cambiar 
    STS     DIG_ACT, R16
    STS     VALOR_DIG, R17
    RJMP    MOSTRAR

MUX_FECHA: //Funciona igual que MUX_HORA solo que con la fecha, busca el digito a prender, y luego sube el valor y el display a la ram
    LDS     R16, DIG_ACT
    CPI     R16, 0b00001110
    BREQ    MXF_1
    CPI     R16, 0b00001101
    BREQ    MXF_2
    CPI     R16, 0b00001011
    BREQ    MXF_3
    RJMP    MXF_0

MXF_0:
    LDI     R16, 0b00001110
    LDS     R17, MES_U
    RJMP    MXF_SAVE
MXF_1:
    LDI     R16, 0b00001101
    LDS     R17, MES_D
    RJMP    MXF_SAVE
MXF_2:
    LDI     R16, 0b00001011
    LDS     R17, DIA_U
    RJMP    MXF_SAVE
MXF_3:
    LDI     R16, 0b00000111
    LDS     R17, DIA_D

MXF_SAVE:
    STS     DIG_ACT, R16
    STS     VALOR_DIG, R17
    RJMP    MOSTRAR

MUX_ALARMA: //Funciona igual que MUX_HORA solo que con la hora de la alarma, busca el digito a prender, y luego sube el valor y el display a la ram
    LDS     R16, DIG_ACT
    CPI     R16, 0b00001110
    BREQ    MXA_1
    CPI     R16, 0b00001101
    BREQ    MXA_2
    CPI     R16, 0b00001011
    BREQ    MXA_3
    RJMP    MXA_0

MXA_0:
    LDI     R16, 0b00001110
    LDS     R17, ALM_MIN_U
    RJMP    MXA_SAVE
MXA_1:
    LDI     R16, 0b00001101
    LDS     R17, ALM_MIN_D
    RJMP    MXA_SAVE
MXA_2:
    LDI     R16, 0b00001011
    LDS     R17, ALM_HOR_U
    RJMP    MXA_SAVE
MXA_3:
    LDI     R16, 0b00000111
    LDS     R17, ALM_HOR_D

MXA_SAVE:
    STS     DIG_ACT, R16
    STS     VALOR_DIG, R17
    RJMP    MOSTRAR

; =========================================================
; ISR PB0 / PB1
; =========================================================
ISR_PB:
    PUSH    R16
    IN      R16, SREG
    PUSH    R16
    PUSH    R17
    PUSH    R18
    PUSH    R19

    IN     R16, PINB //Estado fisico de los estados en el pin B

    //PB0 modo
    LDS     R17, BLOQ_MODO
    CPI     R17, 0
    BRNE    PB_REV_CAMBIO //Si el botón esta bloqueado revisa cambio

    SBRC    R16, PB0 //Si el boton no esta presionado revisa el cambio
    RJMP    PB_REV_CAMBIO

    LDS     R18, MODO_ACT //Leemos el modo actual
    CPI     R18, 0
    BREQ    PB_MODO_A_1 //Si el boton esta en el modo inicado salta a la subrutina
    CPI     R18, 1
    BREQ    PB_MODO_A_2
    CPI     R18, 2
    BREQ    PB_MODO_A_4
    CPI     R18, 3
    BREQ    PB_MODO_A_4
    CPI     R18, 4
    BREQ    PB_MODO_A_6
    CPI     R18, 5
    BREQ    PB_MODO_A_6
    CPI     R18, 6
    BREQ    PB_MODO_A_0
    RJMP    PB_MODO_A_0

PB_MODO_A_1: //Esta en el modo 1
    LDI     R18, 1
    RJMP    PB_GUARDA_MODO
PB_MODO_A_2: //esta en el modo 2
    LDI     R18, 2
    RJMP    PB_GUARDA_MODO
PB_MODO_A_4: //esta en el modo 4
    LDI     R18, 4
    RJMP    PB_GUARDA_MODO
PB_MODO_A_6: //esta en el modo 6
    LDI     R18, 6
    RJMP    PB_GUARDA_MODO
PB_MODO_A_0: //esta en el modo 0 
    CLR     R18

PB_GUARDA_MODO:
    STS     MODO_ACT, R18 //guarda el modo actual en la ram 
    RCALL   ACTUALIZAR_MODE_FLAGS //convierte el valor a la flag que se tiene que encender
    LDI     R17, 1
    STS     BLOQ_MODO, R17 //Bloquea el botón para que ya marque otro contacto erroneo
    LDI     R17, ANT_MODO_MAX //Empieza el contador del antirebote
    STS     CNT_MODO, R17 //Sube el valor del tiempo de antirrebote para que el isr_t0 lo controle

PB_REV_CAMBIO:
    //Botón de cambio en modos 2 4 y 6
    LDS     R17, BLOQ_CAMBIO
    CPI     R17, 0
    BRNE    PB_SALIR

    SBRC    R16, PB1
    RJMP    PB_SALIR
	//Lee en el modo en el que nos encontramos
    LDS     R18, MODO_ACT
    CPI     R18, 2
    BREQ    PB_CAMBIO_23
    CPI     R18, 3
    BREQ    PB_CAMBIO_32
    CPI     R18, 4
    BREQ    PB_CAMBIO_45
    CPI     R18, 5
    BREQ    PB_CAMBIO_54
    CPI     R18, 6
    BREQ    PB_CAMBIO_67
    CPI     R18, 7
    BREQ    PB_CAMBIO_76
    RJMP    PB_SALIR

PB_CAMBIO_23: //Cambiar entre el 2 y el 3
    LDI     R18, 3
    RJMP    PB_GUARDA_CAMBIO
PB_CAMBIO_32: //cambiar del 3 al 2
    LDI     R18, 2
    RJMP    PB_GUARDA_CAMBIO
PB_CAMBIO_45: //cambiar del 4 al 5
    LDI     R18, 5
    RJMP    PB_GUARDA_CAMBIO
PB_CAMBIO_54: //cambiar del 5 al 4
    LDI     R18, 4
    RJMP    PB_GUARDA_CAMBIO
PB_CAMBIO_67: //cambiar del 6 al 7
    LDI     R18, 7
    RJMP    PB_GUARDA_CAMBIO
PB_CAMBIO_76://cambiar del 7 al 6
    LDI     R18, 6

PB_GUARDA_CAMBIO:
    STS     MODO_ACT, R18 //sube el valor del modo actual a la ram
    RCALL   ACTUALIZAR_MODE_FLAGS //actualiza las flags y prende el modo en el que estamos
    LDI     R17, 1
    STS     BLOQ_CAMBIO, R17
    LDI     R17, ANT_CAMBIO_MAX
    STS     CNT_CAMBIO, R17 //nuevamente habilita el antirebote

PB_SALIR:
    POP     R19
    POP     R18
    POP     R17
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI

; =========================================================
; ISR PD0 / PD1
; =========================================================
ISR_PD: //Funciona muy similar a  ISR DE PB pero en este caso para sumar y restar
    PUSH    R16
    IN      R16, SREG
    PUSH    R16
    PUSH    R17
    PUSH    R18
    PUSH    R19

    IN      R16, PIND
    ANDI    R16, 0b00000011
    STS     BTN_ESTADO, R16

    //MAS
    LDS     R17, BLOQ_MAS
    CPI     R17, 0
    BRNE    PD_REV_MENOS

    SBRC    R16, 1
    RJMP    PD_REV_MENOS

    LDS     R18, ACTION_FLAGS
    SBR     R18, (1<<AF_MAS)
    STS     ACTION_FLAGS, R18
    LDI     R18, 1
    STS     BLOQ_MAS, R18
    LDI     R18, ANT_MAS_MAX
    STS     CNT_MAS, R18

PD_REV_MENOS:
    //MENOS
    LDS     R17, BLOQ_MENOS
    CPI     R17, 0
    BRNE    PD_FIN

    SBRC    R16, 0
    RJMP    PD_FIN

    LDS     R19, ACTION_FLAGS
    SBR     R19, (1<<AF_MENOS)
    STS     ACTION_FLAGS, R19
    LDI     R19, 1
    STS     BLOQ_MENOS, R19
    LDI     R19, ANT_MENOS_MAX
    STS     CNT_MENOS, R19

PD_FIN:
    POP     R19
    POP     R18
    POP     R17
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI

; =========================================================
; ISR TIMER0
; =========================================================
ISR_T0:
    PUSH    R16
    IN      R16, SREG
    PUSH    R16
    PUSH    R17
    PUSH    R18
    PUSH    R19

    LDI     R16, TMR0_VALUE //Guarda el valor del timer 0 de inicio
    OUT     TCNT0, R16

    LDS     R17, ACTION_FLAGS
    SBR     R17, (1<<AF_REV) //Activa la flag de revision
    STS     ACTION_FLAGS, R17

    //modo
    LDS     R18, BLOQ_MODO
    CPI     R18, 0 //revisa si el boton esta bloqueado por delay
    BREQ    T0_CAMBIO

    IN      R19, PINB
    SBRS    R19, PB0 //Si el botón esta presionado salta a t0 cambio
    RJMP    T0_CAMBIO

    LDS     R18, CNT_MODO //revisamos el contador de antirebote
    CPI     R18, 0
    BREQ    T0_LIB_MODO //si ya esta en 0 lo libera
    DEC     R18 //decrementa el antirebote hasta llegar a 0
    STS     CNT_MODO, R18 
    RJMP    T0_CAMBIO

T0_LIB_MODO:
    CLR     R18
    STS     BLOQ_MODO, R18 //Limpiamos el modo de bloqueo y el boton vuelve a habilitarse

T0_CAMBIO: //Misma lógica que el anterior pero para el botón de cambio
    LDS     R18, BLOQ_CAMBIO
    CPI     R18, 0
    BREQ    T0_MAS

    IN      R19, PINB
    SBRS    R19, PB1
    RJMP    T0_MAS

    LDS     R18, CNT_CAMBIO
    CPI     R18, 0
    BREQ    T0_LIB_CAMBIO
    DEC     R18
    STS     CNT_CAMBIO, R18
    RJMP    T0_MAS

T0_LIB_CAMBIO:
    CLR     R18
    STS     BLOQ_CAMBIO, R18

T0_MAS: //Lo mismo que los botones anteriores, con la diferencia de que si no esta bloqueado revisa menos
    LDS     R18, BLOQ_MAS
    CPI     R18, 0
    BREQ    T0_MENOS

    IN      R19, PIND
    SBRS    R19, PD1
    RJMP    T0_MENOS

    LDS     R18, CNT_MAS
    CPI     R18, 0
    BREQ    T0_LIB_MAS
    DEC     R18
    STS     CNT_MAS, R18
    RJMP    T0_MENOS

T0_LIB_MAS:
    CLR     R18
    STS     BLOQ_MAS, R18

T0_MENOS://misma logica que los botones anteriores
    LDS     R18, BLOQ_MENOS
    CPI     R18, 0
    BREQ    T0_FIN

    IN      R19, PIND
    SBRS    R19, PD0
    RJMP    T0_FIN

    LDS     R18, CNT_MENOS
    CPI     R18, 0
    BREQ    T0_LIB_MENOS
    DEC     R18
    STS     CNT_MENOS, R18
    RJMP    T0_FIN

T0_LIB_MENOS:
    CLR     R18
    STS     BLOQ_MENOS, R18

T0_FIN:
    POP     R19
    POP     R18
    POP     R17
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI

; =========================================================
; ISR TIMER1
; =========================================================
ISR_T1:
    PUSH    R16
    IN      R16, SREG
    PUSH    R16
    PUSH    R17

    LDI     R16, HIGH(TMR1_VALUE) //Subimos la parte alta y baja del timer 1 para que comience a contar desde ahi
    STS     TCNT1H, R16
    LDI     R16, LOW(TMR1_VALUE)
    STS     TCNT1L, R16

    LDI     R17, 0b00000100
    EOR     PUNTO, R17 //Ponemos xor para que haga toggle el punto

    LDS     R16, TICK_05S //cuenta la cantidad de ticks que han pasado que valen 0.5 s
    INC     R16 //incrementamos la cuenta de los ticks
    CPI     R16, 120
    BRNE    T1_GUARDA 

    CLR     R16
    LDS     R17, ACTION_FLAGS
    SBR     R17, (1<<AF_MINUTO)
    STS     ACTION_FLAGS, R17 // si ya pasaron los 120 ticks, activa la flag para cambiar el minuto

T1_GUARDA:
    STS     TICK_05S, R16 //si no, guarda el tick actual

    POP     R17
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI