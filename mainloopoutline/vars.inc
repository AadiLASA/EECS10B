; Variable Declarations
; Houses all register definitions, SRAM allocations, and constant equates for the pinball machine.

; EEROM addresses to store the high score in non-volatile memory
 .equ HIGH_SCORE_ADDR       = 0x00 

; game state simple binary flags to track if we are actively playing or done
 .equ PLAYING               = 0x00
 .equ GAME_OVER             = 0x01

; game control sensors w/ specific hex codes for buttons that control the flow of the game
 .equ SENSOR_SELECT_PLAYERS = 0x01
 .equ SENSOR_START_GAME     = 0x02
 .equ SENSOR_RESET          = 0x03
 .equ SENSOR_TILT           = 0x04
 .equ SENSOR_BALL_OUT       = 0x05

; actuator sensors defining a range for the 8 actuator buttons
 .equ SENSOR_ACTUATOR_MIN   = 0x10
 .equ SENSOR_ACTUATOR_MAX   = 0x17

; scoring sensors defining a range for general playfield targets/bumpers
 .equ SENSOR_SCORE_MIN      = 0x20
 .equ SENSOR_SCORE_MAX      = 0x3F

; audio freqs hz constants for the PlayNote function so it's easy to tune the sounds later
 .equ GAME_START_TONE       = 880
 .equ ACTUATOR_TONE         = 440
 .equ SCORE_TONE            = 523
 .equ TILT_TONE             = 150
 .equ BALL_OUT_TONE         = 200
 .equ GAME_OVER_TONE        = 100

; data segment

 .dseg
 .org SRAM_START
; 8 bytes total 4 players and 2 bytes each for a 16-bit score
 Player_Scores: .byte 8      
; tracks whose turn it is 1->4
 CurrentPlayer: .byte 1
; tracks which ball the current player is on 1->5
 CurrentBall:   .byte 1
; tracks how many people are playing this match 1->4
 ActivePlayers: .byte 1
; tracks if the game state is PLAYING or GAME_OVER
 GameState:     .byte 1
; 2 bytes to hold the all-time high score loaded from EEROM
 HighScore_Variable: .byte 2