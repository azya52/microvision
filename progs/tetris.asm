	;r3 - y pos, start on 32
	;r4 - current pice
	;r5 - drop delay
	;r6 - shift
	;r7 - keyboard scan mask
	
	aScores EQU #24
	aLevel EQU #25
	aRandom EQU #26
	aNextPiceId EQU #27
	aPice EQU #28
	dropDelay EQU #20
	tickerDelay EQU #4
	microvisionScrollDelay EQU #3
	
	clr a
	mov r1, #aRandom
	mov @r1, a
	
	call scrollMicrovision
	call initGame

mainLoop:
	call updateDropDelay
  mainLoop_updateLCD:
	call updateLCD	
	call genRandom
	call updateLCD
	call scanKeyboard  
	call updateLCD
	djnz r5, mainLoop_updateLCD
	call dropPice
	jmp mainLoop
	
updateDropDelay:
	mov r1, #aScores
	mov a, @r1
	swap a
	cpl a
	anl a, #00001111b
	mov r5, a
	ret
	
scanKeyboard:
	mov a, #00111111b	;scan row 1
	outl P1, a
	in a, P1
	
	mov r0, a
	orl a, r7
	xch a, r0
	rrc a
	rl a
	orl a, #00000110b
	xrl a, r7
	rr a
	cpl c
	rlc a
	mov r7, a 
	mov a, r0
	
	rrc a
	jnc keyRotate 
	rrc a
	jnc keyRight
	rrc a
	jnc keyLeft
		
	mov a, #11101111b	;scan row 3
	outl P1, a
	in a, P1
	rrc a
	rrc a
	mov a, r7
	jc scanKeyboard_notkey
	rlc a
	jnc dropPice
	ret
  scanKeyboard_notkey:
	anl a, #01111111b
	mov r7, a
	ret
  
dropPice:
	call clearPice
	inc r3
	call checkCollision
	jz drawPice
	djnz r3, dropPice_dummy
  dropPice_dummy:
	call drawPice
	call playBop
	call checkFullLines
	jmp newPice
	
clearPice:
drawPice:
	mov a, r3
	mov r0, a
	mov r1, #aPice
	call drawPice_loop
	inc r0
	inc r1
drawPice_loop:
	mov a, @r1
	xrl a, @r0
	mov @r0, a
	inc r0
	inc r1
	mov a, @r1
	xrl a, @r0
	mov @r0, a
	ret
	
checkCollision:
	mov a, r3
	mov r0, a
	mov r1, #aPice
	mov r2, #4
  checkCollision_loop0: 
	mov a, r0	;check out pice below board
	add a, #-48 ;check for a = 48
	mov a, @r1
	jc checkCollision_end
	anl a, @r0
	jnz checkCollision_end
	inc r0
	inc r1
	djnz r2, checkCollision_loop0
  checkCollision_end:
	ret

keyRight:
	call clearPice
moveRight:
	call incShiftAndPrepare
	jz drawPice
	jmp moveLeft

keyLeft:
	call clearPice
moveLeft:
	call decShiftAndPrepare
	jz drawPice
	jmp moveRight
	
keyRotate:
	call clearPice
	mov a, r4
	swap a
	add a, #01000000b
  keyRotate_hz:
	swap a
	mov r4, a
	mov a, r6
	mov T, a
	call prepPice
	jz drawPice
	mov a, T
	mov r6, a
	mov a, r4
	swap a
	cpl a
	add a, #01000000b
	cpl a
	jmp keyRotate_hz
	
winGame:	
	call youWinTextShow
		
initGame:
	mov r1, #aScores
	clr a
	mov @r1, a
	inc r1
	mov @r1, a
	call randomNextPice
	call clearScreen
	call drawDigits
newPice:
	call updateDropDelay
	mov r7, #10000001b
	mov r3, #32
	mov r6, #0
	mov r1, #aNextPiceId
	mov a, @r1
	mov r4, a
	call randomNextPice
	call prepPice
	jz drawPice
	call drawGameOver
	jmp initGame
	
