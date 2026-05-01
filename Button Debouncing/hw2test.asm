;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW2TEST                                  ;
;                            Homework #2 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the sensor functions forHomework #2.
;                   It sets up the stack and calls the homework test function.
;
; Input:            User presses of the switches (sensors) are stored in
;                   memory.
; Output:           None.
;
; User Interface:   No real user interface.  The user inputs switch presses
;                   and that data along with the status function output is
;                   written to memory.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      Only the last (at least) 128 switch inputs are stored.
;
; Revision History:
;    5/17/19  Glen George               initial revision
;    4/30/25  Glen George               changed function calls to match the
;                                          pinball machine controller board
;    4/30/25  Glen George               updated comments
;    4/28/26  Glen George               updated comments




;set the device
;.device  ATMEGA64




;get the definitions for the device
.include  "m64def.inc"

;include all the .inc files since all .asm files are needed here (no linker)
.include "symbols.inc"





.cseg




;setup the vector area

.org    $0000

        JMP     Start                   ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        JMP     Timer0_ISR              ;timer 0 compare match
        JMP     PC                      ;timer 0 overflow
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compare match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready




; start of the actual program

Start:                                  ;start the CPU after a reset
        LDI     R16, LOW(TopOfStack)    ;initialize the stack pointer
        OUT     SPL, R16
        LDI     R16, HIGH(TopOfStack)
        OUT     SPH, R16


        ;call any initialization functions
		RCALL InitVariables
		RCALL InitPorts
		RCALL InitTimer0
		SEI


        RCALL   SensorTest              ;do the sensor tests
        RJMP    Start                   ;shouldn't return, but if it does, restart




; SensorTest
;
; Description:       This procedure tests the sensor functions for Homework #2
;                    (HaveSensor and GetSensor).  It alternates calls to the
;                    two functions, filling SensorBuf with the data it
;                    receives.  If the functions are working properly the
;                    buffer should be filled with debounced sensor codes
;                    alternating with 0xFF.  The function does not test that
;                    GetSensor properly blocks.  The function never returns.
;
; Operation:         The function first initializes the buffer by filling it
;                    with 0x55.  It then loops calling HaveSensor and GetSensor
;                    to test these functions.  First GetSensor is called
;                    checking HaveSensor first and the returned sensor code is
;                    put in the buffer.  Next HaveSensor is called.  If there
;                    is no sensor available (there should not be since
;                    GetSensor was just called), 0xFF is written to the buffer.
;                    Next GetSensor is called without waiting for a sensor to
;                    be activated to check that it does wait for a new sensor
;                    activation.  The returned sensor code is written to the
;                    buffer.  Finally HaveSensor is called again and 0xFF is
;                    written to the buffer if there is no sensor available.
;                    Then all of this is repeated in an infinite loop.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R4 - index into SensorBuf
; Shared Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R4, R16, R17, Y (YH | YL)
; Stack Depth:       at least 3 bytes
;
; Author:            Glen George
; Last Modified:     April 30, 2025
;
; Special Notes:     The buffer (SensorBuf) must be 256 bytes long since the
;                    index is incremented and allowed to wrap at 255.

SensorTest:

STClearBuffer:                  ;first clear the buffer
        LDI     YL, LOW(SensorBuf)      ;get the start of the buffer
        LDI     YH, HIGH(SensorBuf)
        LDI     R17, 0x55       ;will fill buffer with 55 to start
        CLR     R4              ;initialize the loop counter

STClearBufferLoop:              ;loop clearing the buffer
        ST      Y+, R17         ;initialize one byte of the buffer
        INC     R4              ;update the loop index
        BRNE    STClearBufferLoop       ;and loop until fill 256 bytes

        CLR     R4              ;initialize the buffer index (again)


SensorTestLoop:                 ;loop testing the functions

STCheckGetSensor1:              ;first call to GetSensor uses HaveSensor
        PUSH    R4              ;save the buffer index

STWaitLoop:                     ;loop until there is an activated sensor
        RCALL   HaveSensor
        BREQ    STWaitLoop      ;wait for there to be a sensor activations

        RCALL   GetSensor       ;sensor is available - get it
        POP     R4              ;get buffer index back
        RCALL   StoreBuff       ;store sensor code in the buffer

STCheckHaveSensor1:             ;now check that HaveSensor is working
        PUSH    R4              ;check if a sensor is still available (don't
        RCALL   HaveSensor      ;   trash buffer index)
        POP     R4

        BRNE    STSkipFFwrite1  ;if there is no sensor available
        LDI     R16, 0xFF       ;   write FF to buffer
        RCALL   StoreBuff       ;store 0xFF in the buffer
STSkipFFwrite1:
        ;RJMP   STCheckGetSensor2       ;do second test of GetSensor


STCheckGetSensor2:              ;second call to GetSensor does not use HaveSensor
        PUSH    R4              ;save the buffer index
        RCALL   GetSensor       ;should wait for an activated sensor
        POP     R4              ;get buffer index back
        RCALL   StoreBuff       ;store sensor code in the buffer

STCheckHaveSensor2:             ;now check that HaveSensor is working again
        PUSH    R4              ;check if a sensor activation is still
        RCALL   HaveSensor      ;   available (don't trash buffer index)
        POP     R4

        BRNE    STSkipFFwrite2  ;if there is no sensor activation
        LDI     R16, 0xFF       ;   write FF to buffer
        RCALL   StoreBuff       ;store 0xFF in the buffer
STSkipFFwrite2:


        RJMP    SensorTestLoop  ;and keep looping forever

        RET                     ;should never get here




; StoreBuff
;
; Description:       This procedure stores the byte passed in R16 at the
;                    offset in the SensorBuf buffer passed in R4.  The offset
;                    is updated and the new offset is returned in R4.
;
; Operation:         The Y register is loaded with the buffer address.  The
;                    passed offset is then added to this address and the
;                    passed byte is stored at this location.  The passed
;                    offset is then incremented and returned.
;
; Arguments:         R4  - offset in SensorBuf at which to write the passed
;                          byte.
;                    R16 - byte to write to the buffer at the passed offset.
; Return Value:      R4  - offset of the next location in the buffer.
;
; Local Variables:   Y - pointer into buffer.
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
; Registers Changed: flags, R4, R17, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     April 30, 2025

StoreBuff:

        LDI     YL, LOW(SensorBuf)      ;get buffer location to store sensor at
        LDI     YH, HIGH(SensorBuf)

        LDI     R17, 0          ;for carry propagation
        ADD     YL, R4          ;add the passed offset
        ADC     YH, R17

        STD     Y + 0, R16      ;store the passed byte in the buffer

        INC     R4              ;update the buffer offset, wrapping at 256


        RET                     ;all done, return




;the data segment


.dseg


; buffer in which to store sensor activations (length must be 256)
SensorBuf:      .BYTE   256


; the stack - 128 bytes
                .BYTE   127
TopOfStack:     .BYTE   1               ;top of the stack




; since don't have a linker, include all the .asm files

.include "init.asm"
.include "sensors.asm"
