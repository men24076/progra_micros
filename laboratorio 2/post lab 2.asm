/*
* Lab2.asm
*
* Creado: 10/02
* Autor : Jose Méndez
* Descripción: Programa final 
*/

.include "M328PDEF.inc"    

.dseg
.org    SRAM_START

//guardamos información en el flash memory
.cseg
.org 0x0000
    RJMP    SETUP

//Almacenamos en la flash memory toda la tabla de los digitos de los 7 segmentos
tabla7seg:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71


// Configuración de la pila
SETUP:
    LDI     R17, LOW(RAMEND)
    OUT     SPL, R17
    LDI     R17, HIGH(RAMEND)
    OUT     SPH, R17

/**************/
// Configuracion MCU
    CLI

    //Configuración del clock
    LDI     R17, (1<<CLKPCE)
    STS     CLKPR, R17
    LDI     R17, 0b00000100     // /16
    STS     CLKPR, R17

    //Deshabilitamos el UART
    LDI     R17, 0x00
    STS     UCSR0B, R17

    //DISPLAY: Habilitamos de PC0 a PC5 como salidas en el puerto C y los apagamos
    LDI     R17, 0b0011_1111
    OUT     DDRC, R17
    CLR     R17
    OUT     PORTC, R17
	//Habilitamos PB0 como salida
    SBI     DDRB, DDB0        
    CBI     PORTB, PB0
	  //LEDS contador de segundos en PD2-PD5 y LED alarma en PD6
    LDI     R17, 0b01111100
    OUT     DDRD, R17
    CLR     R17
    OUT     PORTD, R17


    //Pull up para Pb1 y Pb2 que serían los push bottons
    SBI     PORTB, PB1
    SBI     PORTB, PB2

  
    //Inicializaciones en 0
    CLR     R20                
    CLR     R25                
    CLR     R26                 
    CLR     R24                 

    //Mostrar estado inicial
    RCALL   mostrar_display //llamamos a mostrar display en 0
    RCALL   actualizar_leds // ponemos r25 en pd2-pd5
    CBI     PORTD, PD6         //Apagamos alarma

   //
    LDI     R17, 0b0000_0010 //Subimos el valor para habilitar CTC
    OUT     TCCR0A, R17 //Habilitamos el CTC que es de comparacion
    LDI     R17, 0b0000_0101//Máscara para leer los bits 2 y 0 que hacen 1024.
    OUT     TCCR0B, R17 //1024
    LDI     R17, 97
    OUT     OCR0A, R17 //Subimos 97 al output compare register, y como el incremento es cada 1 ms aprox contara en 100ms.
    CLR     R17
    OUT     TCNT0, R17 //reiniciamos el timer

    // Escribimos 1 en TIFR0 Para limpiar los flags
    LDI     R17, 0b0000_0010
    OUT     TIFR0, R17



MAIN_LOOP:
    RCALL   revisar_timer

 boton_1:
    SBIC    PINB, PB1 //Salta si el pin B1 esta presionado
    RJMP    boton_2 //Revisa el boton 2
    RCALL   antirebote_1 //delay
    RCALL   incrementar //revisa post delay
    RCALL   mostrar_display //muestra resultado

boton_2:
  
    SBIC    PINB, PB2 //salta si el pin B2 esta presionado
    RJMP    MAIN_LOOP
    RCALL   antirebote_2 
    RCALL   decrementar //revisa post delay
    RCALL   mostrar_display //muestra resultado
    RJMP    MAIN_LOOP

//subrutinas

revisar_timer:
    IN      R17, TIFR0 //leemos el valor del timer en r17
    SBRS    R17, OCF0A //si la flag no esta activada sigue leyendo
    RET

    LDI     R17, 0b0000_0010 //Limpiamos el output compare flag A al ponerlo en 1
    OUT     TIFR0, R17

    //cuenta hasta 1 segundo
    INC     R26
    CPI     R26, 10
    BRLO    fin_timer //salta a fin timer mientras r26 no cuente 1 segundo
    CLR     R26 //limpiamos r26

    //cuenta hasta 15 segundos
    INC     R25
    ANDI    R25, 0x0F //Se encarga de que lea los segundos en solo los primeros 4 bits (0 a 15)
    RCALL   actualizar_leds

    //Compara los segundos con el valor guardado en los botones
    CP      R25, R20
    BRNE    fin_timer

    CLR     R25
    RCALL   actualizar_leds //actualiza el valor en los leds

    // Invierte el valor de la alarma utilizando xor al pasar el ciclo
    IN      R17, PORTD
    LDI     R18, (1<<PD6)
    EOR     R17, R18
    OUT     PORTD, R17

fin_timer:
    RET
//suma y resta de 0 a 15
incrementar:
    INC     R20
    ANDI    R20, 0x0F
    RET

decrementar:
    DEC     R20
    ANDI    R20, 0x0F
    RET

mostrar_display:
//alacenamos en z low y high los valores de la tabla de 7 segmentos
    LDI     ZH, HIGH(tabla7seg<<1)
    LDI     ZL, LOW(tabla7seg<<1)
    ADD     ZL, R20 //le sumamos r20 que es el registro de inc/dec a la parte baja del tablero
    ADC     ZH, R24 //Se suma solamente si huno carry y empieza en 0
    LPM     R21, Z //Lee el byte de z en r21.

    // Lee el valor obtenido en Z y lo saca a los bits 0 a 5 del port c.
    MOV     R22, R21
    ANDI    R22, 0b0011_1111
    OUT     PORTC, R22

    // el 6to bit esta en el puerto 0
    CBI     PORTB, PB0
    SBRC    R21, 6 // si el bit 6 de r21 esta apagado aun sigue apagado
    SBI     PORTB, PB0 //Prende si r21 esta activado
    RET


actualizar_leds:
    IN      R17, PORTD
    ANDI    R17, 0b11000011     //borramos de pd2 a pd5
    MOV     R18, R25
    LSL     R18 //movemos los bits a la izquierda 2 veces para comenzar en pd2
    LSL     R18
    ANDI    R18, 0b00111100 //ahora si mantenemos solamente los leds
    OR      R17, R18 //enciende los leds que tengan 1 comparandolos con el inicio
    OUT     PORTD, R17 //saca el valor al puerto D para encender los LEDS.
    RET

// Anti-rebote boton 1
antirebote_1:
    RCALL   delay
    SBIC    PINB, PB1
    RET
esperar_1:
    SBIS    PINB, PB1
    RJMP    esperar_1
    RCALL   delay
    RET

// Anti-rebote boton 2
antirebote_2:
    RCALL   delay
    SBIC    PINB, PB2
    RET
esperar_2:
    SBIS    PINB, PB2
    RJMP    esperar_2
    RCALL   delay
    RET

/**************/
//Delay
delay:
    LDI     R22, 80
DEL0:
    LDI     R23, 250
DEL1:
    DEC     R23
    BRNE    DEL1
    DEC     R22
    BRNE    DEL0
    RET