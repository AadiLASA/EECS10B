;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file contains the hardware initialization functions
;                   for Homework #3. It configures the I/O ports, initializes
;                   variables, and sets up Timer0 for multiplexing.
;
; Input:            None.
; Output:           Configures hardware and initializes variables.
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
;    5/18/26  Aaditya Bhat               updated timer freq (flickering issue)
;    5/19/26  Aaditya Bhat               updated comments

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
    ;config ports A, C, and D as outputs
    ldi     r16, ALL_OUTPUTS
    out     DDRA, r16
    out     DDRC, r16
    out     DDRD, r16

    ;turn off all displays initially to prevent startup garbage
    ldi     r16, ALL_OFF
    out     PORTA, r16
    out     PORTC, r16
    out     PORTD, r16

    ;initialize variables
    sts     MuxState, r16       ; start at state 0 
    rcall   ClearDisplay      

    ;configure timer0 for multiplexing
    ldi     r16, TIMER_PRESCALE 
    out     TCCR0, r16

    ;enable Timer0 overflow interrupt
    in      r16, TIMSK
    ori     r16, TIMER_INT_ENABLE
    out     TIMSK, r16
    sei                     ;enable global interrupts
    ret