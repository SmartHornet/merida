;= Start 	macro.inc ========================================
;= End 		macro.inc ========================================
.def temp = R16
.def i = R21
.def curspeed = R18 //текущая скорость двигателя(0-255)
.def speed = R19 //требуемая скорость двигателя(0-255)
.def curstep = R17 //номер шага двигателя(0-7) 
.def nStepsL = R0 //переменная для передачи кол-ва шагов в подпрограмму nStep
.def nStepsH = R1
.def curPosL = R2 //переменная текущего положения платформы 0 - 965(0x3C6)
.def curPosH = R3
.def eeadr = R7 //переменная адреса для работы с eeprom
.def eedata = R6 //переменная данных для работы с eeprom
.def distPosL = R4 //переменная целевого положения платформы 0 - 965(0x3C6)
.def distPosH = R5
.def flags0 = R20
//бит 0 - 
//бит 1 - программный таймер для задачи произведения шага переполнен
//бит 2 - задача постепеннного увеличения скорости активна
//бит 3 - программный таймер для задачи постепеннного увеличенмя скорости переполнен
//бит 4 - программный таймер для задачи сканирования кнопок переполнен
//бит 5 - режим программирования активирован
//бит 6 - индикатор выполненной записи активирован
.equ circleL = 0xC6 //длина окружности
.equ circleH = 0x3
.equ circleHalfL = 0xE3 //половина длины окружности
.equ circleHalfH = 0x1
.equ timerQueueLenght = 2 //длина структуры timerQueue (счет с 1)
; RAM ========================================================
		.DSEG

timerQueue:	.byte (timerQueueLenght*2) //очередь программного таймера
//первые timerQueueLenght байт - маски битов в байте флагов(flags0) 255 - таймер выключен
//остальные timerQueueLenght байт - переменные программного таймера

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

	clr i //переменная счетчик цикла от 0 до timerQueueLenght

	LDI YL, low(timerQueue)
	LDI YH, high(timerQueue)
tm0:
	ld temp, Y+ //грузим маску
	cpi temp, 0xFF //маска равна 255?
	breq tm1 //да, пропускаем этот таймер
	push temp //нет, запоминаем маску
	ldd temp, Y+timerQueueLenght-1 //грузим переменную программного таймера
	dec temp //уменьшаем
	brne tm2 //если переменная не равна 0 то переходим на tm2
	pop temp //достаем маску
	or flags0, temp //ставим бит по маске
	ser temp
	st -Y, temp //пишем заглушку 255
	ld temp, Y+//обратно увеличиваем Y
	rjmp tm1
tm2:
	std Y+timerQueueLenght-1, temp //записываем уменьшенную переменную
	pop temp //освобождаем стек(т.к перед ветвлением записывали)
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
	ldi temp, 0x80 //отключение компаратора
	out ACSR, temp

	ldi temp, 0x0F //порт C, выводы 4, 5, 6, 7 на вход, 0, 1, 2, 3 на выход  
	out DDRC, temp

	ldi temp, 0xF0 //порт C выводы на ноль, 4, 5, 6, 7 с подтяжкой (для защиты)
	out PORTC, temp

	clr temp //весь порт D на вход 
	out DDRD, temp

	ldi temp, 0xFF
	out PORTD, temp

	ldi temp, 0x2 //порт B на вход, бит 1 на выход - светодиод режима программирования
	out DDRB, temp

	ldi temp, 0xFF 
	out PORTB, temp

	ldi temp, (1<<TOIE0) //Разрешение прерывания по переполнению таймера 0
	out TIMSK, temp

	ldi temp, 0b00000001 //запуск таймера 0, делитель 1
	out TCCR0, temp

	sei
; End Internal Hardware Init ===================================

; External Hardware Init  ======================================
; End Internal Hardware Init ===================================

; Run ==========================================================
; End Run ======================================================

/////////////////////Инициализация переменных
	ldi speed, 60

	//1-й таймер  программный таймер
	ldi temp, 255
	sts timerQueue+timerQueueLenght+0, temp
	ldi temp, 255 //заглушка
	sts timerQueue+0, temp

	//2-й таймер  программный таймер для задачи сканирования кнопок
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 16 //4-й бит
	sts timerQueue+1, temp

; Main =========================================================
start:

	rcall keyScan
	rcall leds

    rjmp start



EEWrite:	
	SBIC EECR, EEWE		; Ждем готовности памяти к записи. Крутимся в цикле
	RJMP EEWrite 		; до тех пор пока не очистится флаг EEWE
 
	CLI					; Затем запрещаем прерывания.
	OUT EEARL, eeadr	; Загружаем адрес нужной ячейки
	clr temp 		
	OUT EEARH, temp  	; старший и младший байт адреса
	OUT EEDR, eedata	; и сами данные, которые нам нужно загрузить
 
	SBI EECR, EEMWE		; взводим предохранитель
	SBI EECR, EEWE		; записываем байт
 
	SEI 				; разрешаем прерывания
	RET 				; возврат из процедуры
 
 
