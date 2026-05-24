; ==============================================================================
; main.asm
; Description: Main execution loop and test invocation.
; ==============================================================================
.include "pinball_defs.inc"

; Main
; ------------------------------------------------------------------------------
; Description:       System entry point. Initializes stack, calls initialization 
;                    routines, and runs the EEROMSoundTest.
; Operation:         Sets up the Stack Pointer, calls SysInit, and calls the 
;                    external EEROMSoundTest. Enters an infinite loop upon return.
; Arguments:         None.
; Return Value:      None.
; Local Variables:   None.
; Shared Variables:  None.
; Registers Changed: SPH, SPL, R16.

Main:
    Initialize Stack Pointer/Vector Table
    CALL InitFunctions
    CALL HW4TEST.asm test functions 
    



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




; ==============================================================================
; eerom.asm
; Description: Serial EEPROM (93C46) access routines via Hardware SPI.
; ==============================================================================

; SPITransfer
; ------------------------------------------------------------------------------
; Description:       Sends and receives one byte over hardware SPI.
; Operation:         Loads data into SPDR, waits for the SPIF flag, reads SPDR.
; Arguments:         R16 - Byte to send.
; Return Value:      R16 - Received byte.
; Registers Changed: R16, SPSR, SPDR.

SPITransfer:
    Write R16 to SPDR
WaitLoop:
    Read SPSR
    IF (SPIF bit is 0) GOTO WaitLoop
    Read SPDR into R16
    RETURN

; ReadEEROM
; ------------------------------------------------------------------------------
; Description:       Reads n bytes from EEROM at address a into buffer p
; Operation:         Loops n times. For each iteration, asserts CS, constructs 
;                    the READ opcode + address bitstream, shifts it via SPI,
;                    reads the data byte, and deasserts CS.
; Arguments:         R16 - Number of bytes n.
;                    R17 - Starting EEROM address a.
;                    Y (R29|R28) - Pointer p to RAM buffer.
; Return Value:      None.
; Local Variables:   ByteCounter, AddressCounter, HighCmd, LowCmd.
; Shared Variables:  RAM Buffer.
; Registers Changed: R16, R17, R18, R19, Y.

ReadEEROM:
    AddressCounter = R17
    ByteCounter = R16

ReadLoop:
    IF (ByteCounter == 0) GOTO EndRead
    
    Assert SS Pin (Set Low/High depending on active state, usually High for 93C46)
    
    ; Construct 10-bit Read Command: Start(1) + Op(10) + Addr(7-bit)
    ; Sent via two 8-bit SPI transfers.
    HighCmd = EE_READ 
    LowCmd  = (AddressCounter << 1)  ; Shift 7-bit address to align
    
    Call SPITransfer(HighCmd)
    Call SPITransfer(LowCmd)
    
    Call SPITransfer(0x00)           ; Send byte to clock in the data
    Store Received Byte in RAM at Y
    Increment Y
    
    Deassert SS Pin (Drive Low)
    
    Increment AddressCounter
    Decrement ByteCounter
    GOTO ReadLoop
    
EndRead:
    RETURN

; WriteEEROM
; ------------------------------------------------------------------------------
; Description:       Writes n bytes to EEROM at address a from buffer p.
; Operation:         Issues an EWEN command. Loops n times sending the WRITE 
;                    opcode + address, followed by data. Waits for the write 
;                    cycle to complete (polls MISO). Finally issues an EWDS command.
; Arguments:         R16 - Number of bytes n.
;                    R17 - Starting EEROM address a.
;                    Y (R29|R28) - Pointer p to RAM buffer.
; Return Value:      None.
; Local Variables:   ByteCounter, AddressCounter, HighCmd, LowCmd, DataByte.
; Shared Variables:  RAM Buffer.
; Registers Changed: R16-R20, Y.

WriteEEROM:
    ; Enable Erase/Write
    Assert SS Pin
    Call SPITransfer(EE_EWEN)
    Call SPITransfer(0b11000000) ; 93C46 requires 11x for EWEN data phase
    Deassert SS Pin
    
    AddressCounter = R17
    ByteCounter = R16

WriteLoop:
    IF (ByteCounter == 0) GOTO EndWrite
    
    ;Write Command and Address
    Assert SS Pin
    HighCmd = EE_WRITE
    LowCmd  = (AddressCounter << 1)
    
    Call SPITransfer(HighCmd)
    Call SPITransfer(LowCmd)
    
    ;Write Data
    Load DataByte from RAM at Y
    Call SPITransfer(DataByte)
    Deassert SS Pin
    
    ;Poll for completion
    Assert SS Pin
PollReady:
    Read MISO Pin
    IF (MISO == 0) GOTO PollReady   ; 0 = Busy 1 = Ready
    Deassert SS Pin
    
    Increment Y
    Increment AddressCounter
    Decrement ByteCounter
    GOTO WriteLoop

EndWrite:
    ;Disable Erase/Write 
    Assert SS Pin
    Call SPITransfer(EE_EWDS)
    Call SPITransfer(0b00000000) ; 93C46 needs 00x for EWDS data phase
    Deassert SS Pin
    
    RETURN






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