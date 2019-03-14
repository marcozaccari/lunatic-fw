#include <p16f886.inc>
#include "main.inc"
#include "misc.inc"  

    GLOBAL USART_INIT
    GLOBAL USART_TX_BLOCKING
    GLOBAL USART_RX_DO
    GLOBAL USART_RX_BYTE
    GLOBAL USART_GET
    
    GLOBAL USART_BUFFER
    GLOBAL USART_BUFFER_HEAD
    GLOBAL USART_BUFFER_TAIL
    
	    
;*******************************************************************************
;    VARIABLES                                                                 *
;*******************************************************************************
    
#define USART_BUFFER_SIZE   d'64'
GRP_USART   UDATA
USART_BUFFER	    RES USART_BUFFER_SIZE
USART_BUFFER_HEAD   RES 1
USART_BUFFER_TAIL   RES 1
USART_W_TEMP	    RES 1
USART_TEMP	    RES 1
USART_RX_BYTE	    RES 1	    

	    
;*******************************************************************************
;    MACROS                                                                    *
;*******************************************************************************

usart_inc_head macro
     ; increment head
    banksel USART_BUFFER
    incf    USART_BUFFER_HEAD

    movlw   USART_BUFFER_SIZE
    subwf   USART_BUFFER_HEAD, w
    btfsc   STATUS, Z		    ; head == buffer_size ?
    clrf    USART_BUFFER_HEAD      
    endm	    
	
;*******************************************************************************
;    SUBROUTINES                                                               *
;*******************************************************************************
USART CODE
	
; Initialize USART
USART_INIT
    ; init port
    banksel TRISC
    clrf    TRISC               ; PortC as output
    bsf	    TRISC, TRISC7       ; RC7 as RX input
    clrf    PORTC		; clear output data latches on port
    
    ; Set baud rate
    #ifdef EXTERNAL_CLOCK
	; 116.300 baud rate @ 20MHz
	#define SPBRGH_VALUE 0
	#define SPBRG_VALUE d'42'
	#define BRGH_SET bsf	; high speed
	#define BRG16_SET bsf	; 16bit baud generator
    #else
	; 19.230 baud rate @ 8MHz
	#define SPBRGH_VALUE 0
	#define SPBRG_VALUE d'25'
	#define BRGH_SET bcf	; low speed
	#define BRG16_SET bsf	; 16bit baud generator
    #endif

    banksel SPBRGH
    movlw   SPBRGH_VALUE
    movwf   SPBRGH
    ;banksel SPBRGL
    movlw   SPBRG_VALUE
    movwf   SPBRG
    ;banksel TXSTA
    BRGH_SET TXSTA, BRGH
    banksel BAUDCTL
    BRG16_SET BAUDCTL, BRG16

    ; configure and enable the port
    banksel TXSTA
    bcf	    TXSTA, SYNC		; enable async mode
    bsf	    TXSTA, TXEN		; enable transmission
    banksel RCSTA
    bsf	    RCSTA, CREN		; enable receive
    bsf	    RCSTA, SPEN		; enable serial port
  
    ; init buffer vars
    banksel USART_BUFFER
    clrf    USART_BUFFER_HEAD
    clrf    USART_BUFFER_TAIL
    return

    
; add w to buffer
USART_ADD_BUFFER
    ; set buffer[tail] value
    banksel USART_W_TEMP
    movwf   USART_W_TEMP

    set_array USART_BUFFER, USART_BUFFER_TAIL, USART_W_TEMP
    ;movlw   USART_BUFFER
    ;movwf   FSR
    ;movf    USART_BUFFER_TAIL, w
    ;addwf   FSR
    ;movf    USART_W_TEMP, w
    ;movwf   INDF
    
    ; increment tail
    incf    USART_BUFFER_TAIL

    movlw   USART_BUFFER_SIZE
    subwf   USART_BUFFER_TAIL, w
    btfsc   STATUS, Z		    ; tail == buffer_size ?
    clrf    USART_BUFFER_TAIL  
    return

USART_GET
    ; if head == tail then return
    ;banksel USART_BUFFER
    ;movf    USART_BUFFER_HEAD, w
    ;subwf   USART_BUFFER_TAIL, w
    ;btfsc   STATUS, Z		    ; head == tail ?
    ;return
    
    ; get buffer[head] value
    banksel USART_BUFFER
    get_array USART_BUFFER, USART_BUFFER_HEAD
    
    movwf   USART_RX_BYTE
    ;movlw   USART_BUFFER
    ;movwf   FSR
    ;movf    USART_BUFFER_HEAD, w
    ;addwf   FSR
    ;movf    INDF, w
    
    ; send char to port
    ;banksel TXREG
    ;movwf   TXREG    

    usart_inc_head    
    return
  
; Send character stored to W to USART
USART_TX_BLOCKING  
    banksel TXREG
    movwf   TXREG
    nop
    banksel PIR1
    btfss   PIR1, TXIF		; txreg is empty?
    goto    $-1			; (0 = no) goto prev instruction
    return

USART_RX_DO
    banksel PIR1
    btfss   PIR1, RCIF
    return
    
    btfsc   RCSTA, OERR		; if overrun error occurred
    goto    ErrSerialOverr	; then go handle error
    btfsc   RCSTA, FERR		; if framing error occurred
    goto    ErrSerialFrame	; then go handle error
    
    movf    RCREG, w		; received byte
    call    USART_ADD_BUFFER
    return
    
ErrSerialOverr:
    bcf	    RCSTA, CREN		; reset the receiver logic
    bsf	    RCSTA, CREN		; enable reception again
    call    USART_ADD_BUFFER
    return
    
ErrSerialFrame:	
    movf    RCREG, w		; discard received data that has error
    call    USART_ADD_BUFFER
    return
    
    END