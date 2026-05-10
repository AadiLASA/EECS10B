; InitPorts
;
; Description:       Configures the I/O ports for the displays and lights.
;
; Operation:         Sets the data direction registers (DDR) for the segment 
;                    outputs, digit selection outputs, and light matrix pins to 
;                    output mode.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  DDR_SEGMENTS, DDR_DIGITS, DDR_LIGHTS
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
; Registers Changed: R16
;
InitPorts:
 LOAD R16 with 0xFF (all outputs)
 OUT R16 to segment data direction register
 OUT R16 to digit select data direction register
 OUT R16 to light matrix data direction register
 RETURN


; InitDisplayTimer
;
; Description:       Configures the hardware timer to generate interrupts for 
;                    display multiplexing.
;
; Operation:         Sets up the timer control registers for CTC mode, sets 
;                    the compare value for the desired refresh rate, and 
;                    enables the timer interrupt.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  TCCR_REG, TIMSK_REG, OCR_REG
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
; Registers Changed: R16
;
InitDisplayTimer:
 LOAD R16 with timer configuration (e.g., prescaler, CTC mode)
 OUT R16 to Timer Control Register
 LOAD R16 with compare match value (determines multiplexing frequency)
 OUT R16 to Output Compare Register
 LOAD R16 with timer interrupt enable bit mask
 OUT R16 to Timer Interrupt Mask Register
 ENABLE global interrupts (SEI)
 RETURN