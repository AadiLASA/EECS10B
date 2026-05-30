;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW4TEST                                  ;
;                            Homework #4 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #4.  The function makes a
; number of calls to the PlayNote, SetActuator, ReadEEROM, and WriteEEROM
; functions to test them.  The public functions included are:
;    EEROMActuatorSoundTest - test the homework sound and EEROM functions
;
; The local functions included are:
;    Delay16 - delays R16 * 80000 clocks
;
; Revision History:
;    5/31/18  Glen George               initial revision
;    4/21/22  Glen George               added constants for number of tests
;    4/21/22  Glen George               changed test data to match final EEROM
;                                          values
;    5/31/25  Glen George               updated to include tests for
;                                          WriteEEROM
;    5/28/26  Glen George               updated to include tests for
;                                          SetActuator
;    5/30/26  Glen George               fixed error in computation of address
;                                          for EEROM write




; chip definitions
;.include  "m64def.inc"

; local include files
;    none




.cseg




; EEROMActuatorSoundTest
;
; Description:       This procedure tests the sound, actuator, and EEROM
;                    functions.  It first loops calling the PlayNote function.
;                    Following this it makes a number of calls to SetActuator
;                    function.  Finally it makes a number of calls to
;                    WriteEEROM and ReadEEROM.  A tone is output while testing
;                    these last two functions.  The tone increases in pitch as
;                    the tests are done.  If a test fails a low tone is output
;                    and the Player 2 LEDs display zeros.  If all tests pass,
;                    the Twilight Zone theme is played and the Player 1 LEDs
;                    display 5's. The function never returns.
;
; Operation:         The arguments to call each function with are stored in
;                    tables.  The function loops through the tables making the
;                    appropriate function calls.  Delays are done after calls
;                    to PlayNote so the sound can be heard.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20         - test counter.
;                    Z (ZH | ZL) - test table pointer.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Tones are output and either the Player 1 or Player 2 LEDs
;                    are turned on (indirectly).
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18, R19, R20, X (XH | XL), Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       unknown (at least 7 bytes)
;
; Author:            Glen George
; Last Modified:     May 30, 2026

EEROMActuatorSoundTest:

TestSetup:
                                        ;copy EEROM data from code to data
        LDI     ZL, LOW(2 * EEROMDataTab)       ;start at the beginning of the
        LDI     ZH, HIGH(2 * EEROMDataTab)      ;   EEROM data table
        LDI     XL, LOW(CompareBuffer)          ;buffer with expected data
        LDI     XH, HIGH(CompareBuffer)
        LDI     R16, 128                ;128 bytes to transfer

CopyLoop:
        LPM     R0, Z+                  ;get EEROM data
        ST      X+, R0                  ;store in compare buffer
        DEC     R16                     ;update loop counter
        BRNE    CopyLoop                ;and loop while still have bytes to copy
        ;BREQ   PlayNoteTests           ;otherwise start the tests


PlayNoteTests:                          ;do some tests of PlayNote only
        LDI     ZL, LOW(2 * TestPNTab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestPNTab) ;   PlayNote test table
        LDI     R20, TestPNTab_TEST_CNT ;get the number of tests

PlayNoteTestLoop:
        LPM     R16, Z+                 ;get the PlayNote argument from the
        LPM     R17, Z+                 ;   table

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 200                ;delay for 2 seconds
        RCALL   Delay16                 ;and do the delay

        DEC     R20                     ;update loop counter
        BRNE    PlayNoteTestLoop        ;and keep looping if not done
        ;BREQ   ActuatorTests           ;otherwise test SetActuator function


ActuatorTests:                          ;do the SetActuator tests
        LDI	R16, 0			;turn off any note being played
        LDI	R17, 0
	RCALL	PlayNote
        LDI     ZL, LOW(2 * TestSATab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestSATab) ;   SetActuator test table

