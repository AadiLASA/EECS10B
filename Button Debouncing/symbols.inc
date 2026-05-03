;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 symbols.inc                                ;
;                           Symbol & Hardware Defs                           ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file defines constants and hardware-specific
;                   configs for the 5x8 sensor matrix. It includes port
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

;Hardware Initialization Constants
.equ ROW_DIR_INIT   = $1F       ; Lower 5 pins output (0001 1111) for 5 rows
.equ COL_DIR_INIT   = $00       ; All 8 pins input
.equ COL_PULLUP_EN  = $FF       ; Enable internal pull-ups on all columns

;Timer 0 Constants
.equ T0_COMP_MATCH  = $7C       ; 124 count for 1ms interrupt (with prescaler 64)

;Matrix Scanning Constants
.equ ROW_0_ACTIVE   = $FE       ; Row 0 active LOW (1111 1110)
.equ INITIAL_BASEID = 0         ; Starting ID for the top-left sensor
.equ NO_KEY_PRESSED = $FF       ; 0xFF indicates an empty scan/no active key
.equ COLS_PER_ROW   = 8         ; Number of columns per row
.equ TOTAL_SENSORS  = 40        ; Total matrix size (5 rows * 8 cols)
.equ FLAG_CLEARED   = 0         ; Used to clear flags and counters
