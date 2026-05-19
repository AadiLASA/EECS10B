;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; vars.inc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;System Constants
.equ NUM_DIGITS         = 16    ; Total 7-segment digits (4 players * 4 digits)
.equ NUM_LIGHTS         = 128   ; Total individual LEDs
.equ LIGHT_BYTES        = 16    ; NUM_LIGHTS / 8 bits per byte
.equ PLAYER_MIN         = 1     ; Lowest valid player number
.equ PLAYER_MAX         = 4     ; Highest valid player number

;IO Initialization Constants
.equ ALL_OUTPUTS        = 0xFF  ; Data Direction Register mask for all outputs
.equ ALL_OFF            = 0x00  ; Port state for turning everything off

;Multiplexer State Boundaries
.equ STATE_BOT_START    = 8     ; State where bottom digits begin
.equ STATE_MAX          = 16    ; Reduced from 24 to 16

;Port A Hardware Enable Masks
.equ ENABLE_TOP_DIGITS  = 0x08  ; PA3 turns on top digits
.equ ENABLE_BOT_DIGITS  = 0x10  ; PA4 turns on bottom digits

;Bitwise Math Constants (Replacing Magic Numbers)
.equ NIBBLE_MASK        = 0x0F  ; Mask for isolating a 4-bit hex digit
.equ BIT_MOD_MASK       = 0x07  ; Mask for modulo 8 division
.equ BIT_START_VAL      = 0x01  ; Starting value for bit shifting

;Timer Constants
.equ TIMER_PRESCALE     = (1 << CS02) ; Prescaler value for Timer0
.equ TIMER_INT_ENABLE   = (1 << TOIE0); Timer0 Overflow Interrupt Enable

;SRAM Allocation
.dseg
.org 0x0100

DigitBuffer:    .byte NUM_DIGITS  
LightBuffer:    .byte LIGHT_BYTES 
MuxState:       .byte 1