checkFullLines:
	call drawClearAnimation
	mov a, r4
	jz addScores
	mov r5, #4
  clearAndScore_loop0:    
	call clearPice
    mov r6, #8
  clearAndScore_loop1:
    call updateLCD
    djnz r6, clearAndScore_loop1
	djnz r5, clearAndScore_loop0
	
	mov a, r4
	mov r1, a
  checkFullLines_loop0:
	mov r0, #32
	mov a, #0FFh 
  checkFullLines_loop1:
	cpl a
	xch a, @r0
	inc r0
	cpl a
	jnz checkFullLines_loop1	
	djnz r1, checkFullLines_loop0
	
	mov a, r4
	rl a
	dec a
addScores:
	mov r1, #aScores
	add a, @r1
	da a
	mov @r1, a
	clr a
	inc r1
	addc a, @r1
	da a
	mov @r1, a
	jc winGame
	jmp drawDigits
	
org 256
f1: db #00000000b, #00011000b, #00011000b, #00000000b
	db #00000000b, #00011000b, #00011000b, #00000000b
	db #00000000b, #00011000b, #00011000b, #00000000b
	db #00000000b, #00011000b, #00011000b, #00000000b
f2: db #00000000b, #00111100b, #00000000b, #00000000b
	db #00001000b, #00001000b, #00001000b, #00001000b
	db #00000000b, #00111100b, #00000000b, #00000000b
	db #00001000b, #00001000b, #00001000b, #00001000b
f3: db #00000000b, #00001100b, #00011000b, #00000000b
	db #00010000b, #00011000b, #00001000b, #00000000b
	db #00000000b, #00001100b, #00011000b, #00000000b
	db #00010000b, #00011000b, #00001000b, #00000000b
f4: db #00000000b, #00011000b, #00001100b, #00000000b
	db #00000100b, #00001100b, #00001000b, #00000000b
	db #00000000b, #00011000b, #00001100b, #00000000b
	db #00000100b, #00001100b, #00001000b, #00000000b
f5: db #00000000b, #00011100b, #00010000b, #00000000b
	db #00001000b, #00001000b, #00001100b, #00000000b
	db #00000100b, #00011100b, #00000000b, #00000000b
	db #00011000b, #00001000b, #00001000b, #00000000b
f6: db #00000000b, #00011100b, #00000100b, #00000000b
	db #00001100b, #00001000b, #00001000b, #00000000b
	db #00010000b, #00011100b, #00000000b, #00000000b
	db #00001000b, #00001000b, #00011000b, #00000000b
f7: db #00000000b, #00011100b, #00001000b, #00000000b
	db #00001000b, #00001100b, #00001000b, #00000000b
	db #00001000b, #00011100b, #00000000b, #00000000b
	db #00001000b, #00011000b, #00001000b, #00000000b
	
incShiftAndPrepare:
	inc r6
	jmp prepPice
decShiftAndPrepare:
	djnz r6, prepPice
prepPice:
	mov r1, #aPice
	clr a
  prepPice_loop0:
	add a, r4
	movp a, @a
	mov @r1, a
	mov r2, a
	mov a, r6
	jz prepPice_zeroShift
	rlc a
	jc prepPice_shiftLeft
	rrc a
	xch a, r2
  prepPice_RRC:
	rrc a
	djnz r2, prepPice_RRC
	jc decShiftAndPrepare
	jmp prepPice_shiftEnd
  prepPice_shiftLeft:
    rrc a
	cpl a
	inc a
	xch a, r2
  prepPice_RLC:
	rlc a
	djnz r2, prepPice_RLC
	jc incShiftAndPrepare
  prepPice_shiftEnd:
	mov @r1, a
  prepPice_zeroShift:
	inc r1
	mov a, r1
	anl a, #00000011b
	jnz prepPice_loop0
	jmp checkCollision
	
