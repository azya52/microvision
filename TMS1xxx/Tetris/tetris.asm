// Tetris for MB Microvision (TMS1100)
// by Alexander Zakharyan
// 2019
// Translate using tmsasm.lua by Paul Robson

//tones
toneA1 = 15
toneG1 = 14
toneF1 = 13
toneE1 = 12
toneD1 = 11
toneC1 = 8
toneB0 = 7
toneA0 = 5
toneG0 = 4
toneF0 = 2
toneE0 = 1
toneNone = 0

toneLength5 = 15
toneLength4 = 7
toneLength3 = 5
toneLength2 = 3
toneLength1 = 1

//R
rSpeaker0 = 0
rSpeaker1 = 1
rPaddle = 2
rDataClock = 7
rLatchPulse = 6

rKeyCol0 = 8
rKeyCol1 = 9
rKeyCol2 = 10

//X0
x0SpeakerCounter = 0 //mast be equal rSpeaker0
//2 corrupt in redrawLCD_outRows
x0Rows0to3 = 3	// mast be equal rDataClock-4
x0Rows4to7 = 4 // mast be equal rDataClock-3
x0Rows8to11 = 5 // mast be equal rDataClock-2
x0Rows12to15 = 6 // mast be equal rDataClock-1
x0RowDraw = 7//mast be equal rDataClock
x0SpeakerTone = 9
x0ToneLength = 10
x0PartId = 11
x0ToneId = 12
x0ShiftTemp = 14 //for main screen draw
x0RowTemp = 15 //for main screen draw

//X1
//0..7 used for store piece
//
x1RowTemp = 8
x1RandomNum = 10
x1NextPiece = 11
x1DropDelay = 12
x1KeyMask = 14
x1CurrentPiece = 15 //mast be 15

//X2
//0..8 used for backup piece
x2FullLines = 10
x2RowTemp = 11
x2LevelH = 12
x2LevelL = 13
x2ScoreH = 14
x2ScoreL = 15

	lcall clearScreenAndScore
	comc
	lbr drawMicroVision

drawTetrisExit
	call setNextPiece
	
newGame	
	lcall genRandomNum
	lcall redrawLCD
	knez
	br newGame
	lcall clearScreenAndScore
	
newPiece
	ldx 1
	tcy x1KeyMask
	tcmiy 3 //0011

setNextPiece
	tcy x1RandomNum
	tma
	tcy x1NextPiece
	xma
	retn
	lcall loadPiece
	
checkGameOver
	lcall checkCollision
	ldp gameOverAnimation
	cpaiz
	br gameOverAnimation
	
	lbr updateRightSide
updateRightSideExit
	
updatePiece
	ldx 2
	tcy x2LevelH
	tma
	ldx 1
	tcy x1DropDelay
	tam
	lcall drawPiece
	
mainLoop
	lcall redrawLCD
	tcy x0SpeakerTone
	tcmiy 0
	lcall genRandomNum
	
	lbr keyScan
keyScanExit

	tcy x1DropDelay
	imac
	br drop
	tam
	
	lcall redrawLCD
	br mainLoop
	
drop
	lcall backupPieceAndClear
	lcall dropPieceAndCheckCollision
	dan
	br updatePiece
	lcall restorePieceAndDraw
	lbr checkFullLines

	
	page 0
keyScan
	tcy rKeyCol0
	call keyScan_getKeys
	a14aac
	br keyScan_rotatePressed
	rbit 0
	
keyScan_scanMove
	tbit1 3
	br keyScan_skipMove
	sbit 3
	
	call keyScan_getKeysCol1
	a14aac
	br keyScan_rightPressed
	
	tcy rKeyCol2
	call keyScan_getKeys
	a14aac
	br keyScan_leftPressed
	
keyScan_skipMove
	rbit 3
	
keyScan_getKeysCol1
	tcy rKeyCol1
keyScan_getKeys
	setr
	tka
	rstr
	tcy x1KeyMask
	retn
	
	a14aac
	iac
	br keyScan_dropPressed
	rbit 1
	br keyScan_end
	
keyScan_dropPressed
	tbit1 1
	br keyScan_end
	lbr drop
	
keyScan_rotatePressed
	tbit1 0
	br keyScan_ScanMove
	sbit 0
	lcall backupPieceAndClear
	lbr rotatePiece

keyScan_rightPressed
	lcall backupPieceAndClear
keyScan_moveRightPiece
	tcy 7
keyScan_moveRightPiece_loop
	dyn
	dman
	tamdyn
	br keyScan_moveRightPiece_loop
	br keyScan_checkCollision

keyScan_leftPressed
	lcall backupPieceAndClear
keyScan_moveLeftPiece
	tcy 7
keyScan_moveLeftPiece_loop
	dyn
	imac
	tamdyn
	br keyScan_moveLeftPiece_loop
	
keyScan_checkCollision
	lcall checkCollision
	dan
	br keyScan_noCollision
	lcall restorePieceAndDraw
	br keyScan_end
keyScan_noCollision
	lcall drawPiece
