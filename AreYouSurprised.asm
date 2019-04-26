#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

;Start data segment
;si holds the beginning of the current typed value always
;ntyped holds the number of typed keys always
	jmp     str1
	db      1021 dup(0)
	
	;input 8255 DISPLAY 7-seg
	pt1a	equ	10h
	pt1b	equ	12h
	pt1c	equ	14h
	creg1	equ	16h
	
	;for 8255 KEYBOARD button matrix
	pt2a	equ	20h
	pt2b	equ	22h
	pt2c	equ	24h
	creg2	equ	26h
	
	;for 8255 IC I/O
	pt3a	equ	40h
	pt3b	equ	42h
	pt3c	equ	44h
	creg3	equ	46h 
	
	chip1 db 07h,04h,00h,00h			;NAND
	chip2 db 07h,04h,00h,08h			;AND
	chip3 db 07h,04h,03h,02h			;OR
	chip4 db 07h,04h,08h,06h			;XOR
	chip5 db 07h,04h,07h,02h,06h,06h	;XNOR
	
	lookup_7 db 10111111b, 10110000b, 11011011b, 11001111b, 11100110b, 11101101b, 11111101b, 00000111b, 11111111b, 11100111b ; 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	lookup_matrix db 0eeh, 0edh, 0ebh, 0e7h, 0deh, 0ddh, 0dbh, 0d7h, 0beh, 0bdh, 0bbh, 0b7h, 07eh, 07dh, 07bh, 077h ; 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, enter, test, backspace,x ,x,x
	letter_table db 11110001b,11110111b, 10110000b, 10111000b, 11110011b, 11101101b,10111001b; F, A, I, L, P, S, C,
    
    check1 db 00000000b
	check2 db 01010101b
	check3 db 10101010b
	check4 db 11111111b

	chip11 db 11110000b
	chip12 db 11110000b
	chip13 db 11110000b
	chip14 db 00000000b

	chip21 db 00000000b
	chip22 db 00000000b
	chip23 db 00000000b
	chip24 db 11110000b

	chip31 db 00000000b
	chip32 db 11110000b
	chip33 db 11110000b
	chip34 db 11110000b

	chip41 db 00000000b
	chip42 db 11110000b
	chip43 db 11110000b
	chip44 db 00000000b

	chip51 db 11110000b
	chip52 db 00000000b
	chip53 db 00000000b
	chip54 db 11110000b
	
	ntyped	db 1 dup(0h)
	typed 	db 6 dup(0ffh)
	ent		db 1 dup(0h)
	ic 		db 1 dup(0h)
	set 	db 1 dup(0h)

;End data segment
;Start code segment
	
	;initialize ds,es,ss to start of RAM	
str1:
	
	cli					
	mov	ax,0200h
	mov es,ax
	mov ss,ax
	mov ds,ax
	mov sp,0FFFEH 
	
	
	lea si, cs:typed		;Default position for si pointer
	mov al,10000000b
	out creg1,al			;Configure Display. All outputs in I/O mode
	mov al,10001000b
	out creg2,al 		 	;Congifure Keyboard. upper portC I/P, lower portC O/P
	mov al,10010000b
	out creg3, al 			;Configure IC interfacing. portA mode 0 I/P, portC O/P, portB mode 0 I/P	

	
	;SETING INITIAL VALUES (Active high)
	mov al,00000000b
	out pt1a,al
	out pt1b,al
	out pt1c,al
	mov al,00000000b
	out pt3b,al
	
	in al,pt3a
	and al,08h
	cmp al,08h
	jz NOT_SET
	
;PRINT CURRENT VALUE AND GET INPUT FROM KEYBOARD
prt_cur:
	in al,pt3a
	and al,08h
	cmp al,08h
	jz NOT_SET
	
	;Check release
	mov	al, 00h
	out pt2c, al
	x1:	in al,pt2c
		and al,0f0h
		cmp al,0f0h
		jnz x1
	
	;print current values
pr:	
	mov dl,11111110b     
	mov ch,cs:ntyped
	mov cl,0h
	mov bh,0h
	mov ah,0h
	lea di,cs:lookup_7
	lea si,cs:typed
	prt:
		cmp cl,ch
		jge strt
		mov al,dl
		out pt1c,al
		mov bl,cs:[si]
		mov al,cs:[di+bx]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		inc cl
		inc si
		rol dl,01h
		jmp prt
	
	lea si,cs:typed
	call delay20
	
	;check press
	strt:
		
		mov	al, 00h
		out pt2c, al
		p1:	in 	al,pt2c
			and al,0f0h
			cmp al,0f0h
			jz 	pr
	
	call delay20
	
	;check press again
	mov	al, 00h
	out pt2c, al
	in 	al,pt2c
	and al,0f0h
	cmp al,0f0h
	jz 	p1
	
	;check each column
	mov al,0eh		;column 1
	mov bl,al
	out pt2c,al
	in 	al,pt2c
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	mov al,0dh		;column 2
	mov bl,al
	out pt2c,al
	in 	al,pt2c
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	mov al,0bh		;column 3
	mov bl,al
	out pt2c,al
	in 	al,pt2c
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	mov al,07h		;column 4
	mov bl,al
	out pt2c,al
	in 	al,pt2c
	and al,0f0h
	cmp al,0f0h
	
	;it has to be one of the above four columns //no exception
