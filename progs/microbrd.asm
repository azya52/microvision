	;r3 - bird pos start on 32
	;r4 - random 1-randomMax
	;r5 - current columns vertical offset
	;r6 - some delays
	;r7 - bird acceleration 

	aScoresLow  EQU #24
	aScoresHigh EQU #25

	randomMax   EQU #5
	
	TAPposY     EQU #43
	TAPheight   EQU #4
	SCOREposY   EQU #34
	SCOREheight EQU #5
	
	mov a, #00000010b ;scan mid row
	outl p1, a
	
	jmp scrollMicrovision
	
gameOver:
	call clearScreen
	call updateLCD
	
	mov r1, #((90000/700-7)/4/2)
  playBop_loop2:
    mov r2, #3
	call playTone
	djnz r1, playBop_loop2
	mov r2, #6
	call playTone
	
	call drawScoreScreen
	mov r6, #20
  gameOver_loop1:
	call updateLCDfrom2line
	djnz r6, gameOver_loop1
  gameOver_waitKeyPress:
	call updateLCDfrom2line
	in a, p1	;anyKeyScan
	jnz gameOver_waitKeyPress

waitKeyReleaseAndStart:
    call waitKeyRelease
	
newBird:
	call clearScreen
	mov r1, #aScoresLow
	mov @r1, a	;a=0
	inc r1
	mov @r1, a
	mov r4, #randomMax
	mov r7, a
	mov r3, #37
	mov r1, #TAPstring
	mov r0, #TAPposY
	mov r2, #TAPheight
	call drawLine
	
birdAnimation:	
	inc r6
	call updateBirdByr6
	call drawBird
	call updateLCDfrom2line
	call clearBird
	call genRandom
	in a, p1	;anyKeyScan
	jnz birdAnimation
	call clearScreen
	
scrollNextColumns:
	mov r6, a	;a=0
	call addScores
	mov a, r4
	mov r5, a

scrollColumnsAndRedraw:
	call checkCollision
	jnz gameOver 
	call drawBird
	
scrollColumns:
	inc r6
	call updateLCD
	
	mov a, r6
	rrc a
	jc scrollColumns
	
	call clearBird
	in a, p1	;anyKeyScan
	jnz scrollColumns_noKey
	mov a, r3
	dec a
	mov r3, a
	xrl a, #31
	jnz scrollColumns_notTop
	inc r3
  scrollColumns_notTop:
	mov r7, #1
	call genRandom
  scrollColumns_noKey:
  	
	mov a, r6
	anl a, #00000011b
	jnz scrollColumnsAndRedraw
	inc r7
	mov a, r7
	rr a
	rr a
	anl a, #00111111b
	add a, r3
	mov r3, a
	call updateBird

	mov a, r6
	anl a, #00000111b
	jnz scrollColumnsAndRedraw
	mov r0, #32
	mov r1, #48
	call columnsShift
	mov a, r5
	add a, #240 ;a-16
	mov r5, a
	mov a, r6
	xrl a, #80
	jz scrollNextColumns
  
	jmp scrollColumnsAndRedraw
	
updateBird:
	mov a, r7
	add a, #251
	jnc updateBirdRise
	add a, #255
	jc updateBirdDrop
updateBirdForward:
	mov r0, #29
	mov @r0, #00001100b
	inc r0
	mov @r0, #00011010b
	jmp updateBird_lastLine
updateBirdDrop:
	mov r0, #29
	mov @r0, #00011100b
	inc r0
	mov @r0, #00001010b
  updateBird_lastLine:
	inc r0	
	mov @r0, #00001100b
	ret
	
updateBirdByr6:
	mov a, r6
	anl a, #00001100b
	jz updateBirdDrop
	xrl a, #00000100b
	jz updateBirdForward	
updateBirdRise:
	mov r0, #29
	mov @r0, #00001100b
	inc r0
	mov @r0, #00001010b
	inc r0	
	mov @r0, #00011100b
	ret
	
clearBird:
drawBird:
	mov a, r3
	mov r0, a
	mov r1, #29
	mov r2, #3
  drawBird_loop0:
	mov a, @r1
	xrl a, @r0
	mov @r0, a
	inc r0
	inc r1
	djnz r2, drawBird_loop0
	ret
	
