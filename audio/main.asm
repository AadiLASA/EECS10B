; ==============================================================================
; main.asm
; Description: Main execution loop and test invocation.
; ==============================================================================
.include "pinball_defs.inc"

; Main
; ------------------------------------------------------------------------------
; Description:       System entry point. Initializes stack, calls initialization 
;                    routines, and runs the EEROMSoundTest.
; Operation:         Sets up the Stack Pointer, calls SysInit, and calls the 
;                    external EEROMSoundTest. Enters an infinite loop upon return.
; Arguments:         None.
; Return Value:      None.
; Local Variables:   None.
; Shared Variables:  None.
; Registers Changed: SPH, SPL, R16.

Main:
    Initialize Stack Pointer/Vector Table
    CALL InitFunctions
    CALL HW4TEST.asm test functions 
    
