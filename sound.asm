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
    IF (f (R17|R16) == 0) THEN
        Disconnect Timer 1 from OC1A pin (Clear COM1A0 in TCCR1A)
        Clear SPEAKER_PIN output to 0
        RETURN
    ELSE
        Reconnect Timer 1 to OC1A pin (Set COM1A0 in TCCR1A)
    ENDIF

    ; Calculate Timer Compare Value
    ; OCR1A = (F_CPU / (2 * PRESCALER * f)) - 1
    Numerator = F_CPU / (2 * PRESCALER)    ; constants
    Denominator = f (R17|R16)
    
    Call Divide32by16(Numerator, Denominator) ; result in a register pair
    Subtract 1 from the Result
    
    Write Result High to OCR1AH
    Write Result Low to OCR1AL
    
    RETURN