keyScan_end
	lbr keyScanExit	
	
	
	page 1
	
checkFullLines_down_loop
	ldx 4
	call checkFullLines_moveDown
	ldx 5
checkFullLines_moveDown
	tma
	tcmiy 0
	tamdyn
	retn
checkFullLines_down_loopStart
	dyn
	br checkFullLines_down_loop
	
checkFullLines
	tcy 15
checkFullLines_loop
	ldx 4
	imac
	dan
	br checkFullLines_loopNext
	ldx 5
	mnea
	br checkFullLines_loopNext
	ldx 2
	tya
	tcy x2RowTemp
	tamdyn
	imac
	tamza
	
	br checkFullLines_shift_loopStart
checkFullLines_shift_loop
	tam
	ldx 5
	dan
checkFullLines_shift_loopRightNib
	iac
	tam
	amaac
	br checkFullLines_shift_loopRightNib
	
	cpaiz
checkFullLines_shift_loopStart
	lcall redrawLCDandPlayA
	lcall redrawLCD
	ldx 2
	tcy x2RowTemp
	tmy
checkFullLines_shift_loopLeftNib
	ldx 4
	tma
	amaac
	br checkFullLines_shift_loop
	
	br checkFullLines_down_loopStart
checkFullLines_loopNext
	dyn
	br checkFullLines_loop

	ldx 2
	tcy x2FullLines
	tma
	amaac
	tcmiy 0
	tcy x2ScoreL
	ldp bcdAddAtoM
	dan
	call bcdAddAtoM
	
	//Boom
	tcy 6
	lcall redrawLCDandPlayY
	tcy 4
	lcall redrawLCDandPlayY
	
	lbr newPiece
	
	
	page 2
	
dropPieceAndCheckCollision
	tcy 7
dropPiece_loop
	imac
	tamdyn
	dyn
	br dropPiece_loop
	
checkCollision
	tcy x1RowTemp
	cla
	a6aac
checkCollision_loop
	tam
	tay
	tma
	iyc
	tmy
	
	ldx 5
	a12aac
	br checkCollision_rightNib
checkCollision_leftNib
	a12aac //a-4
	ldx 4
checkCollision_rightNib
	a5aac
	br checkCollision_checkX3
	iac
	br checkCollision_checkX2
	iac
	br checkCollision_checkX1
	iac
	br checkCollision_checkX0
	cla
	br checkCollision_isCollision
checkCollision_checkX3
	tbit1 3
	br checkCollision_isCollision
	br checkCollision_CheckY
checkCollision_checkX2
	tbit1 2
	br checkCollision_isCollision
	br checkCollision_CheckY
checkCollision_checkX1
	tbit1 1
	br checkCollision_isCollision
	br checkCollision_CheckY
checkCollision_checkX0
	tbit1 0
	br checkCollision_isCollision
	
checkCollision_CheckY
	ldx 1
	ynec 0
	br checkCollisionNext
	tcy 1
	tmy
	ynec 1
	br checkCollision_isCollision
	
checkCollisionNext
	tcy x1RowTemp
	tma
	a14aac  //a-2
	br checkCollision_loop
	//a>0, return without collision
checkCollision_isCollision
	retn
	
bcdAddAtoMMore15
	a6aac
bcdAddAtoMMore9
	tamza
	iac
	dyn
bcdAddAtoM
	amaac
	br bcdAddAtoMMore15
	a6aac
	br bcdAddAtoMMore9
	a10aac
	tam
	retn


	page 3
	
restorePieceAndDraw
	tcy 7
restorePiece_loop
	ldx 2
	tma
	ldx 1
	tamdyn
	br restorePiece_loop
	br drawPiece

backupPieceAndClear
	tcy 7
backupPiece_loop
	ldx 1
	tma
	ldx 2
	tamdyn
	br backupPiece_loop

clearPiece
	ldx 1
drawPiece
	tcy x1RowTemp
	cla
	a6aac
drawPiece_loop
	tam
	tay
	tma
	iyc
	tmy
	
	ldx 5
	a12aac
	br drawPiece_rightNib
drawPiece_leftNib
	a12aac //a-4
	ldx 4
drawPiece_rightNib
	a5aac
	br drawPiece_check3
	iac
	br drawPiece_check2
	iac
	br drawPiece_check1
	a2aac
	tbit1 0
	br drawPieceSub
	br drawPieceAdd
drawPiece_check2
	a4aac
	tbit1 2
	br drawPieceSub
	br drawPieceAdd
drawPiece_check1
	a2aac
	tbit1 1
	br drawPieceSub
	br drawPieceAdd
drawPiece_check3
	a8aac
	
drawPieceAdd
	amaac
	tam
	br drawPieceNext
drawPieceSub
	saman
	tam
	
drawPieceNext
	ldx 1
	tcy x1RowTemp
	tma
	a14aac
	br drawPiece_loop
	retn
			
genRandomNum
	ldx 1
	tcy x1RandomNum
	dman
	br genRandomNum_end
	a7aac
