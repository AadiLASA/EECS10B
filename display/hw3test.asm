;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #3.  The function makes a
; number of calls to the display functions to test them.  The functions
; included are:
;    DisplayTest - test the homework display functions
;
; Revision History:
;    4/29/19  Glen George               initial revision
;    5/18/23  Glen George               updated for Hexer game
;    5/18/24  Glen George               updated for Balance game
;    5/11/25  Glen George               updated for pinball machine controller
;    5/15/26  Glen George               updated for new version of pinball
;                                       machine controller




;get the definitions for the device
;.include  "m64def.inc"
; local include files
;    none




.cseg




; DisplayTest
;
; Description:       This procedure tests the display functions.  It first
;                    turns on some LEDs and segments and then clears the
;                    display by calling ClearDisplay.  Next it loops
;                    displaying patterns on the light/actuator LEDs using the
;                    DisplayLight function.  Following this it loops sending
;                    values to the DisplayHex function.  To validate the code
;                    the display must be checked for the appropriate patterns
;                    being displayed.  The function never returns, when the
;                    aforementioned patterns have finished, it repeats them.
;
; Operation:         The arguments to call each function with are stored in
;                    tables.  The function loops through the tables making the
;                    appropriate display code calls.  Delays are done after
;                    most calls so the display can be examined.
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
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18, R19, R20, R21, Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       unknown (at least 4 bytes)
;
; Author:            Glen George
; Last Modified:     May 15, 2026

DisplayTest:

        LDI     R16, 0                  ;first turn on some lights/actuators
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 1
        LDI     R17, 0x01
        RCALL   DisplayLight
        LDI     R16, 62
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 63
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 64
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 65
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 126
        LDI     R17, 0x55
        RCALL   DisplayLight
        LDI     R16, 127
        LDI     R17, 0xFF
        RCALL   DisplayLight
        LDI     R16, 0x88               ;now turn on all segments for player 1
        LDI     R17, 0x88
        LDI     R18, 1
        RCALL   DisplayHex
        LDI     R16, 0x88               ;now turn on all segments for player 2
        LDI     R17, 0x88
        LDI     R18, 2
        RCALL   DisplayHex
        LDI     R16, 0x88               ;now turn on all segments for player 3
        LDI     R17, 0x88
        LDI     R18, 3
        RCALL   DisplayHex
        LDI     R16, 0x88               ;now turn on all segments for player 4
        LDI     R17, 0x88
        LDI     R18, 4
        RCALL   DisplayHex
        LDI     R16, 100                ;and delay a bit
        RCALL   Delay16
        RCALL   ClearDisplay            ;now clear the display
        LDI     R16, 100                ;and delay a bit
        RCALL   Delay16


TestLights:                             ;do the DisplayLight tests
        LDI     ZL, LOW(2 * TestLTab)   ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestLTab)  ;   DisplayLight test table

TestLightsLoop:

        LPM     R16, Z+                 ;get the DisplayLights arguments
        LPM     R17, Z+                 ;   from the table

        PUSH    ZL                      ;save registers around function call
        PUSH    ZH
        RCALL   DisplayLight            ;call the function
        POP     ZH                      ;restore the registers
        POP     ZL

        LDI     R16, 20                 ;delay 200 ms between calls
        RCALL   Delay16                 ;and do the delay

        LDI     R20, HIGH(2 * EndTestLTab)      ;setup for end check
        CPI     ZL, LOW(2 * EndTestLTab)        ;check if at end of table
        CPC     ZH, R20
        BRNE    TestLightsLoop          ;and keep looping if not done
        ;BREQ   TestDisplayHex          ;otherwise test DisplayHex function


TestDisplayHex:                         ;do the DisplayHex tests
        LDI     ZL, LOW(2 * TestHexTab) ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestHexTab);   DisplayHex test table