key:
	or 	al,bl
	lea di,cs:lookup_matrix[0fh]
	cmp al,cs:[di]						;Useless key
	jz prt_cur
	
	dec di
	cmp al,cs:[di]						;Useless key
	jz prt_cur
	
	dec di
	cmp al,cs:[di]						;Useless key
	jz prt_cur
	
	dec di
	cmp al,cs:[di]						;backspace
	jz bksp
	
	dec di
	cmp al,cs:[di]						;test
	jz testIC
	
	dec di
	cmp al,cs:[di]
	jz enterIC							;enterIC
	
	mov cl,0bh
	num:
		dec di
		dec cl
		cmp cl,0h
		je	prt_cur
		cmp al,cs:[di]
		jne num
		jmp write
	
	write:	
		dec cl
		mov al,00h					;reset enter status
		mov cs:ent,al
		mov al,cs:ntyped
		cmp al,06h					;if 6 numbers are typed already
		jge prt_cur
		lea di,cs:[si+al]
		mov cs:[di],cl
		inc al
		mov cs:ntyped,al
		
	jmp prt_cur						;print new value
	
	;REMOVING A NUMBER
bksp:						
		mov  al,0h						;reset enter status
		mov  cs:ent,al
		mov  al,cs:ntyped					;check number of chars typed
		cmp  al,0h
		jle	 b1
		dec  al
		mov  cs:ntyped,al
b1:		jmp prt_cur						;print current value after dec 	

	;CHECKING IC NUMBER
enterIC:

	in al,pt3a
	and al,08h
	cmp al,08h
	jz NOT_SET
	
	;check IC number and assign IC variable
	;7400
	mov ah,00h
	IC1:
		lea si,cs:typed
		lea di,cs:chip1
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz IC2
		cld
		reIC1:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz IC2
			inc si
			inc di
			dec cx
			jnz reIC1
		mov al,01h
		jz ICn
	
	;7408
	IC2:
		lea si,cs:typed
		lea di,cs:chip2
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz IC3
		cld
		reIC2:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz IC3
			inc si
			inc di
			dec cx
			jnz reIC2
		mov al,02h
		jz ICn
	
	;7432
	IC3:
		lea si,cs:typed
		lea di,cs:chip3
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz IC4
		cld
		reIC3:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz IC4
			inc si
			inc di
			dec cx
			jnz reIC3
		mov al,03h
		jz ICn	
	
	;7486
	IC4:
		lea si,cs:typed
		lea di,cs:chip4
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz IC5
		cld
		reIC4:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz IC5
			inc si
			inc di
			dec cx
			jnz reIC4
		mov al,04h
		jz ICn
	
	;747266
	IC5:
		lea si,cs:typed
		lea di,cs:chip5
		mov cx,06h
		mov al,cs:ntyped
		cmp ax,cx
		jnz INV
		cld
		reIC5:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz INV
			inc si
			inc di
			dec cx
			jnz reIC5
		mov al,05h
		jz ICn
	
	lea si,cs:typed		;reset to default place
	jmp INV
	
ICn:
	mov cs:ic,al;
	mov al,01h
	mov cs:ent,al
	lea si,cs:typed		;reset to default place
	jmp VAL
	
	;TESTING THE IC
testIC:
	in al,pt3a
	and al,08h
	cmp al,08h
	jz NOT_SET
	
	mov al,cs:ent					;check enter status
	cmp al,01h
	jnz INV						    ;error for testing without entering number
	
	mov al,cs:ic					;Run function according to ICI number 
	cmp al,01h
	je C_NAND
	cmp al,02h
	je C_AND
	cmp al,03h
	je C_OR
	cmp al,04h
	je C_XOR
	cmp al,05h
	je C_XNOR
	
	mov al,0h						;reset stuff
	mov cs:ntyped,al
	lea si,cs:typed
	jmp prt_cur						;Not Sure. This should reset it to the first position in array
	
;assumption : sending input to IC from portC and getting output from IC at upper portA
C_NAND:
	;7400
	;8 input lines 4 ouput lines
	mov al,cs:check1
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip11
	jnz FAIL
	
	mov al,cs:check2
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0fh
	cmp al,cs:chip12
	jnz FAIL
	
	mov al,cs:check3
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip13
	jnz FAIL
	
	mov al,cs:check4
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip14
	jnz FAIL

	jmp PASS
	
