#ifndef ADC_H_
#define ADC_H_

// /*
//  * adc.h
//  *
//  * Created: 21/04/26
//  * Author: Jose Méndez
//  * Description: Archivo para configurar el adc en tipo h.
#include <stdint.h>

void ADC_init(void);
uint16_t ADC_read(uint8_t channel); //leemos el canal analogico

#endif