TestDisplayHexLoop:

        LPM     R16, Z+                 ;get DisplayHex argument from the table
        LPM     R17, Z+
        LPM     R18, Z+

        PUSH    ZL                      ;save registers around DisplayHex call
        PUSH    ZH
        RCALL   DisplayHex              ;call the function
        POP     ZH
        POP     ZL

        LPM     R16, Z                  ;get the time delay from the table
        RCALL   Delay16                 ;and do the delay
        LPM     R16, Z+                 ;do twice the delay
        RCALL   Delay16

        LDI     R20, HIGH(2 * EndTestHexTab)    ;setup for end check
        CPI     ZL, LOW(2 * EndTestHexTab)      ;check if at end of table
        CPC     ZH, R20
        BRNE    TestDisplayHexLoop      ;and keep looping if not done
        ;BREQ   DoneDisplayTests        ;otherwise done with display tests


DoneDisplayTests:                       ;have done all the tests
	    RCALL	ClearDisplay		;clear displays before starting over
        RJMP    DisplayTest             ;start over and loop forever


        RET                             ;should never get here




; Delay16
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units (assuming no interrupt overhead).
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


; TestLTab
;
; Description:      This table contains the values of the arguments for
;                   testing the DisplayLight function.  Each entry consists
;                   of the LED number to change and the new value for the LED
;                   (TRUE/FALSE) pattern displayed.
;
; Author:           Glen George
; Last Modified:    May 15, 2026

