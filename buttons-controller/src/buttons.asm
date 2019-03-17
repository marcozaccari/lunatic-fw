#include <p16f886.inc>
#include "main.inc"
#include "lib/misc.inc"
#include "lib/txrx.inc"

    GLOBAL  BUTTONS_INIT
    GLOBAL  BUTTONS_SCAN
    
    EXTERN  GLOBAL_FLAGS
    
;*******************************************************************************
; KA4  KA3   
;  0    0   First buttons bank (1..64 buttons)
;  0    1   Second buttons bank (65..128 buttons)
;  1    0   First leds bank (1..64 leds)
;  1    1   Second leds bank (65..128 leds)
;
; KA2  KA1  KA0
;  0    0    0    1..8   buttons/leds
;  0    0    1    9..16  buttons/leds
;  0    1    0    17..24 buttons/leds
;  0    1    1    25..32 buttons/leds
;  1    0    0    33..40 buttons/leds
;  1    0    1    41..48 buttons/leds
;  1    1    0    49..56 buttons/leds
;  1    1    1    57..64 buttons/leds
;   
;
; Flusso logico:
;
; - Leggi interruttore #1 (con antibounce)
;     - E' stato attivato ora?
;         - SI: resetta il suo contatore
;
; - Leggi tasto interruttore #2 (con antibounce)
;     - E' stato attivato ora?
;         - NO: incrementa il suo contatore
;         - SI: salva il contatore e notifica alla seriale
;     - E' stato rilasciato ora?
;         - SI: notifica alla seriale   
;*******************************************************************************
    
    
;*******************************************************************************
;    VARIABLES                                                                 *
;*******************************************************************************

#define	    BUTTONS_DEBOUNCE_SCAN_CYCLES	8
    
GRP_BUTTONS_SHR		UDATA_SHR
; indices
BUTTONS_CURBANK		RES 1	; bank index (0..BUTTONS_BANKS)
BUTTONS_CURBANK_COUNTER	RES 1	; bank counter index (BUTTONS_BANKS..1)
BUTTONS_CURBANK_ABS	RES 1	; bank absolute index (0, 8, 16, 24, 32, 48, 56)
CUR_BUTTON 		RES 1
BUTTONS_CURBITS_ON	RES 1	; current status of 8 keys (0 -> 1 variations)	
BUTTONS_CURBITS_OFF	RES 1	; current status of 8 keys (1 -> 0 variations)
BUTTONS_CURBITS		RES 1	; current status of !PORTB	
    
GRP_BUTTONS_BUFFERS	UDATA
; port status (previous and current)		
BUTTONS_BITS		RES BUTTONS_BANKS   ; raw bits status (by BUTTONS_SCAN_BITS)
BUTTONS_BITS_OLD	RES BUTTONS_BANKS
    
;*******************************************************************************
;    SUBROUTINES                                                               *
;*******************************************************************************
BUTTONS CODE

;*******************************************
; Initialize ports and arrays 
BUTTONS_INIT
    ; init ports
    banksel ANSEL
    clrf    ANSEL		; digital I/O (PORTA)
    clrf    ANSELH		; digital I/O (PORTB)
    banksel TRISA
    clrf    TRISA		; PortA as output
    
    movlw   0xFF
    movwf   TRISB               ; PortB as input
    
    banksel OPTION_REG
    bcf	    OPTION_REG, NOT_RBPU ; Enable single pullups on PORT B
    banksel WPUB
    movwf   WPUB		; Enable all pull-up for PORT B

    clrf    PORTA               ; clear output data latches on Ports
    
    ; flush arrays
    movlw   BUTTONS_BANKS
    movwf   CUR_BUTTON
    movwf   TEMP2	    ; CUR_BUTTON-1
    clrf    TEMP1
ButtonsInitFlushBits:    
    decf    TEMP2
    set_array BUTTONS_BITS_OLD, TEMP2, TEMP3

    decfsz  CUR_BUTTON
    goto    ButtonsInitFlushBits
    return

    
;*******************************************
; Scan buttons state   
BUTTONS_SCAN

    ; scan buttons bits
    call    BUTTONS_SCAN_BITS
    
    ; prepare bank counter
    movlw   BUTTONS_BANKS
    movwf   BUTTONS_CURBANK_COUNTER
    clrf    BUTTONS_CURBANK
    clrf    BUTTONS_CURBANK_ABS