genRandomNum_end
	tam
	retn
	

	page 4
	
rotatePiece
	tcy x1CurrentPiece
	imac
	br rotatePiece_toFirst
	a9aac
	br rotatePiece_end
	a3aac
	br rotatePiece_andSetNextToFirst
	br rotatePiece_90
	
rotatePiece_andSetNextToFirst
	tcmiy 15
	br rotatePiece_90
	
rotatePiece_toFirst
	tcmiy 5
	call rotatePiece_90
	call rotatePiece_90
	
rotatePiece_90
	//y = y0-x0+x'
	//x = x0-y'+y0
	cla
	a6aac
rotatePiece_90_loop
	tcy x1RowTemp
	tam	
	
	tcy 0
	tma
	tcy 1
	saman
	tcy x1RowTemp
	tmy
	amaac
	iyc
	xma
	tcy 0
	saman
	tcy 1
	amaac
	tcy x1RowTemp
	tmy
	tam
	
	tya
	a14aac
	br rotatePiece_90_loop
	retn

	ldx 0
	tcy x0SpeakerTone
	tcmiy 15
	ldx 1
	
rotatePiece_end
	lbr keyScan_checkCollision
	

clearScreenAndScore
	tcy 15
	cla	
clearScreenAndScore_loop
	ldx 2
	tam
	ldx 4
	tam
	ldx 5
	tam
	ldx 6
	tam
	ldx 7
	tamdyn
	br clearScreenAndScore_loop
	retn
	
	
	page 5
	
loadPiece //new
	tcy x1CurrentPiece
	tamiyc //tcy 0
	tcmiy 15 //-1
	tcmiy 1
	tcmiy 0
	tcmiy 1
	tcmiy 15 //-1
	tcmiy 2
	tcmiy 0
	tcmiy 2
	a10aac
	br loadPiece_pieceO
	a2aac
	br loadPiece_pieceSorZ
	tcy 4
	tcmiy 14 //-2
	tcmiy 1
	iac
	br loadPiece_pieceI
	iac
loadPiece_pieceL   //A=0
loadPiece_pieceT   //A=15 //-1
loadPiece_pieceJ   //A=14 //-2
	tam
	retn
loadPiece_pieceSorZ
	tcy 2
	dan
	br loadPiece_pieceS
	tcy 6
loadPiece_pieceS
	tcmiy 14 //-2
	retn
loadPiece_pieceI
	tcmiy 1
	tcmiy 1
loadPiece_pieceO
	retn
	
	
gameOverAnimation
	lcall setAllKeyCols
	tcy x0RowTemp
	//cla //A is zero after cpaiz
	dan
gameOverAnimation_loop	
	tam
	ldx 4
	tay
	tcmiy 15
	ldx 5
	tay
	tcmiy 15
	
	lcall redrawLCDandPlayA
gameOverAnimationWaitKey
	lcall redrawLCD
	tcy x0RowTemp
	dman
	br gameOverAnimation_loop
	
	ldp newGame
	knez
	br newGame
	lbr gameOverAnimationWaitKey	
	
	page 6
	
updateRightSide
drawNextPiece
	tcy x1NextPiece
	tma
	ldx 6
	tcy 13
	tcmiy 0
	tcmiy 0
	ldx 7
	tcy 13
	tcmiy 12
	a10aac
	br drawNextPiece_O
	tcmiy 8
	iac
	br drawNextPiece_S
	ldx 6
	tcy 13
	tcmiy 1
	ldx 7
	a2aac
	br drawNextPiece_ZorI
	iac
	br drawNextPiece_L
	iac
	br drawNextPiece_T
drawNextPiece_J
	tcmiy 4		
	br drawScores
drawNextPiece_ZorI
	tcy 13
	cpaiz
	br drawNextPiece_I
drawNextPiece_Z
	tcmiy 8
drawNextPiece_O
	tcmiy 12
	br drawScores
drawNextPiece_I
	tcmiy 14
	tcmiy 0
	br drawScores
drawNextPiece_L
	tcmiy 0
drawNextPiece_S
	ldx 6
	tcy 14
	tcmiy 1
drawNextPiece_T

drawScores
	tcy x2ScoreH
	lcall drawDigit
	tcy x2ScoreL
	lcall drawDigit
	tcy x2LevelH
	lcall drawDigit
	tcy x2LevelL
	lcall drawDigit

	lbr updateRightSideExit
	
	page 7
// draw A digit (3x5) in XY
drawDigit
	ldx 2
	tma
	iyc
	br drawDigit_y0x7
	ldx 6
	iyc
	br drawDigit_y0x6
	iyc
	br drawDigit_y6x7
	tcy 6
	br drawDigit_y6x6
drawDigit_y6x7
	tcy 6
drawDigit_y0x7
	ldx 7
drawDigit_y0x6
drawDigit_y6x6
	tcmiy 7
	tcmiy 5
	tcmiy 7
	tcmiy 5
	tcmiy 7
	dyn
	dyn
	a7aac
	br drawDigit_9
	iac
	br drawDigit_8
	dyn
	dyn
	iac
	br drawDigit_7
	a2aac
	br drawDigit_6or5
	iac
	br drawDigit_4
	a2aac
	br drawDigit_3or2
	iac
	br drawDigit_1