addScores:
	mov r0, #47
	mov a, @r0
	rlc a
	rlc a
	jnc addScores_end
	mov r1, #aScoresLow
  addScores_carry:
	clr a
	addc a, @r1
	da a
	mov @r1, a
	inc r1
	jc addScores_carry
	jz gameOver
	mov r1, #((90000/800-7)/4/2)
	mov r2, #8
	call playTone
  addScores_end:
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

genRandom:
	djnz r4, genRandom_notZero
	mov r4, #randomMax
  genRandom_notZero:
	ret
	
waitKeyRelease:
    call updateLCD
	in a, p1	;anyKeyScan
	jz waitKeyRelease
	ret

org 256
columns:
	db #00000000b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00001111b
	db #00000000b
	db #00000000b
	db #00000000b
	db #00000000b
	db #00000000b
	db #00000000b
	db #00000000b
	db #00001111b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00000110b
	db #00000110b
	
bitByNumber:
	db #10000000b, #01000000b, #00100000b, #00010000b, #00001000b, #00000100b, #00000010b, #00000001b, #00000000b, #00000000b
	
TAPstring:
	db #00011100b, #10011000b
	db #00001001b, #01010100b
	db #00001001b, #11011000b
	db #00001001b, #01010000b

columnsShift:
	mov a, r6
	rr a
	rr a
	rr a
	add a, #bitByNumber-1
	movp a, @a
	mov r2, a
	
  columnsShift_loop:
	mov a, r5
	movp a, @a
	anl a, r2
	jz columnsShift_noBit
	cpl c
  columnsShift_noBit:
	mov a, @r1
	rlc a
	mov @r1, a
	mov a, @r0
	rlc a
	mov @r0, a

	inc r0
	inc r1
	inc r5
	mov a, r0
	add a, #208
	jnc columnsShift_loop
	ret
	
drawLine:
	mov a, r1
	movp a, @a
	mov @r0, a
	inc r1
	mov a, r0
	xrl a, #16
	mov r0, a
	anl a, #16
	jnz drawLine
	inc r0
	djnz r2, drawLine
	ret
	
SCOREstring:
	db #11011011b, #10111011b
	db #10010010b, #10101010b
	db #11010010b, #10110011b
	db #01010010b, #10101010b
	db #11011011b, #10101011b

ByAZstring:
	db #00000000b, #01001110b
	db #01000000b, #10100010b 
	db #01101010b, #10100100b 
	db #01010110b, #11101000b
	db #01100010b, #10101110b
	db #00001100b, #00000000b
	
digits:
	db #00000111b, #00000110b, #00000111b, #00000111b, #00000101b, #00000111b, #00000111b, #00000111b, #00000111b, #00000111b
	db #00000101b, #00000010b, #00000001b, #00000001b, #00000101b, #00000100b, #00000100b, #00000001b, #00000101b, #00000101b
	db #00000101b, #00000010b, #00000111b, #00000011b, #00000111b, #00000111b, #00000111b, #00000010b, #00000111b, #00000111b
	db #00000101b, #00000010b, #00000100b, #00000001b, #00000001b, #00000001b, #00000101b, #00000010b, #00000101b, #00000001b
	db #00000111b, #00000111b, #00000111b, #00000111b, #00000001b, #00000111b, #00000111b, #00000010b, #00000111b, #00000111b
	
drawScoreScreen:
	mov r1, #SCOREstring
	mov r0, #SCOREposY
	mov r2, #SCOREheight
	call drawLine

drawDigits:
	mov r0, #57
	mov r1, #aScoresLow
	call drawTwoDigit
	mov r0, #41
	inc r1
	
drawTwoDigit:  ;@r1 - digit, r0 - y pos
	mov a, @r1
	swap a
	anl a, #00001111b
	add a, #digits
	mov r4, a
	mov a, @r1
	anl a, #00001111b
	add a, #digits
	mov r2, #5
	
  drawTwoDigit_loop0:
	mov r3, a
	movp a, @a   
	mov @r0, a
	mov a, r4
	movp a, @a
	swap a
	xrl a, @r0
	mov @r0, a
	mov a, r4
	add a, #10
	mov r4, a
	mov a, r3
	add a, #10
	inc r0
	djnz r2, drawTwoDigit_loop0
	ret
	
