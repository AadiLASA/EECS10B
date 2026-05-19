;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.cseg

; ClearDisplay
;
; Description:       Clears the 7-segment display buffer and LED matrix buffer.
;
; Operation:         Iterates through the DigitBuffer and LightBuffer, setting all
;                    values to zero.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, R17, R30, R31
; Shared Variables:  None.
; Global Variables:  DigitBuffer, LightBuffer
;
; Input:             None.
; Output:            Clears the display and light buffers.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R30, R31
; Stack Depth:       8 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
ClearDisplay:
    push    r16
    push    r17
    push    r30
    push    r31

    ldi     r30, low(DigitBuffer)
    ldi     r31, high(DigitBuffer)
    ldi     r17, NUM_DIGITS
    clr     r16

; ClearDigitsLoop
;
; Description:       Clears the DigitBuffer by setting all bytes to zero.
;
; Operation:         Iterates through the DigitBuffer and writes zero to each byte.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, R17, R30, R31
; Shared Variables:  None.
; Global Variables:  DigitBuffer
;
; Input:             None.
; Output:            Clears the DigitBuffer.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R30, R31
; Stack Depth:       4 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
ClearDigitsLoop:
    st      Z+, r16
    dec     r17
    brne    ClearDigitsLoop

    ldi     r30, low(LightBuffer)
    ldi     r31, high(LightBuffer)
    ldi     r17, LIGHT_BYTES

; ClearLightsLoop
;
; Description:       Clears the LightBuffer by setting all bytes to zero.
;
; Operation:         Iterates through the LightBuffer and writes zero to each byte.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16, R17, R30, R31
; Shared Variables:  None.
; Global Variables:  LightBuffer
;
; Input:             None.
; Output:            Clears the LightBuffer.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R30, R31
; Stack Depth:       4 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
ClearLightsLoop:
    st      Z+, r16
    dec     r17
    brne    ClearLightsLoop

    pop     r31
    pop     r30
    pop     r17
    pop     r16
    ret


; DisplayHex
;
; Description:       Displays a 16-bit hexadecimal number on the 7-segment display
;                    for a specific player.
;
; Operation:         Converts each nibble of the hex number into its 7-segment code
;                    and stores it in the DigitBuffer at the appropriate offset.
;
; Arguments:         R16:R17 = hex number, R18 = player (1-4)
; Return Value:      None.
;
; Local Variables:   R16, R17, R18, R19, R20, R21, R30, R31
; Shared Variables:  None.
; Global Variables:  DigitBuffer
;
; Input:             Hexadecimal number and player number.
; Output:            Updates the DigitBuffer for the specified player.
;
; Error Handling:    Ignores invalid player numbers.
;
; Algorithms:        Array offset calculation, nibble extraction, and lookup table.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R20, R21, R30, R31
; Stack Depth:       16 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
DisplayHex:
    cpi     r18, PLAYER_MIN
    brlo    EndDisplayHex      
    cpi     r18, PLAYER_MAX + 1
    brsh    EndDisplayHex

    push    r16
    push    r17
    push    r18
    push    r19
    push    r20
    push    r21
    push    r30
    push    r31

    clr     r21

    ; Calculate array offset: (player - 1) * 4
    dec     r18
    lsl     r18
    lsl     r18
    ldi     r30, low(DigitBuffer)
    ldi     r31, high(DigitBuffer)
    add     r30, r18
    adc     r31, r21

    mov     r19, r17
    swap    r19
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z+, r20

    mov     r19, r17
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z+, r20

    mov     r19, r16
    swap    r19
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z+, r20

    mov     r19, r16
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z, r20

    pop     r31
    pop     r30
    pop     r21
    pop     r20
    pop     r19
    pop     r18
    pop     r17
    pop     r16
EndDisplayHex:
    ret


; DisplayLight
;
; Description:       Turns a specific light in the LED matrix on or off.
;
; Operation:         Calculates the byte and bit position of the light in the LightBuffer,
;                    modifies the corresponding bit, and writes the updated value back.
;
; Arguments:         R16 = light index (0-127), R17 = state (0=off, non-zero=on)
; Return Value:      None.
;
; Local Variables:   R16, R17, R18, R19, R21, R30, R31
; Shared Variables:  None.
; Global Variables:  LightBuffer
;
; Input:             Light index and state.
; Output:            Updates the LightBuffer for the specified light.
;
; Error Handling:    Ignores invalid light indices.
;
; Algorithms:        Bit manipulation.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R21, R30, R31
; Stack Depth:       14 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
DisplayLight:
    cpi     r16, NUM_LIGHTS
    brsh    EndDisplayLight    

    push r16
    push r17
    push r18
    push r19
    push r21
    push r30
    push r31

    clr     r21

    ; Calculate byte index: l / 8
    mov     r18, r16
    lsr     r18
    lsr     r18
    lsr     r18
    ldi     r30, low(LightBuffer)
    ldi     r31, high(LightBuffer)
    add     r30, r18
    adc     r31, r21
    ld      r19, Z               

    ; Calculate bit mask: 1 << (l % 8)
    andi    r16, BIT_MOD_MASK          
    ldi     r18, BIT_START_VAL

