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
    Set ACTUATOR_DIR to 0xFF
    Set ACTUATOR_PORT to 0x00
    RETURN

; SetActuator
; ------------------------------------------------------------------------------
; Description:       Turns a specific pinball machine actuator on or off.
; Operation:         Reads the current state of ACTUATOR_PORT. Creates a bitmask 
;                    using the actuator number a. If state s is TRUE, it 
;                    ORs the mask. If FALSE, it ANDs the inverted mask.
; Arguments:         R16 - Actuator number a (0-7).
;                    R17 - Actuator state s (0 = FALSE, non-zero = TRUE).
; Return Value:      None.
; Local Variables:   Bitmask.
; Shared Variables:  ACTUATOR_PORT (Read/Write).
; Registers Changed: R16, R17, R18.

SetActuator:
    Create Bitmask: R18 = (1 << R16 (a))
    Read current port state into a temp register
    
    IF (R17 (s) != 0) THEN
        Set the target bit: Temp = Temp OR R18
    ELSE
        Clear the target bit: Temp = Temp AND (NOT R18)
    ENDIF
    
    Write Temp back to ACTUATOR_PORT
    RETURN


; InitEEROM
; ------------------------------------------------------------------------------
; Description:       Initializes hardware SPI for EEROM communication.
; Operation:         Sets SCK, MOSI, and SS pins as outputs, MISO as input. 
;                    Enables SPI in Master Mode.
; Arguments:         None.
; Return Value:      None.
; Registers Changed: R16, SPI_DIR, SPI_PORT, SPCR.

InitEEROM:
    Set SPI_DIR bits for SCK, MOSI, and SS to 1 (Output)
    Set SPI_DIR bit for MISO to 0 (Input)
    Set SS Pin high (Inactive)
    Enable SPI, Master mode, Clock Rate fck/16 (Write to SPCR)
    RETURN

; InitSound
; ------------------------------------------------------------------------------
; Description:       Configures Timer 1 for sound generation.
; Operation:         Sets SPEAKER_PIN to output. Configures Timer 1 in CTC mode 
;                    (Clear Timer on Compare match OCR1A), toggling OC1A.
; Arguments:         None.
; Return Value:      None.
; Registers Changed: R16, TCCR1A, TCCR1B, SOUND_DIR.

InitSound:
    Set SPEAKER_PIN bit in SOUND_DIR to 1 (Output)
    Set TCCR1A = (1 << COM1A0)             ; Toggle OC1A on compare match
    Set TCCR1B = (1 << WGM12) | PRESCALER  ; CTC mode, prescaler set
    Set OCR1A to 0                         ; Default to 0
    RETURN