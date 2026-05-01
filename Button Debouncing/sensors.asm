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
; Returns:      Z flag is reset (Z=0/Not Equal) if a sensor is available.
;               Z flag is set (Z=1/Equal) if no sensor is available.

HaveSensor:
	LDS R16, SensorFlag
	TST R16
	RET

; GetSensor
; Returns:      R16 contains the debounced sensor code (0 to 39). Blocks until ready.
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
; Description:  Executes every 1ms. Scans the matrix and runs the debouncing state machine.
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

ScanLoop:
	OUT ROW_PORT, R16 ; Drive selected ROW Low
	NOP
	NOP

	IN R19, COL_PIN ; read 8 columns	
	COM R19 ; invert bits => pressed keys = 1

	TST R19
	BREQ NextRow ;IF R19 was empty, just go to next row (no presses)

	LDI R20, 0   ;R20 is col counter
	
FindCol:
	SBRC R19, 0; Skip if BIT 0 is clear
	RJMP FoundPress
	INC R20
	LSR R19
	RJMP FindCol
	
FoundPress:
        ; Calculate the exact button ID (0 to 39)
        MOV     R18, R17        
        ADD     R18, R20        
        RJMP    ScanDone        ; Stop scanning. Handle one key at a time.

NextRow:
	;Find ButtonID
	SUBI R17,-8 ;Add 8 to ROW ID
	SEC
	ROL R16 ;since carry set, 1101 => 1011 => 0111 etc   
	CPI R17, 40 ;checked all 5 rows?
	BRNE ScanLoop

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

Handle_Idle:
	CPI R18, $FF
	BREQ ISR_End ;Nothing pressed
	
	STS CurrentRaw, R18
	LDI R16, STATE_DEBOUNCE
	STS SensorState, R16
	LDI R16, 0
	STS DebounceCnt, R16
	RJMP ISR_End	


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

Reset_To_Idle:
	LDI     R16, STATE_IDLE
    STS     SensorState, R16
    RJMP    ISR_End

Handle_WaitRelease:
	CPI R18, $FF
	BRNE ISR_End  ;user still holding key

	;User Let Go - back to idle
	LDI R16, STATE_IDLE
	STS SensorState, R16
	RJMP ISR_END

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

