; ClearDisplay
;
; Description:       Clears all LEDs on the pinball machine (7-segments and lights).
;
; Operation:         Iterates through the display RAM buffers and writes zeros 
;                    (or the specific "off" pattern) to clear all pending data.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, Z (Pointer)
; Shared Variables:  DisplayBuffer, LightBuffer (Written)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   RAM arrays for display and light states.
; Registers Changed: R16, ZH, ZL
;
ClearDisplay
 LOAD Z pointer with address of DisplayBuffer
 LOAD R16 with loop counter (total digits across all players)
 ClearLoop:
   STORE 0x00 (or "off" segment pattern) to address at Z
   INCREMENT Z
   DECREMENT loop counter
   IF counter != 0 GOTO ClearLoop

 LOAD Z pointer with address of LightBuffer
 LOAD R16 with loop counter (total bytes for light matrix)

 LightClearLoop:
   STORE 0x00 to address at Z
   INCREMENT Z
   DECREMENT loop counter
   IF counter != 0 GOTO LightClearLoop
 RETURN


; DisplayHex
;
; Description:       Outputs a 16-bit number to a specific player's 7-segment display.
;
; Operation:         Extracts the 4 hex nibbles from the input value, looks up 
;                    the 7-segment pattern for each in SEGTABLE, calculates the 
;                    buffer offset for the requested player, and stores the 
;                    patterns in RAM.
;
; Arguments:         n (Value to display) in R17|R16.
;                    p (Player number 1-4) in R18.
; Return Value:      None.
;
; Local Variables:   R19, R20, Z (Pointer)
; Shared Variables:  DisplayBuffer (Written)
; Global Variables:  HexSegTable (in cseg)
;
; Input:             R17|R16 (n), R18 (p)
; Output:            Updates DisplayBuffer in RAM.
;
; Error Handling:    If player number (p) is out of bounds (not 1-4), exit safely.
; Algorithms:        Bit masking and shifting for nibble extraction.
; Data Structures:   RAM DisplayBuffer.
; Registers Changed: R16, R17, R18, R19, R20, ZH, ZL
;
DisplayHex:
 CHECK if p is between 1 and 4. If not, RETURN.
 CALCULATE starting offset in DisplayBuffer based on player p:
   Offset = (p - 1) * 4 digits
 LOAD Z pointer with (DisplayBuffer_Start + Offset)
 
 FOR EACH nibble in R17|R16 (starting from most significant):
   EXTRACT nibble by masking and shifting
   USE nibble as index to look up pattern in HexSegTable (cseg)
   STORE pattern to address at Z
   INCREMENT Z pointer
 END FOR
 RETURN


; DisplayLight
;
; Description:       Turns a specific pinball machine light on or off.
;
; Operation:         Takes a 7-bit light index, calculates the byte and bit 
;                    location in the LightBuffer, and sets or clears the bit 
;                    based on the state argument.
;
; Arguments:         l (Light number 0-127) in R17|R16.
;                    s (State: 0=FALSE, Non-Zero=TRUE) in R18.
; Return Value:      None.
;
; Local Variables:   R19, R20, Z (Pointer)
; Shared Variables:  LightBuffer (Read/Written)
; Global Variables:  None.
;
; Input:             R17|R16 (l), R18 (s)
; Output:            Updates specific bit in LightBuffer in RAM.
;
; Error Handling:    If light number (l) is > 127, exit safely.
; Algorithms:        Division/Modulo by 8 using bit shifts/masks.
; Data Structures:   RAM LightBuffer.
; Registers Changed: R16, R17, R18, R19, R20, ZH, ZL
;
DisplayLight:
 CHECK if l > 127. If so, RETURN.
 CALCULATE byte offset: ByteOffset = l / 8 (logical shift right 3 times)
 CALCULATE bit mask: BitIndex = l % 8 (mask lower 3 bits)
   Create a mask with a 1 at BitIndex (e.g., 00010000)
 
 LOAD Z pointer with (LightBuffer_Start + ByteOffset)
 LOAD R19 with value at Z
 
 IF s != 0 (TRUE):
   R19 = R19 OR mask (set the bit)
 ELSE (FALSE):
   INVERT mask
   R19 = R19 AND inverted_mask (clear the bit)
 
 STORE R19 back to address at Z
 RETURN


; DisplayMuxISR
;
; Description:       Timer Interrupt Service Routine to multiplex displays/lights.
;
; Operation:         Turns off current outputs to prevent ghosting, increments the 
;                    multiplexing step variable, fetches the next digit/row data 
;                    from RAM, outputs the data, and activates the next column/digit.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, Z (Pointer)
; Shared Variables:  DisplayBuffer, LightBuffer (Read), MuxStep (Read/Written)
; Global Variables:  PORT_SEGMENTS, PORT_DIGIT_SEL
;
; Input:             None (Hardware Timer Triggered)
; Output:            Signals to display and digit select hardware ports.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   RAM Buffers.
; Registers Changed: SREG (Saved/Restored), R16, ZH, ZL
;
DisplayMuxISR:
 SAVE Status Register (SREG) and any used registers to Stack
 TURN OFF all digit selections (write disable pattern to PORT_DIGIT_SEL)
 
 LOAD R16 with current MuxStep
 INCREMENT R16
 IF R16 >= MAX_MUX_STEPS:
   R16 = 0
 STORE R16 back to MuxStep
 
 CALCULATE data buffer address based on MuxStep
 FETCH data pattern from DisplayBuffer/LightBuffer at that address
 OUT data pattern to PORT_SEGMENTS / PORT_LIGHTS
 
 FETCH digit/row selection mask based on MuxStep
 OUT mask to PORT_DIGIT_SEL (turns on this specific digit/row)
 
 RESTORE SREG and registers from Stack
 RETURN FROM INTERRUPT (RETI)
