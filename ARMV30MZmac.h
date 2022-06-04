//
//  ARMV30MZmac.h
//  ARMV30MZ
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2022 Fredrik Ahlström. All rights reserved.
//

#include "ARMV30MZ.i"
							;@ ARM flags
	.equ PSR_S, 0x00000008		;@ Sign (negative)
	.equ PSR_Z, 0x00000004		;@ Zero
	.equ PSR_C, 0x00000002		;@ Carry
	.equ PSR_V, 0x00000001		;@ Overflow

	.equ PSR_P, 0x00000020		;@ Parity
	.equ PSR_A, 0x00000010		;@ Aux/Half carry
	.equ PSR_ALL, 0x0000001F	;@ All flags


							;@ V30 flags
	.equ MF, 0x8000				;@ Mode, native/emulated, invalid in V30MZ.
		;@   0x4000				;@ 1
		;@   0x2000				;@ 1
		;@   0x1000				;@ 1
	.equ OF, 0x0800				;@ Overflow
	.equ DF, 0x0400				;@ Direction
	.equ IF, 0x0200				;@ Interrupt enable
	.equ TF, 0x0100				;@ BREAK
	.equ SF, 0x0080				;@ Sign (negative)
	.equ ZF, 0x0040				;@ Zero
		;@   0x0020				;@ 0
	.equ AF, 0x0010				;@ Aux / Half carry
		;@   0x0008				;@ 0
	.equ PF, 0x0004				;@ Parity
		;@   0x0002				;@ 1
	.equ CF, 0x0001				;@ Carry

;@----------------------------------------------------------------------------
	.equ CYC_SHIFT, 8
	.equ CYCLE, 1<<CYC_SHIFT	;@ One cycle
	.equ CYC_MASK, CYCLE-1		;@ Mask

	.equ PC_OFS_COUNT, 24		;@ Used for Branch to offset PC