; BitLoop
;
; Description:       Calculates the bit mask for a specific light index.
;
; Operation:         Shifts a bit mask left until the desired bit position is reached.
;
; Arguments:         R16 = bit position (0-7)
; Return Value:      R18 = bit mask
;
; Local Variables:   R16, R18
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Bit position.
; Output:            Bit mask for the specified position.
;
; Error Handling:    None.
;
; Algorithms:        Bit shifting.
; Data Structures:   None.
;
; Registers Changed: R16, R18
; Stack Depth:       2 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
BitLoop:
    tst     r16
    breq    BitDone
    lsl     r18
    dec     r16
    rjmp    BitLoop
BitDone:
    
    tst     r17
    breq    ClearLightBit

; SetLightBit
;
; Description:       Sets a specific bit in the LightBuffer to turn on a light.
;
; Operation:         Performs a bitwise OR operation to set the desired bit.
;
; Arguments:         R18 = bit mask, R19 = current byte value
; Return Value:      R19 = updated byte value
;
; Local Variables:   R18, R19
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Bit mask and current byte value.
; Output:            Updated byte value with the bit set.
;
; Error Handling:    None.
;
; Algorithms:        Bitwise OR.
; Data Structures:   None.
;
; Registers Changed: R18, R19
; Stack Depth:       2 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
SetLightBit:
    or      r19, r18             
    rjmp    WriteLight

; ClearLightBit
;
; Description:       Clears a specific bit in the LightBuffer to turn off a light.
;
; Operation:         Performs a bitwise AND operation with the complement of the bit mask.
;
; Arguments:         R18 = bit mask, R19 = current byte value
; Return Value:      R19 = updated byte value
;
; Local Variables:   R18, R19
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Bit mask and current byte value.
; Output:            Updated byte value with the bit cleared.
;
; Error Handling:    None.
;
; Algorithms:        Bitwise AND with complement.
; Data Structures:   None.
;
; Registers Changed: R18, R19
; Stack Depth:       2 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
ClearLightBit:
    com     r18                 
    and     r19, r18

; WriteLight
;
; Description:       Writes the updated byte value back to the LightBuffer.
;
; Operation:         Stores the updated byte value into the LightBuffer at the calculated address.
;
; Arguments:         R19 = updated byte value, Z = address in LightBuffer
; Return Value:      None.
;
; Local Variables:   R19, Z
; Shared Variables:  None.
; Global Variables:  LightBuffer
;
; Input:             Updated byte value and address.
; Output:            Updates the LightBuffer.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026
WriteLight:
    st      Z, r19

    pop     r31
    pop     r30
    pop     r21
    pop     r19
    pop     r18
    pop     r17
    pop     r16
EndDisplayLight:
    ret


; GetSegCode
;
; Description:       Retrieves the 7-segment display code for a hexadecimal digit.
;
; Operation:         Uses the SegTable lookup table to find the 7-segment code
;                    corresponding to the input hex digit.
;
; Arguments:         R19 = hex digit (0-F)
; Return Value:      R20 = 7-segment code
;
; Local Variables:   R19, R20, ZL, ZH, R21
; Shared Variables:  None.
; Global Variables:  SegTable
;
; Input:             Hexadecimal digit.
; Output:            7-segment code for the digit.
;
; Error Handling:    None.
;
; Algorithms:        Lookup table access.
; Data Structures:   None.
;
; Registers Changed: R20, ZL, ZH, R21
; Stack Depth:       6 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 16, 2026

GetSegCode:
    push    ZL
    push    ZH
    push    r21
    clr     r21
    ldi     ZL, low(2 * SegTable)
    ldi     ZH, high(2 * SegTable)
    add     ZL, r19
    adc     ZH, r21
    lpm     r20, Z
    pop     r21
    pop     ZH
    pop     ZL
    ret

; 7-Segment Lookup Table (Common Cathode Standard)
SegTable:
    .db 0x3F, 0x06 ; 0, 1
    .db 0x5B, 0x4F ; 2, 3
    .db 0x66, 0x6D ; 4, 5
    .db 0x7D, 0x07 ; 6, 7
    .db 0x7F, 0x6F ; 8, 9
    .db 0x77, 0x7C ; A, b
    .db 0x39, 0x5E ; C, d
    .db 0x79, 0x71 ; E, F