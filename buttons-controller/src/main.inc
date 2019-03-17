;*******************************************************************************
;    GLOBAL CONFIGURATION                                                      *
;*******************************************************************************
#ifndef GLOBAL_INC
    
    #define TXRX_TX_BUFFER_SIZE   d'32'
    #define TXRX_RX_BUFFER_SIZE   d'16'

    #define BUTTONS_BANKS 16
    
    #define USE_I2C
    ; TX by interrupt (no lag)
    #define TXRX_ISR

    ; 20MHz external oscillator
    #define EXTERNAL_CLOCK
    
    ; B6, B7 disabled
    ;#define PROGRAMMER

    ; Global flags mapping, don't change
    #define GLOBAL_FLAG_NOTEOFF_VELOCITY 7
    #define GLOBAL_FLAG_PIN		 6

#define GLOBAL_INC
#endif

