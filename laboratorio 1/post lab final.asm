;
; AssemblerApplication18.asm
;
; Created: 10/02/2026 09:37:11
; Author : joe05
;
//Post Lab Jose Méndez
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x0000
// --------------------------------------- //
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
// Configuracion MCU
// --------------------------------------- //
SETUP:
	//se quita usart del pin D0 y D1
	LDI r16, 0x00							
	STS UCSR0B, r16

// ENTRADAS + PULL-UPS
//Volvemos d4 a d7 entradas y se habilitan pull ups con set bit in

SBI PORTD, PORTD4
SBI PORTD, PORTD5
SBI PORTD, PORTD6
SBI PORTD, PORTD7

//Boton de suma y su pull up
SBI PORTC, PORTC5

//salidas
// d0 a d3 son los pines del contador 1
SBI DDRD, DDD0
SBI DDRD, DDD1
SBI DDRD, DDD2
SBI DDRD, DDD3

//clear bit in para que comience apagado
CBI PORTD, PORTD0
CBI PORTD, PORTD1
CBI PORTD, PORTD2
CBI PORTD, PORTD3

//contador 2 de c0 a c3
SBI DDRC, DDC0
SBI DDRC, DDC1
SBI DDRC, DDC2
SBI DDRC, DDC3

//Clear bit in para que comience apagado
CBI PORTC, PORTC0
CBI PORTC, PORTC1
CBI PORTC, PORTC2
CBI PORTC, PORTC3

//LED del overflow
SBI DDRC, DDC4
CBI PORTC, PORTC4

// sumador en b0 a b3 
SBI DDRB, DDB0
SBI DDRB, DDB1
SBI DDRB, DDB2
SBI DDRB, DDB3

//clear bit in para que comiencen apagados
CBI PORTB, PORTB0
CBI PORTB, PORTB1
CBI PORTB, PORTB2
CBI PORTB, PORTB3


//seteamos el prescaler
//Basicamente el clkpce se pone en 1 para cambiar el prescaler, 
//y el clkpr recibe el valor de 16 para dividrlo y pasarlo a 1Mhz
LDI R16, (1<<CLKPCE) 
STS CLKPR, R16
LDI R16, 0b00000100      ; /16
STS CLKPR, R16

//Registros limpios que se utilizan para incremento o decremento
CLR R20      
CLR R22     
CLR R24      
	
//Programa
MAIN_LOOP:
    CALL CONTADOR_1        //ejecuta rutina del contador 1
    CALL CONTADOR_2        //ejecuta rutina del contador 2
    CALL SUMADOR           //ejecuta rutina del sumador
    RJMP MAIN_LOOP         //repite indefinidamente
    

//CONTADOR 1
CONTADOR_1:
IN  R18, PIND              //lee el estado actual del puerto D
SBRC R18, 5                //si PD5=1 (al tener logica inversa) salta la siguiente
RJMP REVISAR_SUMA_1        //si no hay resta, revisar suma
CALL RESTAR_C1             //si PD5=0 ejecuta resta

REVISAR_SUMA_1:
SBRC R18, 4                //si PD4=1 (al tener logica inversa) salta la siguiente
RJMP MOSTRAR_C1            //si no hay suma, solo muestra
CALL SUMAR_C1              //si PD4=0 ejecuta suma

MOSTRAR_C1:
MOV R21, R20               //copia valor del contador 1 anterior
ANDI R21, 0x0F             //mascara de 4 bits
IN R18, PORTD              //lee el puerto actual
ANDI R18, 0b11110000       //conserva los bits altos
OR   R18, R21              //coloca el contador en bits bajos
OUT PORTD, R18             //envía valor a LEDs
RET                        //regresa


//CONTADOR 2 (sigue la misma logica que el contador 1)
CONTADOR_2:
IN R18, PIND               
SBRC R18, 6                
RJMP REVISAR_SUMA_2        
CALL RESTAR_C2             

REVISAR_SUMA_2:
SBRC R18, 7                
RJMP MOSTRAR_C2            
CALL SUMAR_C2              

MOSTRAR_C2:
MOV R21, R22               
ANDI R21, 0x0F             
IN  R18, PORTC             
ANDI R18, 0b11110000       
OR   R18, R21              
OUT PORTC, R18             
RET                       


//SUMADOR
SUMADOR:
IN R19, PINC               //lee boton de suma
SBRC R19, 5                //si no presionado regresa al main loop
RET

LDI R26, 1                 //carga valor para delay
CALL DELAY                 //antirebote

IN R19, PINC               //lee nuevamente
SBRC R19, 5                //si no sigue presionado regresa al main loop
RET

MOV R24, R20               //copia contador 1 para realizar la operacion
ADD R24, R22               //suma contador 2

MOV R25, R24               //copia para verificar overflow
ANDI R25, 0xF0             //extrae bits altos
CPI R25, 0x00              //compara
BREQ SIN_OVERFLOW          //branch if equal por si es 0 no hay overflow

SBI PORTC, 4               //enciende LED overflow
RJMP MOSTRAR_SUMA          //regresa a muestra de suma

SIN_OVERFLOW:
CBI PORTC, 4               //apaga LED overflow

MOSTRAR_SUMA:
MOV R21, R24               //copia resultado
ANDI R21, 0x0F             //limita a 4 bits
OUT PORTB, R21             //muestra resultado
RET                        //regresa


//DELAY
DELAY:
CLR R27                    //pone contador interno en 0
BUCLE:
INC R27                    
CPI R27, 0               
BRNE BUCLE                 
DEC R26                   
BRNE BUCLE                
RET                        


//RESTAR C1 
RESTAR_C1:
LDI R26, 1                 //prepara delay
CALL DELAY                 //antirebote
IN R19, PIND               //verifica boton
SBRC R19, 5                //skip if bit register cleared, entonces si esta presionado continua si no, regresa
RET
DEC R20                    //decrementa contador 1
ANDI R20, 0x0F             //limita a 4 bits
ESPERA_DEC1:
IN R19, PIND               //espera soltar boton
SBRC R19, 5
RET
RJMP ESPERA_DEC1


//SUMAR C1  //misma logica solo que con suma
SUMAR_C1:
LDI R26, 1
CALL DELAY
IN R19, PIND
SBRC R19, 4
RET
INC R20                   
ANDI R20, 0x0F
ESPERA_INC1:
IN R19, PIND
SBRC R19, 4
RET
RJMP ESPERA_INC1


// RESTAR C2 //misma logica para contador 2 y suma del contador 2
RESTAR_C2:
LDI R26, 1
CALL DELAY
IN R19, PIND
SBRC R19, 6
RET
DEC R22                    
ANDI R22, 0x0F
ESPERA_DEC2:
IN R19, PIND
SBRC R19, 6
RET
RJMP ESPERA_DEC2


//SUMAR C2
SUMAR_C2:
LDI R26, 1
CALL DELAY
IN R19, PIND
SBRC R19, 7
RET
INC R22                    
ANDI R22, 0x0F
ESPERA_INC2:
IN R19, PIND
SBRC R19, 7
RET
RJMP ESPERA_INC2
