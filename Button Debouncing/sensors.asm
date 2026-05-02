;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 sensors.asm                                ;
;                         Matrix Scanning & Debouncing                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
; --- Shared Variables in SRAM ---
SensorFlag:     .BYTE 1         ; Set to 1 when a valid, debounced key is ready
SensorCode:     .BYTE 1         ; Holds the ID (0-39) of the debounced key
SensorState:    .BYTE 1         ; Tracks the current phase of the state machine
DebounceCnt:    .BYTE 1         ; Counts how many ms the key has been held
CurrentRaw:     .BYTE 1         ; The raw key ID currently being debounced


.cseg


; HaveSensor
;
; Description:       Checks if a valid, debounced sensor activation is available.
;
; Operation:         Reads the `SensorFlag` variable to determine if a sensor is ready.
;                    If `SensorFlag` is non-zero, a sensor is available.
;
; Arguments:         None.
; Return Value:      Z flag is reset (Z=0) if a sensor is available.
;                    Z flag is set (Z=1) if no sensor is available.
;
; Local Variables:   None.
; Shared Variables:  SensorFlag
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026            Z flag is set (Z=1/Equal) if no sensor is available.

HaveSensor:
	LDS R16, SensorFlag
	TST R16
	RET

; GetSensor
;
; Description:       Retrieves the debounced sensor code. Blocks until a sensor is ready.
;
; Operation:         Waits for `SensorFlag` to indicate a valid sensor activation.
;                    Reads the `SensorCode` and clears the `SensorFlag` after reading.
;
; Arguments:         None.
; Return Value:      R16 contains the debounced sensor code (0 to 39).
;
; Local Variables:   None.
; Shared Variables:  SensorFlag, SensorCode
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026
GetSensor:
GS_Wait:
	RCALL HaveSensor
	BREQ GS_Wait ;Loop if Z=0 implies No Sensor Flag

	;If no branch, sensor is ready
	LDS R16, SensorCode
	LDI R17, 0
	STS SensorFlag, R17 ;clear the flag, acknowledge reading
	RET

; Timer0_ISR
;
; Description:       Executes every 1ms to scan the sensor matrix and handle debouncing.
;
; Operation:         Scans the 5x8 sensor matrix row by row, detects key presses, and
;                    runs a state machine to debounce the input. Updates shared variables
;                    to indicate valid sensor activations.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16-R20, CurrentRaw
; Shared Variables:  SensorFlag, SensorCode, SensorState, DebounceCnt
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Matrix scanning, state machine for debouncing.
; Data Structures:   None.
;
; Registers Changed: R16-R20, flags
; Stack Depth:       At least 5 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

Timer0_ISR:
	;Save Context
	PUSH R16
	IN R16, SREG
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH R20

	;Setup Matrix Scanning
	LDI R16, $FE ;Row 0 Active LOW (1111 1110)
	LDI R17, 0   ;Tracking BaseID for cur row
	LDI R18, $FF ;R18 defaults to 0xFF (No key pressed)

; ScanLoop
;
; Description:       Iterates through each row of the 5x8 sensor matrix to detect key presses.
;
; Operation:         Drives one row low at a time, reads the column states, and checks for key presses.
;                    If a key press is detected, it calculates the key's ID and exits the loop.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (row selector), R17 (base row ID), R18 (key ID), R19 (column states), R20 (column counter)
; Shared Variables:  None.
; Global Variables:  ROW_PORT, COL_PIN
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Iterative row scanning.
; Data Structures:   None.
;
; Registers Changed: R16-R20
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

ScanLoop:
	OUT ROW_PORT, R16 ; Drive selected ROW Low
	NOP
	NOP

	IN R19, COL_PIN ; read 8 columns	
	COM R19 ; invert bits => pressed keys = 1

	TST R19
	BREQ NextRow ;IF R19 was empty, just go to next row (no presses)

	LDI R20, 0   ;R20 is col counter
	
; FindCol
;
; Description:       Identifies the column of the pressed key in the current row.
;
; Operation:         Iterates through the bits of the column state register to find the first active column.
;                    The column counter is incremented until the active column is found.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R19 (column states), R20 (column counter)
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Bitwise iteration.
; Data Structures:   None.
;
; Registers Changed: R19, R20
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

FindCol:
	SBRC R19, 0; Skip if BIT 0 is clear
	RJMP FoundPress
	INC R20
	LSR R19
	RJMP FindCol

; FoundPress
;
; Description:       Calculates the unique key ID based on the current row and column.
;
; Operation:         Adds the base row ID to the column counter to compute the key ID.
;                    Exits the scanning loop after identifying the key.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R17 (base row ID), R18 (key ID), R20 (column counter)
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Arithmetic calculation.
; Data Structures:   None.
;
; Registers Changed: R18
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026
	
