;= Start 	macro.inc ========================================
;= End 		macro.inc ========================================
.def temp = R16
.def temp2 = R17
.def temp3 = R18
.def temp4 = R19
.def i = R21
.def softTimerflags0 = R23
//.def ProcedureParametr = R24 //���������� ��� �������� �������� � ������������������� ���������
//��� 0 - ���������� ������ 1 ����������(��������� ������)
//��� 1 - ���������� ������ 2 ����������(��������� �������)

.def softTimerflags1 = R24
//��� 0 - 16�� ��������� ���������� ������ 1 ����������(�������� RGB �����: 0 - ���� ��������, 1 - ������� ����)

.def LedStripflags = R22
//
//��� 1 - 0 - �������� RGB �����: ���� ���������� �������, 1 - ���� ���������� �������

.def sysFlags0 = R20
//��� 3 - 1 - ��� ���� ��������� ��������� ������ � ���������� buttonsState
//��� 4 - 1 - �������� RGB ����� ��������, 0 - ���������


.equ timerQueueLenght0 = 2 //����� ��������� timerQueue0 (���� � 1) ���-�� 8�� ��������� ���������� ��������
.equ timerQueueLenght1 = 1 //����� ��������� timerQueue1 (���� � 1) ���-�� 16�� ��������� ���������� ��������
.equ qtyButtons = 7 //���-�� ������ (���� � 1)
.equ bounce = 5//���-�� ������(�������) ����� �������� ����� ������� ��������� ������ �����������
//.equ bounce = 1
.equ brightnessIncreaseDelay = 2 //(���� 2)�������� ����� ������ ��� ���������� ������� (��� ����, ��� ���� �������� ��������� �������)
.equ brightnessDecreaseDelay = 3//(���� 4)�������� ����� ������ ��� ���������� ������� (��� ����, ��� ���� �������� ��������� �������)
.equ delayPhase1 = 255 //����� ���� 1 - �������� ����� ����������� �������(����� ����� ���� ����������)
.equ delayPhase3 = 10 //����� ���� 3 - �������� ����� ����������� �������(����� ����� ���������� �������)
/*
���� 1 - ��������
���� 2 - ���������� �������
���� 3 - ��������
���� 4 - ���������� �������
����� ����� ���� 1
*/
; RAM ========================================================
		.DSEG

