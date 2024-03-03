;= Start 	macro.inc ========================================
;= End 		macro.inc ========================================
.def temp = R16
.def temp2 = R17
.def temp3 = R18
.def temp4 = R19
.def i = R21
.def softTimerflags0 = R23
//.def ProcedureParametr = R24 //переменная для передачи значения в параметризированную процедуру
//бит 0 - программый таймер 1 переполнен(обработка кнопок)
//бит 1 - программый таймер 2 переполнен(изменение яркости)

.def softTimerflags1 = R24
//бит 0 - 16ти рязрядный программый таймер 1 переполнен(анимация RGB ленты: 0 - фаза ожидания, 1 - рабочая фаза)

.def LedStripflags = R22
//
//бит 1 - 0 - анимация RGB ленты: фаза увеличения яркости, 1 - фаза уменьшения яркости

.def sysFlags0 = R20
//бит 3 - 1 - был факт изменения состояния кнопки в переменной buttonsState
//бит 4 - 1 - анимация RGB ленты включена, 0 - выключена


.equ timerQueueLenght0 = 2 //длина структуры timerQueue0 (счет с 1) кол-во 8ми разрядных программых таймеров
.equ timerQueueLenght1 = 1 //длина структуры timerQueue1 (счет с 1) кол-во 16ти разрядных программых таймеров
.equ qtyButtons = 7 //кол-во кнопок (счет с 1)
.equ bounce = 5//кол-во циклов(времени) после которого можно считать состояние кнопки достоверным
//.equ bounce = 1
.equ brightnessIncreaseDelay = 2 //(фаза 2)задержка между шагами при увеличении яркости (чем выше, тем ниже скорость изменения яркости)
.equ brightnessDecreaseDelay = 3//(фаза 4)задержка между шагами при уменьшении яркости (чем выше, тем ниже скорость изменения яркости)
.equ delayPhase1 = 255 //время фазы 1 - задержка перед увеличением яркости(после конца фазы уменьшения)
.equ delayPhase3 = 10 //время фазы 3 - задержка после увеличением яркости(перед фазой уменьшения яркости)
/*
Фаза 1 - ожидание
Фаза 2 - увеличение яркости
Фаза 3 - ожидание
Фаза 4 - уменьшение яркости
Далее опять Фаза 1
*/
; RAM ========================================================
		.DSEG

timerQueue0: .byte (timerQueueLenght0*2) //очередь программного таймера 0
timerQueue1: .byte (timerQueueLenght1*2) //очередь программного 16ти рязрядного таймера 1
//первые timerQueueLenght0 байт - маски битов в байте флагов(softTimerflags0) 255 - таймер выключен
//остальные timerQueueLenght0 байт - переменные программного таймера
buttonsCounters: .byte (qtyButtons) //переменные для хранения текущего значения количества циклов(времени) нахождения кнопки в состоянии отличном от текущего
buttonsState: .byte(1) //биты текущего состояния кнопок 0й  - 8я кнопка,.. .1 - значит не нажата(высокий уровень на порту), 0 - нажата
softTimerVar1Delay: .byte(1) //Значение задержки между шагами при измеении яркости (чем выше, тем ниже скорость изменения яркости), используется для передачи значения а процедуру инициализации таймера
softTimerVar2Delay: .byte(1) //переменная времени фазы ожидания 
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

	clr i //переменная счетчик цикла от 0 до timerQueueLenght0

	LDI YL, low(timerQueue0)
	LDI YH, high(timerQueue0)
tm0:
	ld temp, Y+ //грузим маску
	cpi temp, 0xFF //маска равна 255?
	breq tm1 //да, пропускаем этот таймер
	push temp //нет, запоминаем маску
	ldd temp, Y+timerQueueLenght0-1 //грузим переменную программного таймера
	dec temp //уменьшаем
	brne tm2 //если переменная не равна 0 то переходим на tm2
	pop temp //достаем маску
	or softTimerflags0, temp //ставим бит по маске
	ser temp
	st -Y, temp //пишем заглушку 255
	ld temp, Y+//обратно увеличиваем Y
	rjmp tm1
