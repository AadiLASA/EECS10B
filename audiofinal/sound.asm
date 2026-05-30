; ==============================================================================
; sound.asm
; Description: Note generation and speaker control routines via Timer 1.
; ==============================================================================


; PlayNote
; ------------------------------------------------------------------------------
; Description:       Plays a note of frequency 'f' Hz on the speaker.
; Operation:         If 'f' is 0, turns off the timer output. If > 0, calculates
;                    the required OCR1A value using (F_CPU / (2 * PRESCALER * f)) - 1
;                    and updates the OCR1AH and OCR1AL registers.
; Arguments:         R17 | R16 - Frequency 'f' in Hz (R17 is High Byte).
; Return Value:      None.
; Local Variables:   OCR_Value.
; Shared Variables:  TCCR1A, OCR1A.
; Registers Changed: R16-R21 (depending on division logic).

PlayNote:
    PUSH R18
    PUSH R19
    PUSH R20
    PUSH R21

    ; Check if f (R17:R16) == 0
    CPI R16, 0
    BRNE ValidFreq
    CPI R17, 0
    BRNE ValidFreq
    
    ; Frequency is 0: Disconnect Timer Output
    LDI R18, (0<<COM1A0)
    OUT TCCR1A, R18
    RJMP EndPlayNote

ValidFreq:
    ; Connect Timer 1 to OC1A (Toggle on Compare Match)
    LDI R18, (1<<COM1A0)
    OUT TCCR1A, R18

    ; Initialize Numerator Constant: 8000000 / (2 * 64) = 62500 (0xF424)
    LDI R18, LOW(62500)
    LDI R19, HIGH(62500)
    
    ; Initialize 16-bit Quotient Counter (R21:R20) to 0
    LDI R20, 0
    LDI R21, 0

DividerLoop:
    ; Subtract Denominator (f) from Numerator
    SUB R18, R16
    SBC R19, R17
    
    ; Break the loop if an underflow occurred (Numerator < f)
    BRCS EndDivide          

    ; Safely increment the 16-bit quotient counter
    INC R20
    BRNE DividerLoop        ; If low byte didn't wrap to 0, keep dividing
    INC R21                 ; Low byte wrapped, carry over to high byte
    RJMP DividerLoop

EndDivide:
    ; Formula requires (Numerator / f) - 1
    SUBI R20, 1
    SBCI R21, 0

    ; Write to 16-bit Hardware Register
    ; MUST write High Byte first, then Low Byte
    OUT OCR1AH, R21
    OUT OCR1AL, R20

EndPlayNote:
    POP R21
    POP R20
    POP R19
    POP R18
    RET
    