ActuatorTestLoop:

        LPM     R16, Z+                 ;get the SetActuator arguments
        LPM     R17, Z+                 ;   from the table

        PUSH    ZL                      ;save registers around function call
        PUSH    ZH
        RCALL   SetActuator             ;call the function
        POP     ZH                      ;restore the registers
        POP     ZL

        LDI     R16, 20                 ;delay 200 ms between calls
        RCALL   Delay16                 ;and do the delay

        LDI     R20, HIGH(2 * EndTestSATab)     ;setup for end check
        CPI     ZL, LOW(2 * EndTestSATab)       ;check if at end of table
        CPC     ZH, R20
        BRNE    ActuatorTestLoop        ;and keep looping if not done
        ;BREQ   EEROMTests              ;otherwise test EEROM functions


EEROMTests:                             ;do the SetCursor tests
        LDI     ZL, LOW(2 * TestROMTab) ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestROMTab);   EEROM test table
        LDI     R20, TestROMTab_TEST_CNT;get the number of tests

EEROMTestLoop:

        LPM     R16, Z+                 ;get sound to play while testing EEROM
        LPM     R17, Z+                 ;   functions

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

	LPM	R16, Z+			;get EEROM operation to perform
	TST	R16
	BREQ	ReadEEROMTest		;do a read operation
	;BRNE   WriteEEROMTest		;do a write operation

WriteEEROMTest:				;want to try writing the EEROM
        LPM     R16, Z+                 ;now get the WriteEEROM arguments from
        LPM     R17, Z+                 ;   the table
        LDI     YL, LOW(CompareBuffer)  ;buffer with the data to write
        LDI     YH, HIGH(CompareBuffer)

        LDI     R18, 0			;compute the address of the data to
        ADD     YL, R17                 ;   write
        ADC     YH, R18

        PUSH    ZL                      ;save registers around WriteEEROM call
        PUSH    ZH
        PUSH    R20
        RCALL   WriteEEROM              ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL
	RJMP    EEROMTestDone		;and done with the test

ReadEEROMTest:				;want to try reading the EEROM
        LPM     R16, Z+                 ;now get the ReadEEROM arguments from
        LPM     R17, Z+                 ;   the table
        LDI     YL, LOW(ReadBuffer)     ;buffer to read data into
        LDI     YH, HIGH(ReadBuffer)

        PUSH    ZL                      ;save registers around ReadEEROM call
        PUSH    ZH
        PUSH    R20
        PUSH    R17
        PUSH    R16
        RCALL   ReadEEROM               ;call the function
        POP     R16                     ;restore the registers
        POP     R17
        POP     R20
        POP     ZH
        POP     ZL

CheckData:                              ;check the data read
        LDI     YL, LOW(ReadBuffer)     ;buffer with data read
        LDI     YH, HIGH(ReadBuffer)
        LDI     XL, LOW(CompareBuffer)  ;buffer with expected data
        LDI     XH, HIGH(CompareBuffer)

        ADD     XL, R17                 ;get the pointer to data actually read
        LDI     R17, 0
        ADC     XH, R17

CheckDataLoop:                          ;now loop checking the bytes
        LD      R18, Y+                 ;get read data
        LD      R19, X+                 ;get compare data
        CP      R18, R19                ;check if the same
        BRNE    PlayFailure             ;if not, failure
        DEC     R16                     ;otherwise decrement byte count
        BRNE    CheckDataLoop           ;and check all the data

        LDI     R16, 35                 ;read worked - let the note play for
        RCALL   Delay16                 ;   350 milliseconds
	;RJMP   EEROMTestDone		;and done with the test

EEROMTestDone:				;done with this test
	ADIW	Z, 1			;skip padding byte
        DEC     R20                     ;update loop counter
        BRNE    EEROMTestLoop           ;and keep looping if not done
        ;BREQ   PlaySuccess             ;if done - everything worked, play success tune


PlaySuccess:                            ;play the tune indicating success

        LDI     R16, 0x55               ;put 5555 on Player 2 LEDs
        LDI     R17, 0x55
        LDI     R18, 1
        RCALL	DisplayHex

        LDI     ZL, LOW(2 * SuccessTab) ;start at the beginning of the
        LDI     ZH, HIGH(2 * SuccessTab);   special success tune table
        LDI     R20, SuccessTab_LEN     ;get the number of notes