drawDigit_0
	iyc
	tcmiy 5
	br drawDigit_end
drawDigit_7
	tcmiy 1
	br drawDigit_7Part2
drawDigit_4
	dyn
	tcmiy 5
	iyc
	iyc
	tcmiy 1
	br drawDigit_4Part2
drawDigit_3or2
	tcmiy 1
	iyc
	dan
	br drawDigit_3Part2
drawDigit_6or5
	tcmiy 4
	dan
	br drawDigit_end
	iyc
drawDigit_4Part2
drawDigit_3Part2
drawDigit_9
	tcmiy 1
	br drawDigit_end
drawDigit_1
	dyn
	tcmiy 6
drawDigit_7Part2
	tcmiy 2
	tcmiy 2
	tcmiy 2
drawDigit_8
drawDigit_end
	retn
	
	
	page 8
	
redrawLCDandPlayY
	tya
redrawLCDandPlayA
	ldx 0
	tcy x0SpeakerTone
	tam
redrawLCD
	ldx 0
	tcy x0Rows12to15
	tcmiy 1
	dman
redrawLCD_loop
	tamdyn
	 
	rstr //reset LatchPulse
	
	tcy x0SpeakerTone
	tma
	tcy x0SpeakerCounter
	rstr
	saman
	br redrawLCD_noSpeaker
	setr
redrawLCD_noSpeaker
	tam
	
	tcy x0Rows0to3
redrawLCD_outRows
	tma
	tdo
	amaac //shift row cursor
	br redrawLCD_carry
redrawLCD_carryExit
	tamiyc
	tya
	tcy rDataClock
	rstr
	setr
	tay
	ynec rDataClock
	br redrawLCD_outRows
	
	tmy

	a8aac //A=15
	ldx 4
redrawLCD_outCols
	xma
	tdo
	xma
	ldx 0
	tcy rDataClock
	rstr
	setr
	tmy
	ldx 5
	a8aac
	br redrawLCD_outCols
	ldx 6
	a2aac
	br redrawLCD_outCols
	ldx 7
	a5aac
	br redrawLCD_outCols
	ldx 0
	
	tcy rLatchPulse
	setr
		
	tcy rDataClock
	dman
	br redrawLCD_loop  //123 ~42.3fps
	
	//reset DataClock for invert polarity on next draw
	rstr
	retn
	
redrawLCD_carry
	dyn
	tcmiy 1
	br redrawLCD_carryExit
	
	
//
//  Draw main(TETRIS) screen 
//
//

	page 9
	
getTetrisNib
	tcy 1	//start draw row
	ldx 3
	a5aac
	br getTetrisNib_0
	iac
	br getTetrisNib_1
	iac
	br getTetrisNib_2
	iac
	br getTetrisNib_3
	iac
	br getTetrisNib_4
	iac
	br getTetrisNib_5
	iac
	br getTetrisNib_6
	iac
	br getTetrisNib_7
getTetrisNib_clear
	tcmiy 0
	br getTetrisNib_end
	br getTetrisNib_clear
getTetrisNib_0
getTetrisNib_3
	tcmiy 15
	tcmiy 15
	tcmiy 10
	tcmiy 2
	tcmiy 2
	tcmiy 7
	tcmiy 7
	br getTetrisNib_end
getTetrisNib_1
getTetrisNib_4
	tcmiy 11
	tcmiy 11
	tcmiy 11
	tcmiy 3
	tcmiy 3
	tcmiy 3
	br getTetrisNib_Y3
getTetrisNib_2
	tcmiy 14
	tcmiy 0
	tcmiy 12
	tcmiy 8
	tcmiy 0
	tcmiy 14
	br getTetrisNib_7End
getTetrisNib_5
	tcmiy 14
	tcmiy 2
	tcmiy 4
	tcmiy 8
	br getTetrisNib_7Mid
getTetrisNib_6
	tcmiy 13
	tcmiy 13
	tcmiy 0
	tcmiy 12
	tcmiy 13
	tcmiy 13
	tcmiy 5
getTetrisNib_7
	tcmiy 15
	tcmiy 9
getTetrisNib_7Mid
	tcmiy 12
	tcmiy 6
getTetrisNib_Y3
	tcmiy 3
	tcmiy 15
getTetrisNib_7End
	tcmiy 15
getTetrisNib_end
	ldx 0
	retn
	
	
	page 10
	
drawByAz
	ldx 4
	tcy 10
	tcmiy 4
	tcmiy 6
	tcmiy 5
	tcmiy 6
	ldx 5
	tcy 11
	tcmiy 10
	tcmiy 6
	tcmiy 2
	tcmiy 12
	ldx 7
	tcy 10
	tcmiy 14
	tcmiy 2
	tcmiy 4
	tcmiy 8
	tcmiy 14
	ldx 6
	tcy 10
	tcmiy 4