timerQueue0: .byte (timerQueueLenght0*2) //������� ������������ ������� 0
timerQueue1: .byte (timerQueueLenght1*2) //������� ������������ 16�� ���������� ������� 1
//������ timerQueueLenght0 ���� - ����� ����� � ����� ������(softTimerflags0) 255 - ������ ��������
//��������� timerQueueLenght0 ���� - ���������� ������������ �������
buttonsCounters: .byte (qtyButtons) //���������� ��� �������� �������� �������� ���������� ������(�������) ���������� ������ � ��������� �������� �� ��������
buttonsState: .byte(1) //���� �������� ��������� ������ 0�  - 8� ������,.. .1 - ������ �� ������(������� ������� �� �����), 0 - ������
softTimerVar1Delay: .byte(1) //�������� �������� ����� ������ ��� �������� ������� (��� ����, ��� ���� �������� ��������� �������), ������������ ��� �������� �������� � ��������� ������������� �������
softTimerVar2Delay: .byte(1) //���������� ������� ���� �������� 
; FLASH ======================================================
		.CSEG

		.ORG 0x0000 ;RESET External Pin, Power-on Reset, Brown-out Reset and Watchdog System
		RJMP	Reset
		.ORG 0x0002 ;INT0 External Interrupt Request 0
		RETI
		.ORG 0x0004 ;INT1 External Interrupt Request 0
		RETI
		.ORG 0x0006 ;PCINT0 Pin Change Interrupt Request 0
		RETI
		.ORG 0x0008 ;PCINT1 Pin Change Interrupt Request 1
		RETI
		.ORG 0x000A ;PCINT2 Pin Change Interrupt Request 2
		RETI
		.ORG 0x000C ;WDT Watchdog Time-out Interrupt
		RETI
		.ORG 0x000E ;TIMER2_COMPA Timer/Counter2 Compare Match A
		RETI
		.ORG 0x0010 ;TIMER2_COMPB Timer/Coutner2 Compare Match B
		RETI
		.ORG 0x0012 ;TIMER2_OVF Timer/Counter2 Overflow
		RETI
		.ORG 0x0014 ;TIMER1_CAPT Timer/Counter1 Capture Event
		RETI
		.ORG 0x0016 ;TIMER1_COMPA Timer/Counter1 Compare Match A
		RETI
		.ORG 0x0018 ;TIMER1_COMPB Timer/Coutner1 Compare Match B
		RETI
		.ORG 0x001A ;TIMER1_OVF Timer/Counter1 Overflow
		RJMP timer1Ovf
		.ORG 0x001C ;TIMER0_COMPA Timer/Counter0 Compare Match A
		RETI
		.ORG 0x001E ;TIMER0_COMPB Timer/Coutner0 Compare Match B
		RETI
		.ORG 0x0020 ;TIMER0_OVF Timer/Counter0 Overflow
		RJMP timer0Ovf
		.ORG 0x0022 ;SPI STC SPI Serial Transfer Complete
		RETI
		.ORG 0x0024 ;USART_RX USART Rx Complete
		RETI
		.ORG 0x0026 ;USART_UDRE USART Data Register Empty
		RETI
		.ORG 0x0028 ;USART_TX USART Tx Complete
		RETI
		.ORG 0x002A ;ADC ADC Conversion Complete
		RETI
		.ORG 0x002C ;EE READY EEPROM Ready
		RETI
		.ORG 0x002E ;ANALOG COMP Analog Comparator
		RETI

;===========================================================
; Interrupts =============================================
timer0Ovf:
	push temp
	in temp, SREG
	push temp
	push YL
	push YH
	push i

	clr i //���������� ������� ����� �� 0 �� timerQueueLenght0

	LDI YL, low(timerQueue0)
	LDI YH, high(timerQueue0)
tm0:
	ld temp, Y+ //������ �����
	cpi temp, 0xFF //����� ����� 255?
	breq tm1 //��, ���������� ���� ������
	push temp //���, ���������� �����
	ldd temp, Y+timerQueueLenght0-1 //������ ���������� ������������ �������
	dec temp //���������
	brne tm2 //���� ���������� �� ����� 0 �� ��������� �� tm2
	pop temp //������� �����
	or softTimerflags0, temp //������ ��� �� �����
	ser temp
	st -Y, temp //����� �������� 255
	ld temp, Y+//������� ����������� Y
	rjmp tm1
tm2:
	std Y+timerQueueLenght0-1, temp //���������� ����������� ����������
	pop temp //����������� ����(�.� ����� ���������� ����������)
tm1:
	inc i
	cpi i, timerQueueLenght0
	brne tm0
	
	pop i
	pop YH
	pop YL
	pop temp
	out SREG, temp
	pop temp

reti

timer1Ovf:
	push temp
	in temp, SREG
	push temp
	push YL
	push YH
	push i

	clr i //���������� ������� ����� �� 0 �� timerQueueLenght1

	LDI YL, low(timerQueue1)
	LDI YH, high(timerQueue1)
tm10:
	ld temp, Y+ //������ �����
	cpi temp, 0xFF //����� ����� 255?
	breq tm11 //��, ���������� ���� ������
	push temp //���, ���������� �����
	ldd temp, Y+timerQueueLenght1-1 //������ ���������� ������������ �������
	dec temp //���������
	brne tm12 //���� ���������� �� ����� 0 �� ��������� �� tm12
	pop temp //������� �����
	or softTimerflags1, temp //������ ��� �� �����
	ser temp
	st -Y, temp //����� �������� 255
	ld temp, Y+//������� ����������� Y
	rjmp tm11
