; ==============================================================================
; vars.inc
; Description: symbol definitions, macros, and constants.
; ==============================================================================

; hardware 
.equ F_CPU = 8000000              ; CPU Clock Frequency in Hz 
.equ PRESCALER = 64               ; Timer 1 Prescaler

; Actuator Port 
.equ ACTUATOR_PORT = PORTA        ; Port assigned to drive actuators
.equ ACTUATOR_DIR  = DDRA         ; Direction register for actuators

; Sound Port Timer 1 OC1A
.equ SOUND_PORT = PORTB
.equ SOUND_DIR  = DDRB
.equ SPEAKER_PIN = 5              ; OC1A is PB5 on ATMega64

; SPI / EEROM Pin Port B
.equ SPI_PORT = PORTB
.equ SPI_DIR  = DDRB
.equ SPI_SS   = 0                 ; Chip Select for 93C46
.equ SPI_SCK  = 1                 ; Serial Clock
.equ SPI_MOSI = 2                 ; Master Out Slave In 
.equ SPI_MISO = 3                 ; Master In Slave Out

; 93C46 Opcodes (including Start Bit = 1)
.equ EE_READ  = 0b00000110        ; Start (1) + Read Opcode (10)
.equ EE_WRITE = 0b00000101        ; Start (1) + Write Opcode (01)
.equ EE_EWEN  = 0b00000100        ; Start (1) + EWEN Opcode (00) (Data requires 11xxxxx)
.equ EE_EWDS  = 0b00000100        ; Start (1) + EWDS Opcode (00) (Data requires 00xxxxx)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display vars.inc
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