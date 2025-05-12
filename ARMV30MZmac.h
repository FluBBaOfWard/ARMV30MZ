//
//  ARMV30MZmac.h
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2025 Fredrik Ahlström. All rights reserved.
//

#include "ARMV30MZ.i"
							;@ ARM flags
	.equ PSR_S, 0x00000008		;@ Sign (negative)
	.equ PSR_Z, 0x00000004		;@ Zero
	.equ PSR_C, 0x00000002		;@ Carry
	.equ PSR_V, 0x00000001		;@ Overflow

	.equ PSR_P, 0x00000020		;@ Parity
	.equ PSR_A, 0x00000010		;@ Aux/Half carry


							;@ V30 flags
	.equ MF, 0x8000				;@ Mode, 1=native/0=emulated, 0 invalid in V30MZ.
		;@   0x4000				;@ 1
		;@   0x2000				;@ 1
		;@   0x1000				;@ 1
	.equ OF, 0x0800				;@ Overflow
	.equ DF, 0x0400				;@ Direction
	.equ IF, 0x0200				;@ Interrupt enable
	.equ TF, 0x0100				;@ BREAK/TRAP
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

	.macro getNextSignedWordTo dst use
	ldrb \dst,[v30pc],#1
	ldrsb \use,[v30pc],#1
	orr \dst,\dst,\use,lsl#8
	.endm

	.macro getNextSignedWord
	getNextSignedWordTo r0, r1
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

	.macro SetSegmentPrefix
	orr v30f,v30f,#SEG_PF
	.endm

	.macro TestSegmentPrefix
	tst v30f,#SEG_PF
	.endm

	.macro SetRepeatEPrefix
	orr v30f,v30f,#REPE_PF
	.endm

	.macro SetRepeatNEPrefix
	orr v30f,v30f,#RPNE_PF
	.endm

	.macro TestRepeatPrefix
	tst v30f,#REPE_PF+RPNE_PF
	.endm

	.macro TestRepeatEPrefix
	tst v30f,#REPE_PF
	.endm

	.macro TestRepeatNEPrefix
	tst v30f,#RPNE_PF
	.endm

	.macro SetLockPrefix
	.endm

	.macro ClearPrefixes
	bic v30f,v30f,#SEG_PF+REPE_PF+RPNE_PF	//+LOCK_PF
	.endm

	.macro GetIyOfsESegment
