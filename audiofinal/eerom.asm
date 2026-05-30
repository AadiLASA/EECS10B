; ==============================================================================
; eerom.asm
; Description: Serial EEPROM (NM93C46 - 16-bit) access routines via Hardware SPI.
; ==============================================================================

; SPITransfer
; ------------------------------------------------------------------------------
; Description:       Sends and receives one byte over hardware SPI.
; Arguments:         R16 - Byte to send.
; Return Value:      R16 - Received byte.
; Registers Changed: R16, SPSR, SPDR.

SPITransfer:
    OUT SPDR, R16           
WaitSPI:
    IN R16, SPSR            
    SBRS R16, SPIF          
    RJMP WaitSPI            
    
    IN R16, SPDR            
    RET

; ReadEEROM
; ------------------------------------------------------------------------------
; Description:       Reads n bytes from EEROM at address a into buffer p.
;                    (Reads two bytes per 16-bit EEPROM register).
; Arguments:         R16 - Number of BYTES n (Must be even).
;                    R17 - Starting EEROM address a (6-bit).
;                    Y (R29:R28) - Pointer p to RAM buffer.
; Registers Changed: R16, R17, R18, R19, R20, R21, R22, Y.

ReadEEROM:
    PUSH R18                
    PUSH R19
    PUSH R20
    PUSH R21
    PUSH R22

    MOV R18, R16            ; Copy n
    LSR R18                 ; Divide n by 2 to get the 16-bit WORD count
    MOV R19, R17            ; Copy Address

ReadLoop:
    TST R18                 
    BREQ EndRead
    
    SBI PORTB, 0            ; Assert CS
    
    ; --- Send 9-bit Command (Aligned to 16 bits) ---
    LDI R16, 0x01           ; Start Bit (padded with 7 zeros)
    RCALL SPITransfer
    
    MOV R16, R19            ; Load 6-bit address
    ORI R16, 0x80           ; Add READ Opcode '10' to bits 7 and 6
    RCALL SPITransfer
    
    ; --- Read 17-bits (Dummy 0 + 16 Data Bits) ---
    LDI R16, 0x00           
    RCALL SPITransfer
    MOV R20, R16            ; Byte 1: [Dummy 0, D15-D9]
    
    LDI R16, 0x00           
    RCALL SPITransfer       
    MOV R21, R16            ; Byte 2: [D8-D1]
    
    LDI R16, 0x00
    RCALL SPITransfer
    MOV R22, R16            ; Byte 3: [D0, X, X, X, X, X, X, X]
    
    ; --- Reconstruct the 16-bit payload ---
    LSL R22                 ; Shift D0 into the Carry flag
    ROL R21                 ; Shift D0 from Carry into R21, push D8 to Carry
    ROL R20                 ; Shift D8 into R20, discard Dummy 0
    
    ; --- Store 2 Bytes to RAM ---
    ST Y+, R20              ; Store High Byte
    ST Y+, R21              ; Store Low Byte
    
    CBI PORTB, 0            ; Deassert CS to reset state machine
    
    INC R19                 ; Next EEPROM Address
    DEC R18                 ; Decrement WORD counter
    RJMP ReadLoop
    
EndRead:
    POP R22
    POP R21
    POP R20
    POP R19
    POP R18
    RET

; WriteEEROM
; ------------------------------------------------------------------------------
; Description:       Writes n bytes to EEROM at address a from buffer p.
; Arguments:         R16 - Number of BYTES n (Must be even).
;                    R17 - Starting EEROM address a (6-bit).
;                    Y (R29:R28) - Pointer p to RAM buffer.
; Registers Changed: R16, R17, R18, R19, R20, Y.

WriteEEROM:
    PUSH R18
    PUSH R19
    PUSH R20

    MOV R18, R16            
    LSR R18                 ; Divide byte count by 2 for word count
    MOV R19, R17            

    ; ---------------------------------------------------
    ; 1. Enable Erase/Write (EWEN Command)
    ; ---------------------------------------------------
    SBI PORTB, 0            
    LDI R16, 0x01           ; Start Bit
    RCALL SPITransfer
    LDI R16, 0x30           ; EWEN Opcode (00) + Address (11XXXX) -> 0x30
    RCALL SPITransfer
    CBI PORTB, 0            

WriteLoop:
    TST R18
    BREQ EndWrite
    
    ; ---------------------------------------------------
    ; 2. Send Write Command & 6-bit Address
    ; ---------------------------------------------------
    SBI PORTB, 0            
    LDI R16, 0x01           ; Start Bit 
    RCALL SPITransfer
    
    MOV R16, R19
    ORI R16, 0x40           ; WRITE Opcode (01) + 6-bit Address -> 0x40 | Addr
    RCALL SPITransfer
    
    ; ---------------------------------------------------
    ; 3. Write 16-bit Data (2 Bytes)
    ; ---------------------------------------------------
    LD R16, Y+              ; Load High Byte
    RCALL SPITransfer
    
    LD R16, Y+              ; Load Low Byte
    RCALL SPITransfer
    
    ; ---------------------------------------------------
    ; 4. Initiate Self-Timed Write & Poll
    ; ---------------------------------------------------
    CBI PORTB, 0            ; Drop CS to start burn
    NOP                     
    
    SBI PORTB, 0            ; Raise CS to read MISO status
PollReady:
    IN R16, PINB
    SBRS R16, 3             ; Check PB3 (MISO). 0 = Busy, 1 = Ready
    RJMP PollReady          
    CBI PORTB, 0            
    
    INC R19                 ; Next Address
    DEC R18                 ; Decrement WORD counter
    RJMP WriteLoop

EndWrite:
    ; ---------------------------------------------------
    ; 5. Disable Erase/Write (EWDS Command)
    ; ---------------------------------------------------
    SBI PORTB, 0
    LDI R16, 0x01           ; Start Bit
    RCALL SPITransfer
    LDI R16, 0x00           ; EWDS Opcode (00) + Address (00XXXX)
    RCALL SPITransfer
    CBI PORTB, 0
    
    POP R20
    POP R19
    POP R18
    RET