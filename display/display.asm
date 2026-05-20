;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file contains the display functions for Homework #3.
;                   It includes the Timer0 interrupt service routine for
;                   multiplexing the 7-segment displays and LED matrix.
;
; Input:            None.
; Output:           Updates the 7-segment displays and LED matrix based on
;                   the current state of the multiplexer.
;
; User Interface:   None.
; Error Handling:   None.
;
; Algorithms:       State machine for multiplexing.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    5/16/26  Aaditya Bhat               initial revision
;    5/18/26  Aaditya Bhat               updated comments
;    5/19/26  Aaditya Bhat               updated comments

.cseg


; Timer0_ISR
;
; Description:       Interrupt Service Routine for Timer0 overflow. Handles the 
;                    simultaneous multiplexing of the 16 7-segment displays 
;                    (Port C) and the 16x8 LED matrix (Port D) across 16 states.
;
; Operation:         Turns off Port A to prevent ghosting. Reads MuxState (0-15).
;                    Retrieves segment data from DigitBuffer and outputs to Port C.
;                    Retrieves column data from LightBuffer and outputs to Port D.
;                    Applies the appropriate row select (0-7) and device enable 
;                    bits (Top or Bottom) to Port A. Increments and loops state.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, R17, R21, Z (ZH | ZL)
; Shared Variables:  MuxState (Read/Write)
; Global Variables:  DigitBuffer (Read), LightBuffer (Read)
;
; Input:             None.
; Output:            Updates PORTA, PORTC, and PORTD based on the current state.
;
; Error Handling:    None.
;
; Algorithms:        16-State machine for simultaneous multiplexing.
; Data Structures:   None.
;
; Registers Changed: None (all saved and restored)
; Stack Depth:       7 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 18, 2026

Timer0_ISR:
    push    r16                     ;save working register
    in      r16, SREG               ;save status register flags
    push    r16
    push    r17                     ;save remaining working registers
    push    r21
    push    r30
    push    r31

    clr     r21                     ;zero register for 16-bit math carry

                                    ;turn off Port A completely before changing data
    out     PORTA, r21
    lds     r16, MuxState           ; load current multiplexer state (0-15)

    ;fetch/output 7seg data (portc)
    ldi     r30, low(DigitBuffer)
    ldi     r31, high(DigitBuffer)
    add     r30, r16                ;add state offset
    adc     r31, r21
    ld      r17, Z                  
    out     PORTC, r17              ; output digit pattern

    ;fetchout/output LED matrix data(port d)
    ldi     r30, low(LightBuffer)
    ldi     r31, high(LightBuffer)
    add     r30, r16                ; add state offset
    adc     r31, r21
    ld      r17, Z                  
    out     PORTD, r17              ; output column pattern

    ; port A row select and device enables
    cpi     r16, STATE_BOT_START
    brsh    DoBottomHalf            ; if state >= 8, jump to bottom half

DoTopHalf:
    ; states 0-7: top device enables
    mov     r17, r16
    ori     r17, ENABLE_TOP_DIGITS  ; add top enable mask to row number (0-7)
    out     PORTA, r17
    rjmp    MuxDone

DoBottomHalf:
    ; states 8-15: bottom device enables
    mov     r17, r16
    subi    r17, STATE_BOT_START    ; bring state value back down to 0-7 for the row
    ori     r17, ENABLE_BOT_DIGITS  ; add bottom enable mask to row number
    out     PORTA, r17

MuxDone:
    inc     r16                     ; increment state and loop at max
    cpi     r16, STATE_MAX
    brne    SaveState
    clr     r16                     ; reset to 0 if max state reached

SaveState:
    sts     MuxState, r16           ; save next state to RAM
    pop     r31                     ; restore all registers
    pop     r30
    pop     r21
    pop     r17
    pop     r16
    out     SREG, r16               ; restore status register
    pop     r16
    reti