drawByAz_part
	tcmiy 10
	tcmiy 14
	tcmiy 10
	tcmiy 10
	
setAllKeyCols
	ldx 0
	tcy rKeyCol2
setAllKeyCols_loop
	setr
	dyn
	ynec rKeyCol0
	br setAllKeyCols_loop
	retn
	
drawPUSH
	ldx 4
	tcy 10
	tcmiy 7
	tcmiy 5
	tcmiy 7
	tcmiy 4
	tcmiy 4
	ldx 5
	tcy 10
drawPUSH_repeat5
	tcmiy 5
	ynec 14
	br drawPUSH_repeat5
	tcmiy 7
	ldx 6
	tcy 10
	tcmiy 6
	tcmiy 4
	tcmiy 6
	tcmiy 2
	tcmiy 6
	ldx 7
	tcy 10
	tcmiy 10
	br drawByAz_part
	
	
	page 11
	
drawTetris
	lcall clearScreenAndScore
	lcall drawByAz
	lcall tetrisThemeInit
drawTetris_restart
	cla
	a11aac //text length + space in nibls 
	tcy x0ShiftTemp
drawTetris_loop
	tam
	lcall getTetrisNib

drawTetris_shiftLeft
	tcy x0RowTemp
	cla
	a3aac
drawTetris_shiftLeftLoopFor4X
	tam
	tcy 1
drawTetris_shiftLeftLoopForY
	cla
	ldx 3
	call drawTetris_shiftLeftLoop
	ldx 7
	call drawTetris_shiftLeftLoop
	ldx 6
	call drawTetris_shiftLeftLoop
	ldx 5
	call drawTetris_shiftLeftLoop
	ldx 4
drawTetris_shiftLeftLoop
	amaac
	br drawTetris_shiftLeftMis15
	amaac
	br drawTetris_shiftLeftCarry
	tamza
	br drawTetris_shiftLeftNoCarry
drawTetris_shiftLeftMis15
	a15aac
drawTetris_shiftLeftCarry
	tamza
	iac
drawTetris_shiftLeftNoCarry
	retn
	iyc
	ynec 8
	br drawTetris_shiftLeftLoopForY
	
	lcall genRandomNum
		
	ldp drawTetrisExit
	knez
	br drawTetrisExit
	
	lbr tetrisTheme
tetrisThemeExit
	lcall redrawLCD
	lcall redrawLCD
	lcall redrawLCD
	lcall redrawLCD
	tcy x0RowTemp
	dman
	br drawTetris_shiftLeftLoopFor4X
	
	tcy x0ShiftTemp
	dman
	br drawTetris_loop
	lcall drawPUSH
	br drawTetris_restart

	
//
//  Korabeiniky
//
//
	page 12
	
tetrisThemeInit
	tcy x0SpeakerTone
	tcmiy 0 //x0SpeakerTone
	tcmiy 5 //start melody delay //x0ToneLength
	tcmiy 0 //x0PartId
	tcmiy 15 //mToneIDX0
	retn
	
tetrisTheme
	ldx 0
	tcy x0ToneLength
	dman
	br tetrisThemeDelay
	
	//tcy x0SpeakerCounter
	//tcmiy 0
	
	tcy x0ToneId
	imac
	tam
	tcy x0SpeakerTone
	tam
	tcy x0PartId
	tma
	tcy x0SpeakerTone

	ldp tetrisThemePart8
	a9aac
	br tetrisThemePart8
	ldp tetrisThemePart7
	iac
	br tetrisThemePart7
	iac
	br tetrisThemePart6
	iac
	br tetrisThemePart5
tetrisThemeRepeat0to3
	ldp tetrisThemePart4
	iac
	br tetrisThemePart4
	ldp tetrisThemePart3
	iac
	br tetrisThemePart3
	ldp tetrisThemePart2
	iac
	br tetrisThemePart2
	iac
	br tetrisThemePart1
	lbr tetrisThemeRepeat0to3
	
tetrisThemePart3
	ldp tetrisThemeTones
	tma
	a11aac
	br tetrisThemePart3Tone6
	iac
	br tetrisThemePart3Tone5
	iac
	br tetrisThemePart3Tone4
	iac
	br tetrisThemePart3Tone3
	iac
	br tetrisThemePart3Tone2
	br tetrisThemePart3Tone1
		
tetrisThemeDelay
	tam
	mnez
	br tetrisThemeEnd
	tcy x0SpeakerTone  //pause between tones
	tcmiy 0
tetrisThemeEnd
	lbr tetrisThemeExit
	
	
	page
	
tetrisThemeTones
	
tetrisThemePart8
	tma
	a13aac
	br tetrisThemePart8Tone4
	iac
	br tetrisThemePart8Tone3
	iac
	br tetrisThemePart8Tone2
	
tetrisThemePart2Tone10
tetrisThemePart8Tone1
	tcmiy toneC1
	br tetrisThemeTonesLength2
