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
