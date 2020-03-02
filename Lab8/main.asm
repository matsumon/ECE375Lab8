;***********************************************************
;*
;* Enter Name of file here
;*
;* Enter the description of the program here
;*
;* This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;* Author: Nicholas Matsumoto
;*   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc" ; Include definition file

;***********************************************************
;* Internal Register Definitions and Constants
;***********************************************************
.def mpr = r16 ; Multi-Purpose Register
.def udr_address = r17 ; register for address
.def udr_action = r18 ; register for use by udr
.def frozen_register = r19 ; register for frozen
.def waitcnt = r23 ; Wait Loop Counter
.def ilcnt = r24 ; Inner Loop Counter
.def olcnt = r25 ; Outer Loop Counter

.equ WTime = 10 ; Time to wait in wait loop

.equ EngEnR = 4 ; Right Engine Enable Bit
.equ EngEnL = 7 ; Left Engine Enable Bit
.equ EngDirR = 5 ; Right Engine Direction Bit
.equ EngDirL = 6 ; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1)) ;0b10110000 Move Forward Action Code
.equ MovBck =  ($80|$00) ;0b10000000 Move Backward Action Code
.equ TurnR =   ($80|1<<(EngDirL-1)) ;0b10100000 Turn Right Action Code
.equ TurnL =   ($80|1<<(EngDirR-1)) ;0b10010000 Turn Left Action Code
.equ Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1)) ;0b11001000 Halt Action Code
.equ Frozen = 0b11111000 ; frozen value action code

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg ; Beginning of code segment

;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
rjmp INIT ; Reset interrupt
.org $0046 ; End of Interrupt Vectors


;***********************************************************
;* Program Initialization
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
ldi mpr, 0b0000_1000 ; loading mpr with value
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
ldi udr_address, 0b00110101 ; setting udr_address
clr frozen_register ; clearing frozen register
ldi mpr, 0b10101010 ; setting interrupts to trigger on falling edge
sts EICRA, mpr ; falling edge trigger
out EICRB, mpr ; falling edge trigger
clr mpr ; clearing mpr
out EIMSK, mpr		; disabling interrupts 0 to 7
sei ; setting global interrupts



;Other

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
;TODO: ???
in mpr,PIND		; grabbing any user input
sbrc mpr, 0			; skipping if bit is set
rjmp Forward		; calling to  function
sbrc mpr, 1			; skipping if bit is set
rjmp Backward		; calling to  function
;sbrc mpr, 2			; skipping if bit is set
;rcall Left		; calling to  function
;sbrc mpr, 3			; skipping if bit is set
;rcall Right		; calling to  function
;sbrc mpr, 4			; skipping if bit is set
;rcall Freeze		; calling to  function
;sbrc mpr, 5			; skipping if bit is set
;rcall Halt		; calling to  function
;sbrc mpr, 6			; skipping if bit is set
;rcall HitRight		; calling to  function
;sbrc mpr, 7			; skipping if bit is set
;rcall HitLeft		; calling to  function
rjmp MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************
USART_Transmit:
mov mpr, udr_address ; loading mpr with address
sts UDR1,mpr ; loading value into register
WaitingAddress:
lds mpr, UCSR1A
sbrs mpr, 5 ; skips next instruction if the empty data register is set
rjmp WaitingAddress ; basically a wait function that waits until finished transmitting
mov mpr, udr_action ; loading mpr with address
sts UDR1,mpr ; loading value into register
WaitingAction:
lds mpr, UCSR1A	; loading mpr
sbrs mpr, 5 ; skips next instruction if transmission is complete
rjmp WaitingAction ; basically a wait function that waits until finished transmitting
ret ; returns

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
ret ; Return from subroutine

Right:
; Turn right for a second
ldi udr_action, 0b10100000 ;loading action value
ldi mpr, TurnR ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
ret ; Return from subroutine

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
ret ; Return from subroutine

Freeze:
; Turn right for a second
ldi udr_action, Frozen  ;loading action value
ldi mpr, Frozen ; Load Turn Left Command
out PORTB, mpr ; Send command to port
ldi waitcnt, WTime ; Wait for 1 second
rcall Waits ; Call wait function
rcall USART_Transmit ; Call USART_Transmit function
ret ; Return from subroutine

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
;* Stored Program Data
;***********************************************************

;***********************************************************
;* Additional Program Includes
;***********************************************************