tetrisThemePart1Tone1
tetrisThemePart2Tone9
tetrisThemePart2Tone2
tetrisThemePart8Tone2
	tcmiy toneE1
	
tetrisThemeTonesLength2
	tcmiy toneLength2
	br tetrisThemePartsEnd
	
tetrisThemePart1Tone2
tetrisThemePart1Tone6
tetrisThemePart2Tone6
	tcmiy toneB0
	br tetrisThemeTonesLength1
tetrisThemePart1Tone3
tetrisThemePart1Tone5
tetrisThemePart2Tone1
tetrisThemePart2Tone7
tetrisThemePart2Tone4
	tcmiy toneC1
	
tetrisThemeTonesLength1
	tcmiy toneLength1
	br tetrisThemePartsEnd
	
tetrisThemePart1Tone4
tetrisThemePart3Tone1
tetrisThemePart2Tone8
	tcmiy toneD1
	br tetrisThemeTonesLength2
tetrisThemePart1Tone7
tetrisThemePart2Tone11
	tcmiy toneA0
	br tetrisThemeTonesLength2
tetrisThemePart3Tone5
tetrisThemePart3Tone2
	tcmiy toneF1
	br tetrisThemeTonesLength1
tetrisThemePart3Tone4
	tcmiy toneG1
	br tetrisThemeTonesLength1
tetrisThemePart3Tone3
	tcmiy toneA1
	br tetrisThemeTonesLength2
tetrisThemePart2Tone3
	tcmiy toneD1
	br tetrisThemeTonesLength1	
tetrisThemePart2Tone5
	tcmiy toneB0
	br tetrisThemeTonesLength2
tetrisThemePart2Tone12
tetrisThemePart6Tone2
	tcmiy toneA0
	
tetrisThemeTonesLength4
	tcmiy toneLength4
	br tetrisThemePartsEnd
	
tetrisThemePart5Tone1
	tcmiy toneE1
	br tetrisThemeTonesLength4
tetrisThemePart5Tone2
tetrisThemePart6Tone1
	tcmiy toneC1
	br tetrisThemeTonesLength4
tetrisThemePart5Tone3
	tcmiy toneD1	
	br tetrisThemeTonesLength4
tetrisThemePart6Tone3
	tcmiy toneG0//7b
	br tetrisThemeTonesLength4
tetrisThemePart8Tone3
	tcmiy toneA1
	br tetrisThemeTonesLength4
	
tetrisThemePart3Tone6
	tcmiy toneE1
	tcmiy toneLength3
	br tetrisThemePrepNextPart
tetrisThemePart2Tone13
	tcmiy toneNone
	br tetrisThemePrepNextPartWithLength1
tetrisThemePart6Tone4
tetrisThemePart5Tone4
	tcmiy toneB0
	tcmiy toneLength4
	br tetrisThemePrepNextPart
tetrisThemePart8Tone4
	tcmiy toneF1 //14b
	tcmiy toneLength5
	br tetrisThemePrepFirstPart
tetrisThemePart1Tone8	
	tcmiy toneA0
tetrisThemePrepNextPartWithLength1
	tcmiy toneLength1
	
tetrisThemePrepNextPart
	imac //next part
tetrisThemePrepFirstPart
	tamiyc
	tcmiy 15 //prep x0ToneId for next part	
tetrisThemePartsEnd
	lbr tetrisThemeEnd
	
	
	page
	
tetrisThemePart1
	ldp tetrisThemeTones
	tma
	a9aac
	br tetrisThemePart1Tone8
	iac
	br tetrisThemePart1Tone7
	iac
	br tetrisThemePart1Tone6
	iac
	br tetrisThemePart1Tone5
	iac
	br tetrisThemePart1Tone4
	iac
	br tetrisThemePart1Tone3
	iac
	br tetrisThemePart1Tone2
	br tetrisThemePart1Tone1
	
tetrisThemePart4
tetrisThemePart2
	ldp tetrisThemeTones
	tma
	a4aac
	br tetrisThemePart2Tone13
	iac
	br tetrisThemePart2Tone12
	iac
	br tetrisThemePart2Tone11
	iac
	br tetrisThemePart2Tone10
	iac
	br tetrisThemePart2Tone9
	iac
	br tetrisThemePart2Tone8
	iac
	br tetrisThemePart2Tone7
	iac
	br tetrisThemePart2Tone6
	iac
	br tetrisThemePart2Tone5
	iac
	br tetrisThemePart2Tone4
	iac
	br tetrisThemePart2Tone3
	iac
	br tetrisThemePart2Tone2
	br tetrisThemePart2Tone1
	
tetrisThemePart7
tetrisThemePart5
	ldp tetrisThemeTones
	tma
	a13aac
	br tetrisThemePart5Tone4
	iac
	br tetrisThemePart5Tone3
	iac
	br tetrisThemePart5Tone2
	br tetrisThemePart5Tone1
	
tetrisThemePart6
	ldp tetrisThemeTones
	tma
	a13aac
	br tetrisThemePart6Tone4
	iac
	br tetrisThemePart6Tone3
	iac
	br tetrisThemePart6Tone2
	br tetrisThemePart6Tone1
	
		
	page 16
	
