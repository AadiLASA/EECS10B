


; ATmega64 SPI Hardware I/O Registers
.equ SPCR  = 0x0D          ; SPI Control Register
.equ SPSR  = 0x0E          ; SPI Status Register
.equ SPDR  = 0x0F          ; SPI Data Register
.equ SPIF  = 7             ; SPI Interrupt Flag bit in SPSR

; EEPROM Chip Select (CS) Pin Mapping
; Microwire CS is ACTIVE HIGH (unlike standard SPI which is active low)
.equ CS_PORT = 0x18         ; PORTB Data Register (ATmega64 standard)
.equ CS_DDR  = 0x17         ; DDRB Data Direction Register (ATmega64 standard)
.equ CS_PIN  = 0            ; PB0 (Pin 0 of PORTB)

; =========================================================================
; FUNCTION: SPITransfer
; Transmits the byte in R20, waits for completion, returns received byte in R20.
; Modifies: R20, SPSR (flags)
; =========================================================================
SPITransfer:
    out   SPDR, r20         ; Start SPI transmission with byte in R20
SPI_Wait:
    in    r20, SPSR         ; Read SPI status register
    sbrs  r20, SPIF         ; Skip next instruction if SPIF flag is set (done)
    rjmp  SPI_Wait          ; Loop until transmission finishes
    in    r20, SPDR         ; Read incoming byte into R20
    ret

; =========================================================================
; FUNCTIONS: CS_High / CS_Low
; Controls the Active-High Chip Select line for the 93C46
; =========================================================================
CS_High:
    sbi   CS_PORT, CS_PIN   ; Assert CS (Logic 1)
    ret

CS_Low:
    cbi   CS_PORT, CS_PIN   ; De-assert CS (Logic 0)
    ret

; =========================================================================
; FUNCTION: ReadEEROM(a, p, n)
; Inputs:  R17 = EEPROM starting address (a)
;          Y   = Pointer to RAM destination buffer (p) [R29:R28]
;          R16 = Number of bytes to read (n)
; Modifies: R16, R17, R20, Y
; =========================================================================
ReadEEROM:
    tst   r16               ; Check if n == 0
    breq  Read_Done         ; If 0, exit immediately

    rcall CS_High           ; Assert Chip Select (Active High)

    ; --- Step 1: Send Opcode Byte (0x06) ---
    ldi   r20, 0x06         ; Start bit (1) + Read Opcode (10) padded: 00000110
    rcall SPITransfer

    ; --- Step 2: Send Shifted Address Byte ---
    mov   r20, r17          ; Copy address (a) to transfer register
    lsl   r20               ; Left shift address by 1 to match command structure
    rcall SPITransfer       ; The 93C46A releases its dummy 0 during this byte

    ; --- Step 3: Sequential Read Loop ---
Read_Loop:
    ldi   r20, 0x00         ; Load dummy byte to clock out target data
    rcall SPITransfer       ; R20 now contains the data byte from EEPROM
    st    Y+, r20           ; Store byte in RAM buffer and increment Y pointer
    dec   r16               ; Decrement loop counter (n)
    brne  Read_Loop         ; Repeat until all n bytes are retrieved

Read_Done:
    rcall CS_Low            ; De-assert Chip Select
    ret

; =========================================================================
; FUNCTION: WriteEEROM(a, p, n)
; Inputs:  R17 = EEPROM starting address (a)
;          Y   = Pointer to RAM source buffer (p) [R29:R28]
;          R16 = Number of bytes to write (n)
; Modifies: R16, R17, R20, Y
; =========================================================================
WriteEEROM:
    tst   r16               ; Check if n == 0
    breq  Write_Exit        ; If 0, exit immediately

    ; --- Step 1: Global Write Enable (WEN) ---
    rcall CS_High
    ldi   r20, 0x04         ; Start bit (1) + WEN Opcode (00) padded: 00000100
    rcall SPITransfer
    ldi   r20, 0x18         ; Upper address bits for WEN (11XXXXXX) shifted: 00110000 -> 0x30 or 0x18 depending on clocking
    ; For 93C46A 8-bit mode, WEN is explicitly: Start(1) + Opcode(00) + 11XXXXX
    ; Structured across 2 bytes: Byte1=0x04, Byte2=0xC0
    ldi   r20, 0xC0         
    rcall SPITransfer
    rcall CS_Low            ; Cycle CS to commit command
    
    ; --- Step 2: Write Loop ---
Write_Loop:
    rcall CS_High           ; New cycle for this specific byte

    ; Send Write Opcode Byte
    ldi   r20, 0x05         ; Start bit (1) + Write Opcode (01) padded: 00000101
    rcall SPITransfer

    ; Send Address Byte
    mov   r20, r17          ; Get current execution address
    lsl   r20               ; Left shift address by 1
    rcall SPITransfer

    ; Send Data Byte
    ld    r20, Y+           ; Load data byte from RAM pointer and advance Y
    rcall SPITransfer
    rcall CS_Low            ; Dropping CS initiates the internal write cycle

    ; --- Step 3: Hardware Ready/Busy Polling ---
    rcall CS_High           ; Raising CS allows DO pin to reflect status
Wait_Ready:
    ldi   r20, 0x00         ; Clock dummy data to read DO status pin
    rcall SPITransfer       ; SPI hardware handles clocking MISO pin status
    ; Note: In SPI mode, checking if MISO is high requires verifying the received byte. 
    ; If the EEPROM is still busy, DO stays low (0x00). When ready, DO goes high (0xFF).
    tst   r20               
    breq  Wait_Ready        ; Loop if returned byte is still 0x00 (Busy)
    rcall CS_Low            ; Clean up CS line

    inc   r17               ; Manually increment destination address for next loop iteration
    dec   r16               ; Decrement loop counter (n)
    brne  Write_Loop        ; Loop back if more bytes remain

    ; --- Step 4: Write Disable (WDS) for Safety ---
    rcall CS_High
    ldi   r20, 0x04         ; Start bit (1) + WDS Opcode (00) padded
    rcall SPITransfer
    ldi   r20, 0x00         ; Address bits for WDS (00XXXXX)
    rcall SPITransfer
    rcall CS_Low

Write_Exit:
    ret
