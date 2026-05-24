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