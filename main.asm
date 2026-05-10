; This file contains all the constants, port definitions, and register 
; aliases used across the project to avoid magic numbers.

DEFINE PORT_SEGMENTS as the output port for 7-segment data
DEFINE PORT_DIGIT_SEL as the output port for digit/player multiplexing
DEFINE PORT_LIGHTS as the output port for individual LED matrix rows/cols
DEFINE DISPLAY_BUFFER_START as the starting RAM address for display data
DEFINE LIGHT_BUFFER_START as the starting RAM address for light states


; Main
;
; Description:       System entry point. Initializes hardware and starts the test loop.
;
; Operation:         Sets up the stack pointer, initializes I/O ports and timers, 
;                    clears the display, enables interrupts, and passes control 
;                    to the provided DisplayTest routine.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R16
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
; Registers Changed: R16, SP
;
Main:
 INCLUDE FILES

 INIT Stack Pointer to top of RAM
 CALL InitPorts
 CALL InitDisplayTimer
 CALL ClearDisplay
 
 CALL DisplayTest  ; Provided in hw3test.asm, contains the loop