updateLCD:
	mov r0, #32
	mov r1, #48
	mov r2, #10000000b
updateLCDsub:
	clr a
	mov T, a
	clr c
  
  Line:	
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
	anl a, #11110000b
	outl bus, a
	orl a, #00000010b
	outl bus, a
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
	
	jnc Line
	
	clr a
	outl bus, a
	inc a
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
	
checkCollision:
	mov a, r3
	mov r0, a
	add a, #210 ;check for a = 45
	inc a
	jc checkCollision_end
	mov r1, #29
	mov r2, #3
  checkCollision_loop0:
	mov a, @r1
	anl a, @r0
	jnz checkCollision_end
	inc r0
	inc r1
	djnz r2, checkCollision_loop0
  checkCollision_end:
	ret
	
playTone:
	mov a, #00100000b
  playTone_loop:
	xrl a, #00110000b
	mov r0, a
	mov a, r1
	xch a, r0
  playTone_low:
	outl p2, a
	djnz r0, playTone_low
	djnz r2, playTone_loop
	ret	
	
;
;   Introduction screens
;

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
	
mainScreenText:	
	db #11000101b, #00000000b, #00011110b, #10000001b
	db #11101100b, #01101101b, #11011010b, #00110111b
	db #11010101b, #01001001b, #01011100b, #10100101b
	db #11000101b, #01001001b, #01011010b, #10100101b
	db #11000101b, #01101001b, #11011110b, #10100111b
	
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
	
bitByNumber2:
	db #10000000b, #01000000b, #00100000b, #00010000b, #00001000b, #00000100b, #00000010b, #00000001b
		
	tickerDelay             EQU #5
	microvisionScrollDelay  EQU #3

horisontalShift5Lines:
	mov r3, #5
horisontalShift:
	mov a, r4
	add a, #11100000b
	jnc horisontalShift_strNotEnd
	clr a
	jmp horisontalShift_strEnd
  horisontalShift_strNotEnd:
	anl a, #00000111b
	add a, #bitByNumber2
	movp a, @a
  horisontalShift_strEnd:
	mov r2, a
	
	mov a, r4
	rr a
	rr a
	rr a
	anl a, #00000111b
	add a, r5
	
	mov r7, #00010000b
  horisontalShift_loop:
    mov r6, a
	movp a, @a
	anl a, r2
	jz horisontalShift_noBit
	cpl c
  horisontalShift_noBit:
	
	mov a, r0
	xrl a, r7
	mov r1, a
	anl a, r7
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
    
    mov a, r6
    add a, #4 ;string length in bytes
	inc r0
	djnz r3, horisontalShift_loop
	ret
		
scrollMicrovision:
	call clearScreen
	mov r4, a
horisontalScroll:
	mov r0, #50
	mov r5, #microText
	call horisontalShift5Lines
	
	mov r0, #41
	mov r5, #visionText
	call horisontalShift5Lines
	
	mov r6, #microvisionScrollDelay
  horisontalScroll_updateLCD:
	call updateLCDfrom2line
	djnz r6, horisontalScroll_updateLCD
	in a, p1	;anyKeyScan
	jz drawByAz
	
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
	call updateLCDfrom2line

	in a, p1
	jz drawByAz
	
	inc r4
	mov a, r4
	add a, #255-15
	jnc scrollForty_loop0

	add a, #255-55
	jnc scrollForty_notShift

drawByAz:
    call waitKeyRelease
	call clearScreen
	mov r4, a	;a=0
	mov r1, #ByAZstring
	mov r0, #41
	mov r2, #6
	call drawLine
	
drawMainScreenScroll:
	mov r0, #50
	mov r5, #mainScreenText
	call horisontalShift5Lines
	
	mov r6, #tickerDelay
  drawMainScreenScroll_updateLCD:
	call updateLCDfrom2line
	djnz r6, drawMainScreenScroll_updateLCD
		
	inc r4
	mov a, r4
	xrl a, #48
	jnz drawMainScreenScroll_notEnd
	mov r4, a
  drawMainScreenScroll_notEnd:
  
	in a, p1	;anyKeyScan
	jnz drawMainScreenScroll
	jmp waitKeyReleaseAndStart
	
updateLCDfrom2line:
	mov r0, #34
	mov r1, #50
	mov r2, #00100000b
	jmp updateLCDsub
	