ButtonsScanSwitchOnBank:    

    get_array BUTTONS_BITS, BUTTONS_CURBANK
    movwf   BUTTONS_CURBITS
    movwf   TEMP1

    get_array BUTTONS_BITS_OLD, BUTTONS_CURBANK
    movwf   TEMP3

    xorwf   TEMP1	    ; TEMP1 = CURBITS XOR BITS_OLD (all variations)

    movf    BUTTONS_CURBITS, w
    andwf   TEMP1, w	    ; W = TEMP1 AND CURBITS (0->1 variations)
    movwf   BUTTONS_CURBITS_ON

    movf    TEMP3, w
    andwf   TEMP1, w		; W = TEMP1 AND BITS_OLD (1->0 variations)
    movwf   BUTTONS_CURBITS_OFF

    ; save bits status
    set_array BUTTONS_BITS_OLD, BUTTONS_CURBANK, BUTTONS_CURBITS

    clrf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 0
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 0
    call    BUTTON_SET_OFF
    
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 1
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 1
    call    BUTTON_SET_OFF

    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 2
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 2
    call    BUTTON_SET_OFF
 
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 3
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 3
    call    BUTTON_SET_OFF
 
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 4
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 4
    call    BUTTON_SET_OFF
 
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 5
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 5
    call    BUTTON_SET_OFF
 
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 6
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 6
    call    BUTTON_SET_OFF
 
    incf    CUR_BUTTON
    btfsc   BUTTONS_CURBITS_ON, 7
    call    BUTTON_SET_ON
    btfsc   BUTTONS_CURBITS_OFF, 7
    call    BUTTON_SET_OFF
    
    movlw   8
    addwf   BUTTONS_CURBANK_ABS
    
    incf    BUTTONS_CURBANK
    decfsz  BUTTONS_CURBANK_COUNTER
    goto    ButtonsScanSwitchOnBank
    return
    
 
;*******************************************
; Set single button to ON   
; uses CUR_BUTTON, BUTTONS_CURBANK_ABS
BUTTON_SET_ON
    movf    CUR_BUTTON, w
    addwf   BUTTONS_CURBANK_ABS, w	    ; w = absolute key index

    iorlw   b'10000000'		    ; key = 1XXXXXXX
    txrx_tx_w
    led_tx_on
    return

    
;*******************************************
; Set single button to OFF  
; uses CUR_BUTTON, BUTTONS_CURBANK_ABS
BUTTON_SET_OFF
    movf    CUR_BUTTON, w
    addwf   BUTTONS_CURBANK_ABS, w	    ; w = absolute key index
    
    txrx_tx_w
    ;led_tx_on
    return

    
;*******************************************
; Scan buttons bits (repeat for antibounce)   
;
BUTTONS_SCAN_BITS
    ; prepare indirect address
    movlw   BUTTONS_BITS
    movwf   FSR
    bankisel BUTTONS_BITS

    ; prepare bank counter
    movlw   BUTTONS_BANKS
    movwf   BUTTONS_CURBANK_COUNTER
    clrf    BUTTONS_CURBANK

ButtonsScanBitsBank:

    ; output address to PORTA
    movf    BUTTONS_CURBANK, w
    banksel PORTA
    movwf   PORTA

    ; wait 2us in order to discarge the pull-ups
    nop
    nop
    nop
    nop
    nop

    nop
    nop
    nop
    nop
    nop
    
    ; get keys status by PORTB
    comf    PORTB, w	    ; not

    #ifdef PROGRAMMER
	movwf	TEMP1
	movlw	b'00111111'
	andwf	TEMP1, w    ; remove upper 2 bits (used by programmer)
    #endif
    
;movwf TEMP1
;movf  TEMP1
;btfsc STATUS, Z
;goto ZZ
;movf TEMP1, w    
;txrx_tx_w_blocking    
;ZZ

;movf BUTTONS_CURBANK, w
;txrx_tx_w_blocking    
;delay_5dec    

    ; save bits status
    movwf   INDF
    
    incf    FSR		    ; next BUTTONS_BITS offset
    
    incf    BUTTONS_CURBANK
    decfsz  BUTTONS_CURBANK_COUNTER
    goto    ButtonsScanBitsBank

    ; Start debouncing
    #if BUTTONS_DEBOUNCE_SCAN_CYCLES == 0
	return
    #endif
    
    movlw   BUTTONS_DEBOUNCE_SCAN_CYCLES
    movf    TEMP2

ButtonsScanBitsDebounce:

    ; prepare indirect address
    movlw   BUTTONS_BITS
    movwf   FSR

    ; prepare bank counter
    movlw   BUTTONS_BANKS
    movwf   BUTTONS_CURBANK_COUNTER
    clrf    BUTTONS_CURBANK
    
ButtonsScanBitsBankDebounce:

    ; output address to PORTA
    movf    BUTTONS_CURBANK, w
    banksel PORTA
    movwf   PORTA

    ; get keys status by PORTB
    comf    PORTB, w	    ; not

    #ifdef PROGRAMMER
	movwf	TEMP1
	movlw	b'00111111'
	andwf	TEMP1, w    ; remove upper 2 bits (used by programmer)
    #endif

    ; save bits status (OR)
    iorwf   INDF
    
    incf    FSR		    ; next BUTTONS_BITS offset

    incf    BUTTONS_CURBANK
    decfsz  BUTTONS_CURBANK_COUNTER
    goto    ButtonsScanBitsBankDebounce

    decfsz  TEMP2
    goto    ButtonsScanBitsDebounce

    return

    END