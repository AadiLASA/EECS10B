; InitHardware
; Description:  Initializes all required microcontroller peripherals for the pinball machine,
;               including I/O ports, external memory interfaces (if used), 
;               and initial states of displays and actuators.
;
; Operation:    Sets Data Direction Registers (DDRx) for inputs (sensors) and outputs 
;               (7-segment displays, LEDs, speaker, actuators). 
;               Clears all displays and turns off all actuators to ensure a safe starting state.
;
; Arguments:    None
; Return Value: None
; Local Var:    None
; Shared Var:   None
; Global Var:   None
; Input:        None
; Output:       Configures microcontroller pins. Calls ClearDisplay() and loops SetActuator() to false.
;
; Error Handle: Assumes hardware is physically connected as defined in the schematic.
; Algorithms:   Iterates through actuator indices (0-7) to turn them off.
; Data Struct:  None
; Regs Changed: R16, R17, Status Register

; Author: Aaditya Bhat
; Last Modified: June 6th, 2026

InitHardware:
    
    ; set port directions (Inputs for sensors, Outputs for Displays/Actuators)
    ; previous init functions here
    RCALL PreviousInitFunctions
    

    ; disable LEDs and Displays
    RCALL ClearDisplay()
    
    ; disable all actuators 
    SET R16 = 0  ; index counter
    SET R17 = 0  ; state s (FALSE/OFF)
ActuatorDisableLoop:
    RCALL SetActuator(R16, R17)
    INCREMENT R16
    COMPARE R16 with 8
    IF NOT EQUAL THEN JMP ActuatorDisableLoop
    
    ; turn off speaker
    SET R16 = 0
    SET R17 = 0
    RCALL PlayNote(0)  ; 0 Hz turns it off
    
    RET