tm12:
	std Y+timerQueueLenght1-1, temp //���������� ����������� ����������
	pop temp //����������� ����(�.� ����� ���������� ����������)
tm11:
	inc i
	cpi i, timerQueueLenght1
	brne tm10
	
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
/*PD2 - ����� �� ����
  PD3 - ����� �� RGB �����, ����� R (���)
  PD4 - ����� �� ������ ������ ����� ����� (1-������ ���������� � �������� ������)
  PD5 - ����� �� RGB �����, ����� B (���)
  PD6 - ����� �� RGB �����, ����� G (���)
  PD7 - �������
  
  PB1 - ������� (���)
  PB2 - �������� ����� (���)
  PB3 - ������� (���)

  PC0 - ���� ������ 8 (��������� � ���������� �����)
  PC1 - ���� ������ 6 (��������� � ���������� RGB ����)
  PC2 - ���� ������ 5
  PC3 - ���� ������ 4
  PC4 - ���� ������ 3 (��������� � ���������� �����)
  PC5 - ���� ������ 2 (������� �������)
  PC6 - ���� ������ 1  *����������� ���������*

  [1] [3] [5] [7]
  [2] [4] [6] [8]

*/

	ldi temp, 0x80 //���������� �����������
	out ACSR, temp

	ldi temp, 0b01000100 //���� D, ������ 2,6 �� �����, ��������� �� ���� � ���������
	out DDRD, temp

	ldi temp, 0b10111011
	out PORTD, temp

	ldi temp, 0b00000100//���� B, ����� 2 �� �����, ��������� �� ���� � ���������
	out DDRB, temp

	ldi temp, 0b11111011
	out PORTB, temp

	clr temp		 //���� C, ������ 0-5 �� ���� � ���������
	out DDRC, temp

	ldi temp, 0b00111111
	out PORTC, temp

	//��� ����� �������� ������������
	//�������� ������

	ldi temp, 0b00000100 //������ ������� 0, �������� 256
	//ldi temp, 0b00000001
	out TCCR0B, temp

	ldi temp, (1<<TOIE0) //���������� ���������� �� ������������ ������� 0
	sts TIMSK0, temp
	
	ldi temp, 0b00000010 //������ ������� 1, �������� 8
	//ldi temp, 0b00000001
	LDI YL, low(TCCR1B) //������� MEMORY MAPPED
	LDI YH, high(TCCR1B)
	st Y, temp

	ldi temp, 0b00000001 //���������� ���������� �� ������������ ������� 1
	LDI YL, low(TIMSK1) //������� MEMORY MAPPED
	LDI YH, high(TIMSK1)
	st Y, temp

	sei

; End Internal Hardware Init ===================================

; External Hardware Init  ======================================
; End Internal Hardware Init ===================================

; Run ==========================================================
; End Run ======================================================

/////////////////////������������� ����������
	rcall initSoftTimer0 //1-� ����������� ������ - ������������ ������

	LDI YL, low(buttonsState) //������ ����� ���������� ��������� � Y
	LDI YH, high(buttonsState)
	ser temp //������������� ��������� �������� �������� buttonsState, ��� ���� � 1 - ���������� ��� ������ �� ������
	st Y, temp
	
//rcall RGBStripInitialization
; Main =========================================================
start:
	
	rcall keyScan
	rcall buttonHandler
	rcall RGBStrip

    rjmp start

//1-� ����������� ������ - ������������ ������
initSoftTimer0:
	ldi temp, 1 //1 - 4,096 ��������
	sts timerQueue0+timerQueueLenght0+0, temp
	ldi temp, 0b00000001
	sts timerQueue0+0, temp
ret