C_AND:
	;7408
	;8in, 4out
	mov al,cs:check1
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip21
	jnz FAIL
	
	mov al,cs:check2
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip22
	jnz FAIL
	
	mov al,cs:check3
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip23
	jnz FAIL
	
	mov al,cs:check4
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip24
	jnz FAIL
	
	jmp PASS

C_OR:
	;7432
	;8in, 4out
	mov al,cs:check1
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip31
	jnz FAIL
	
	mov al,cs:check2
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip32
	jnz FAIL
	
	mov al,cs:check3
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip33
	jnz FAIL
	
	mov al,cs:check4
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip34
	jnz FAIL
	
	jmp PASS

C_XOR:
	;7486
	;same
	mov al,cs:check1
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip41
	jnz FAIL
	
	mov al,cs:check2
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip42
	jnz FAIL
	
	mov al,cs:check3
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip43
	jnz FAIL
	
	mov al,cs:check4
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip44
	jnz FAIL
	
	jmp PASS
C_XNOR:
	;747266
	;8in, 4out
	mov al,cs:check1
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip51
	jnz FAIL
	
	mov al,cs:check2
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip52
	jnz FAIL
	
	mov al,cs:check3
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip53
	jnz FAIL
	
	mov al,cs:check4
	out pt3c,al
	call delay20
	in al, pt3a
	and al,0f0h
	cmp al,cs:chip54
	jnz FAIL
	
	jmp PASS
	
FAIL:
	;check key release
	mov	al, 00h
	out pt2c, al
	FAIL1:	
		in al,pt2c
		and al,0f0h
		cmp al,0f0h
		jnz FAIL1
		
	mov cx,01fffh
	FAIL2:
		mov al,11111110b
		out pt1c,al
		mov al,cs:letter_table[0h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111101b
		out pt1c,al
		mov al,cs:letter_table[01h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111011b
		out pt1c,al
		mov al,cs:letter_table[02h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11110111b
		out pt1c, al
		mov al,cs:letter_table[03h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		loop FAIL2
	
		mov al,00000000b
		out pt1b,al
		mov al,00000000b
		out pt1c,al
	jmp prt_cur
	
PASS:
	;check key release
	mov	al, 00h
	out pt2c, al
	PASS1:	
		in al,pt2c
		and al,0f0h
		cmp al,0f0h
		jnz PASS1
		
	mov cx,01fffh
	PASS2:
		mov al,11111110b
		out pt1c,al
		mov al,cs:letter_table[04h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111101b
		out pt1c,al
		mov al,cs:letter_table[01h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111011b
		out pt1c,al
		mov al,cs:letter_table[05h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11110111b
		out pt1c, al
		mov al,cs:letter_table[05h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		loop PASS2
		
		mov al,00000000b
		out pt1b,al
		mov al,00000000b
		out pt1c,al
	jmp prt_cur

	;VALID IC
VAL:
	;check key release
	mov	al, 00h
	out pt2c, al
	VAL1:	
		in al,pt2c
		and al,0f0h
		cmp al,0f0h
		jnz VAL1
		
	;print AC
	mov cx,01fffh
	VAL_AC:
	    mov ah,00h
	    mov al,11111110b
		out pt1c,al  
		mov al,cs:letter_table[01h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111101b
		out pt1c,al
	    mov al,cs:letter_table[06h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		loop VAL_AC
	jmp prt_cur
	
	;INVALID IC
INV:
	;check key release
	mov	al, 00h
	out pt2c, al
	INV1:	
		in al,pt2c
		and al,0f0h
		cmp al,0f0h
		jnz INV1
		
	;print AI
	mov cx,01fffh
	INV_AI:
	    mov al,11111110b
		out pt1c,al
		mov al,cs:letter_table[01h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al, 11111101b
		out pt1c,al
		mov al,cs:letter_table[02h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		loop INV_AI
	jmp prt_cur
	
NOT_SET:
		mov al,11111110b
		out pt1c,al
		mov al,cs:letter_table[02h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		mov al,11111101b
		out pt1c,al
		mov al,cs:letter_table[06h]
		out pt1b,al
		mov al,00000000b
		out pt1b,al
		
		in al,pt3a
		and al,08h
		cmp al,08h
		jz NOT_SET
		jmp prt_cur
				
	;(22n+27)*200ns delay, if clock is 5MHz
	; for 20ms, n=4545=11C1h
delay20 proc near
		mov cx,11C1h
	d1:	nop
		dec cx
		jnz d1
		ret
	
HLT           ; halt!


