    EXTERN USART_INIT
    EXTERN USART_TX_BLOCKING
    EXTERN USART_RX_DO
    EXTERN USART_RX_BYTE
    EXTERN USART_GET

    EXTERN USART_BUFFER
    EXTERN USART_BUFFER_HEAD
    EXTERN USART_BUFFER_TAIL
    
;*******************************************************************************
;    MACROS                                                                    *
;*******************************************************************************

; send a literal character in blocking mode
usart_tx_blocking macro char	    
    movlw	char
    call	USART_TX_BLOCKING
    endm  

; send W value in blocking mode
usart_tx_w_blocking macro
    call	USART_TX_BLOCKING
    endm
	
; initialize USART
usart_init macro
    call	USART_INIT
    endm

; do state machine
usart_do macro
    call	USART_RX_DO
    endm

; check rx buffer, skip if there are data to read (with usart_get_buffer)    
usart_skip_if_buffer_not_empty macro
    banksel USART_BUFFER
    movf    USART_BUFFER_HEAD, w
    subwf   USART_BUFFER_TAIL, w
    btfsc   STATUS, Z		    ; head == tail ?
    endm
    
; get byte from buffer and update buffer head.
; byte readed will be available in USART_RX_BYTE
; NOTE: use usart_skip_if_buffer_not_empty, because this function does not check for empty buffer!
usart_get_buffer macro
    call	USART_GET
    endm
    
usart_get macro
    call	USART_RX
    endm