PlaySuccessLoop:
        LPM     R16, Z+                 ;get the PlayNote argument from the
        LPM     R17, Z+                 ;   table

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 35                 ;each note is 350ms
        RCALL   Delay16                 ;and do the delay

        DEC     R20                     ;update loop counter
        BRNE    PlaySuccessLoop         ;and keep looping if not done
        BREQ    DoneEEROMActuatorSoundTests  ;otherwise done with tests


PlayFailure:                            ;play the tune indicating failure
        LDI     R16, LOW(261)           ;play middle C
        LDI     R17, HIGH(261)
        RCALL   PlayNote

        LDI     R16, 0x00               ;put 0000 on Player 2 LEDs
        LDI     R17, 0x00
        LDI     R18, 2
        RCALL	DisplayHex

        LDI     R16, 50                 ;1/2 second note
        RCALL   Delay16

        LDI     R16, LOW(82)            ;play E2
        LDI     R17, HIGH(82)
        RCALL   PlayNote

        LDI     R16, 100                ;1 second note
        RCALL   Delay16

        ;BREQ   DoneEEROMActuatorSoundTests  ;and done with tests


DoneEEROMActuatorSoundTests:            ;have done all the tests
        LDI     R16, 0                  ;turn off the sound
        LDI     R17, 0
        RCALL   PlayNote

        RJMP    PC                      ;and tests are done


        RET                             ;should never get here




; Delay16
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units.
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         R16 - 1/80000 the number of CPU clocks to delay.
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
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 6, 2018

Delay16:

Delay16Loop:                            ;outer loop runs R16 times
        LDI     YL, LOW(20000)          ;inner loop is 4 clocks
        LDI     YH, HIGH(20000)         ;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:                       ;do the delay
        SBIW    Y, 1
        BRNE    Delay16InnerLoop

        DEC     R16                     ;count outer loop iterations
        BRNE    Delay16Loop


DoneDelay16:                            ;done with the delay loop - return
        RET




; Test Tables


; TestPNTab
;
; Description:      This table contains the values of arguments for testing
;                   the PlayNote function.  Each entry is just a 16-bit
;                   frequency for the note to play.
;
; Author:           Glen George
; Last Modified:    April 8, 2022

TestPNTab:

        .DW     261                     ;middle C
        .DW     440                     ;middle A
        .DW     1000
        .DW     0                       ;turn off output for a bit
        .DW     2000
        .DW     50
        .DW     4000
        .DW     100

        ;size of the table (number of tests)
        .EQU    TestPNTab_TEST_CNT = PC - TestPNTab




; TestSATab
;
; Description:      This table contains the values of arguments for testing
;                   the SetActuator function.  Each entry is just two 8-bit
;                   values, the actuator number to set and whether to turn it
;                   on or off.
;
; Author:           Glen George
; Last Modified:    May 27, 2026

TestSATab:
        .DB     0, 0xFF, 1, 0xFF, 2, 0xFF, 3, 0xFF	;turn on in order
        .DB     4, 0xFF, 5, 0xFF, 6, 0xFF, 7, 0xFF

        .DB     4, 0,    3, 0,    5, 0,    2, 0		;turn off from middle
        .DB     6, 0,    1, 0,    7, 0,    0, 0		;  outward

        .DB     0, 0xFF, 7, 0xEE, 1, 1,    6, 0xF0	;turn on from outside
        .DB     2, 0x80, 5, 0x7F, 3, 2,    4, 4 	;  inward

        .DB     7, 0,    6, 0,    5, 0,    4, 0		;turn off from bottom
        .DB     3, 0,    2, 0,    1, 0,    0, 0		;  to top

        .DB     8, 0xFF, 0xFF, 0, 11, 0xFF		;illegal arguments

        .DB     0, 0xFE, 1, 1,    0, 0,    2, 0xFF	;walking 1
        .DB     1, 0,    3, 8,    2, 0,    4, 16
        .DB     3, 0,    5, 32,   4, 0,    6, 0xFF
        .DB     5, 0,    7, 7,    6, 0,    7, 0

        .DW     100