randomNextPice:
	mov r1, #aRandom
	mov a, @r1
	swap a
	inc r1
	mov @r1, a
	
drawNextPice:
	;mov r1, #aNextPiceId
	mov r0, #61
	mov a, @r1
	inc a
	mov @r0, a
	movp a, @a      
	xch a, @r0
	inc a
	movp a, @a
	inc r0
	mov @r0, a

genRandom:
	mov r1, #aRandom
	mov a, @r1
	jnz genRandom_else0
	mov a, #7
  genRandom_else0:
	dec a
	mov @r1, a
	ret

updateLCD:
	mov r0, #32
	mov r1, #48
	mov r2, #10000000b
	clr a
	mov T, a
	clr c

  updateLCD_lineLoop:		  
    ;row
	mov a, r2   
	call updateLCD_out2port
	mov a, r2
	rrc A
	xch A, r2
	call updateLCD_SwapAndOut2Port
	mov a, T
	call updateLCD_out2port
	mov a, T
	call updateLCD_SwapAndOut2Port
	mov A, T
	rrc A
	mov T, A
	
	;col
	mov a, @r0
	call updateLCD_out2port
	mov a, @r0
	call updateLCD_SwapAndOut2Port
	inc r0
	
	mov a, @r1
	call updateLCD_out2port
	mov a, @r1
	call updateLCD_SwapAndOut2Port
	inc r1
	
	inc a
	outl bus, a
	clr a
	outl bus, a
	inc a
	
	jnc updateLCD_lineLoop
		 
	outl bus, a
	ret

  updateLCD_SwapAndOut2Port:
	swap a
  updateLCD_Out2Port:
	anl a, #11110000b
	outl bus, a
	orl a, #00000010b
	outl bus, a
	ret
	
anyKeyCheck:
	mov a, #00001111b
	outl P1, a
	in a, P1
	
    mov r0, a
	orl a, r7
	xch a, r0
	cpl a
	mov r7, a
	mov a, r0

	cpl a
	ret

org 512
d0: db #00000111b, #00000110b, #00000111b, #00000111b, #00000101b, #00000111b, #00000111b, #00000111b, #00000111b, #00000111b
	db #00000101b, #00000010b, #00000001b, #00000001b, #00000101b, #00000100b, #00000100b, #00000001b, #00000101b, #00000101b
	db #00000101b, #00000010b, #00000111b, #00000011b, #00000111b, #00000111b, #00000111b, #00000010b, #00000111b, #00000111b
	db #00000101b, #00000010b, #00000100b, #00000001b, #00000001b, #00000001b, #00000101b, #00000010b, #00000101b, #00000001b
	db #00000111b, #00000111b, #00000111b, #00000111b, #00000001b, #00000111b, #00000111b, #00000010b, #00000111b, #00000111b
	
drawDigits:
	mov r0, #48
	mov r1, #aScores
	call drawTwoDigit
	inc r0
	inc r1
	
drawTwoDigit:  ;@r1 - digit, r0 - y pos
	mov a, @r1
	swap a
	anl a, #00001111b
	xchd a, @r1
	mov r4, a
	xchd a, @r1
	mov r2, #5
	
  drawTwoDigit_loop0:
	mov T, a
	movp a, @a   
	swap a
	mov @r0, a
	mov a, r4
	movp a, @a
	xrl a, @r0
	mov @r0, a
	mov a, r4
	add a, #10
	mov r4, a
	mov a, T
	add a, #10
	inc r0
	djnz r2, drawTwoDigit_loop0
	ret
	
clearScreen:
	mov r2, #32
	mov r0, #32
	clr a
	clearScreen_loop0:
	mov @r0, a
	inc r0
	djnz r2, clearScreen_loop0
	ret
	
