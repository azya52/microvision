	mov R4, #00000010b          
	mov R3, #11110000b
	
main:
	mov r0, #OCTOPUS
	call updateLCD
	call updateLCD
	call updateLCD
	jmp main
	
	org 256

OCTOPUS:
	dw #00060h, #08063h, #0c017h, #0de0eh, #07e0dh, #0e01eh, #0feefh, #0ffcfh, #0f307h, #0b801h, #09c01h, #0ec00h, #06000h, #00000h
	dw #00060h, #00020h, #08013h, #04e0ch, #07e0dh, #0601ch, #0feefh, #0f78fh, #0e207h, #0b001h, #09c00h, #0c800h, #06000h, #00000h
	dw #00040h, #00020h, #08013h, #04c0ch, #03e09h, #02018h, #07c6ch, #0f687h, #0e000h, #0b001h, #09c00h, #0c800h, #06000h, #00000h
	
updateLCD:
	mov R1, #00100000b          
	mov R2, #00000000b
updateLCD_loop:  	  	
	mov a, R0
	movp a, @a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	mov a, R0
	movp a, @a
	swap a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	inc R0
	mov a, R0
	movp a, @a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	mov a, R0
	movp a, @a
	swap a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	inc R0
	
	mov a, R1
	anl a, R3
	outl bus, a                 
	add a, R4
	outl bus, a
	mov a, R1                   
	rrc a
	xch a, R1
	swap a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	mov a, R2
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	mov a, R2
	rrc a
	xch a, R2
	swap a
	anl a, R3
	outl bus, a
	orl a, R4
	outl bus, a
	
	inc a
	outl bus, a
	
	jnc updateLCD_loop

	clr a
	outl bus, a
	inc a
	outl bus, a
	
	ret