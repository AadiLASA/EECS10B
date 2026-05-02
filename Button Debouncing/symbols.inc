;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 symbols.inc                                ;
;                           Symbol & Hardware Defs                           ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file defines symbolic constants and hardware-specific
;                   configurations for the 5x8 sensor matrix. It includes port
;                   definitions, debounce timing, and state machine states.
;
; Input:            None.
; Output:           None.
;
; User Interface:   None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    4/28/26   Aaditya Bhat              added debounce constants and state machine states
;    5/02/26   Aaditya Bhat              added comments/documentation

;Hardware Port Definitions: 5x8 Matrix. Rows are outputs, Columns are inputs.
.equ ROW_PORT = PORTG           ; Port to drive rows HIGH/LOW
.equ ROW_DDR  = DDRG            ; Data direction register for rows
.equ COL_PORT = PORTE           ; Port to enable pull-ups for columns
.equ COL_DDR  = DDRE            ; Data direction register for columns
.equ COL_PIN  = PINE            ; Port to read the actual column states

;Debouncing Constants
; The timer ISR runs every 1ms. We need 20 consecutive milliseconds of the 
; same switch state to consider it fully debounced.
.equ DEBOUNCE_TIME = 20         

;State Machine States
.equ STATE_IDLE         = 0     ; Waiting for a new key press
.equ STATE_DEBOUNCE     = 1     ; Key detected, currently verifying duration
.equ STATE_WAIT_RELEASE = 2     ; Key confirmed, waiting for physical release