FoundPress:
        ; Calculate the exact button ID (0 to 39)
        MOV     R18, R17        
        ADD     R18, R20        
        RJMP    ScanDone        ; Stop scanning. Handle one key at a time.

; NextRow
;
; Description:       Advances to the next row in the sensor matrix for scanning.
;
; Operation:         Updates the row selector and base row ID to prepare for scanning the next row.
;                    Checks if all rows have been scanned and loops back if necessary.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (row selector), R17 (base row ID)
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Iterative row advancement.
; Data Structures:   None.
;
; Registers Changed: R16, R17
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

NextRow:
	;Find ButtonID
	SUBI R17,-8 ;Add 8 to ROW ID
	SEC
	ROL R16 ;since carry set, 1101 => 1011 => 0111 etc   
	CPI R17, 40 ;checked all 5 rows?
	BRNE ScanLoop

; ScanDone
;
; Description:       Handles the transition from matrix scanning to the debouncing state machine.
;
; Operation:         Reads the current state of the debouncing state machine and branches to the appropriate handler.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (state machine state)
; Shared Variables:  SensorState
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        State machine branching.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

ScanDone:
	;Debouncing StateMachine
	LDS R16, SensorState
	CPI R16, STATE_IDLE
	BREQ Handle_Idle
	CPI R16, STATE_DEBOUNCE
    BREQ Handle_Debounce
    CPI R16, STATE_WAIT_RELEASE
    BREQ Handle_WaitRelease
    RJMP ISR_End


; Handle_Idle
;
; Description:       Handles the idle state of the debouncing state machine.
;
; Operation:         Checks if a key press is detected. If so, transitions to the debounce state and initializes variables.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (state machine state), R18 (key ID)
; Shared Variables:  SensorState, CurrentRaw, DebounceCnt
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        State transition.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

Handle_Idle:
	CPI R18, $FF
	BREQ ISR_End ;Nothing pressed
	
	STS CurrentRaw, R18
	LDI R16, STATE_DEBOUNCE
	STS SensorState, R16
	LDI R16, 0
	STS DebounceCnt, R16
	RJMP ISR_End	


; Handle_Debounce
;
; Description:       Handles the debounce state of the debouncing state machine.
;
; Operation:         Verifies if the key press is stable for the required debounce time.
;                    If stable, transitions to the wait-release state and updates shared variables.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (debounce counter, state machine state), R18 (key ID)
; Shared Variables:  SensorState, DebounceCnt, SensorCode, SensorFlag
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        State transition, time-based validation.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

Handle_Debounce:
	CPI R18, $FF
	BREQ Reset_To_Idle ;key pressed early

	LDS R16, CurrentRaw
	CP R18,R16
	BRNE Reset_To_Idle ;switched keys early

	;Valid Continuous Press (neither above cases happened)
	LDS R16, DebounceCnt
	INC R16
	STS DebounceCnt,R16
	CPI R16, DEBOUNCE_TIME
	BRNE ISR_End ;Not Fully debounced
	
	;Debounced Time Reached
	LDI R16, STATE_WAIT_RELEASE
	STS SensorState, R16

	LDS R16, CurrentRaw
	STS SensorCode, R16

	LDI R16, $01
	STS SensorFlag, R16
	RJMP ISR_End

; Reset_To_Idle
;
; Description:       Resets the state machine to the idle state.
;
; Operation:         Sets the state machine to idle and clears any intermediate variables.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (state machine state)
; Shared Variables:  SensorState
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        State reset.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

Reset_To_Idle:
	LDI     R16, STATE_IDLE
    STS     SensorState, R16
    RJMP    ISR_End

; Handle_WaitRelease
;
; Description:       Handles the wait-release state of the debouncing state machine.
;
; Operation:         Waits for the user to release the key. Once released, transitions back to the idle state.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16 (state machine state), R18 (key ID)
; Shared Variables:  SensorState
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        State transition.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

Handle_WaitRelease:
	CPI R18, $FF
	BRNE ISR_End  ;user still holding key

	;User Let Go - back to idle
	LDI R16, STATE_IDLE
	STS SensorState, R16
	RJMP ISR_END

; ISR_END
;
; Description:       Restores the processor context and exits the interrupt service routine.
;
; Operation:         Pops all saved registers from the stack and returns from the interrupt.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Stack Depth:       Restores all saved registers.
;
; Author:            Aaditya Bhat
; Last Modified:     May 2, 2026

ISR_END:
	;Restore Context
    POP     R20
    POP     R19
    POP     R18
    POP     R17
    POP     R16
    OUT     SREG, R16       
    POP     R16
    RETI

