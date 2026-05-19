;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hardware.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.cseg

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