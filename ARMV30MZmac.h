//
//  ARMV30MZmac.h
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2023 Fredrik Ahlström. All rights reserved.
//

#include "ARMV30MZ.i"
							;@ ARM flags
	.equ PSR_S, 0x00000008		;@ Sign (negative)
	.equ PSR_Z, 0x00000004		;@ Zero
	.equ PSR_C, 0x00000002		;@ Carry
	.equ PSR_V, 0x00000001		;@ Overflow

	.equ PSR_P, 0x00000020		;@ Parity
	.equ PSR_A, 0x00000010		;@ Aux/Half carry
	.equ SEG_PF, 1<<7			;@ Segment prefix
	.equ REP_PF, 1<<6			;@ Repeat prefix


							;@ V30 flags
	.equ MF, 0x8000				;@ Mode, 1=native/0=emulated, 0 invalid in V30MZ.
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

	.macro eatCycles count
	sub v30cyc,v30cyc,#(\count)*CYCLE
	.endm

	.macro loadLastBank reg
	ldr \reg,[v30ptr,#v30LastBank]
	.endm

	.macro getNextByteTo reg
	ldrb \reg,[v30pc],#1
	.endm

	.macro getNextByte
	getNextByteTo r0
	.endm

	.macro getNextSignedByteTo reg
	ldrsb \reg,[v30pc],#1
	.endm

	.macro getNextSignedByte
	getNextSignedByteTo r0
	.endm

	.macro getNextWordTo dst use
	ldrb \dst,[v30pc],#1
	ldrb \use,[v30pc],#1
	orr \dst,\dst,\use,lsl#8
	.endm

	.macro getNextWord
	getNextWordTo r0, r1
	.endm

	.macro fetch count
	subs v30cyc,v30cyc,#(\count)*CYCLE
	ldrbgt r0,[v30pc],#1
	ldrgt pc,[v30ptr,r0,lsl#2]
	b v30OutOfCycles
	.endm

	.macro executeNext
	ldrb r0,[v30pc],#1
	ldr pc,[v30ptr,r0,lsl#2]
	.endm

	.macro fetchForce count
	eatCycles \count
	executeNext
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
//	tst v30pc,#1
//	subne v30cyc,v30cyc,#1*CYCLE
//	bl V30ReEncodePC
	.endm

	.macro TestSegmentPrefix
	tst v30f,#SEG_PF
	.endm

	.macro ClearSegmentPrefix
	bic v30f,v30f,#SEG_PF
	.endm

	.macro ClearPrefixes
	bic v30f,v30f,#SEG_PF+REP_PF	//+LOCK_PREFIX
	.endm

	.macro GetIyOfsESegment
#ifdef ARM9
	ldrd v30ofs,v30csr,[v30ptr,#v30RegIY]
#else
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldr v30csr,[v30ptr,#v30SRegES]
#endif
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
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro and16 src dst
	and r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro decWord reg
	ldr r0,[v30ptr,#\reg -2]
	and v30f,v30f,#PSR_C		;@ Only keep C
	subs r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg -2]
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	fetch 1
	.endm
;@----------------------------------------------------------------------------
	.macro incWord reg
	ldr r0,[v30ptr,#\reg -2]
	and v30f,v30f,#PSR_C		;@ Only keep C
	adds r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg -2]
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	fetch 1
	.endm
;@----------------------------------------------------------------------------
	.macro jmpne flag
	getNextSignedByte
	tst v30f,#\flag
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
	.endm

	.macro jmpeq flag
	getNextSignedByte
	tst v30f,#\flag
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
	.endm
;@----------------------------------------------------------------------------
	.macro or8 src dst
	orr r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro or16 src dst
	orr r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro popWord8F
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	add r2,v30ofs,#0x20000
	add r0,r0,v30ofs,lsr#4
	str r2,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	.endm

	.macro popWord
	bl v30ReadStack
	add v30ofs,v30ofs,#0x20000
	str v30ofs,[v30ptr,#v30RegSP]
	.endm

	.macro popRegister reg
	popWord
	strh r0,[v30ptr,#\reg]
	fetch 1
	.endm

	.macro pushRegister reg
	ldrh r1,[v30ptr,#\reg]
	bl v30PushW
	fetch 1
	.endm
;@----------------------------------------------------------------------------
	.macro rol8 dst src
	cmp \src,#0x10
	andne \src,\src,#0x0F
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro rol16 dst src
	cmp \src,#0x10
	andne \src,\src,#0x0F
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro rolc8 dst src
	tst v30f,#PSR_C
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrne \dst,\dst,#0x100
	cmp \src,#0
	beq 10f
9:
	tst \dst,\dst,lsr#9
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 9b
10:
	movs \dst,\dst,lsl#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro rolc16 dst src
	tst v30f,#PSR_C
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrne \dst,\dst,#0x10000
	cmp \src,#0
	beq 12f
11:
	tst \dst,\dst,lsr#17
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 11b
12:
	movs \dst,\dst,lsl#16
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro ror8 dst src
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C
	eors r1,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#24
	.endm

	.macro ror16 dst src
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C
	eors r1,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	mov r1,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro rorc8 dst src
	mov \dst,\dst,lsl#24
	tst v30f,#PSR_C
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrne \dst,\dst,#0x00800000
	cmp \src,#0
	beq 14f
13:
	tst \dst,\dst,lsr#24
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 13b
14:
	movs r1,\dst,lsr#24
	orrcs v30f,v30f,#PSR_C
	eors r2,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm

	.macro rorc16 dst src
	tst v30f,#PSR_C
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	mov \dst,\dst,lsl#16
	orrne \dst,\dst,#0x00008000
	cmp \src,#0
	beq 16f
15:
	tst \dst,\dst,lsr#16
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 15b
16:
	movs r1,\dst,lsr#16
	orrcs v30f,v30f,#PSR_C
	eors r2,\dst,\dst,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm
;@----------------------------------------------------------------------------
	.macro shl8 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	mov \dst,\dst,lsl#24
	movs \dst,\dst,lsl \src
	mov r1,\dst,lsr#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shl16 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	mov \dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	mov r1,\dst,asr#16
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shr8 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	movs r1,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	orreq v30f,v30f,#PSR_Z
	movs r0,r1,lsl#25			;@ Move bit 6 to bit 31 & 7 to Carry.
	orrcs v30f,v30f,#PSR_S+PSR_V
	eormi v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shr16 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	movs r1,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	orreq v30f,v30f,#PSR_Z
	movs r0,r1,lsl#17			;@ Move bit 14 to bit 31 & 15 to Carry.
	orrcs v30f,v30f,#PSR_S+PSR_V
	eormi v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shra8 dst src
	mov \dst,\dst,lsl#24
	mov \dst,\dst,asr#24
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	movs r1,\dst,asr \src
	orrcs v30f,v30f,#PSR_C
	orreq v30f,v30f,#PSR_Z
	orrmi v30f,v30f,#PSR_S+PSR_V
	movs r0,r1,lsl#25			;@ Move bit 6 to bit 31.
	eormi v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shra16 dst src
	mov \dst,\dst,lsl#16
	mov \dst,\dst,asr#16
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	movs r1,\dst,asr \src
	orrcs v30f,v30f,#PSR_C
	orreq v30f,v30f,#PSR_Z
	orrmi v30f,v30f,#PSR_S+PSR_V
	movs r0,r1,lsl#17			;@ Move bit 14 to bit 31.
	eormi v30f,v30f,#PSR_V
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

	.macro rsb16 src dst
	eor r2,\src,\dst,lsr#16
	rsbs \src,\dst,\src,lsl#16
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

	.macro rsbc16 dst src
	mov \src,\src,lsr#16
	mov \dst,\dst,lsl#16
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
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro xor16 src dst
	eor r1,\src,\dst,lsr#16
	movs v30f,r1,lsl#16			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro xchgreg src
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#\src]
	strh r0,[v30ptr,#\src]
	strh r1,[v30ptr,#v30RegAW]
	fetch 3
	.endm

;@---------------------------------------