//2-� ����������� ������ - ��������� ������� (������������������� ���������, ��������: ��������)
initSoftTimer1:
	LDI YL, low(softTimerVar1Delay) //������ ����� ���������� �������� ��������� ������� � Y
	LDI YH, high(softTimerVar1Delay)
	ld temp, Y

	sts timerQueue0+timerQueueLenght0+1, temp
	ldi temp, 0b00000010
	//ldi temp, 255
	sts timerQueue0+1, temp	
ret

//1-� 16�� ��������� ����������� ������ - �������� RGB �����
initSoftTimer10:
	LDI YL, low(softTimerVar2Delay) //������ ����� ���������� �������� � Y
	LDI YH, high(softTimerVar2Delay)
	ld temp, Y
	
	sts timerQueue1+timerQueueLenght1+0, temp
	ldi temp, 0b00000001
	//ldi temp, 255
	sts timerQueue1+0, temp	
ret


/*

  .def LedStripflags = R22
//��� 1 - 0 - �������� RGB �����: ���� ���������� �������, 1 - ���� ���������� �������

.equ brightnessIncreaseDelay = 3
.equ brightnessDecreaseDelay = 5
*/



//������� ��������� ������������� �������� RGB �����
RGBStripInitialization:
	clr temp
	out OCR0A, temp

	ldi temp, 0b10000011 //Fast PWM, Clear OC0A on Compare Match, 
	out TCCR0A, temp

	LDI YL, low(softTimerVar1Delay) //������ ����� ���������� �������� ��������� ������� � Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessIncreaseDelay //������������� ��������� �������� �������� softTimerVar1Delay
	st Y, temp
	rcall initSoftTimer1 //2-� ����������� ������ - ��������� ������� RGB ����� (������������������� ���������, ��������: ��������)

	ori softTimerflags1, 0b00000001 //��������� ������� �����, ����� 1 ���, ����� � ��������� ����
	ori sysFlags0, 0b00010000 //�������� ��������
ret

//������� ���������� �������� RGB �����
RGBStripOFF:
	andi sysFlags0, 0b11101111 //��������� ��������

	clr temp //��������� ���
	out TCCR0A, temp
	andi LedStripflags, 0b11111101 //� ������ ����(���������� � 0) �� ���������� �������
ret

//������� ������ �������� RGB �����
RGBStrip:
	sbrs sysFlags0, 4 //������� �� s0 ���� ��� 4 ������� �.�. �������� ���������
	rjmp s0
	//����� ��������

	sbrs softTimerflags1, 0 //������� �� s1 ���� ��� 0 ������� �.�. ���� ��������
	rjmp s1

	sbrs softTimerflags0, 1 //������� �� s4 ���� ��� 1 ������� �.�. �� ��������� ����� ��������� �������
	rjmp s4
	andi softTimerflags0, 0b11111101 //���������� ��� 1

	in temp3, OCR0A //��������� ���������� = �������

	sbrc LedStripflags, 1 //������� �� s2 ���� ��� 1 ���������� �.�. ���������� �������
	rjmp s2
	//��� ���� ���������� �������
	inc temp3 //���������� ����������� �� 1
	brne s3 //������� ���� ����� ���������� ������� �� ���� = 0
	ser temp3 //����� ������������� ������� � ������� 255 
	ori LedStripflags, 0b00000010 //� ������ ���� �� ���������� �������

	LDI YL, low(softTimerVar1Delay) //������ ����� ���������� �������� ��������� ������� � Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessDecreaseDelay
	st Y, temp

	//������������������ ����������� ������ ��� ������ ��������
	ldi temp, delayPhase3

	/*LDI YL, low(softTimerVar2Delay) //������ ����� ���������� �������� � Y
	LDI YH, high(softTimerVar2Delay)
	 //������������� �������� �������� softTimerVar2Delay
	st Y, temp2
	rcall initSoftTimer10 //1-� 16�� ��������� ����������� ������ - �������� RGB �����
	andi LedStripflags, 0b11111110 //������������� ���� ��������*/

	rjmp s5

	s2:
	//��� ���� ���������� �������
	dec temp3 //���������� ��������� �� 1
	brne s3 //������� ���� ����� ���������� ������� �� ���� = 0
	andi LedStripflags, 0b11111101 //� ������ ����(���������� � 0) �� ���������� �������

	LDI YL, low(softTimerVar1Delay) //������ ����� ���������� �������� ��������� ������� � Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessIncreaseDelay
	st Y, temp

	//������������������ ����������� ������ ��� ������ ��������
	ldi temp, delayPhase1

	s5:
	LDI YL, low(softTimerVar2Delay) //������ ����� ���������� �������� � Y
	LDI YH, high(softTimerVar2Delay)
	 //������������� �������� �������� softTimerVar2Delay
	st Y, temp
	rcall initSoftTimer10 //1-� 16�� ��������� ����������� ������ - �������� RGB �����
	andi softTimerflags1, 0b11111110 //������������� ���� ��������

	s3:
	out OCR0A, temp3
	rcall initSoftTimer1//�������������� 2-� ����������� ������ - ��������� ������� RGB ����� (������������������� ���������, ��������: ��������)

	s1:
	//��� ���� ��������


	s4:

	s0:
ret


	/*sbrs sysFlags0, 0 //������� �� s0 ���� ��� 0 ������� �.�. ����� ������� ������� �� ���������
	rjmp s0
	//����� ��������

	in temp, OCR0A //��������� ���������� = �������

	sbrc sysFlags0, 1 //������� �� s1 ���� ��� 1 ���������� �.�. ���������� ��������� ����������
	rjmp s1

	inc temp //����� ���������� ����������� �� 1
	brne s2 //������� ���� ����� ���������� ������� �� ���� = 0
	ser temp //����� ������������� ������� � ������� 255 
	sbr sysFlags0, 0b00000010 //� ������ ���� �� ���������� �������

s1: 
	dec temp //���������� ��������� �� 1
	brne s2 //������� ���� ����� ���������� ������� �� ���� = 0
	cbr sysFlags0, 0b00000010 //� ������ ����(���������� � 0) �� ���������� �������
s2:

	out OCR0A, temp
	cbr sysFlags0, 0b00000001 //���������� ���

	rcall initSoftTimer1 //������������������ ������

s0:
ret*/

//������������ ������������ ����������
keyScan:
	sbrs softTimerflags0, 0 //������� ���� ���������� //��� 0 - ����������� ������ ��� ������ ������������ ������ ����������
	rjmp km0
	cbr softTimerflags0, 1 //�������� ��� 0

	LDI YL, low(buttonsState) //������ ����� ���������� ��������� � Y
	LDI YH, high(buttonsState)
	clr i //����������-������� �����
	ldi temp3, 0b00000001 //����� ��� ��������� ������ ����
	LDI ZL, low(buttonsCounters) //������ ����� ���������� � Z
	LDI ZH, high(buttonsCounters)

km1:
	ld temp, Y //��������� ���������� � ������
	in temp2, PINC //��������� ��������� ������

	AND temp, temp3 //� ����� �������� ������ ������ � ������ ������ ���
	AND temp2, temp3
	eor temp, temp2 //���� ��� ��������� � ����� ���������� �� ���� ��������� �� ���������� ������ ������ �������� ��������� � ����� ������� temp �� ����� ����� 0

	breq km2 //������� ���� 0 �.�. ���� ����������
	//����� �������������� ������� ������
	
	ld temp2, Z //��������� ���������� � ������
	inc temp2 //����������� ��
	cpi temp2, bounce //���������� ������������ �������� � ���������
	brne km3 //�����?
	//��
	ld temp4, Y //��������� ���������� ��������� ������ � ������
	eor temp4, temp //����������� ��� �.�. ������� ������� ��������� ������ ����������
	st Y, temp4 //���������� ������� ���������� ��������� ������
	clr temp2 //�������� ���������� ������� ��� ���� ������
	sbr sysFlags0, 0b00001000 //������������� ��� 3 (��� ���� ��������� ��������� ������ � ���������� buttonsState)
km3:
	//���
	st Z, temp2 //���������� ����������
km2:
	ld temp, Z+ //��������� ���������� � ������ � ������������������ ��� ���� ����� �������� �������� ���������� ���� ����������, ���� �������� �� �����
	lsl temp3 //������ ����� �����, ��� ��������� ���������� ����
	inc i
	cpi i, qtyButtons+1
	brne km1

	rcall initSoftTimer0
km0:
ret

/*PD2 - ����� �� ����
  PD3 - ����� �� RGB �����, ����� R (���)
  PD4 - ����� �� ������ ������ ����� ����� (1-������ ���������� � �������� ������)
  PD5 - ����� �� RGB �����, ����� B (���)
  PD6 - ����� �� RGB �����, ����� G (���)
  PD7 - �������
  
  PB1 - ������� (���)
  PB2 - �������� ����� (���)
  PB3 - ������� (���)

  PC0 - ���� ������ 8 (��������� � ���������� �����)
  PC1 - ���� ������ 6 (��������� � ���������� RGB ����)
  PC2 - ���� ������ 5
  PC3 - ���� ������ 4
  PC4 - ���� ������ 3 (��������� � ���������� �����)
  PC5 - ���� ������ 2 (������� �������)
  PC6 - ���� ������ 1  *����������� ���������*

  [1] [3] [5] [7]
  [2] [4] [6] [8]

*/

//������������ ��������� ������� ������
buttonHandler:
	sbrs sysFlags0, 3 //������� ���� ���������� ////��� 3 - 1 - ��� ���� ��������� ��������� ������ � ���������� buttonsState
	rjmp bm0
	cbr sysFlags0, 0b00001000 //�������� ��� 3

	LDI YL, low(buttonsState) //������ ����� ���������� ��������� � Y
	LDI YH, high(buttonsState)
	ld temp, Y //��������� ���������� ��������� ������ � ������

	sbrs temp, 0
	rcall btn8

	sbrs temp, 2
	rcall btn5

	sbrs temp, 4
	rcall btn3

	//sbrs temp, 5
	//rcall btn2

bm0:
ret

/*btn2:
	SBIS PORTB, 2
	rjmp btn2m0
	CBI PORTB, 2
	rjmp btn2m1
btn2m0:
	SBI PORTB, 2
btn2m1:
ret*/

btn8: //(��������� � ���������� �����)
	SBIS PORTD, 2
	rjmp btn8m0
	CBI PORTD, 2
	rjmp btn8m1
btn8m0:
	SBI PORTD, 2
btn8m1:
ret

btn3: //(��������� � ���������� �����)
	SBIS PORTB, 2
	rjmp btn3m0
	CBI PORTB, 2
	rjmp btn3m1
btn3m0:
	SBI PORTB, 2
btn3m1:
ret

btn5:
	SBRS sysFlags0, 4
	rjmp btn5m0
	rcall RGBStripOFF
	rjmp btn5m1
btn5m0:
	rcall RGBStripInitialization
btn5m1:
ret


















//������������ ������������ ����������
/*keyScan:
	sbrs sysFlags0, 4 //������� ���� ���������� //��� 4 - ����������� ������ ��� ������ ������������ ������ ����������
	rjmp km0
	cbr sysFlags0, 16 //�������� ��� 4

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
	sts timerQueue0+timerQueueLenght0+1, temp
	ldi temp, 16 //4-� ���
	sts timerQueue0+1, temp

km0:
ret

//������������ ��������� ������� ������
btn0:

	*//*ldi temp, 0
	mov eeadr, temp
	rcall EERead
	mov distPosL, eedata

	ldi temp, 1
	mov eeadr, temp
	rcall EERead
	mov distPosH, eedata

	rcall runTo*/

	/*ldi i, 0
	rcall btnPosHandler
ret

btn1:
	ldi i, 1
	rcall btnPosHandler
ret*/