drawMicroVision
	ldx 0
	tcy x0SpeakerTone
	tcmiy 0
	tcy rKeyCol2
drawMicroVision_setAllKeyColsLoop
	setr
	dyn
	ynec rKeyCol0
	br drawMicroVision_setAllKeyColsLoop

	cla
	a11aac //text length + space in nibls 
	tcy x0ShiftTemp
drawMicroVision_loop
	tam
	lcall getMicroNib
	ldx 0
	tcy x0ShiftTemp
	tma
	lcall getVisionNib
	ldx 0
	
	
	tcy x0RowTemp
	cla
	a3aac
	lbr shiftMicroVision
shiftMicroVisionExit

	tcy x0ShiftTemp
	dman
	br drawMicroVision_loop

draw40Start
	ldx 5
	tcy 8
	tcmiy 1
draw40Start_tcmiy2
	tcmiy 2
	ynec 13
	br draw40Start_tcmiy2
	tcmiy 3
	tcmiy 1
	ldx 6
	tcy 8
	tcmiy 15
draw40Start_tcmiy13
	tcmiy 13
	ynec 0
	br draw40Start_tcmiy13
	tcy 12
	tcmiy 1
	ldx 7
	tcy 8
	tcmiy 15
	tcmiy 1
draw40Start_tcmiy6
	tcmiy 6
	ynec 15
	br draw40Start_tcmiy6
	tcmiy 8
	
	ldx 0
	tcy x0RowTemp
	cla
	a3aac
	lbr draw40
	
	
	page 17
	
shiftMicroVision
shiftMicroVision_loopFor4X
	tam
	
	tcy 6
shiftMicroVision_loopForYToLeft
	cla
	ldx 2
	call shiftMicroVision_shiftLeftLoop
	ldx 7
	call shiftMicroVision_shiftLeftLoop
	ldx 6
	call shiftMicroVision_shiftLeftLoop
	ldx 5
	call shiftMicroVision_shiftLeftLoop
	ldx 4
	call shiftMicroVision_shiftLeftLoop	
	dyn
	br shiftMicroVision_loopForYToLeft
	
	lcall redrawLCD2To13row
	lcall redrawLCD2To13row
	tcy 13
	
shiftMicroVision_loopForYToRight
	cla
	ldx 2
	call shiftMicroVision_shiftLeftLoop
	ldx 4
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	ldx 5
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	ldx 6
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	ldx 7
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
	call shiftMicroVision_shiftLeftLoop
shiftMicroVision_shiftLeftLoop
	amaac
	br shiftMicroVision_shiftLeftMis15
	amaac
	br shiftMicroVision_shiftLeftCarry
	tamza
	br shiftMicroVision_shiftLeftNoCarry
shiftMicroVision_shiftLeftMis15
	a15aac
shiftMicroVision_shiftLeftCarry
	tamza
	iac
shiftMicroVision_shiftLeftNoCarry
	retn
		
	dyn
	ynec 8
	br shiftMicroVision_loopForYToRight

	
	ldp draw40End
	knez
	br draw40End
	
	lcall redrawLCD2To13row
	
	//tcy x0RowTemp
	dman
	br shiftMicroVision_loopFor4X
	
	lbr shiftMicroVisionExit
		
		
	page 18
	
draw40
shift40loop
	tam
	
	tcy 1
shift40loop_byYloop
	ldx 4
	call shift40loop_byYldx
	ldx 5
	call shift40loop_byYldx
	ldx 6
	call shift40loop_byYldx
	sbit 1
	ldx 7
shift40loop_byYldx
	tma
	dyn
	tamiyc
	retn
	tcmiy 15
	ynec 0
	br shift40loop_byYloop
	
shift40loop_byXloop
	cla
	lcall shiftMicroVision_shiftLeftloop
	ldx 6
	lcall shiftMicroVision_shiftLeftloop
	ldx 5
	lcall shiftMicroVision_shiftLeftloop
	ldx 4
	lcall shiftMicroVision_shiftLeftloop

	ldx 7
	iyc
	ynec 15
	br shift40loop_byXloop
	
shift40loop_addShadow
	sbit 0
	dyn
	ynec 7
	br shift40loop_addShadow
	
	lcall redrawLCD2
	lcall redrawLCD2
	//tcy x0RowTemp
	dman
	br shift40loop
	
draw40WaitKeyDown
	tam
	lcall redrawLCD2
	lcall redrawLCD2
	lcall redrawLCD2
	knez
	br draw40End
	//tcy x0RowTemp
	dman
	br draw40WaitKeyDown
	
draw40End
draw40WaitKeyUp
	lcall redrawLCD2
	knez
	br draw40WaitKeyUp
	comc
	lbr drawTetris
	
	
	page
	