;	
;	Tickers
;	
gameOverText:
	db #00000000b, #00111100b, #01100000b, #01100110b, #01100010b, #00111100b
	db #00000000b, #00111100b, #01100110b, #01111110b, #01100110b, #00000000b
	db #01100010b, #01110110b, #01101010b, #01100010b, #00000000b, #01111110b
	db #01100000b, #01111100b, #01100000b, #01111110b, #00000000b, #00000000b
	db #00111100b, #01100110b, #01100110b, #00111100b, #00000000b, #01100010b
	db #01100010b, #00110100b, #00011000b, #00000000b, #01111110b, #01100000b
	db #01111100b, #01100000b, #01111110b, #00000000b, #01111100b, #01100010b
	db #01111100b, #01100110b
	
youWinText:
	db #00000000b, #01100010b, #01101010b, #01101010b, #00110100b, #00000000b
	db #00111100b, #00011000b, #00011000b, #00111100b, #00000000b, #01100010b,
	db #01110010b, #01101010b, #01100110b, #00000000b, #11011011b, #11011011b,
	db #00000000b, #01001001b
youWinTextEnd:
	
drawGameOver:	
	mov r3, #gameOverText
	mov r4, #255-(youWinText-gameOverText)
	jmp prepareTicker
	
youWinTextShow:	
	mov r3, #youWinText
	mov r4, #255-(youWinTextEnd-youWinText)
	
prepareTicker:
	mov r7, #0FFh			;deley before key events     
	mov r5, #-15
drawTicker:
	inc r5
	mov a, r5
	mov r2, a
	mov r0, #32
	mov r1, #16
  drawTicker_loop0:
	mov a, r2
	rlc a
	jc drawTicker_loop0_nextLine
	mov a, r4
	add a, r2
	clr a
	jc drawTicker_loop0_line2screen
	mov a, r2
	add a, r3
	movp a, @a
  drawTicker_loop0_line2screen:
	mov @r0, a
  drawTicker_loop0_nextLine:
	inc r0
	inc r2         
	djnz r1, drawTicker_loop0
	
	mov a, r5
	add a, r4
	jz prepareTicker
	
	mov r6, #tickerDelay
  drawTicker_updateLCD:
	call updateLCD
    djnz r6, drawTicker_updateLCD
    
	call anyKeyCheck
	jz drawTicker
	ret
	
;playBeep:
	;mov r1, #((90000/2000-7)/4/2)
	;jmp play
	
playBop:
	call updateLCD
	mov r1, #((90000/700-7)/4/2)
play:
	mov a, #00100000b
  playBop_loop:
	xrl a, #00110000b
	mov r0, a
	mov a, r1
	xch a, r0
  playTone_delay:
	outl p2, a
	djnz r0, playTone_delay	
	djnz r1, playBop_loop
	call updateLCD
	ret
	
drawClearAnimation:
	mov a, r3
	mov r0, a
	mov r4, #0
	mov r1, #aPice
	mov r2, #4
  drawClearAnimation_loop0:
	mov a, @r0
	cpl a
	mov @r1, #0
	jnz drawClearAnimation_notFull
	mov @r1, #0FFh
	inc r4
  drawClearAnimation_notFull:
	inc r0
	inc r1
	djnz r2, drawClearAnimation_loop0
	ret
	
;
;horizontal scroll
;
org 768
scrollMicrovision:
	call clearScreen
	mov r7, #0FFh
	mov r4, a   ;a=0 after clearScreen
horisontalScroll:
	mov r0, #50
	mov r5, #microText
	call horisontalShift5Lines
	
	mov r0, #41
	call horisontalShift5Lines
	
	mov r6, #microvisionScrollDelay
  horisontalScroll_updateLCD:
	call updateLCD
	djnz r6, horisontalScroll_updateLCD
	call anyKeyCheck
	jnz drawByAz
	
	inc r4
	mov a, r4
	xrl a, #48
	jnz horisontalScroll
	
scrollForty:
	mov r4, a   ;a=0 after scrollMicrovision
scrollForty_loop0:
	mov r0, #35
	mov r5, #fortyText
	call horisontalShift5Lines
	
	mov r0, #56
	mov r5, #fortyText+2
	call horisontalShift5Lines
		
