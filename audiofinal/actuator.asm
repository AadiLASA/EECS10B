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
    ;push non param regs
    PUSH R18
    PUSH R19

    ; read state make mask
    IN R18, ACTUATOR_PORT   ; R18 = Current port state
    LDI R19, 1              ; R19 = Mask starting at 00000001

Loop:
    CPI R16, 0              ; Check if shift counter is 0
    BREQ Done               ; If 0, we are done shifting
    LSL R19                 ; Shift mask left by 1
    DEC R16                 ; Decrement counter
    RJMP Loop               ; Jump back to the top of the loop!

Done:
    CPI R17, 0              ; Check if state parameter s is false 0
    BREQ Clear              ; If 0, branch to the clear logic
    
    ; set true logic
    OR R18, R19             ; Bitwise OR to set the bit
    OUT ACTUATOR_PORT, R18  ; Output to the port
    RJMP Cleanup            ; Jump over the Clear logic to exit

Clear:
    ; clear false logic
    COM R19                 ; Invert the mask (e.g., 00100000 -> 11011111)
    AND R18, R19            ; Bitwise AND to clear the bit safely
    OUT ACTUATOR_PORT, R18  ; Output to the port

Cleanup:
    POP R19                 
    POP R18
    RET                     ; Return to caller