EndTestSATab:




; TestROMTab
;
; Description:      This table contains the values of arguments for testing
;                   the ReadEEROM and WriteEEROM functions.  Each entry
;                   consists of the note frequency to play during the test,
;                   the function to perform (zero for Read, non-zero for
;                   Write), the number of bytes to read or write, and the
;                   address at which to read or write the bytes.  There is
;                   also a padding byte to keep the tests word aligned.
;
; Author:           Glen George
; Last Modified:    May 29, 2025

TestROMTab:
        .DW     146
        .DB     1, 2, 0, 0	;write one word at beginning of EEROM

        ;size of each entry in test table
        .EQU    TestROMTab_ENTRY_SIZE = PC - TestROMTab

        .DW     180
        .DB     0, 2, 0, 0	;read the word written

        .DW     220
        .DB     1, 100, 2, 0	;write 50 more words
        .DW     260
        .DB     0, 10, 6, 0	;do some reads
        .DW     294
        .DB     0, 3, 98, 0	;read odd bytes at even address
        .DW     370
        .DB     0, 4, 67, 0	;read even bytes at odd address
        .DW     440
        .DB     0, 21, 33, 0	;read odd bytes at odd address
        .DW     523
        .DB     1, 24, 99, 0	;write even bytes at odd address
        .DW     622
        .DB     0, 25, 98, 0	;check that the previous write worked
        .DW     784
        .DB     1, 1, 127, 0	;write last byte
        .DW     1000
        .DB     0, 1, 127, 0	;read last byte

        ;size of the table (number of tests)
        .EQU    TestROMTab_TEST_CNT = (PC - TestROMTab) / TestROMTab_ENTRY_SIZE




; SuccessTab
;
; Description:      This table contains the tune to play upon successful
;                   completion of the tests.  Each entry is the frequency of a
;                   note to play.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

SuccessTab:

        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784

        ;size of the table (number of notes)
        .EQU    SuccessTab_LEN = PC - SuccessTab




; EEROMDataTab
;
; Description:      Table of data to that should be read from the EEROM.
;                   There are 1024 bits (64 16-bit words).
;
; Author:           Glen George
; Last Modified:    May 28, 2025

EEROMDataTab:

        .DW     0xD4D2, 0xB42B, 0xFFFF, 0xFFFF
        .DW     0x7749, 0x4382, 0x2532, 0x70C8
        .DW     0xB4D2, 0x964B, 0xAC69, 0x2D53
        .DW     0x952E, 0x80BD, 0xD486, 0x2131
        .DW     0x6A6C, 0x9695, 0xA569, 0x539A
        .DW     0xFFFF, 0x1598, 0x4282, 0x9CD8
        .DW     0x939A, 0x6A65, 0xCA95, 0x6C35
        .DW     0x31B0, 0x6B8A, 0x6059, 0x838A
        .DW     0x336A, 0x4BD4, 0x2DB4, 0x95CA
        .DW     0x1313, 0x0A09, 0x3345, 0x43D8
        .DW     0x9A4D, 0x6CA5, 0x9953, 0xB266
        .DW     0x7AF0, 0x284D, 0x480C, 0x2160
        .DW     0x2D2B, 0x0000, 0x3665, 0xD2C9
        .DW     0xFA12, 0x73C0, 0x0000, 0x0000
        .DW     0x9A2D, 0x9365, 0xA55A, 0xD46A
        .DW     0x60C2, 0x6302, 0x5B0C, 0x043A




;the data segment


.dseg


; buffer for data read from the EEROM
ReadBuffer:     .BYTE   128             ;EEROM is 1024 bits

; buffer containing the expected data from the EEROM
CompareBuffer:  .BYTE   128             ;EEROM is 1024 bits