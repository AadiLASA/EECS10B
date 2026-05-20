;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file contains the constants and variable definitions
;                   for Homework #3. It includes system constants, I/O
;                   initialization constants, and SRAM allocations.
;
; Input:            None.
; Output:           None.
;
; User Interface:   None.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    5/16/26  Aaditya Bhat               initial revision
;    5/18/26  Aaditya Bhat               updated comments

;System Constants
.equ NUM_DIGITS         = 16    ; total 7-segment digits
.equ NUM_LIGHTS         = 128   ; total individual LEDs
.equ LIGHT_BYTES        = 16    ; NUM_LIGHTS / 8 bits per byte
.equ PLAYER_MIN         = 1     ; lowest valid player number
.equ PLAYER_MAX         = 4     ; highest valid player number

;IO Initialization Constants
.equ ALL_OUTPUTS        = 0xFF  ; ddr mask for all outputs
.equ ALL_OFF            = 0x00  ; port state for turning everything off

;Multiplexer State Boundaries
.equ STATE_BOT_START    = 8     ; state where bottom digits begin
.equ STATE_MAX          = 16    ; state where top digits begin

;Port A Hardware Enable Masks
.equ ENABLE_TOP_DIGITS  = 0x08  ; PA3 turns on top digits
.equ ENABLE_BOT_DIGITS  = 0x10  ; PA4 turns on bottom digits

;Bitwise Math Constants (Replacing Magic Numbers)
.equ NIBBLE_MASK        = 0x0F  ; mask for isolating a 4-bit hex digit
.equ BIT_MOD_MASK       = 0x07  ; mask for modulo 8 division
.equ BIT_START_VAL      = 0x01  ; starting value for bit shifting
.equ BIT_START_MASK     = 0x80
; Additional Constants for LED Matrix
.equ BITS_PER_BYTE      = 8     ; number of bits in a byte
.equ TOP_ROW_MAX        = 7     ; maximum row index for the top grid
.equ BOTTOM_ROW_MAX     = 23    ; maximum row index for the bottom grid

;Timer Constants
.equ TIMER_PRESCALE     = (1 << CS01) | (1 << CS00) ; prescaler value for Timer0
.equ TIMER_INT_ENABLE   = (1 << TOIE0)              ; timer0 overflow interrupt enable

;SRAM Allocation
.dseg
.org 0x0100

DigitBuffer:    .byte NUM_DIGITS  
LightBuffer:    .byte LIGHT_BYTES 
MuxState:       .byte 1