#ifdef __ARM_ARCH_5TE__
	ldrd v30ofs,v30csr,[v30ptr,#v30RegIY]
#else
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldr v30csr,[v30ptr,#v30SRegDS1]
#endif
	.endm

	.macro GetIyOfsESegmentR2R3
#ifdef __ARM_ARCH_5TE__
	ldrd r2,r3,[v30ptr,#v30RegIY]
#else
	ldr r2,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegDS1]
#endif
	.endm

;@ Opcode macros always return result in r1
;@ Any register except r2 can be used for src & dst.
;@ r1 should not be used for src
;@----------------------------------------------------------------------------
	.macro add8 dst src
	mov \src,\src,lsl#24
	mov r2,\dst,lsl#28
	adds \dst,\src,\dst,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	adds r2,r2,\src,lsl#4
	orrcs v30f,v30f,#PSR_A
	mov r1,\dst,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro add16 dst src
	mov r2,\dst,lsl#12
	adds r1,\dst,\src,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	adds r2,r2,\src,lsl#28
	orrcs v30f,v30f,#PSR_A
	str r1,[v30ptr,#v30ParityValL]
	.endm
;@----------------------------------------------------------------------------
	.macro adc8 dst src
	tst v30f,v30f,lsr#2			;@ Get Carry
	subcs \src,\src,#0x100
	mov \src,\src,ror#8
	adcs \dst,\src,\dst,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	mov r2,\dst,lsl#4
	cmp r2,\src,lsl#4
	orrcc v30f,v30f,#PSR_A
	mov r1,\dst,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro adc16 dst src
	tst v30f,v30f,lsr#2			;@ Get Carry
	subcs \src,\src,#0x10000
	eor r2,\src,\dst,lsr#16
	adcs r1,\dst,\src,ror#16
	eor r2,r2,r1,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	str r1,[v30ptr,#v30ParityValL]
	.endm
;@----------------------------------------------------------------------------
	.macro and8 dst src
	and r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro and16 dst src
	ands v30f,\dst,\src,lsl#16	;@ Do op & clear flags.
	str v30f,[v30ptr,#v30ParityValL]
	mov r1,v30f,lsr#16
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	.endm
;@----------------------------------------------------------------------------
	.macro decByte
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r0,r0,lsl#24
	subs r1,r0,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF000000
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro decWord
	and v30f,v30f,#PSR_C		;@ Only keep C
	subs r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#v30ParityValL]
	.endm
;@----------------------------------------------------------------------------
	.macro incByte
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r0,r0,lsl#24
	adds r1,r0,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF000000
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro incWord
	and v30f,v30f,#PSR_C		;@ Only keep C
	adds r1,r0,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#v30ParityValL]
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
	.macro or8 dst src
	orr r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro or16 dst src
	orrs v30f,\dst,\src,lsl#16	;@ Do op & clear flags.
	str v30f,[v30ptr,#v30ParityValL]
	mov r1,v30f,lsr#16
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
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
	rsb r2,\src,#0
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry, keep eq
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr r1,\dst,\dst,lsl#8
	orr r1,r1,r1,lsl#16
	movs r0,r1,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,r1,ror r2
	.endm

	.macro rol16 dst src
	rsb r2,\src,#0
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr r1,\dst,\dst,lsl#16
	movs r0,r1,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,r1,ror r2
	.endm
;@----------------------------------------------------------------------------
	.macro rolc8 dst src
	cmp \src,#18
	subcs \src,\src,#18
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrcs \dst,\dst,#0x00000100
	mov \dst,\dst,lsl \src
	orr \dst,\dst,\dst,lsr#9
	orr r1,\dst,\dst,lsr#9
	movs r0,r1,lsl#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	.endm

	.macro rolc16 dst src
	cmp \src,#17
	subcs \src,\src,#17
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	mov \dst,\dst,lsl#16
	orrcs \dst,\dst,#0x00008000
	orr \dst,\dst,\dst,lsr#17
	movs r1,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_V
	mov r1,r1,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro ror8 dst src
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs r1,\dst,ror \src
	orrcs v30f,v30f,#PSR_C
	teq r1,r1,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm

	.macro ror16 dst src
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orr \dst,\dst,\dst,lsl#16
	movs r1,\dst,ror \src
	orrcs v30f,v30f,#PSR_C
	teq r1,r1,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm
;@----------------------------------------------------------------------------
	.macro rorc8 dst src
	cmp \src,#18
	subcs \src,\src,#18
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrcs \dst,\dst,#0x00000100
	orr \dst,\dst,\dst,lsl#9
	orr \dst,\dst,\dst,lsl#9
	movs r1,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	mov r0,r1,lsl#24
	teq r0,r0,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm

	.macro rorc16 dst src
	cmp \src,#17
	subcs \src,\src,#17
	tst v30f,v30f,lsr#2					;@ Move PSR_C to Carry
	and v30f,v30f,#PSR_S+PSR_Z+PSR_A	;@ Keep S, Z & A
	orrcs \dst,\dst,#0x00010000
	orr \dst,\dst,\dst,lsl#17
	movs r1,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	mov r0,r1,lsl#16
	teq r0,r0,lsl#1
	orrmi v30f,v30f,#PSR_V
	.endm
;@----------------------------------------------------------------------------
	.macro shl8 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	mov \dst,\dst,lsl#24
	movs r1,\dst,lsl \src
	mov r1,r1,lsr#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro shl16 dst src
	movs v30f,v30f,lsl#31		;@ Move PSR_C to Carry, clear flags
	mov \dst,\dst,lsl#16
	movs r1,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eormi v30f,v30f,#PSR_S+PSR_V
	orreq v30f,v30f,#PSR_Z
	str r1,[v30ptr,#v30ParityValL]
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
	movs r0,r1,lsl#25			;@ Move bit 6 to bit 31 & 7 to Carry.
	orrcs v30f,v30f,#PSR_S+PSR_V
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
	movs r0,r1,lsl#17			;@ Move bit 14 to bit 31 & 15 to Carry.
	orrcs v30f,v30f,#PSR_S+PSR_V
	eormi v30f,v30f,#PSR_V
	strb r1,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro sub8 dst src
	mov r2,\src,lsl#28
	mov \dst,\dst,lsl#24
	subs \src,\dst,\src,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	rsbs r2,r2,\dst,lsl#4
	orrcc v30f,v30f,#PSR_A
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\src,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro sub16 dst src
	mov r2,\dst,lsl#12
	subs \dst,\dst,\src,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	cmp r2,\src,lsl#28
	orrcc v30f,v30f,#PSR_A
	eor v30f,v30f,#PSR_C		;@ Invert C
	str r1,[v30ptr,#v30ParityValL]
	.endm

	.macro rsb16 dst src
	mov r2,\dst,lsl#28
	rsbs r1,\src,\dst,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	cmp r2,\src,lsl#12
	orrcc v30f,v30f,#PSR_A
	eor v30f,v30f,#PSR_C		;@ Invert C
	str r1,[v30ptr,#v30ParityValL]
	.endm
;@----------------------------------------------------------------------------
	.macro subc8 dst src
	and v30f,v30f,#PSR_C
	subs \src,\src,v30f,lsl#7	;@ Fix up src and set correct C.
	mvn \src,\src,ror#8
	adcs \dst,\src,\dst,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	mov r2,\dst,lsl#4
	cmp r2,\src,lsl#4
	orrcs v30f,v30f,#PSR_A
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,\dst,lsr#24
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro subc16 dst src
	and v30f,v30f,#PSR_C
	subs \src,\src,v30f,lsl#15	;@ Fix up src and set correct C.
	eor r2,\src,\dst,lsr#16
	sbcs r1,\dst,\src,ror#16
	eor r2,r2,r1,lsr#16
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, C & V.
	orr v30f,r2,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	str r1,[v30ptr,#v30ParityValL]
	.endm

	.macro rsbc16 dst src
	and v30f,v30f,#PSR_C
	mov \src,\src,lsr#16
	subs \src,\src,v30f,lsl#15	;@ Fix up src and set correct C.
	mvn \src,\src,ror#16
	adcs r1,\src,\dst,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	mov r2,r1,lsl#12
	cmp r2,\src,lsl#12
	orrcs v30f,v30f,#PSR_A
	eor v30f,v30f,#PSR_C		;@ Invert C
	str r1,[v30ptr,#v30ParityValL]
	.endm

;@----------------------------------------------------------------------------
	.macro tst16 dst src
	ands v30f,\dst,\src,lsl#16	;@ Do op & clear flags.
	str v30f,[v30ptr,#v30ParityValL]
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	.endm
;@----------------------------------------------------------------------------
	.macro xor8 dst src
	eor r1,\dst,\src
	movs v30f,r1,lsl#24			;@ Clear flags.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	.endm

	.macro xor16 dst src
	eors v30f,\dst,\src,lsl#16	;@ Do op & clear flags.
	str v30f,[v30ptr,#v30ParityValL]
	mov r1,v30f,lsr#16
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
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
