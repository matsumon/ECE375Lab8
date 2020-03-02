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
.def mpr = r16 ; Multi-Purpose Register
.def udr_address = r17 ; register for address
.def udr_action = r18 ; register for use by udr
.def frozen_register = r19 ; register for frozen
.def last_transmission = r20  ; register for last command
.def last_action = r21			; register for current action
.def waitcnt = r23 ; Wait Loop Counter
.def ilcnt = r24 ; Inner Loop Counter
.def olcnt = r25 ; Outer Loop Counter 

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

.org $003C ; beginning of recieve complete interrupt
rcall Rec ; calling recieive
reti			; returning
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
ldi mpr, 0b0000_1100 ; setting data direction to input except for 2 and 3
out DDRD, mpr ; setting ddrd to input
ldi mpr, 0b1111_0011 ; loading port value 2 3 are output
out PORTD, mpr ; loading value into PORTD
ldi mpr, $ff ; setting mpr
out DDRB, mpr ;setting ddrb to output
;I/O Ports
ldi mpr, 0b1001_0000 ; loading mpr with value
sts UCSR1B, mpr ; loading ustart control register B with mpr
ldi mpr, 0b0000_1110 ; loading mpr with value
sts UCSR1C, mpr ; loading ustart control register c with mpr
ldi mpr, $01 ; loading mpr with high of ubrr
sts UBRR1H, mpr ; loading high with high
ldi mpr, $A0 ; loading mpr with low of ubrr
sts UBRR1L,mpr ; loading low with low
;USART1
;Set baudrate at 2400bps
;Enable transmitter
;Set frame format: 8 data bits, 2 stop bits
; interrupts
ldi udr_address, 0b00110101 ; setting udr_address
clr frozen_register ; clearing frozen register
ldi mpr, 0b10101010 ; setting interrupts to trigger on falling edge
sts EICRA, mpr ; falling edge trigger
out EICRB, mpr ; falling edge trigger
clr mpr ; clearing mpr
out EIMSK, mpr		; disabling interrupts 0 to 7
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
Rec:
;I am broke
USART_Recieve:
WaitingAddress:
sbic UCSR1A, 7			; skips next instruction if the recieve transmission isnt cleared as that means there is stuff in there
rjmp WaitingAddress		; basically a wait function that waits until finished transmitting
cbi UCSR1A, 7			; clearing transmit register by writing a one to it. Just in case
in mpr, UDR1			; grabbing the address
cpi mpr, BotAddress     ; sets zero register
brne skip				; jumps to skip and then returns if the address and botaddress not equal.
WaitingAction:
sbis UCSR01, 6			; skips next instruction if transmission is complete
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
; Turn left for a second
ldi mpr, TurnL ; Load Turn Left Command
ldi udr_action, 0b10010000 ;loading action value
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

Right:
; Turn right for a second
ldi udr_action, 0b10100000 ;loading action value
ldi mpr, TurnR ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

Forward:
ldi udr_action, 0b10110000  ;loading action value
ldi mpr, MovFwd ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

Backward:
; Turn right for a second
ldi udr_action, 0b10000000  ;loading action value
ldi mpr, MovBck ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

Stop:
; Turn right for a second
ldi udr_action, 0b11001000  ;loading action value
ldi mpr, Halt ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

Freeze:
; Turn right for a second
ldi udr_action, Frozen  ;loading action value
ldi mpr, Frozen ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
rjmp Main ; Return from subroutine

HitRight:
push mpr ; Save mpr register
push waitcnt ; Save wait register
in mpr, SREG ; Save program state
push mpr ;
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts
; Move Backwards for a second
ldi mpr, MovBck ; Load Move Backward command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function

; Turn left for a second
ldi mpr, TurnL ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function

ldi mpr, 0b0000_0000 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
clr mpr ; clearing it
ret ; Return from subroutine

HitLeft:
cli ; disabling interrupts
push mpr ; Save mpr register
push waitcnt ; saveing wait register
in mpr, SREG ; Save program state
push mpr ; save sreg
clr mpr ; masking interrupts
out EIMSK, mpr ; masking inetrrupts


; Move Backwards for a second
ldi mpr, MovBck ; Load Move Backward command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function

; Turn right for a second
ldi mpr, TurnR ; Load Turn Left Command
out PORTB, mpr ; Send command to port
rcall Waits ; Call wait function

ldi mpr, 0b00001111 ; loading with eimsk value
out EIMSK, mpr ; unmasking interrupts
ldi mpr, $ff ; loading ones in EIFR
out EIFR,mpr ; clearing EIFR
pop mpr ; Restore program state
out SREG, mpr ;
pop waitcnt ; Restore wait register
pop mpr ; Restore mpr
clr mpr ; clearing it
ret ; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************

