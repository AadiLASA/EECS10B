;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hardware.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.cseg

; Timer0_ISR
;
; Description:       Interrupt Service Routine for Timer0 overflow. Handles multiplexing
;                    of 7-segment displays and LED matrix.
;
; Operation:         Determines the current state of the multiplexer and updates the
;                    corresponding hardware (top digits, bottom digits, or lights).
;                    Increments the state and loops back to the beginning when the max
;                    state is reached.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, R17, R21, R30, R31
; Shared Variables:  MuxState
; Global Variables:  DigitBuffer, LightBuffer
;
; Input:             None.
; Output:            Updates PORTA, PORTC, and PORTD based on the current state.
;
; Error Handling:    None.
;
; Algorithms:        State machine for multiplexing.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R21, R30, R31
; Stack Depth:       10 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026

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
    push    r16                     ; Save working register
    in      r16, SREG               ; Save status register flags
    push    r16
    push    r17                     ; Save remaining working registers
    push    r21
    push    r30
    push    r31

    clr     r21                     ; Zero register for 16-bit math carry

    ; Prevent ghosting: Turn off Port A completely before changing data
    out     PORTA, r21
    lds     r16, MuxState           ; Load current multiplexer state (0-15)

    ; 1. Fetch and Output 7-Segment Data (Port C)
    ldi     r30, low(DigitBuffer)
    ldi     r31, high(DigitBuffer)
    add     r30, r16                ; Add state offset
    adc     r31, r21
    ld      r17, Z                  
    out     PORTC, r17              ; Output digit pattern

    ; 2. Fetch and Output LED Matrix Column Data (Port D)
    ldi     r30, low(LightBuffer)
    ldi     r31, high(LightBuffer)
    add     r30, r16                ; Add state offset
    adc     r31, r21
    ld      r17, Z                  
    out     PORTD, r17              ; Output column pattern

    ; 3. Handle Port A Row Select and Device Enables
    cpi     r16, STATE_BOT_START
    brsh    DoBottomHalf            ; If state >= 8, jump to bottom half

DoTopHalf:
    ; States 0-7: Top Device Enables
    mov     r17, r16
    ori     r17, EN_TOP_HALF        ; Add top enable mask to row number (0-7)
    out     PORTA, r17
    rjmp    MuxDone

DoBottomHalf:
    ; States 8-15: Bottom Device Enables
    mov     r17, r16
    subi    r17, STATE_BOT_START    ; Bring state value back down to 0-7 for the row
    ori     r17, EN_BOT_HALF        ; Add bottom enable mask to row number
    out     PORTA, r17

MuxDone:
    ; Increment state and loop at max
    inc     r16
    cpi     r16, STATE_MAX
    brne    SaveState
    clr     r16                     ; Reset to 0 if max state reached

SaveState:
    sts     MuxState, r16           ; Save next state to RAM

    pop     r31                     ; Restore all registers
    pop     r30
    pop     r21
    pop     r17
    pop     r16
    out     SREG, r16               ; Restore status register
    pop     r16
    reti