getMicroNib
	tcy 2	//start draw row
	ldx 2
	a5aac
	br getMicroNib_0
	iac
	br getMicroNib_1
	iac
	br getMicroNib_2
	iac
	br getMicroNib_3
	iac
	br getMicroNib_4
	iac
	br getMicroNib_5
	iac
	br getMicroNib_6
	iac
	br getMicroNib_7
getMicroNib_clear
	tcmiy 0
	br getMicroNib_end
	br getMicroNib_clear
getMicroNib_0
	tcmiy 12
	tcmiy 14
	tcmiy 13
	tcmiy 12
	br getMicroNib_0Part2
getMicroNib_1
	tcmiy 5
	tcmiy 13
	tcmiy 5
	tcmiy 5
	tcmiy 5
	retn
getMicroNib_2
	tcmiy 9
	tcmiy 11
	tcmiy 11
	tcmiy 11
	tcmiy 9
	retn
getMicroNib_3
	tcmiy 14
	tcmiy 1
	tcmiy 0
	tcmiy 1
	tcmiy 14
	retn
getMicroNib_4
	tcmiy 7
	tcmiy 6
	tcmiy 7
	br getMicroNib_4Part2
getMicroNib_5
	tcmiy 12
	tcmiy 6
	tcmiy 12
	br getMicroNib_5Part2
getMicroNib_6
	tcmiy 3
getMicroNib_4Part2
	tcmiy 6
	tcmiy 6
getMicroNib_5Part2
	tcmiy 6
	tcmiy 3
	retn
getMicroNib_7
	tcmiy 12
	tcmiy 2
	tcmiy 2
	tcmiy 2
getMicroNib_0Part2
	tcmiy 12
getMicroNib_end
	retn

	
	page
	
getVisionNib
	tcy 9	//start draw row
	ldx 2
	a5aac
	br getVisionNib_0
	iac
	br getVisionNib_1
	iac
	br getVisionNib_2
	iac
	br getVisionNib_3
	iac
	br getVisionNib_4
	iac
	br getVisionNib_5
	iac
	br getVisionNib_6
	iac
	br getVisionNib_7
getVisionNib_clear
	tcmiy 0
	br getVisionNib_end
	br getVisionNib_clear
getVisionNib_0
	tcmiy 8
	tcmiy 9
	tcmiy 10
	br getVisionNib_0Part2
getVisionNib_1
	tcmiy 12
	tcmiy 13
	tcmiy 13
	tcmiy 13
	br getVisionNib_1Part2
getVisionNib_2
	tcmiy 15
	tcmiy 1
	tcmiy 1
	tcmiy 1
	tcmiy 15
	retn
getVisionNib_3
	tcmiy 3
	tcmiy 11
	tcmiy 11
	tcmiy 11
	br getVisionNib_3Part2
getVisionNib_4
	tcmiy 7
	tcmiy 0
	tcmiy 7
	tcmiy 6
getVisionNib_3Part2
	tcmiy 3
	retn
getVisionNib_5
	tcmiy 9
	tcmiy 13
	tcmiy 13
	tcmiy 1
	tcmiy 13
	retn
getVisionNib_6
	tcmiy 10
	tcmiy 10
	tcmiy 10
	tcmiy 9
	br getVisionNib_6Part2
getVisionNib_7
	tcmiy 6
	tcmiy 6
	tcmiy 6
getVisionNib_0Part2
getVisionNib_1Part2
	tcmiy 12
getVisionNib_6Part2
	tcmiy 8
getVisionNib_end
	retn

	
	page 
redrawLCD2To13row
	ldx 0
	tcy x0Rows12to15
	tcmiy 4
	tcmiy 13
	br redrawLCD2_sart
redrawLCD2
	ldx 0
	tcy x0Rows12to15
	tcmiy 1
	tcmiy 15
redrawLCD2_sart
	tcy x0Rows0to3
	tcmiy 0
	tcmiy 0
	tcmiy 0
redrawLCD2_loop
	tcy rLatchPulse
	rstr //reset rLatchPulse
	
	tcy x0Rows0to3
redrawLCD2_outRows
	tma
	tdo
	amaac //shift row cursor
	br redrawLCD2_carry
redrawLCD2_carryExit
	tamiyc
	tya
	tcy rDataClock
	rstr
	setr
	tay
	ynec rDataClock
	br redrawLCD2_outRows
	
	tmy

	a8aac //A=15
	ldx 4
redrawLCD2_outCols
	xma
	tdo
	xma
	ldx 0
	tcy rDataClock
	rstr
	setr
	tmy
	ldx 5
	a8aac
	br redrawLCD2_outCols
	ldx 6
	a2aac
	br redrawLCD2_outCols
	ldx 7
	a5aac
	br redrawLCD2_outCols
	ldx 0
	
	tcy rLatchPulse
	setr
	
	tcy rDataClock
	dman
	tam
	
	tay
	ynec 0
	br redrawLCD2_loop
	
	tcy rDataClock
	//reset DataClock for invert polarity on next draw
	rstr
	tcy x0RowTemp
	retn
	
redrawLCD2_carry
	dyn
	tcmiy 1
	br redrawLCD2_carryExit