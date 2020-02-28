;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.def	frozen_register = r19 ; register for frozen
.def	waitcnt = r23 ; Wait Loop Counter
.def	 ilcnt = r24 ; Inner Loop Counter
.def	olcnt = r25 ; Outer Loop Counter
.equ WTime = 10 ; Time to wait in wait loop

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = 0b00110101 ;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
rjmp INIT ; Reset interrupt
.org $0002 ; Beginning of IVs
rcall Forward ; Reset interrupt
reti ; return from interrupt
.org $0004 ; Beginning of IVs
rcall Backward ; Reset interrupt
reti ; return from interrupt
.org $0006 ; Beginning of IVs
rcall Right ; Reset interrupt
reti ; return from interrupt
.org $0008 ; Beginning of IVs
rcall Left ; Reset interrupt
reti ; return from interrupt
.org $0010 ; Beginning of IVs
rcall Stop ; Reset interrupt
reti ; return from interrupt
.org $0012 ; Beginning of IVs
rcall Freeze ; Reset interrupt
reti ; return from interruptpt

;Should have Interrupt vectors for:
;- Left whisker
;- Right whisker
;- USART receive

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
ldi mpr , high(RAMEND) ; loading mpr with high of end of ram
out SPH, mpr ; loading stack pointer
ldi mpr, low(RAMEND) ; loading mpr with low of end of ram
out SPL, mpr ; loading stack pointer
;Stack Pointer (VERY IMPORTANT!!!!)
clr mpr ; clearing mpr
out DDRD, mpr ; setting ddrd to input
ldi mpr, $ff ; setting mpr
out DDRB, mpr ;setting ddrb to output
;I/O Ports
ldi mpr, 0b1010100 ; loading mpr with value
sts UCSR0B, mpr ; loading ustart control register B with mpr
ldi mpr, 0b00111110 ; loading mpr with value
sts UCSR0C, mpr ; loading ustart control register c with mpr
ldi mpr, $01 ; loading mpr with high of ubrr
sts UBRR0H, mpr ; loading high with high
ldi mpr, $A0 ; loading mpr with low of ubrr
sts UBRR0L,mpr ; loading low with low
;USART1
;Set baudrate at 2400bps
;Enable transmitter
;Set frame format: 8 data bits, 2 stop bits
; interrupts
ldi mpr, $FF ; setting mpr
out EIMSK, mpr ; setting EIMSK So all interrupts are available
ldi mpr, 0b10101010 ; setting interrupts to trigger on falling edge
sts EICRA, mpr ; falling edge trigger
out EICRB, mpr ; falling edge trigger
clr frozen_register				; clearing frozen register
sei ; setting global interrupts
	;Stack Pointer (VERY IMPORTANT!!!!)
	;I/O Ports
	;USART1
		;Set baudrate at 2400bps
		;Enable receiver and enable receive interrupts
		;Set frame format: 8 data bits, 2 stop bits
	;External Interrupts
		;Set the External Interrupt Mask
		;Set the Interrupt Sense Control to falling edge detection

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
USART_Recieve:
WaitingAddress:
sbic UCSR0A, 7			; skips next instruction if the recieve transmission isnt cleared as that means there is stuff in there
rjmp WaitingAddress		; basically a wait function that waits until finished transmitting
cbi UCSR0A, 7			; clearing transmit register by writing a one to it. Just in case
in mpr, UDR0			; grabbing the address
cpi mpr, BotAddress     ; sets zero register
brne skip				; jumps to skip and then returns if the address and botaddress not equal.
WaitingAction:
sbis UCSR0A, 6			; skips next instruction if transmission is complete
rjmp WaitingAction		; basically a wait function that waits until finished transmitting
skip:
ret						; returns

Waits:
push waitcnt ; Save wait register
push ilcnt ; Save ilcnt register
push olcnt ; Save olcnt register

Loop: ldi olcnt, 224 ; load olcnt register
OLoop: ldi ilcnt, 237 ; load ilcnt register
ILoop: dec ilcnt ; decrement ilcnt
brne ILoop ; Continue Inner Loop
dec olcnt ; decrement olcnt
brne OLoop ; Continue Outer Loop
dec waitcnt ; Decrement wait
brne Loop ; Continue Wait loop

pop olcnt ; Restore olcnt register
pop ilcnt ; Restore ilcnt register
pop waitcnt ; Restore wait register
ret ; Return from subroutine

Left:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn left for a second
ldi mpr, TurnL ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function


ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine

Right:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn right for a second
ldi mpr, TurnR ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function


ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine

Forward:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn right for a second
ldi mpr, MovFwd ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function


ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine

Backward:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn right for a second
ldi mpr, MovBck ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function


ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine

Stop:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn right for a second
ldi mpr, Halt ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function

ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine

Freeze:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts

; Turn right for a second
ldi mpr, Frozen ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function


ldi mpr, 0b11111111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
ret ; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************