;@----------------------------------------------------------------------------

	.macro eatCycles count
	sub v30cyc,v30cyc,#(\count)*CYCLE
	.endm

	.macro loadLastBank reg
	ldr \reg,[v30ptr,#v30LastBank]
	.endm

	.macro getNextByteToReg reg
	ldrb \reg,[v30pc],#1
	.endm

	.macro getNextByte
	getNextByteToReg r0
	.endm

	.macro getNextSignedByteToReg reg
	ldrsb \reg,[v30pc],#1
	.endm

	.macro getNextSignedByte
	getNextSignedByteToReg r0
	.endm

	.macro getNextWord
	ldrb r0,[v30pc],#1
	ldrb r1,[v30pc],#1
	orr r0,r0,r1,lsl#8
	.endm

	.macro fetch count
	subs v30cyc,v30cyc,#(\count)*CYCLE
	ldrbgt r0,[v30pc],#1
	ldrgt pc,[v30ptr,r0,lsl#2]
	b outOfCycles
	.endm

	.macro v30DecodeFastPC
	bl V30DecodePC
	.endm

	.macro v30DecodeFastPCToReg reg
	loadLastBank \reg
	sub \reg,v30pc,\reg
	.endm

	.macro v30EncodeFastPC
	bl V30EncodePC
	.endm

	.macro v30ReEncodeFastPC
//	bl V30ReEncodePC
	.endm

;@ Opcode macros always return result in r1
;@ Any register except r2 can be used for src & dst.
;@----------------------------------------------------------------------------
	.macro add8 src dst
	eor r2,\dst,\src
	mov \dst,\dst,lsl#24
	adds \src,\dst,\src,lsl#24
	eor r2,r2,\src,lsr#24
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	mov r1,\src,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro add16 src dst
	eor r2,\src,\dst,lsr#16
	adds \src,\dst,\src,lsl#16
	eor r2,r2,\src,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	mov r1,\src,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro adc8 src dst
	tst v30f,v30f,lsr#2			;@ Get Carry
	subcs \src,\src,#0x100
	eor r2,\dst,\src
	mov \dst,\dst,lsl#24
	adcs \src,\dst,\src,ror#8
	eor r2,r2,\src,lsr#24
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	mov r1,\src,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro adc16 src dst
	tst v30f,v30f,lsr#2			;@ Get Carry
	subcs \src,\src,#0x10000
	eor r2,\src,\dst,lsr#16
	adcs \src,\dst,\src,ror#16
	eor r2,r2,\src,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	mov r1,\src,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro and8 src dst
	and r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro and16 src dst
	and r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro decWord reg
	ldr r0,[v30ptr,#\reg -2]
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A	;@ Clear S, Z, V & A.
	subs r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg -2]
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro incWord reg
	ldr r0,[v30ptr,#\reg -2]
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A	;@ Clear S, Z, V & A.
	adds r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg -2]
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro jmpne flag
	getNextSignedByte
	tst v30f,#\flag
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	sub v30cyc,v30cyc,#1*CYCLE
	v30ReEncodeFastPC
	bx lr
	.endm

	.macro jmpeq flag
	getNextSignedByte
	tst v30f,#\flag
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	sub v30cyc,v30cyc,#1*CYCLE
	v30ReEncodeFastPC
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro or8 src dst
	orr r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro or16 src dst
	orr r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro popWord
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	add r2,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r2,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	.endm

	.macro popRegister reg
	stmfd sp!,{lr}
	popWord
	strh r0,[v30ptr,#\reg]
	eatCycles 1
	ldmfd sp!,{pc}
	.endm

	.macro pushRegister reg
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#\reg]
	eatCycles 1
	b cpuWriteMem20W
	.endm
;@----------------------------------------------------------------------------
	.macro rol8 dst src
	ands \src,\src,#0x1F
	bicne v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	cmp \src,#0x08
	andpl \src,\src,#0x7
	orrpl \src,\src,#0x8
	orr \dst,\dst,\dst,ror#8
	orrs \dst,\dst,\dst,ror#16
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro rol16 dst src
	ands \src,\src,#0x1F
	bicne v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	cmp \src,#0x10
	andne \src,\src,#0xF
	orrs \dst,\dst,\dst,lsl#16		;@ Clear Carry
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro rolc8 dst src
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orrne \dst,\dst,#0x100
9:
	tst \dst,\dst,lsr#9
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 9b
	movs \dst,\dst,lsl#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro rolc16 dst src
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orrne \dst,\dst,#0x10000
10:
	tst \dst,\dst,lsr#17
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 10b
	movs \dst,\dst,lsl#16
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro ror8 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	tst \dst,#0x40000000
	eoreq v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro ror16 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	tst \dst,#0x40000000
	eoreq v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro rorc8 dst src
	mov \dst,\dst,lsl#24
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orrne \dst,\dst,#0x00800000
11:
	tst \dst,\dst,lsr#24
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 11b
	movs r1,\dst,lsr#24
	orrcs v30f,v30f,#PSR_C
	eors r2,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm

	.macro rorc16 dst src
	mov \dst,\dst,lsl#16
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orrne \dst,\dst,#0x00008000
12:
	tst \dst,\dst,lsr#16
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 12b
	movs r1,\dst,lsr#16
	orrcs v30f,v30f,#PSR_C
	eors r2,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm
;@----------------------------------------------------------------------------
	.macro shl8 dst src
	ands \src,\src,#0x1F
	and v30f,v30f,#PSR_C+PSR_V
	movne v30f,#0
	movs \dst,\dst,lsl#24			;@ This clears Carry
	movs \dst,\dst,lsl \src
	mov r1,\dst,asr#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shl16 dst src
	add \src,\src,#16
	movs \dst,\dst,lsl \src
	mov r1,\dst,asr#16
	and v30f,r1,#PSR_A
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shr8 dst src
	movs r1,\dst,lsr \src
	and v30f,r1,#PSR_A
	orreq v30f,v30f,#PSR_Z
	orrcs v30f,v30f,#PSR_C
	tst r1,#0x40
	orrne v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shr16 dst src
	movs r1,\dst,lsr \src
	and v30f,r1,#PSR_A
	orreq v30f,v30f,#PSR_Z
	orrcs v30f,v30f,#PSR_C
	tst r1,#0x4000
	orrne v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shra8 dst src
	mov \dst,\dst,lsl#24
	mov \dst,\dst,asr \src
	movs r1,\dst,asr#24
	and v30f,r1,#PSR_A
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrcs v30f,v30f,#PSR_C
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shra16 dst src
	mov \dst,\dst,lsl#16
	mov \dst,\dst,asr \src
	movs r1,\dst,asr#16
	and v30f,r1,#PSR_A
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrcs v30f,v30f,#PSR_C
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro sub8 src dst
	eor r2,\dst,\src
	mov \dst,\dst,lsl#24
	subs \src,\dst,\src,lsl#24
	eor r2,r2,\src,lsr#24
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\src,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro sub16 src dst
	eor r2,\src,\dst,lsr#16
	subs \src,\dst,\src,lsl#16
	eor r2,r2,\src,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\src,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro subc8 src dst
	and v30f,v30f,#PSR_C
	subs \src,\src,v30f,lsl#7	;@ Fix up src and set correct C.
	eor r2,\dst,\src
	mov \dst,\dst,lsl#24
	sbcs \src,\dst,\src,ror#8
	eor r2,r2,\src,lsr#24
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\src,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro subc16 src dst
	and v30f,v30f,#PSR_C
	subs \src,\src,v30f,lsl#15	;@ Fix up src and set correct C.
	eor r2,\src,\dst,lsr#16
	sbcs \src,\dst,\src,ror#16
	eor r2,r2,\src,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\src,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro xor8 src dst
	eor r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro xor16 src dst
	eor r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@---------------------------------------
