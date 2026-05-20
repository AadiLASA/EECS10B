;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This file contains the main functions for Homework #3.
;                   It includes functions to clear the display buffers and
;                   display hexadecimal numbers and LED patterns.
;
; Input:            None.
; Output:           Updates the display buffers and LED matrix.
;
; User Interface:   None.
; Error Handling:   None.
;
; Algorithms:       Buffer clearing, nibble extraction, and bit manipulation.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    5/16/26  Aaditya Bhat               initial revision
;    5/18/26  Aaditya Bhat               revised port a output directionality (was inverted)
;    5/18/26  Aaditya Bhat               updated comments

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
    push    r16                         ;save registers
    push    r17
    push    r30
    push    r31

    ldi     r30, low(DigitBuffer)       ;load digit buffer base address
    ldi     r31, high(DigitBuffer)
    ldi     r17, NUM_DIGITS             ;set loop counter to num of digits
    clr     r16                         ;clear for zero writing

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
    st      Z+, r16                    ;store zero at cur address and inc Z
    dec     r17                        ;dec loop counter
    brne    ClearDigitsLoop            ;repeat till light bytes are cleared

    ldi     r30, low(LightBuffer)      ;load lightbuf base addr into z
    ldi     r31, high(LightBuffer)
    ldi     r17, LIGHT_BYTES           ;set loop counter to num light bytes

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
    st      Z+, r16                     ;store zero at cur address
    dec     r17                         ;decrement loop counter
    brne    ClearLightsLoop             ;repeat until ;ight bytes clearaed

    pop     r31                         ;restore regs
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
; DisplayHex
DisplayHex:
    cpi     r18, PLAYER_MIN                     ;check if player num is valid (>=min)
    brlo    EndDisplayHex      
    cpi     r18, PLAYER_MAX + 1                 ;check if player num is valid (<=max)
    brsh    EndDisplayHex
                                                ;otherwise skip function
    push    r16                                 ;save regs
    push    r17
    push    r18
    push    r19
    push    r20
    push    r21
    push    r30
    push    r31

    clr     r21                                 ;clear to prep carry in address calculations

    ;calculate array offset: (player - 1) * 4
    dec     r18                                 ;dec player num
    lsl     r18
    lsl     r18                                 ;multi by 2 twice = *4
    
    ldi     r30, low(DigitBuffer)               ;load digitbuffer base address
    ldi     r31, high(DigitBuffer)
    add     r30, r18                            ;add offset to Z
    adc     r31, r21

    
    ;Z+0 rightmost digit-> low nibble of R16
    mov     r19, r16                            
    andi    r19, NIBBLE_MASK                    ;mask low nibble from R16
    rcall   GetSegCode                          ;get the 7seg code
    st      Z+, r20                             ;store and incZ

    ;Z+1: high nibble of r16
    mov     r19, r16                            
    swap    r19                                 ;swap nibbles
    andi    r19, NIBBLE_MASK                    ;mask low (prev high)
    rcall   GetSegCode                          ;get the 7 seg code
    st      Z+, r20                             ;store and incz

    ;Z+2 low nibble of R17
    mov     r19, r17                            ;now repeat above process r17/r19
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z+, r20

    ;Z+3 leftmost digit -> high nibble of R17
    mov     r19, r17
    swap    r19
    andi    r19, NIBBLE_MASK
    rcall   GetSegCode
    st      Z, r20                              ;last store, no increment needed

EndDisplayHex:
    pop     r31                                 ;restore regs
    pop     r30 
    pop     r21
    pop     r20
    pop     r19
    pop     r18
    pop     r17
    pop     r16
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
; DisplayLight
DisplayLight:
    cpi     r16, NUM_LIGHTS
    brsh    EndDisplayLight             ;ensure not done with light cycle loop

    push    r16                         ;store register contents
    push    r17
    push    r18
    push    r19
    push    r21
    push    r30
    push    r31
    clr     r21

    ;calculate byte index: (l / 8)
    mov     r18, r16
    lsr     r18
    lsr     r18
    lsr     r18                         ;div r16 contents by 8 (2**3)

    ;if row is 0-7, subtract from 7. if 8-15, subtract from 23 to flip the block.
    cpi     r18, STATE_BOT_START
    brsh    BottomGridRow
TopGridRow:
    ldi     r19, TOP_ROW_MAX            ;load max row idnex
    sub     r19, r18
    mov     r18, r19                    ;flip and store index
    rjmp    GetAddress
BottomGridRow:
    ldi     r19, BOTTOM_ROW_MAX         ;load mx row index for bot grid
    sub     r19, r18
    mov     r18, r19                    ;flip and store

GetAddress:
    ldi     r30, low(LightBuffer)       ;load lightbuffer base address to Z
    ldi     r31, high(LightBuffer)
    add     r30, r18                    ;add byte index to Z
    adc     r31, r21
    ld      r19, Z                      ;load current byte val from buffer

    andi    r16, BIT_MOD_MASK           ;modulo 8
    ldi     r18, BIT_START_MASK         ;start mask at 10000000 (Bit 7)
BitLoop:
    tst     r16                         ;check if bitpos is zero
    breq    BitDone                     ;exit the loop if true
    lsr     r18                         ;shift the mask left
    dec     r16                         ;decrement the bit pos
    rjmp    BitLoop                     ;now just repeat until bit pos IS zero
BitDone:
    
    tst     r17                         ;check if state is off or non-zero (on)
    breq    ClearLightBit               ;if zero, clear bit
SetLightBit:
    or      r19, r18                    ;set the bit
    rjmp    WriteLight                  ;write back updated value
ClearLightBit:
    com     r18                         ;invert bit mask
    and     r19, r18                    ;clear the bit
WriteLight:
    st      Z, r19                      ;write the updated byte val to lightbuffer

    pop     r31                         ;restore registers
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
    push    ZL                              ;save regs
    push    ZH
    push    r21
    clr     r21                             ;clear carry in address calcs reg
    ldi     ZL, low(2 * DigitSegTable)      ;load segtable base address into Z
    ldi     ZH, high(2 * DigitSegTable)
    add     ZL, r19                         ;add digit index to Z
    adc     ZH, r21
    lpm     r20, Z                          ;load 7seg code from prog memory
    pop     r21                             ;restore registers
    pop     ZH
    pop     ZL
    ret