TestLTab:
               ;Arguments (LED number and LED on/off)
        .DB       0, 0xFF,   1, 0x80,   2, 0x01,   3, 0xFF  ;turn on LEDs
        .DB       4, 0xFF,   5, 0x08,   6, 0x10,   7, 0xFF  ;   in sequence
        .DB       8, 0xFF,   9, 0x08,  10, 0x10,  11, 0xFF
        .DB      12, 0xFF,  13, 0xFF,  14, 0xFF,  15, 0xFF
        .DB      16, 0xFF,  17, 0xFF,  18, 0xFF,  19, 0xFF
        .DB      20, 0xFF,  21, 0xFF,  22, 0xFF,  23, 0xFF
        .DB      24, 0xFF,  25, 0xFF,  26, 0xFF,  27, 0xFF
        .DB      28, 0xFF,  29, 0xFF,  30, 0xFF,  31, 0xFF
        .DB      32, 0xFF,  33, 0xFF,  34, 0xFF,  35, 0xFF
        .DB      36, 0xFF,  37, 0xFF,  38, 0xFF,  39, 0xFF
        .DB      40, 0x01,  41, 0x01,  42, 0x01,  43, 0x01
        .DB      44, 0x01,  45, 0x01,  46, 0x01,  47, 0x01
        .DB      48, 0x01,  49, 0x01,  50, 0x01,  51, 0x01
        .DB      52, 0x01,  53, 0x01,  54, 0x01,  55, 0x01
        .DB      56, 0x01,  57, 0x01,  58, 0x01,  59, 0x01
        .DB      60, 0x01,  61, 0x01,  62, 0x01,  63, 0x01
        .DB      64, 0xFF,  65, 0xFF,  66, 0xFF,  67, 0xFF
        .DB      68, 0xFF,  69, 0xFF,  70, 0xFF,  71, 0xFF
        .DB      72, 0xFF,  73, 0xFF,  74, 0xFF,  75, 0xFF
        .DB      76, 0xFF,  77, 0xFF,  78, 0xFF,  79, 0xFF
        .DB      80, 0x01,  81, 0x01,  82, 0x01,  83, 0x01
        .DB      84, 0x01,  85, 0x01,  86, 0x01,  87, 0x01
        .DB      88, 0x01,  89, 0x01,  90, 0x01,  91, 0x01
        .DB      92, 0x01,  93, 0x01,  94, 0x01,  95, 0x01
        .DB      96, 0x01,  97, 0x01,  98, 0x01,  99, 0x01
        .DB     100, 0x01, 101, 0x01, 102, 0x01, 103, 0x01
        .DB     104, 0xFF, 105, 0xFF, 106, 0xFF, 107, 0xFF
        .DB     108, 0xFF, 109, 0xFF, 110, 0xFF, 111, 0xFF
        .DB     112, 0xFF, 113, 0xFF, 114, 0xFF, 115, 0xFF
        .DB     116, 0xFF, 117, 0xFF, 118, 0xFF, 119, 0xFF
        .DB     120, 0x01, 121, 0x01, 122, 0x01, 123, 0x01
        .DB     124, 0x01, 125, 0x01, 126, 0x01, 127, 0x01

        .DB      95, 0x00,  96, 0x00,  94, 0x00,  97, 0x00  ;turn off LEDs
        .DB      93, 0x00,  98, 0x00,  92, 0x00,  99, 0x00  ;   from center
        .DB      91, 0x00, 100, 0x00,  90, 0x00, 101, 0x00  ;   for each display
        .DB      89, 0x00, 102, 0x00,  88, 0x00, 103, 0x00
        .DB      87, 0x00, 104, 0x00,  86, 0x00, 105, 0x00
        .DB      85, 0x00, 106, 0x00,  84, 0x00, 107, 0x00
        .DB      83, 0x00, 108, 0x00,  82, 0x00, 109, 0x00
        .DB      81, 0x00, 110, 0x00,  80, 0x00, 111, 0x00
        .DB      79, 0x00, 112, 0x00,  78, 0x00, 113, 0x00
        .DB      77, 0x00, 114, 0x00,  76, 0x00, 115, 0x00
        .DB      75, 0x00, 116, 0x00,  74, 0x00, 117, 0x00
        .DB      73, 0x00, 118, 0x00,  72, 0x00, 119, 0x00
        .DB      71, 0x00, 120, 0x00,  70, 0x00, 121, 0x00
        .DB      69, 0x00, 122, 0x00,  68, 0x00, 123, 0x00
        .DB      67, 0x00, 124, 0x00,  66, 0x00, 125, 0x00
        .DB      65, 0x00, 126, 0x00,  64, 0x00, 127, 0x00
        .DB      31, 0x00,  32, 0x00,  30, 0x00,  33, 0x00
        .DB      29, 0x00,  34, 0x00,  28, 0x00,  35, 0x00
        .DB      27, 0x00,  36, 0x00,  26, 0x00,  37, 0x00
        .DB      25, 0x00,  38, 0x00,  24, 0x00,  39, 0x00
        .DB      23, 0x00,  40, 0x00,  22, 0x00,  41, 0x00
        .DB      21, 0x00,  42, 0x00,  20, 0x00,  43, 0x00
        .DB      19, 0x00,  44, 0x00,  18, 0x00,  45, 0x00
        .DB      17, 0x00,  46, 0x00,  16, 0x00,  47, 0x00
        .DB      15, 0x00,  48, 0x00,  14, 0x00,  49, 0x00
        .DB      13, 0x00,  50, 0x00,  12, 0x00,  51, 0x00
        .DB      11, 0x00,  52, 0x00,  10, 0x00,  53, 0x00
        .DB       9, 0x00,  54, 0x00,   8, 0x00,  55, 0x00
        .DB       7, 0x00,  56, 0x00,   6, 0x00,  57, 0x00
        .DB       5, 0x00,  58, 0x00,   4, 0x00,  59, 0x00
        .DB       3, 0x00,  60, 0x00,   2, 0x00,  61, 0x00
        .DB       1, 0x00,  62, 0x00,   0, 0x00,  63, 0x00

        .DB     128, 0xFF, 177, 0xFF, 255, 0xFF             ;some bad arguments

        .DB       0, 0xFF,   1, 0xFF,   8, 0xFF,   2, 0xFF  ;fill both displays
        .DB       9, 0x0F,  16, 0xFF,   3, 0xFF,  10, 0xFF  ;   diagonally
        .DB      17, 0xFF,  24, 0xFF,   4, 0xEF,  11, 0xFF
        .DB      18, 0xFF,  25, 0xEE,  32, 0xFF,   5, 0xFF
        .DB      12, 0xFF,  19, 0xFF,  26, 0xFF,  33, 0xFF
        .DB      40, 0x0F,   6, 0xEF,  13, 0xFF,  20, 0xFF
        .DB      27, 0xFF,  34, 0xFF,  41, 0xFF,  48, 0xFE
        .DB       7, 0xFF,  14, 0xFF,  21, 0xFF,  28, 0xFF
        .DB      35, 0xFF,  42, 0xFF,  49, 0xFF,  56, 0xFF
        .DB      15, 0xFF,  22, 0xFF,  29, 0xFF,  36, 0xFF
        .DB      43, 0xFF,  50, 0xFF,  57, 0xFF,  23, 0xFF
        .DB      30, 0xFF,  37, 0xFF,  44, 0xFF,  51, 0xFF
        .DB      58, 0xFF,  31, 0xFF,  38, 0xFF,  45, 0xFF
        .DB      52, 0xFF,  59, 0xFF,  39, 0xFF,  46, 0xFF
        .DB      53, 0xFF,  60, 0xFF,  47, 0xFF,  54, 0xFF
        .DB      61, 0xFF,  55, 0xFF,  62, 0xFF,  63, 0xFF
        .DB      71, 0x01,  70, 0x12,  79, 0xFF,  69, 0xF0
        .DB      78, 0x02,  87, 0x14,  68, 0x46,  77, 0x80
        .DB      86, 0x03,  95, 0x16,  67, 0x4A,  76, 0x88
        .DB      85, 0x04,  94, 0x18, 103, 0x4E,  66, 0x91
        .DB      75, 0x05,  84, 0x1A,  93, 0x53, 102, 0x99
        .DB     111, 0x06,  65, 0x1C,  74, 0x57,  83, 0xA2
        .DB      92, 0x07, 101, 0x1E, 110, 0x5B, 119, 0xAA
        .DB      64, 0x08,  73, 0x20,  82, 0x5F,  91, 0xB3
        .DB     100, 0x09, 109, 0x24, 118, 0x64, 127, 0xBB
        .DB      72, 0x0A,  81, 0x28,  90, 0x68,  99, 0xC4
        .DB     108, 0x0B, 117, 0x2C, 126, 0x6C,  80, 0xCC
        .DB      89, 0x0C,  98, 0x31, 107, 0x70, 116, 0xD5
        .DB     125, 0x0D,  88, 0x35,  97, 0x71, 106, 0xDD
        .DB     115, 0x0E, 124, 0x39,  96, 0x75, 105, 0xE6
        .DB     114, 0x0F, 123, 0x3D, 104, 0x79, 113, 0xEE
        .DB     122, 0x10, 112, 0x42, 121, 0x7D, 120, 0xF7

        .DB      64, 0x00,  65, 0x00,  72, 0x00,  66, 0x00  ;clear both
        .DB      73, 0x00,  80, 0x00,  67, 0x00,  74, 0x00  ;    displays
        .DB      81, 0x00,  88, 0x00,  68, 0x00,  75, 0x00  ;    diagonally
        .DB      82, 0x00,  89, 0x00,  96, 0x00,  69, 0x00
        .DB      76, 0x00,  83, 0x00,  90, 0x00,  97, 0x00
        .DB     104, 0x00,  70, 0x00,  77, 0x00,  84, 0x00
        .DB      91, 0x00,  98, 0x00, 105, 0x00, 112, 0x00
        .DB      71, 0x00,  78, 0x00,  85, 0x00,  92, 0x00
        .DB      99, 0x00, 106, 0x00, 113, 0x00, 120, 0x00
        .DB      79, 0x00,  86, 0x00,  93, 0x00, 100, 0x00
        .DB     107, 0x00, 114, 0x00, 121, 0x00,  87, 0x00
        .DB      94, 0x00, 101, 0x00, 108, 0x00, 115, 0x00
        .DB     122, 0x00,  95, 0x00, 102, 0x00, 109, 0x00
        .DB     116, 0x00, 123, 0x00, 103, 0x00, 110, 0x00
        .DB     117, 0x00, 124, 0x00, 111, 0x00, 118, 0x00
        .DB     125, 0x00, 119, 0x00, 126, 0x00, 127, 0x00
        .DB       7, 0x00,   6, 0x00,  15, 0x00,   5, 0x00
        .DB      14, 0x00,  23, 0x00,   4, 0x00,  13, 0x00
        .DB      22, 0x00,  31, 0x00,   3, 0x00,  12, 0x00
        .DB      21, 0x00,  30, 0x00,  39, 0x00,   2, 0x00
        .DB      11, 0x00,  20, 0x00,  29, 0x00,  38, 0x00
        .DB      47, 0x00,   1, 0x00,  10, 0x00,  19, 0x00
        .DB      28, 0x00,  37, 0x00,  46, 0x00,  55, 0x00
        .DB       0, 0x00,   9, 0x00,  18, 0x00,  27, 0x00
        .DB      36, 0x00,  45, 0x00,  54, 0x00,  63, 0x00
        .DB       8, 0x00,  17, 0x00,  26, 0x00,  35, 0x00
        .DB      44, 0x00,  53, 0x00,  62, 0x00,  16, 0x00
        .DB      25, 0x00,  34, 0x00,  43, 0x00,  52, 0x00
        .DB      61, 0x00,  24, 0x00,  33, 0x00,  42, 0x00
        .DB      51, 0x00,  60, 0x00,  32, 0x00,  41, 0x00
        .DB      50, 0x00,  59, 0x00,  40, 0x00,  49, 0x00
        .DB      58, 0x00,  48, 0x00,  57, 0x00,  56, 0x00

        .DB       0, 0xFF,   9, 0xFF,  18, 0xFF,  27, 0xFF  ;leave a single
        .DB      36, 0xFF,  45, 0xFF,  54, 0xFF,  63, 0xFF  ;   diagonal on
        .DB      71, 0xFF,  78, 0xFF,  85, 0xFF,  92, 0xFF  ;   each display
        .DB      99, 0xFF, 106, 0xFF, 113, 0xFF, 120, 0xFF