EERead:	
	SBIC EECR, EEWE		; Ждем пока будет завершена прошлая запись.
	RJMP EERead			; также крутимся в цикле.
	OUT EEARL, eeadr		; загружаем адрес нужной ячейки
	clr temp
	OUT EEARH, temp 		; его старшие и младшие байты
	SBI EECR, EERE 		; Выставляем бит чтения
	IN 	eedata, EEDR 		; Забираем из регистра данных результат
	RET

leds:
	sbrs flags0, 5 //пропуск если установлен //бит 5 - режим программирования активирован
	sbi PORTB, 1 //выключить светодиод режим программирования активирован

	sbrc flags0, 5 //пропуск если сброшен //бит 5 - режим программирования активирован
	cbi PORTB, 1 //включить светодиод режим программирования активирован	
		
ret

//Подпрограмма сканирования клавиатуры
keyScan:
	sbrs flags0, 4 //пропуск если установлен //бит 4 - программный таймер для задачи сканирования кнопок переполнен
	rjmp km0
	cbr flags0, 16 //сбросить бит 4

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
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 16 //4-й бит
	sts timerQueue+1, temp

km0:
ret

//Подпрограмма обработчик нажатий кнопок изменения позиции хранящихся в памяти
//номер кнопки в i (0-4)
btnPosHandler:
	sbrs flags0, 5 //пропуск если установлен //бит 5 - режим программирования активирован
	rjmp bm0

	lsl i //умножаем номер кнопки на 2 (в eeprom по два байта на каждую позицию)
	mov eeadr, i
	mov eedata, curPosL
	rcall EEWrite

	inc i
	mov eeadr, i
	mov eedata, curPosH
	rcall EEWrite

	cbr flags0, 32 //сбросить бит 5
	
	rjmp bm1
bm0:
	
	lsl i //умножаем номер кнопки на 2 (в eeprom по два байта на каждую позицию)
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

//Подпрограммы обработки нажатий клавиш
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
	sbr flags0, 32 //установить бит 5
ret

; End Main =====================================================
; Procedure ====================================================
//Подпрограмма для перемещения платформы на целевую позицию(distPosL, distPosH)
//для перемещения выбирается минимальный путь относительно текущей позиции
runTo:
	//сравниваем что больше текущее положение или цель
	cp curPosH, distPosH
	brlo rm0 //меньше
	brne rm1 //если не равно значит больше
	//иначе значит = и нужно сравнивать младшие байты
	cp curPosL, distPosL
	brlo rm0 //меньше
	brne rm1 //если не равно значит больше
	//если равны то стоим на месте
	rjmp rm2
rm0://меньше
	//вычисляем число шагов
	sub distPosL, curPosL //отнимаем младший
	sbc distPosH, curPosH //старший с переносом

	//в distPos осталось требуемое кол-во шагов
	//сравниваем требуемое число шагов с количеством шагов в половине окружности
	ldi temp, circleHalfH
	cp distPosH, temp
	brlo rm4 //меньше
	brne rm5 //если не равно значит больше
	//иначе значит = и нужно сравнивать младшие байты
	ldi temp, circleHalfL
	cp distPosL, temp
	brlo rm4 //меньше
	brne rm5 //если не равно значит больше
	//если равное кол-во то делаем шаги вперед
rm4: //шаги вперед
	clt //сбрасываем Т
	rjmp rm3

rm5: //шаги назад	

	//тут кол-во шагов круг минус кол-во шагов(distPos)
	ldi temp, circleL
	sub temp, distPosL //отнимаем младший
	mov distPosL, temp
	ldi temp, circleH
	sbc temp, distPosH //старший с переносом
	mov distPosH, temp

	set //устанавливаем T
	rjmp rm3

rm1://больше
	//вычисляем число шагов
	mov temp, curPosL
	sub temp, distPosL //отнимаем младший
	mov distPosL, temp
	mov temp, curPosH
	sbc temp, distPosH //старший с переносом
	mov distPosH, temp

	//в distPos осталось требуемое кол-во шагов
	//сравниваем требуемое число шагов с количеством шагов в половине окружности
	ldi temp, circleHalfH
	cp distPosH, temp
	brlo rm6 //меньше
	brne rm7 //если не равно значит больше
	//иначе значит = и нужно сравнивать младшие байты
	ldi temp, circleHalfL
	cp distPosL, temp
	brlo rm6 //меньше
	brne rm7 //если не равно значит больше
	//если равное кол-во то делаем шаги назад

rm6://шаги назад
	set //устанавливаем T
	rjmp rm3

rm7://шаги вперед

	//тут кол-во шагов круг минус кол-во шагов(distPos)
	ldi temp, circleL
	sub temp, distPosL //отнимаем младший
	mov distPosL, temp
	ldi temp, circleH
	sbc temp, distPosH //старший с переносом
	mov distPosH, temp

	clt //сбрасываем Т
rm3:	
	mov nStepsL, distPosL //перемещаем кол-во шагов в переменные
	mov nStepsH, distPosH

	//rcall modCurPos //вызываем подпрограмму изменения тек положения
	rcall nStep //подпрограмма выполнения шагов

rm2:
ret

//Подпрограмма выполнения n шагов двигателя
//число шагов 2 байта в nStepsL младший, nStepsH старший
//направление бит T 0-вперед 1-назад
nStep:
	ldi curspeed, 250 //ставим мин скорость
	sbr flags0, 0x2 //установить бит 1 чтобы алгоритм первый раз сделал шаг и завел таймер
	sbr flags0, 0x4 //включаем плавный пуск

nm3:
	clr temp
	cp nStepsH, temp //сравниваем с 0
	brne nm0 //не равен 0?(nStepsH может либо = 0 либо > 0) переходим к телу цикла
	cp nStepsL, temp //сравниваем с 0
	breq nm1 //значит nStepsH = 0 и если nStepsL = 0 то выходим из цикла
nm0:
	
	sbrs flags0, 1 //пропуск если установлен //бит 1 - программный таймер для задачи произведения шага переполнен
	rjmp nm2
	cbr flags0, 0x2 //сбросить бит 1
	brts nm5//переход если T установлен т.е. вращение назад
	rcall stepUp
	rjmp nm6
nm5:
	rcall stepDown
nm6:
	sts timerQueue+timerQueueLenght+0, curspeed //инициализация таймера для задачи вращения
	ldi temp, 0x2 //1-й бит
	sts timerQueue+0, temp

	//уменьшаем кол-во шагов
	ldi temp, 1
	sub nStepsL, temp //уменьшаем младший байт
	brsh nm7 //если нет переноса, то уходим
	dec nStepsH //иначе уменьшаем старший байт
nm7:
	sbrs flags0, 2 //задача плавного пуска активна?
	rjmp nm2 //нет уходим
	cp speed, curspeed //сравниваем текущую и заданную скорость
	breq nm4 //если равны то уходим на nm4
	subi curspeed, 5 //увеличиваем текущую скорость
	rjmp nm2
nm4:
	cbr flags0, 0x4 //выключаем плавный пуск
nm2:
	rjmp nm3
nm1:
	ldi temp, 0xFF //заглушка, выключаем таймер
	sts timerQueue+0, temp
	cbr flags0, 0x2 //навсякий сбросить бит 1
	cbr flags0, 0x4 //выключаем плавный пуск навсякий
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

	//Изменение текущей позиции
	ldi temp, 1 //инкремент позиции
	add curPosL, temp
	clr temp
	adc curPosH, temp

	//проверка на выход за границу длины окружности
	ldi temp, circleH
	cp curPosH, temp 
	brne um0 //если не равно circleH уходим 
	ldi temp, circleL
	cp curPosL, temp
	brne um0 //если не равно circleL уходим
	clr curPosL //иначе обнуляем
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

	//проверка на выход за границу длины окружности
	clr temp
	cp curPosH, temp 
	brne dm0 //если не равно 0 уходим 
	cp curPosL, temp
	brne dm0 //если не равно 0 уходим

	ldi temp, circleH
	mov curPosH, temp
	ldi temp, circleL - 1
	mov curPosL, temp

	rjmp dm1
dm0:

	ldi temp, 1 //декремент позиции
	sub curPosL, temp
	clr temp
	sbc curPosH, temp

dm1:
ret


; End Procedure ================================================


; EEPROM =====================================================
							; Сегмент EEPROM

.ESEG .db 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0













//Подпрограмма изменения текущего положения
//число шагов 2 байта в nStepsL младший, nStepsH старший
//направление бит T 0-вперед 1-назад
/*modCurPos:
	
	brts mm0 //переход если T установлен т.е. вращение назад

	add curPosL, nStepsL
	adc curPosH, nStepsH
mm3:
	ldi temp, circleH
	cp curPosH, temp
	brlo mm1 //если меньше 3 то уходим 
	brne mm2 //если не равно 3 значит больше трех то идем на уменьшение(отнять целые круги)
	//иначе значит = 3, проверяем младший байт

	ldi temp, circleL
	cp curPosL, temp
	brlo mm1 //если меньше C6 то уходим 
	brne mm2 //если не равно C6 значит больше трех то идем на уменьшение(отнять целые круги)
	//иначе значит = C6 и нужно обнулить
	clr curPosL //обнуляем
	clr curPosH
	rjmp mm1

mm2://уменьшаем 
	ldi temp, circleL 
	sub curPosL, temp //отнимаем младший
	ldi temp, circleH
	sbc curPosH, temp //старший с переносом
	rjmp mm3
	
mm0: //отнимаем
//отнимаем от всего круга число котороое нужно отнять
//получившиеся прибавляем к текущей позиции
//прибавление осуществляется как рекурсивный вызов данной подпрограммы
	
	push nStepsL//запоминаем т.к. изменим далее
	push nStepsH

	ldi temp, circleL 
	sub temp, nStepsL//отнимаем от всего круга младший
	mov nStepsL, temp//перемещаем
	ldi temp, circleH
	sbc temp, nStepsH//отнимаем от всего круга старший
	mov nStepsH, temp

	clt //сбрасываем Т т.к. нам нужно будет сложение

	rcall modCurPos 

	set //установливаем Т обратно

	pop nStepsH //достаем исходные
	pop nStepsL

mm1:
ret
*/





//ldi curspeed, 100 //240

	/////////////////////Инициализация переменных в RAM
	/*//1-й таймер
	//ldi temp, 80
	sts timerQueue+timerQueueLenght+0, curspeed
	ldi temp, 0x2 //1-й бит
	sts timerQueue+0, temp

	//2-й таймер
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 255//0x8
	sts timerQueue+1, temp

	//3-й таймер
	ldi temp, 255
	sts timerQueue+timerQueueLenght+2, temp
	ldi temp, 255//0x10
	sts timerQueue+2, temp
*/	

/*sbrs flags0, 1 //пропуск если установлен //бит 1 - программный таймер для задачи произведения шага переполнен
	rjmp m1
	cbr flags0, 0x2 //сбросить бит 1
	rcall stepDown
	dec nsteps
	breq m1

	//ldi temp, 80 //инициализация таймера
	sts timerQueue+timerQueueLenght+0, curspeed
	ldi temp, 0x2 //1-й бит
	sts timerQueue+0, temp
	*/
/*
	sbrs flags0, 3 //программный таймер для задачи постепеннного увеличения скорости переполнен? 
	rjmp start
	sbrs flags0, 2 //задача плавного пуска активна?
	rjmp start
	cp speed, curspeed //сравниваем текущую и заданную скорость
	breq m2
	subi curspeed, 5 //увеличиваем текущую скорость
	cbr flags0, 0x8 //сбросить бит 3 (таймер переполнен)

	//2-й таймер
	ldi temp, 255
	sts timerQueue+timerQueueLenght+1, temp
	ldi temp, 0x8
	sts timerQueue+1, temp

	rjmp start
m2:
	cbr flags0, 0x4 //сбросить бит 2 (выключить задачу плавного пуска)
	cbr flags0, 0x8 //сбросить бит 3 (таймер переполнен)
	*/
/*m3:

	sbrs flags0, 4 //программный таймер для задачи сканирования кнопок переполнен?
	rjmp m4

	sbis PINB, 0
	rcall stepUp

	sbis PINB, 1
	rcall stepDown

	cbr flags0, 0x10 //сбросить бит 4

	ldi temp, 255
	sts timerQueue+timerQueueLenght+2, temp
	ldi temp, 0x10
	sts timerQueue+2, temp
m4:*/



/*inc task0Clock
	cp task0Clock, curspeed
	brlo tm0 //переход если меньше
	sbr flags0, 0x2 //установить бит 1
	clr task0Clock
tm0:
	*/
	/*sbrs flags0, 2 //бит 2 - задача постепеннного увеличения скорости активна
	rjmp tm1
	inc task1Clock
	cpse ff, task1Clock //пропуск при равенстве
	rjmp tm1
	sbr flags0, 0x8 //установить бит 3 //бит 3 - программный таймер для задачи постепеннного увеличенмя скорости переполнен
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
    
	CPSE temp, R19 //если р16 = 0 то не уходим на м1, а делаем первую инициализацию
	rjmp m1
	inc temp
	rjmp end

m1:
	SBRS temp, 3 //если установлен бит то пропуск след команды //если 3 бит стоит то нужно установить регистр в 1
	rjmp m2
	ldi temp, 0x01
	rjmp end

m2:
	lsl temp

end:	
	out PORTC, temp*/



	/*
	in temp, PORTC

	CPSE temp, R19 //если р16 = 0 то не уходим на м1, а делаем первую инициализацию
	rjmp m1
	inc temp
	rjmp end

m1:
	SBRS temp, 3 //если установлен бит то пропуск след команды //если 3 бит стоит то нужно установить регистр в 1
	rjmp m2
	ldi temp, 0x01
	rjmp end

m2:
	lsl temp

end:	
	out PORTC, temp
	*/