scrollForty_notShift:
	call updateLCD

	call anyKeyCheck
	jnz drawByAz
	
	inc r4
	mov a, r4
	add a, #255-15
	jnc scrollForty_loop0

	add a, #255-55
	jnc scrollForty_notShift
		
drawByAz:
	call clearScreen
drawByAz_wclear:
	mov r0, #42
	mov r1, #byAz
	call draw5Lines
	mov r0, #58
	call draw5Lines
	
drawMainScreenScroll:
	mov r0, #49
	mov r3, #7
	mov r5, #mainScreenText
	call horisontalShift
	
	mov r6, #tickerDelay
  drawMainScreenScroll_updateLCD:
	call updateLCD
	call genRandom
	djnz r6, drawMainScreenScroll_updateLCD
		
	inc r4
	mov a, r4
	xrl a, #47
	jz drawByAz_wclear
	
	call anyKeyCheck
	jz drawMainScreenScroll
	ret

draw5Lines:
	mov r4, #5
drawLines:
	mov a, r1
	movp a, @a
	mov @r0, a
	inc r0
	inc r1
	djnz r4, drawLines
	ret
	
horisontalShift5Lines:
	mov r3, #5
horisontalShift:
	mov a, r4
	add a, #11100000b
	jc horisontalShift_strEnd
	anl a, #00000111b
	mov r2, a
	xrl a, r4
	rr a
	rr a
	rr a
	add a, r5
	movp a, @a
	
  horisontalShift_strEnd:
	inc r2
	horisontalShift_loopRLC:
	rlc a
	djnz r2, horisontalShift_loopRLC
	
	mov a, r0
	xrl a, #00010000b
	mov r1, a
	anl a, #00010000b
	jnz horisontalShift_RRC
	mov a, @r0
	rlc a
	mov @r0, a
	mov a, @r1
	rlc a
	jmp horisontalShift_RRCEnd
  horisontalShift_RRC:
	mov a, @r0
	rrc a
	mov @r0, a
	mov a, @r1
	rrc a
  horisontalShift_RRCEnd:
    mov @r1, a
    
	inc r0
	mov a, r5
	add a, #4 ;string length in bytes
	mov r5, a
	djnz r3, horisontalShift
	ret
	
fortyText:
	db #00111100b, #01100110b
	db #11111011b, #10111011b
	db #01100010b, #11011101b
	db #01111011b, #10111011b
	db #11011101b, #11011101b
	db #00001011b, #11000111b
	db #11011101b, #11011101b
	db #00001111b, #01111111b
	db #11010101b, #11000001b
	db #00000111b, #00111110b

byAz:
	db #01000000b, #01101010b, #01010110b, #01100010b, #00001100b, #01001110b, #10100010b, #10100100b, #11101000b, #10101110b
	
mainScreenText:
	db #11111011b, #10011111b, #01111001b, #10111110b
	db #10101010b, #00010101b, #01010001b, #10110000b
	db #00100011b, #10000100b, #01100000b, #00011000b
	db #00100011b, #00000100b, #01110001b, #10001100b
	db #00100010b, #00000100b, #01011001b, #10100110b
	db #01110011b, #11001110b, #01001101b, #10111110b
	db #01110011b, #11101110b, #01000110b, #10111110b

microText:
	db #11000101b, #11100111b, #10011111b, #10011110b
	db #11101100b, #11001100b, #01011000b, #10110001b
	db #11010100b, #11001100b, #00011111b, #00110001b
	db #11000100b, #11001100b, #01011001b, #10110001b
	db #11000101b, #11100111b, #10011000b, #11011110b

visionText:
	db #10001100b, #11110011b, #01111101b, #10100011b
	db #10011101b, #00011011b, #00001101b, #10100011b
	db #10101101b, #00011011b, #01111101b, #10100011b
	db #11001101b, #00011011b, #01100001b, #10010110b
	db #10001100b, #11110011b, #01111101b, #10001100b