EndTestLTab:




; TestHexTab
;
; Description:      This table contains the argument values for testing the
;                   DisplayHex function.  Each entry consists of the value to
;                   display, the player number, and the time delay to leave the
;                   pattern displayed.
;
; Author:           Glen George
; Last Modified:    May 15, 2026

TestHexTab:
               ;Value         Player   Delay (10 ms)
        .DB     0x88, 0x88,   1,       150      ;all segments on
        .DB     0x88, 0x88,   2,       150
        .DB     0x88, 0x88,   3,       150
        .DB     0x88, 0x88,   4,       150
        .DB     0x00, 0x00,   4,       150      ;zero for all players
        .DB     0x00, 0x00,   3,       150
        .DB     0x00, 0x00,   2,       150
        .DB     0x00, 0x00,   1,       150
        .DB     0x34, 0x12,   1,       150      ;1234 5678 9ABC DEF0
        .DB     0x78, 0x56,   2,       150
        .DB     0xBC, 0x9A,   3,       150
        .DB     0xF0, 0xDE,   4,       150
        .DB     0xFF, 0xFF,   4,       150      ;max for all players
        .DB     0xFF, 0xFF,   3,       150
        .DB     0xFF, 0xFF,   2,       150
        .DB     0xFF, 0xFF,   1,       150
        .DB     0x00, 0x00,   0,       10       ;illegal values
        .DB     0x00, 0x00,   5,       10
        .DB     0x00, 0x00,   255,     10
        .DB     0x00, 0x00,   90,      10
        .DB     0x34, 0xD7,   1,       150      ;random values
        .DB     0x34, 0xD7,   4,       150
        .DB     0xEF, 0xBE,   3,       150
        .DB     0xAD, 0xDE,   2,       150

EndTestHexTab:
