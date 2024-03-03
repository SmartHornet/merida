;= Start 	macro.inc ========================================
;= End 		macro.inc ========================================
.def temp = R16
.def i = R21
.def curspeed = R18 //������� �������� ���������(0-255)
.def speed = R19 //��������� �������� ���������(0-255)
.def curstep = R17 //����� ���� ���������(0-7) 
.def nStepsL = R0 //���������� ��� �������� ���-�� ����� � ������������ nStep
.def nStepsH = R1
.def curPosL = R2 //���������� �������� ��������� ��������� 0 - 965(0x3C6)
.def curPosH = R3
.def eeadr = R7 //���������� ������ ��� ������ � eeprom
.def eedata = R6 //���������� ������ ��� ������ � eeprom
.def distPosL = R4 //���������� �������� ��������� ��������� 0 - 965(0x3C6)
.def distPosH = R5
.def flags0 = R20
//��� 0 - 
//��� 1 - ����������� ������ ��� ������ ������������ ���� ����������
//��� 2 - ������ ������������� ���������� �������� �������
//��� 3 - ����������� ������ ��� ������ ������������� ���������� �������� ����������
//��� 4 - ����������� ������ ��� ������ ������������ ������ ����������
//��� 5 - ����� ���������������� �����������
//��� 6 - ��������� ����������� ������ �����������
.equ circleL = 0xC6 //����� ����������
.equ circleH = 0x3
.equ circleHalfL = 0xE3 //�������� ����� ����������
.equ circleHalfH = 0x1
.equ timerQueueLenght = 2 //����� ��������� timerQueue (���� � 1)
; RAM ========================================================
		.DSEG

timerQueue:	.byte (timerQueueLenght*2) //������� ������������ �������
//������ timerQueueLenght ���� - ����� ����� � ����� ������(flags0) 255 - ������ ��������
//��������� timerQueueLenght ���� - ���������� ������������ �������

; FLASH ======================================================
		.CSEG

		.ORG 0x000	;(RESET)				External Pin, Power-on Reset, Brown-out Reset, and Watchdog Reset
		RJMP	Reset
		.ORG 0x001	;(INT0)					External Interrupt Request 0
		RETI
		.ORG 0x002	;(INT1)					External Interrupt Request 1
		RETI
		.ORG 0x003	;(TIMER2 COMP)			Timer/Counter2 Compare Match
		RETI
		.ORG 0x004	;(TIMER2 OVF)			Timer/Counter2 Overflow
		RETI
		.ORG 0x005	;(TIMER1 CAPT)			Timer/Counter1 Capture Event
		RETI
		.ORG 0x006	;(TIMER1 COMPA)			Timer/Counter1 Compare Match A
		RETI
		.ORG 0x007	;(TIMER1 COMPB)			Timer/Counter1 Compare Match B
		RETI
		.ORG 0x008	;(TIMER1 OVF)			Timer/Counter1 Overflow
		RETI
		.ORG 0x009	;(TIMER0 OVF)			Timer/Counter0 Overflow
		RJMP	timer0Ovf
		.ORG 0x00A	;(SPI), STC)			Serial Transfer Complete
		RETI
		.ORG 0x00B	;(USART, RXC USART)		Rx Complete
		RETI
		.ORG 0x00C	;(USART, UDRE USART)	Data Register Empty
		RETI
		.ORG 0x00D	;(USART, TXC USART)		Tx Complete
		RETI
		.ORG 0x00E	;(ADC)					ADC Conversion Complete
		RETI
		.ORG 0x00F	;(EE_RDY)				EEPROM Ready
		RETI
		.ORG 0x010	;(ANA_COMP)				Analog Comparator
		RETI
		.ORG 0x011	;(TWI)					Two-wire Serial Interface
		RETI
		.ORG 0x012	;(SPM_RDY)				Store Program Memory Ready
		RETI

;===========================================================
steps: .db	0b00000001, 0b00000011, 0b00000010, 0b00000110, 0b00000100, 0b00001100, 0b00001000, 0b00001001
; Interrupts ==============================================
timer0Ovf:

	push temp
	in temp, SREG
	push temp
	push YL
	push YH
	push i

	clr i //���������� ������� ����� �� 0 �� timerQueueLenght

	LDI YL, low(timerQueue)
	LDI YH, high(timerQueue)
tm0:
	ld temp, Y+ //������ �����
	cpi temp, 0xFF //����� ����� 255?
	breq tm1 //��, ���������� ���� ������
	push temp //���, ���������� �����
	ldd temp, Y+timerQueueLenght-1 //������ ���������� ������������ �������
	dec temp //���������
	brne tm2 //���� ���������� �� ����� 0 �� ��������� �� tm2
	pop temp //������� �����
	or flags0, temp //������ ��� �� �����
	ser temp
	st -Y, temp //����� �������� 255
	ld temp, Y+//������� ����������� Y
	rjmp tm1
tm2:
	std Y+timerQueueLenght-1, temp //���������� ����������� ����������
	pop temp //����������� ����(�.� ����� ���������� ����������)
tm1:
	inc i
	cpi i, timerQueueLenght
	brne tm0
	
	pop i
	pop YH
	pop YL
	pop temp
	out SREG, temp
	pop temp

reti
; End Interrupts ==========================================

Reset:   	LDI 	R16,Low(RAMEND)	; ������������� �����
		    OUT 	SPL,R16			; �����������!!!

		 	LDI 	R16,High(RAMEND)
		 	OUT 	SPH,R16
				 
RAM_Flush:	LDI		ZL,Low(SRAM_START)	; ����� ������ ��� � ������
			LDI		ZH,High(SRAM_START)
			CLR		R16					; ������� R16
Flush:		ST 		Z+,R16				; ��������� 0 � ������ ������
			CPI		ZH,High(RAMEND)		; �������� ����� ����������?
			BRNE	Flush				; ���? �������� ������!
 
			CPI		ZL,Low(RAMEND)		; � ������� ���� ������ �����?
			BRNE	Flush
 
			CLR		ZL					; ������� ������
			CLR		ZH
			CLR		R0
			CLR		R1
			CLR		R2
			CLR		R3
			CLR		R4
			CLR		R5
			CLR		R6
			CLR		R7
			CLR		R8
			CLR		R9
			CLR		R10
			CLR		R11
			CLR		R12
			CLR		R13
			CLR		R14
			CLR		R15
			CLR		R16
			CLR		R17
			CLR		R18
			CLR		R19
			CLR		R20
			CLR		R21
			CLR		R22
			CLR		R23
			CLR		R24
			CLR		R25
			CLR		R26
			CLR		R27
			CLR		R28
			CLR		R29
; End coreinit.inc

; Internal Hardware Init  ======================================
	ldi temp, 0x80 //���������� �����������
	out ACSR, temp

	ldi temp, 0x0F //���� C, ������ 4, 5, 6, 7 �� ����, 0, 1, 2, 3 �� �����  
	out DDRC, temp

	ldi temp, 0xF0 //���� C ������ �� ����, 4, 5, 6, 7 � ��������� (��� ������)
	out PORTC, temp

	clr temp //���� ���� D �� ���� 
	out DDRD, temp

	ldi temp, 0xFF
	out PORTD, temp

	ldi temp, 0x2 //���� B �� ����, ��� 1 �� ����� - ��������� ������ ����������������
	out DDRB, temp

	ldi temp, 0xFF 
	out PORTB, temp

	ldi temp, (1<<TOIE0) //���������� ���������� �� ������������ ������� 0
	out TIMSK, temp

	ldi temp, 0b00000001 //������ ������� 0, �������� 1
	out TCCR0, temp

	sei
; End Internal Hardware Init ===================================

; External Hardware Init  ======================================
; End Internal Hardware Init ===================================

; Run ==========================================================
; End Run ======================================================

/////////////////////������������� ����������
	ldi speed, 60

	//1-� ������  ����������� ������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+0, temp
	ldi temp, 255 //��������
	sts timerQueue+0, temp

	//2-� ������  ����������� ������ ��� ������ ������������ ������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 16 //4-� ���
	sts timerQueue+1, temp

; Main =========================================================
start:

	rcall keyScan
	rcall leds

    rjmp start



EEWrite:	
	SBIC EECR, EEWE		; ���� ���������� ������ � ������. �������� � �����
	RJMP EEWrite 		; �� ��� ��� ���� �� ��������� ���� EEWE
 
	CLI					; ����� ��������� ����������.
	OUT EEARL, eeadr	; ��������� ����� ������ ������
	clr temp 		
	OUT EEARH, temp  	; ������� � ������� ���� ������
	OUT EEDR, eedata	; � ���� ������, ������� ��� ����� ���������
 
	SBI EECR, EEMWE		; ������� ��������������
	SBI EECR, EEWE		; ���������� ����
 
	SEI 				; ��������� ����������
	RET 				; ������� �� ���������
 
 
EERead:	
	SBIC EECR, EEWE		; ���� ���� ����� ��������� ������� ������.
	RJMP EERead			; ����� �������� � �����.
	OUT EEARL, eeadr		; ��������� ����� ������ ������
	clr temp
	OUT EEARH, temp 		; ��� ������� � ������� �����
	SBI EECR, EERE 		; ���������� ��� ������
	IN 	eedata, EEDR 		; �������� �� �������� ������ ���������
	RET

leds:
	sbrs flags0, 5 //������� ���� ���������� //��� 5 - ����� ���������������� �����������
	sbi PORTB, 1 //��������� ��������� ����� ���������������� �����������

	sbrc flags0, 5 //������� ���� ������� //��� 5 - ����� ���������������� �����������
	cbi PORTB, 1 //�������� ��������� ����� ���������������� �����������	
		
ret

//������������ ������������ ����������
keyScan:
	sbrs flags0, 4 //������� ���� ���������� //��� 4 - ����������� ������ ��� ������ ������������ ������ ����������
	rjmp km0
	cbr flags0, 16 //�������� ��� 4

	SBIS PINB, 0
	rcall btn0

	SBIS PIND, 1
	rcall btn1

	SBIS PIND, 2
	rcall btn2

	SBIS PIND, 3
	rcall btn3

	SBIS PIND, 4
	rcall btn4

	SBIS PIND, 5
	rcall btn5

	SBIS PIND, 6
	rcall btn6

	SBIS PIND, 7
	rcall btn7

	//������ �������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 16 //4-� ���
	sts timerQueue+1, temp

km0:
ret

//������������ ���������� ������� ������ ��������� ������� ���������� � ������
//����� ������ � i (0-4)
btnPosHandler:
	sbrs flags0, 5 //������� ���� ���������� //��� 5 - ����� ���������������� �����������
	rjmp bm0

	lsl i //�������� ����� ������ �� 2 (� eeprom �� ��� ����� �� ������ �������)
	mov eeadr, i
	mov eedata, curPosL
	rcall EEWrite

	inc i
	mov eeadr, i
	mov eedata, curPosH
	rcall EEWrite

	cbr flags0, 32 //�������� ��� 5
	
	rjmp bm1
bm0:
	
	lsl i //�������� ����� ������ �� 2 (� eeprom �� ��� ����� �� ������ �������)
	mov eeadr, i
	rcall EERead
	mov distPosL, eedata

	inc i
	mov eeadr, i
	rcall EERead
	mov distPosH, eedata

	rcall runTo
	
bm1:
ret

//������������ ��������� ������� ������
btn0:

	/*ldi temp, 0
	mov eeadr, temp
	rcall EERead
	mov distPosL, eedata

	ldi temp, 1
	mov eeadr, temp
	rcall EERead
	mov distPosH, eedata

	rcall runTo*/

	ldi i, 0
	rcall btnPosHandler
ret

btn1:
	ldi i, 1
	rcall btnPosHandler
ret

btn2:
	ldi i, 2
	rcall btnPosHandler
ret

btn3:
	ldi i, 3
	rcall btnPosHandler
ret

btn4:
	ldi i, 4
	rcall btnPosHandler
ret

btn5:
	rcall stepUp
ret

btn6:
	rcall stepDown
ret

btn7:
	sbr flags0, 32 //���������� ��� 5
ret

; End Main =====================================================
; Procedure ====================================================
//������������ ��� ����������� ��������� �� ������� �������(distPosL, distPosH)
//��� ����������� ���������� ����������� ���� ������������ ������� �������
runTo:
	//���������� ��� ������ ������� ��������� ��� ����
	cp curPosH, distPosH
	brlo rm0 //������
	brne rm1 //���� �� ����� ������ ������
	//����� ������ = � ����� ���������� ������� �����
	cp curPosL, distPosL
	brlo rm0 //������
	brne rm1 //���� �� ����� ������ ������
	//���� ����� �� ����� �� �����
	rjmp rm2
rm0://������
	//��������� ����� �����
	sub distPosL, curPosL //�������� �������
	sbc distPosH, curPosH //������� � ���������

	//� distPos �������� ��������� ���-�� �����
	//���������� ��������� ����� ����� � ����������� ����� � �������� ����������
	ldi temp, circleHalfH
	cp distPosH, temp
	brlo rm4 //������
	brne rm5 //���� �� ����� ������ ������
	//����� ������ = � ����� ���������� ������� �����
	ldi temp, circleHalfL
	cp distPosL, temp
	brlo rm4 //������
	brne rm5 //���� �� ����� ������ ������
	//���� ������ ���-�� �� ������ ���� ������
rm4: //���� ������
	clt //���������� �
	rjmp rm3

rm5: //���� �����	

	//��� ���-�� ����� ���� ����� ���-�� �����(distPos)
	ldi temp, circleL
	sub temp, distPosL //�������� �������
	mov distPosL, temp
	ldi temp, circleH
	sbc temp, distPosH //������� � ���������
	mov distPosH, temp

	set //������������� T
	rjmp rm3

rm1://������
	//��������� ����� �����
	mov temp, curPosL
	sub temp, distPosL //�������� �������
	mov distPosL, temp
	mov temp, curPosH
	sbc temp, distPosH //������� � ���������
	mov distPosH, temp

	//� distPos �������� ��������� ���-�� �����
	//���������� ��������� ����� ����� � ����������� ����� � �������� ����������
	ldi temp, circleHalfH
	cp distPosH, temp
	brlo rm6 //������
	brne rm7 //���� �� ����� ������ ������
	//����� ������ = � ����� ���������� ������� �����
	ldi temp, circleHalfL
	cp distPosL, temp
	brlo rm6 //������
	brne rm7 //���� �� ����� ������ ������
	//���� ������ ���-�� �� ������ ���� �����

rm6://���� �����
	set //������������� T
	rjmp rm3

rm7://���� ������

	//��� ���-�� ����� ���� ����� ���-�� �����(distPos)
	ldi temp, circleL
	sub temp, distPosL //�������� �������
	mov distPosL, temp
	ldi temp, circleH
	sbc temp, distPosH //������� � ���������
	mov distPosH, temp

	clt //���������� �
rm3:	
	mov nStepsL, distPosL //���������� ���-�� ����� � ����������
	mov nStepsH, distPosH

	//rcall modCurPos //�������� ������������ ��������� ��� ���������
	rcall nStep //������������ ���������� �����

rm2:
ret

//������������ ���������� n ����� ���������
//����� ����� 2 ����� � nStepsL �������, nStepsH �������
//����������� ��� T 0-������ 1-�����
nStep:
	ldi curspeed, 250 //������ ��� ��������
	sbr flags0, 0x2 //���������� ��� 1 ����� �������� ������ ��� ������ ��� � ����� ������
	sbr flags0, 0x4 //�������� ������� ����

nm3:
	clr temp
	cp nStepsH, temp //���������� � 0
	brne nm0 //�� ����� 0?(nStepsH ����� ���� = 0 ���� > 0) ��������� � ���� �����
	cp nStepsL, temp //���������� � 0
	breq nm1 //������ nStepsH = 0 � ���� nStepsL = 0 �� ������� �� �����
nm0:
	
	sbrs flags0, 1 //������� ���� ���������� //��� 1 - ����������� ������ ��� ������ ������������ ���� ����������
	rjmp nm2
	cbr flags0, 0x2 //�������� ��� 1
	brts nm5//������� ���� T ���������� �.�. �������� �����
	rcall stepUp
	rjmp nm6
nm5:
	rcall stepDown
nm6:
	sts timerQueue+timerQueueLenght+0, curspeed //������������� ������� ��� ������ ��������
	ldi temp, 0x2 //1-� ���
	sts timerQueue+0, temp

	//��������� ���-�� �����
	ldi temp, 1
	sub nStepsL, temp //��������� ������� ����
	brsh nm7 //���� ��� ��������, �� ������
	dec nStepsH //����� ��������� ������� ����
nm7:
	sbrs flags0, 2 //������ �������� ����� �������?
	rjmp nm2 //��� ������
	cp speed, curspeed //���������� ������� � �������� ��������
	breq nm4 //���� ����� �� ������ �� nm4
	subi curspeed, 5 //����������� ������� ��������
	rjmp nm2
nm4:
	cbr flags0, 0x4 //��������� ������� ����
nm2:
	rjmp nm3
nm1:
	ldi temp, 0xFF //��������, ��������� ������
	sts timerQueue+0, temp
	cbr flags0, 0x2 //�������� �������� ��� 1
	cbr flags0, 0x4 //��������� ������� ���� ��������
ret

stepUp:
	mov YL, curstep
	ldi YH, 0
	ldi ZL, low(steps*2)
	ldi ZH, high(steps*2)
	add ZL, YL
	adc ZH, YH

	lpm temp, Z
	out PORTC, temp

	inc curstep
	
	SBRC curstep, 3
	clr curstep

	//��������� ������� �������
	ldi temp, 1 //��������� �������
	add curPosL, temp
	clr temp
	adc curPosH, temp

	//�������� �� ����� �� ������� ����� ����������
	ldi temp, circleH
	cp curPosH, temp 
	brne um0 //���� �� ����� circleH ������ 
	ldi temp, circleL
	cp curPosL, temp
	brne um0 //���� �� ����� circleL ������
	clr curPosL //����� ��������
	clr curPosH

um0:
ret

stepDown:
	mov YL, curstep
	ldi YH, 0
	ldi ZL, low(steps*2)
	ldi ZH, high(steps*2)
	add ZL, YL
	adc ZH, YH

	lpm temp, Z
	out PORTC, temp

	dec curstep
	
	SBRC curstep, 7
	ldi curstep, 0x7

	//�������� �� ����� �� ������� ����� ����������
	clr temp
	cp curPosH, temp 
	brne dm0 //���� �� ����� 0 ������ 
	cp curPosL, temp
	brne dm0 //���� �� ����� 0 ������

	ldi temp, circleH
	mov curPosH, temp
	ldi temp, circleL - 1
	mov curPosL, temp

	rjmp dm1
dm0:

	ldi temp, 1 //��������� �������
	sub curPosL, temp
	clr temp
	sbc curPosH, temp

dm1:
ret


; End Procedure ================================================


; EEPROM =====================================================
							; ������� EEPROM

.ESEG .db 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0













//������������ ��������� �������� ���������
//����� ����� 2 ����� � nStepsL �������, nStepsH �������
//����������� ��� T 0-������ 1-�����
/*modCurPos:
	
	brts mm0 //������� ���� T ���������� �.�. �������� �����

	add curPosL, nStepsL
	adc curPosH, nStepsH
mm3:
	ldi temp, circleH
	cp curPosH, temp
	brlo mm1 //���� ������ 3 �� ������ 
	brne mm2 //���� �� ����� 3 ������ ������ ���� �� ���� �� ����������(������ ����� �����)
	//����� ������ = 3, ��������� ������� ����

	ldi temp, circleL
	cp curPosL, temp
	brlo mm1 //���� ������ C6 �� ������ 
	brne mm2 //���� �� ����� C6 ������ ������ ���� �� ���� �� ����������(������ ����� �����)
	//����� ������ = C6 � ����� ��������
	clr curPosL //��������
	clr curPosH
	rjmp mm1

mm2://��������� 
	ldi temp, circleL 
	sub curPosL, temp //�������� �������
	ldi temp, circleH
	sbc curPosH, temp //������� � ���������
	rjmp mm3
	
mm0: //��������
//�������� �� ����� ����� ����� �������� ����� ������
//������������ ���������� � ������� �������
//����������� �������������� ��� ����������� ����� ������ ������������
	
	push nStepsL//���������� �.�. ������� �����
	push nStepsH

	ldi temp, circleL 
	sub temp, nStepsL//�������� �� ����� ����� �������
	mov nStepsL, temp//����������
	ldi temp, circleH
	sbc temp, nStepsH//�������� �� ����� ����� �������
	mov nStepsH, temp

	clt //���������� � �.�. ��� ����� ����� ��������

	rcall modCurPos 

	set //������������� � �������

	pop nStepsH //������� ��������
	pop nStepsL

mm1:
ret
*/





//ldi curspeed, 100 //240

	/////////////////////������������� ���������� � RAM
	/*//1-� ������
	//ldi temp, 80
	sts timerQueue+timerQueueLenght+0, curspeed
	ldi temp, 0x2 //1-� ���
	sts timerQueue+0, temp

	//2-� ������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 255//0x8
	sts timerQueue+1, temp

	//3-� ������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+2, temp
	ldi temp, 255//0x10
	sts timerQueue+2, temp
*/	

/*sbrs flags0, 1 //������� ���� ���������� //��� 1 - ����������� ������ ��� ������ ������������ ���� ����������
	rjmp m1
	cbr flags0, 0x2 //�������� ��� 1
	rcall stepDown
	dec nsteps
	breq m1

	//ldi temp, 80 //������������� �������
	sts timerQueue+timerQueueLenght+0, curspeed
	ldi temp, 0x2 //1-� ���
	sts timerQueue+0, temp
	*/
/*
	sbrs flags0, 3 //����������� ������ ��� ������ ������������� ���������� �������� ����������? 
	rjmp start
	sbrs flags0, 2 //������ �������� ����� �������?
	rjmp start
	cp speed, curspeed //���������� ������� � �������� ��������
	breq m2
	subi curspeed, 5 //����������� ������� ��������
	cbr flags0, 0x8 //�������� ��� 3 (������ ����������)

	//2-� ������
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 0x8
	sts timerQueue+1, temp

	rjmp start
m2:
	cbr flags0, 0x4 //�������� ��� 2 (��������� ������ �������� �����)
	cbr flags0, 0x8 //�������� ��� 3 (������ ����������)
	*/
/*m3:

	sbrs flags0, 4 //����������� ������ ��� ������ ������������ ������ ����������?
	rjmp m4

	sbis PINB, 0
	rcall stepUp

	sbis PINB, 1
	rcall stepDown

	cbr flags0, 0x10 //�������� ��� 4

	ldi temp, 255
	sts timerQueue+timerQueueLenght+2, temp
	ldi temp, 0x10
	sts timerQueue+2, temp
m4:*/



/*inc task0Clock
	cp task0Clock, curspeed
	brlo tm0 //������� ���� ������
	sbr flags0, 0x2 //���������� ��� 1
	clr task0Clock
tm0:
	*/
	/*sbrs flags0, 2 //��� 2 - ������ ������������� ���������� �������� �������
	rjmp tm1
	inc task1Clock
	cpse ff, task1Clock //������� ��� ���������
	rjmp tm1
	sbr flags0, 0x8 //���������� ��� 3 //��� 3 - ����������� ������ ��� ������ ������������� ���������� �������� ����������
	clr task1Clock
tm1:*/







/*inc tmr0Ovf
	in temp, PORTC
	cpse temp, R18
	rjmp m1
	ldi temp, 0x01
	rjmp m2
m1: 
	clr temp
m2:
	out PORTC, temp*/






	/*cp tmr0Ovf, R18
	brne start

	//clr tmr0Ovf
    
	CPSE temp, R19 //���� �16 = 0 �� �� ������ �� �1, � ������ ������ �������������
	rjmp m1
	inc temp
	rjmp end

m1:
	SBRS temp, 3 //���� ���������� ��� �� ������� ���� ������� //���� 3 ��� ����� �� ����� ���������� ������� � 1
	rjmp m2
	ldi temp, 0x01
	rjmp end

m2:
	lsl temp

end:	
	out PORTC, temp*/



	/*
	in temp, PORTC

	CPSE temp, R19 //���� �16 = 0 �� �� ������ �� �1, � ������ ������ �������������
	rjmp m1
	inc temp
	rjmp end

m1:
	SBRS temp, 3 //���� ���������� ��� �� ������� ���� ������� //���� 3 ��� ����� �� ����� ���������� ������� � 1
	rjmp m2
	ldi temp, 0x01
	rjmp end

m2:
	lsl temp

end:	
	out PORTC, temp
	*/