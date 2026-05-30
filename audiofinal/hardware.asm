; ==============================================================================
; hardware.asm
; Description: Hardware initialization master routine.
; ==============================================================================



; InitActuator
; ------------------------------------------------------------------------------
; Description:       Initializes the actuator port as an output and clears it.
; Operation:         Sets ACTUATOR_DIR to all 1s (outputs) and ACTUATOR_PORT to 0.
; Arguments:         None.
; Return Value:      None.
; Registers Changed: R16, ACTUATOR_DIR, ACTUATOR_PORT.

InitActuator:
    LDI R16, ACTUATOR_DIR
    OUT ACTUATOR_PORT, R16
    RET



; InitEEROM
; ------------------------------------------------------------------------------
; Description:       Initializes hardware SPI for EEROM communication.
; Operation:         Sets SCK, MOSI, and SS pins as outputs, MISO as input. 
;                    Enables SPI in Master Mode.
; Arguments:         None.
; Return Value:      None.
; Registers Changed: R16, SPI_DIR, SPI_PORT, SPCR.

InitEEROM:
    ; Set SS (PB0), SCK (PB1), and MOSI (PB2) as outputs
    ; (Assuming DD_SS=0, DD_SCK=1, DD_MOSI=2 based on PORTB)
    ; Set PB0 (CS), PB1 (SCK), and PB2 (MOSI) as outputs
    SBI DDRB, 0
    SBI DDRB, 1
    SBI DDRB, 2
    
    ; Set PB3 (MISO) as input
    CBI DDRB, 3
    
    ; Ensure CS is low (inactive) to start
    CBI PORTB, 0
    
    ; Enable SPI, Master, set clock rate fck/16
    LDI R16, (1<<SPE) | (1<<MSTR) | (1<<SPR0)
    OUT SPCR, R16
    RET


; InitSound
; ------------------------------------------------------------------------------
; Description:       Configures Timer 1 for sound generation.
; Operation:         Sets SPEAKER_PIN to output. Configures Timer 1 in CTC mode 
;                    (Clear Timer on Compare match OCR1A), toggling OC1A.
; Arguments:         None.
; Return Value:      None.
; Registers Changed: R16, TCCR1A, TCCR1B, SOUND_DIR.

InitSound:
    SBI DDRB, 5
    LDI R16, (1<<COM1A0) ;toggle on int
    OUT TCCR1A, R16

    LDI R16, (1<<WGM12) | (1<<CS11) | (1<<CS10) ;ctc 64 prescalar
    OUT TCCR1B, R16

    LDI R16, 0
    OUT OCR1A, R16     ; Default to 0
    RET


    ; InitHardware
;
; Description:       Initializes the hardware, including I/O ports, variables, and Timer0.
;
; Operation:         Configures Ports A, C, and D as outputs, clears all displays, and
;                    sets up Timer0 for normal mode with overflow interrupt enabled.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  MuxState
;
; Input:             None.
; Output:            Configures hardware and initializes variables.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
InitHardware:
    ;Configure Ports A, C, and D as outputs
    ldi     r16, ALL_OUTPUTS
    out     DDRA, r16
    out     DDRC, r16
    out     DDRD, r16

    ;Turn off all displays initially to prevent startup garbage
    ldi     r16, ALL_OFF
    out     PORTA, r16
    out     PORTC, r16
    out     PORTD, r16

    ;Initialize Variables
    sts     MuxState, r16       ; Start at state 0 (ALL_OFF is conveniently 0)
    rcall   ClearDisplay      

    ;Configure Timer0 for multiplexing (Normal Mode)
    ldi     r16, TIMER_PRESCALE 
    out     TCCR0, r16

    ;Enable Timer0 Overflow Interrupt
    in      r16, TIMSK
    ori     r16, TIMER_INT_ENABLE
    out     TIMSK, r16

    sei                     ; Enable global interrupts
    ret