tm2:
	std Y+timerQueueLenght0-1, temp //записываем уменьшенную переменную
	pop temp //освобождаем стек(т.к перед ветвлением записывали)
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

	clr i //переменная счетчик цикла от 0 до timerQueueLenght1

	LDI YL, low(timerQueue1)
	LDI YH, high(timerQueue1)
tm10:
	ld temp, Y+ //грузим маску
	cpi temp, 0xFF //маска равна 255?
	breq tm11 //да, пропускаем этот таймер
	push temp //нет, запоминаем маску
	ldd temp, Y+timerQueueLenght1-1 //грузим переменную программного таймера
	dec temp //уменьшаем
	brne tm12 //если переменная не равна 0 то переходим на tm12
	pop temp //достаем маску
	or softTimerflags1, temp //ставим бит по маске
	ser temp
	st -Y, temp //пишем заглушку 255
	ld temp, Y+//обратно увеличиваем Y
	rjmp tm11
tm12:
	std Y+timerQueueLenght1-1, temp //записываем уменьшенную переменную
	pop temp //освобождаем стек(т.к перед ветвлением записывали)
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

Reset:   	LDI 	R16,Low(RAMEND)	; Инициализация стека
		    OUT 	SPL,R16			; Обязательно!!!

		 	LDI 	R16,High(RAMEND)
		 	OUT 	SPH,R16
				 
RAM_Flush:	LDI		ZL,Low(SRAM_START)	; Адрес начала ОЗУ в индекс
			LDI		ZH,High(SRAM_START)
			CLR		R16					; Очищаем R16
Flush:		ST 		Z+,R16				; Сохраняем 0 в ячейку памяти
			CPI		ZH,High(RAMEND)		; Достигли конца оперативки?
			BRNE	Flush				; Нет? Крутимся дальше!
 
			CPI		ZL,Low(RAMEND)		; А младший байт достиг конца?
			BRNE	Flush
 
			CLR		ZL					; Очищаем индекс
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
/*PD2 - выход на неон
  PD3 - выход на RGB ленту, канал R (ШИМ)
  PD4 - выход на оптрон кнопки повер банка (1-оптрон включается и замыкает кнопку)
  PD5 - выход на RGB ленту, канал B (ШИМ)
  PD6 - выход на RGB ленту, канал G (ШИМ)
  PD7 - незанят
  
  PB1 - незанят (ШИМ)
  PB2 - передние ленты (ШИМ)
  PB3 - незанят (ШИМ)

  PC0 - вход кнопка 8 (включение и выключение неона)
  PC1 - вход кнопка 6 (включение и выключение RGB лент)
  PC2 - вход кнопка 5
  PC3 - вход кнопка 4
  PC4 - вход кнопка 3 (включение и выключение ленты)
  PC5 - вход кнопка 2 (мигнуть лентами)
  PC6 - вход кнопка 1  *неправильно подключил*

  [1] [3] [5] [7]
  [2] [4] [6] [8]

*/

	ldi temp, 0x80 //отключение компаратора
	out ACSR, temp

	ldi temp, 0b01000100 //порт D, выводы 2,6 на выход, остальные на вход с подтяжкой
	out DDRD, temp

	ldi temp, 0b10111011
	out PORTD, temp

	ldi temp, 0b00000100//порт B, вывод 2 на выход, остальные на вход с подтяжкой
	out DDRB, temp

	ldi temp, 0b11111011
	out PORTB, temp

	clr temp		 //порт C, выводы 0-5 на вход с подтяжкой
	out DDRC, temp

	ldi temp, 0b00111111
	out PORTC, temp

	//ТУТ нужно сбросить предделитель
	//защитить выходы

	ldi temp, 0b00000100 //запуск таймера 0, делитель 256
	//ldi temp, 0b00000001
	out TCCR0B, temp

	ldi temp, (1<<TOIE0) //Разрешение прерывания по переполнению таймера 0
	sts TIMSK0, temp
	
	ldi temp, 0b00000010 //запуск таймера 1, делитель 8
	//ldi temp, 0b00000001
	LDI YL, low(TCCR1B) //регистр MEMORY MAPPED
	LDI YH, high(TCCR1B)
	st Y, temp

	ldi temp, 0b00000001 //Разрешение прерывания по переполнению таймера 1
	LDI YL, low(TIMSK1) //регистр MEMORY MAPPED
	LDI YH, high(TIMSK1)
	st Y, temp

	sei

; End Internal Hardware Init ===================================

; External Hardware Init  ======================================
; End Internal Hardware Init ===================================

; Run ==========================================================
; End Run ======================================================

/////////////////////Инициализация переменных
	rcall initSoftTimer0 //1-й программный таймер - сканирование кнопок

	LDI YL, low(buttonsState) //грузим адрес переменной состояния в Y
	LDI YH, high(buttonsState)
	ser temp //устанавливаем начальное значение пеменной buttonsState, все биты в 1 - изначально все кнопки не нажаты
	st Y, temp
	
//rcall RGBStripInitialization
; Main =========================================================
start:
	
	rcall keyScan
	rcall buttonHandler
	rcall RGBStrip

    rjmp start

//1-й программный таймер - сканирование кнопок
initSoftTimer0:
	ldi temp, 1 //1 - 4,096 миллисек
	sts timerQueue0+timerQueueLenght0+0, temp
	ldi temp, 0b00000001
	sts timerQueue0+0, temp
ret

//2-й программный таймер - изменение яркости (параметризированная процедура, параметр: задержка)
initSoftTimer1:
	LDI YL, low(softTimerVar1Delay) //грузим адрес переменной задержки изменения яркости в Y
	LDI YH, high(softTimerVar1Delay)
	ld temp, Y

	sts timerQueue0+timerQueueLenght0+1, temp
	ldi temp, 0b00000010
	//ldi temp, 255
	sts timerQueue0+1, temp	
ret

//1-й 16ти рязрядный программный таймер - анимация RGB ленты
initSoftTimer10:
	LDI YL, low(softTimerVar2Delay) //грузим адрес переменной задержки в Y
	LDI YH, high(softTimerVar2Delay)
	ld temp, Y
	
	sts timerQueue1+timerQueueLenght1+0, temp
	ldi temp, 0b00000001
	//ldi temp, 255
	sts timerQueue1+0, temp	
ret


/*

  .def LedStripflags = R22
//бит 1 - 0 - анимация RGB ленты: фаза увеличения яркости, 1 - фаза уменьшения яркости

.equ brightnessIncreaseDelay = 3
.equ brightnessDecreaseDelay = 5
*/



//функция начальной инициализации анимации RGB ленты
RGBStripInitialization:
	clr temp
	out OCR0A, temp

	ldi temp, 0b10000011 //Fast PWM, Clear OC0A on Compare Match, 
	out TCCR0A, temp

	LDI YL, low(softTimerVar1Delay) //грузим адрес переменной задержки изменения яркости в Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessIncreaseDelay //устанавливаем начальное значение пеменной softTimerVar1Delay
	st Y, temp
	rcall initSoftTimer1 //2-й программный таймер - изменение яркости RGB ленты (параметризированная процедура, параметр: задержка)

	ori softTimerflags1, 0b00000001 //запускаем рабочий режим, нужно 1 раз, далее в алгоритме само
	ori sysFlags0, 0b00010000 //включаем анимацию
ret

//функция выключения анимации RGB ленты
RGBStripOFF:
	andi sysFlags0, 0b11101111 //выключаем анимацию

	clr temp //выключаем ШИМ
	out TCCR0A, temp
	andi LedStripflags, 0b11111101 //и ставил флаг(сбрасываем в 0) на увеличение яркости
ret

//функция работы анимации RGB ленты
RGBStrip:
	sbrs sysFlags0, 4 //переход на s0 если бит 4 сброшен т.е. анимация выключена
	rjmp s0
	//иначе работаем

	sbrs softTimerflags1, 0 //переход на s1 если бит 0 сброшен т.е. фаза ожидания
	rjmp s1

	sbrs softTimerflags0, 1 //переход на s4 если бит 1 сброшен т.е. не наступило время изменения яркости
	rjmp s4
	andi softTimerflags0, 0b11111101 //сбрасываем бит 1

	in temp3, OCR0A //считываем скважность = яркость

	sbrc LedStripflags, 1 //переход на s2 если бит 1 установлен т.е. уменьшения яркости
	rjmp s2
	//тут фаза увеличения яркости
	inc temp3 //скважность увеличиваем на 1
	brne s3 //переход если после увеличения регистр не стал = 0
	ser temp3 //иначе устанавливаем обратно в регистр 255 
	ori LedStripflags, 0b00000010 //и ставил флаг на уменьшение яркости

	LDI YL, low(softTimerVar1Delay) //грузим адрес переменной задержки изменения яркости в Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessDecreaseDelay
	st Y, temp

	//переинициализируем программный таймер для задачи ожидания
	ldi temp, delayPhase3

	/*LDI YL, low(softTimerVar2Delay) //грузим адрес переменной задержки в Y
	LDI YH, high(softTimerVar2Delay)
	 //устанавливаем значение пеменной softTimerVar2Delay
	st Y, temp2
	rcall initSoftTimer10 //1-й 16ти рязрядный программный таймер - анимация RGB ленты
	andi LedStripflags, 0b11111110 //устанавливаем фазу ожидания*/

	rjmp s5

	s2:
	//тут фаза уменьшения яркости
	dec temp3 //скважность уменьшаем на 1
	brne s3 //переход если после уменьшения регистр не стал = 0
	andi LedStripflags, 0b11111101 //и ставил флаг(сбрасываем в 0) на увеличение яркости

	LDI YL, low(softTimerVar1Delay) //грузим адрес переменной задержки изменения яркости в Y
	LDI YH, high(softTimerVar1Delay)
	ldi temp, brightnessIncreaseDelay
	st Y, temp

	//переинициализируем программный таймер для задачи ожидания
	ldi temp, delayPhase1

	s5:
	LDI YL, low(softTimerVar2Delay) //грузим адрес переменной задержки в Y
	LDI YH, high(softTimerVar2Delay)
	 //устанавливаем значение пеменной softTimerVar2Delay
	st Y, temp
	rcall initSoftTimer10 //1-й 16ти рязрядный программный таймер - анимация RGB ленты
	andi softTimerflags1, 0b11111110 //устанавливаем фазу ожидания

	s3:
	out OCR0A, temp3
	rcall initSoftTimer1//инициализируем 2-й программный таймер - изменение яркости RGB ленты (параметризированная процедура, параметр: задержка)

	s1:
	//тут фаза ожидания


	s4:

	s0:
ret


	/*sbrs sysFlags0, 0 //переход на s0 если бит 0 сброшен т.е. время измения яркости не наступило
	rjmp s0
	//иначе работаем

	in temp, OCR0A //считываем скважность = яркость

	sbrc sysFlags0, 1 //переход на s1 если бит 1 установлен т.е. необходимо уменьшать скважность
	rjmp s1

	inc temp //иначе скважность увеличиваем на 1
	brne s2 //переход если после увеличения регистр не стал = 0
	ser temp //иначе устанавливаем обратно в регистр 255 
	sbr sysFlags0, 0b00000010 //и ставил флаг на уменьшение яркости

s1: 
	dec temp //скважность уменьшаем на 1
	brne s2 //переход если после увеличения регистр не стал = 0
	cbr sysFlags0, 0b00000010 //и ставил флаг(сбрасываем в 0) на увеличение яркости
s2:

	out OCR0A, temp
	cbr sysFlags0, 0b00000001 //сбрасываем бит

	rcall initSoftTimer1 //переинициализируем таймер

s0:
ret*/

//Подпрограмма сканирования клавиатуры
keyScan:
	sbrs softTimerflags0, 0 //пропуск если установлен //бит 0 - программный таймер для задачи сканирования кнопок переполнен
	rjmp km0
	cbr softTimerflags0, 1 //сбросить бит 0

	LDI YL, low(buttonsState) //грузим адрес переменной состояния в Y
	LDI YH, high(buttonsState)
	clr i //переменная-счетчик цикла
	ldi temp3, 0b00000001 //маска для выделения одного бита
	LDI ZL, low(buttonsCounters) //грузим адрес переменной в Z
	LDI ZH, high(buttonsCounters)

km1:
	ld temp, Y //считываем переменную с памяти
	in temp2, PINC //считываем состояние кнопок

	AND temp, temp3 //в байте остается только нужный в данный момент бит
	AND temp2, temp3
	eor temp, temp2 //если бит считанный с порта отличается от бита состояния из переменной значит кнопка изменила состояние и после команды temp не будет равен 0

	breq km2 //переход если 0 т.е. биты одинаковые
	//иначе инкрементируем счетчик кнопки
	
	ld temp2, Z //считываем переменную с памяти
	inc temp2 //увеличиваем ее
	cpi temp2, bounce //сравниваем получивщиеся значение с граничным
	brne km3 //равно?
	//да
	ld temp4, Y //считываем переменную состояния кнопок с памяти
	eor temp4, temp //инвентируем бит т.к. считаем текущее состояние кнопки достовеным
	st Y, temp4 //записываем обратно переменную состояния кнопок
	clr temp2 //обнуляем переменную времени для этой кнопки
	sbr sysFlags0, 0b00001000 //устанавливаем бит 3 (был факт изменения состояния кнопки в переменной buttonsState)
km3:
	//нет
	st Z, temp2 //записываем переменную
km2:
	ld temp, Z+ //считываем переменную с памяти с постинкрементацией для того чтобы значение адресной переменной было актуальным, само значение не нужно
	lsl temp3 //делаем сдвиг маски, для обработки следующего бита
	inc i
	cpi i, qtyButtons+1
	brne km1

	rcall initSoftTimer0
km0:
ret

/*PD2 - выход на неон
  PD3 - выход на RGB ленту, канал R (ШИМ)
  PD4 - выход на оптрон кнопки повер банка (1-оптрон включается и замыкает кнопку)
  PD5 - выход на RGB ленту, канал B (ШИМ)
  PD6 - выход на RGB ленту, канал G (ШИМ)
  PD7 - незанят
  
  PB1 - незанят (ШИМ)
  PB2 - передние ленты (ШИМ)
  PB3 - незанят (ШИМ)

  PC0 - вход кнопка 8 (включение и выключение неона)
  PC1 - вход кнопка 6 (включение и выключение RGB лент)
  PC2 - вход кнопка 5
  PC3 - вход кнопка 4
  PC4 - вход кнопка 3 (включение и выключение ленты)
  PC5 - вход кнопка 2 (мигнуть лентами)
  PC6 - вход кнопка 1  *неправильно подключил*

  [1] [3] [5] [7]
  [2] [4] [6] [8]

*/

//Подпрограмма обработки нажатий клавиш
buttonHandler:
	sbrs sysFlags0, 3 //пропуск если установлен ////бит 3 - 1 - был факт изменения состояния кнопки в переменной buttonsState
	rjmp bm0
	cbr sysFlags0, 0b00001000 //сбросить бит 3

	LDI YL, low(buttonsState) //грузим адрес переменной состояния в Y
	LDI YH, high(buttonsState)
	ld temp, Y //считываем переменную состояния кнопок с памяти

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

btn8: //(включение и выключение неона)
	SBIS PORTD, 2
	rjmp btn8m0
	CBI PORTD, 2
	rjmp btn8m1
btn8m0:
	SBI PORTD, 2
btn8m1:
ret

btn3: //(включение и выключение ленты)
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


















//Подпрограмма сканирования клавиатуры
/*keyScan:
	sbrs sysFlags0, 4 //пропуск если установлен //бит 4 - программный таймер для задачи сканирования кнопок переполнен
	rjmp km0
	cbr sysFlags0, 16 //сбросить бит 4

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

	//Запуск таймера
	ldi temp, 255
	sts timerQueue0+timerQueueLenght0+1, temp
	ldi temp, 16 //4-й бит
	sts timerQueue0+1, temp

km0:
ret

//Подпрограммы обработки нажатий клавиш
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