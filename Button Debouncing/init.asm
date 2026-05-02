;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  init.asm                                  ;
;                         Hardware Initialization Setup                      ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.cseg

; InitPorts
;
; Description:       Configures the I/O ports for the 5x8 sensor matrix.
;
; Operation:         Sets the row pins as outputs and the column pins as inputs.
;                    Enables internal pull-up resistors on the column pins.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  ROW_PORT, ROW_DDR, COL_PORT, COL_DDR
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
; Last Modified:     May 2, 2026
InitPorts:
	;Set the lower pins of ROW_PORT to outputs (0001 1111)
	LDI R16, $1F
	OUT ROW_DDR, R16

	;Set all pins of COL_PORT to inputs
	LDI R16, $00
	OUT  COL_DDR, R16

	;Enable the internal pull-up resistors on the column inputs
	LDI R16, $FF
	OUT COL_PORT, R16

	RET


; InitTimer0
;
; Description:       Configures Timer 0 to generate a compare match interrupt every 1ms.
;
; Operation:         Sets Timer 0 to CTC mode, loads the compare match value, enables
;                    the interrupt, and starts the timer with a prescaler of 64.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  TIMSK, TCCR0, OCR0
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
; Last Modified:     May 2, 2026
InitTimer0:
	;Set the timer to CTC Mode
	LDI R16, (1 << WGM01)
	OUT TCCR0, R16

	;Set the compare match value
	LDI R16, $7C
	OUT OCR0, R16

	;Enable the Timer0 Match Interrupt
	LDI R16, (1 << OCIE0)
	OUT TIMSK, R16

	;Start the timer (Prescalar = 64)
	LDI     R16, (1 << WGM01) | (1 << CS02) 
    OUT     TCCR0, R16
	SEI
        
    RET


; InitVariables
;
; Description:       Clears all shared SRAM variables used by the sensor routines.
;
; Operation:         Sets `SensorFlag`, `SensorState`, `DebounceCnt`, and `SensorCode` to 0.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  SensorFlag, SensorState, DebounceCnt, SensorCode
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
; Last Modified:     May 2, 2026
InitVariables:
        CLR     R16
        STS     SensorFlag, R16
        STS     SensorState, R16
        STS     DebounceCnt, R16
        STS     SensorCode, R16
        RET
