; FunctionName: MainLoop
; Description:  The primary execution loop for the pinball game. Handles up to 4 players, 
;               dedicated setup states, actuator toggling via specific buttons, and dynamic turn wrapping.
;
; Operation:    Enters a pre-game boot state to allow player count selection. 
;               Once started, clears unused displays and loops to process sensor events. 
;               Actuator buttons directly trigger hardware and add score. 
;               Alternates turns based on the ActivePlayers count.
;
; Arguments:    None
; Return Value: None should run indefinitly
; Local Var:    CurrentSensorData (R16), ActuatorIndex (R17)
; Shared Var:   None
; Global Var:   Player_Scores (Array of 4x 16-bit), CurrentPlayer (8-bit), 
;               CurrentBall (8-bit), ActivePlayers (8-bit), GameState (8-bit), HighScore (16-bit)
; Input:        Debounced sensor codes via GetSensor(), High score from EEROM
; Output:       7-segment displays via DisplayHex(), sounds via PlayNote(), 
;               actuators via SetActuator(), EEROM saves
;
; Error Handle: Ignores undefined sensor codes. Limits player count to max 4.
; Algorithms:   State machine with separate Pre-Game and Active-Game loops.
; Data Structs: Array indexing for dynamic player score updates.
;
; Regs Changed: R16, R17, R18, R28, R29, Status Register
; Author:       Aaditya Bhat
; Last Edited:  June 6th, 2026


MainLoop:
    ; initializaiton
    RCALL InitHardware

    ; get the high score frmo eerom
    SET EEROM_Address = HIGH_SCORE_ADDR
    SET Buffer_Pointer = HighScore_Variable
    RCALL ReadEEROM(2, EEROM_Address, Buffer_Pointer)

BootState:
    ; rst the pre-game variables
    SET ActivePlayers = 1
    RCALL ClearDisplay()
    RCALL DisplayHex(ActivePlayers, 1)

PlayerSelectLoop:
    ; wait for button presses to add players or start the game  
    RCALL GetSensor()  
    
    COMPARE R16 with SENSOR_SELECT_PLAYERS
    IF EQUAL THEN
        INCREMENT ActivePlayers
        IF ActivePlayers > 4 THEN SET ActivePlayers = 1
        RCALL DisplayHex(ActivePlayers, 1)
        JMP PlayerSelectLoop
    ENDIF
    
    COMPARE R16 with SENSOR_START_GAME
    IF EQUAL THEN JMP StartGame
    
    JMP PlayerSelectLoop  

StartGame:
    ; init game variables for the active players
    SET Player_Scores[1..4] = 0
    SET CurrentPlayer = 1
    SET CurrentBall = 1
    SET GameState = PLAYING
    
    RCALL ClearDisplay() 
    
    ; output 0 to the displays of active players
    SET LoopCounter = 1
InitDisplaysLoop:
    ; loop through and output 0 to only the active players displays
    RCALL DisplayHex(0, LoopCounter)
    INCREMENT LoopCounter
    IF LoopCounter <= ActivePlayers THEN JMP InitDisplaysLoop
    
    RCALL PlayNote(GAME_START_TONE)

GameLoop:
    ; main polling loop to check game over state and wait for next sensor input
    IF GameState == GAME_OVER THEN JMP HandleGameOver

    ; event polling
    RCALL GetSensor()
    
    ; game controls
    COMPARE R16 with SENSOR_RESET
    IF EQUAL THEN JMP BootState
    
    COMPARE R16 with SENSOR_TILT
    IF EQUAL THEN JMP HandleTilt
    
    COMPARE R16 with SENSOR_BALL_OUT
    IF EQUAL THEN JMP HandleBallOut
    
    ; actuator buttons
    IF R16 >= SENSOR_ACTUATOR_MIN AND R16 <= SENSOR_ACTUATOR_MAX THEN
        SET ActuatorIndex = R16 - SENSOR_ACTUATOR_MIN
        
        RCALL SetActuator(ActuatorIndex, TRUE)
        RCALL PlayNote(ACTUATOR_TONE)
        
        ADD 50 to Player_Scores[CurrentPlayer]
        RCALL DisplayHex(Player_Scores[CurrentPlayer], CurrentPlayer)
        
        RCALL SetActuator(ActuatorIndex, FALSE) 
        JMP GameLoop
    ENDIF
    
    ; scoring sensors
    IF R16 >= SENSOR_SCORE_MIN AND R16 <= SENSOR_SCORE_MAX THEN
    ; add whatever non-zero score for gameplay
        ADD 10 to Player_Scores[CurrentPlayer]
        
        RCALL DisplayHex(Player_Scores[CurrentPlayer], CurrentPlayer)
        RCALL PlayNote(SCORE_TONE)
        
        JMP GameLoop
    ENDIF

    ; ignore anything outside these categories
    JMP GameLoop

HandleTilt:
    ; play the tilt sound and end their turn
    RCALL PlayNote(TILT_TONE)
    JMP AdvanceTurn

HandleBallOut:
    ; play ball out sound and move on
    RCALL PlayNote(BALL_OUT_TONE)
    JMP AdvanceTurn

AdvanceTurn:
    ; move to the next player, wrap around, and increment the ball if needed
    INCREMENT CurrentPlayer
    
    IF CurrentPlayer > ActivePlayers THEN
        SET CurrentPlayer = 1
        INCREMENT CurrentBall
    ENDIF
    
    IF CurrentBall > 5 THEN
        SET GameState = GAME_OVER
    ENDIF
    
    JMP GameLoop

HandleGameOver:
    ; play the game over tune and setup high score check
    RCALL PlayNote(GAME_OVER_TONE)
    
    SET MaxCurrentScore = 0
    SET LoopCounter = 1

FindMaxScoreLoop:
    ; loop through all active players to find the highest score this game
    IF Player_Scores[LoopCounter] > MaxCurrentScore THEN
        SET MaxCurrentScore = Player_Scores[LoopCounter]
    ENDIF
    INCREMENT LoopCounter
    IF LoopCounter <= ActivePlayers THEN JMP FindMaxScoreLoop

    ; write to eerom if it beats the all-time high score
    IF MaxCurrentScore > HighScore THEN
        SET HighScore = MaxCurrentScore
        RCALL WriteEEROM(2, HIGH_SCORE_ADDR, HighScore_Variable)
    ENDIF
    
WaitForReset:
    ; wait in an infinite loop until the reset button is pressed
    RCALL GetSensor()
    COMPARE R16 with SENSOR_RESET
    IF EQUAL THEN JMP BootState
    JMP WaitForReset