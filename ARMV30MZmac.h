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
	.equ PSR_ALL, 0x0000003F	;@ All flags

.equ PSR_X, 0x00000000
.equ PSR_Y, 0x00000000


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
;@----------------------------------------------------------------------------

	.macro encodePC				;@ Translate v30pc from V30 PC to rom offset
#ifdef V30_FAST
	and r0,v30pc,#MEM_BANK_MASK
	add r2,v30ptr,#v30MemTbl
	ldr r0,[r2,r0,lsr#MEM_BANK_SHIFT]
	storeLastBank r0
	add v30pc,v30pc,r0
#else
	bl translateZ80PCToOffset	;@ In=z80pc, out=z80pc
#endif
	.endm

	.macro encodeFLG			;@ Pack Z80 flags into r0
	and r0,v30f,#PSR_A|PSR_Y
	and r1,v30f,#PSR_S|PSR_Z
	orr r0,r0,r1,lsl#4
	movs r1,v30f,lsl#31
	orrmi r0,r0,#VF
	and r1,v30f,#PSR_n
	adc r0,r0,r1,lsr#6			;@ NF & CF
	tst v30f,#PSR_X
	orrne r0,r0,#XF
	.endm

	.macro decodeFLG			;@ Unpack Z80 flags from r0
	and v30f,r0,#HF|YF
	tst r0,#XF
	orrne v30f,v30f,#PSR_X
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	and r1,r0,#SF|ZF
	movs r0,r0,lsl#30
	adc v30f,v30f,r1,lsr#4		;@ Also sets V/P Flag.
	orrmi v30f,v30f,#PSR_n
	.endm


	.macro getNextOpcode
	ldrb r0,[v30pc],#1
	.endm

	.macro executeOpcode count
	subs v30cyc,v30cyc,#(\count)*CYCLE
	ldrpl pc,[v30ptr,r0,lsl#2]
	b outOfCycles
	.endm

/*
	.macro fetch count
	subs v30cyc,v30cyc,#(\count)*CYCLE
	b fetchDebug
	.endm
*/
	.macro fetch count
	getNextOpcode
	executeOpcode \count
	.endm
/*	.macro fetch count
	subs v30cyc,v30cyc,#(\count)*CYCLE
	ldrplb r0,[v30pc],#1
	ldrpl pc,[v30ptr,r0,lsl#2]
	ldr pc,[v30ptr,#v30NextTimeout]
	.endm
*/
	.macro fetchForce
	getNextOpcode
	ldr pc,[v30ptr,r0,lsl#2]
	.endm

	.macro eatCycles count
	sub v30cyc,v30cyc,#(\count)*CYCLE
	.endm

	.macro getNextByte
	ldr r0,[v30ptr,#v30SRegCS]
	add r0,r0,v30pc,lsr#4
	add v30pc,v30pc,#0x10000
	bl cpuReadMem20
	.endm

	.macro getNextWord
	ldr r0,[v30ptr,#v30SRegCS]
	add r0,r0,v30pc,lsr#4
	add v30pc,v30pc,#0x20000
	bl cpuReadMem20W
	.endm

	.macro readMem8
#ifdef V30_FAST
	and r1,addy,#0xF0000
	add r2,v30ptr,#v30ReadTbl
	mov lr,pc
	ldr pc,[r2,r1,lsr#11]		;@ In: addy,r0=val(bits 8-31=?)
0:
#else
	bl memRead8
#endif
	.endm

	.macro readMem8BC
	mov addy,v30bc,lsr#16
	readMem8
	.endm

	.macro readMem8DE
	mov addy,z80de,lsr#16
	readMem8
	.endm

	.macro readMem8HL
#ifdef Z80_FAST
	mov addy,z80hl,lsr#16
	readMem8
#else
	bl memRead8HL
#endif
	.endm

	.macro readMem16 reg
	readMem8
	mov \reg,r0,lsl#16
	add addy,addy,#1
	readMem8
	orr \reg,\reg,r0,lsl#24
	.endm

	.macro writeMem8
#ifdef Z80_FAST
	and r1,addy,#0xE000
	add r2,z80optbl,#z80WriteTbl
	mov lr,pc
	ldr pc,[r2,r1,lsr#11]		;@ In: addy,r0=val(bits 8-31=?)
0:
#else
	bl memWrite8
#endif
	.endm

	.macro writeMem8e adr
#ifdef Z80_FAST
	and r1,addy,#0xE000
	add r2,z80optbl,#z80WriteTbl
	adr lr,\adr
	ldr pc,[r2,r1,lsr#11]		;@ In: addy,r0=val(bits 8-31=?)
#else
	adr lr,\adr
	b memWrite8
#endif
	.endm

	.macro writeMem8BC
	mov addy,z80bc,lsr#16
	writeMem8
	.endm

	.macro writeMem8DE
#ifdef Z80_FAST
	mov addy,z80de,lsr#16
	writeMem8
#else
	bl memWrite8DE
#endif
	.endm

;@----------------------------------------------------------------------------
	.macro add8 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	adds \src,\dst,\src,lsl#24
	eor r2,r2,\src
	orrcs v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x10000000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro add16 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	adds \src,\dst,\src,lsl#16
	eor r2,r2,\src
	orrcs v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x00100000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro adc8 src dst
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	subne \src,\src,#0x100
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	adcs \src,\dst,\src,ror#8
	eor r2,r2,\src
	orrcs v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x10000000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro adc16 src dst
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	subne \src,\src,#0x10000
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	adcs \src,\dst,\src,ror#16
	eor r2,r2,\src
	orrcs v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x00100000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro and8 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \src,\src,lsl#24
	and \src,\src,\dst,lsl#24
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro and16 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \src,\src,lsl#16
	and \src,\src,\dst,lsl#16
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro decWord reg
	ldr r0,[v30ptr,#\reg -2]
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_P+PSR_A	;@ Clear S, Z, V, P & A.
	subs r1,r0,#0x10000
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg]
	mov r1,r1,asr#16
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro incWord reg
	ldr r0,[v30ptr,#\reg -2]
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_P+PSR_A	;@ Clear S, Z, V, P & A.
	adds r1,r0,#0x10000
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	str r1,[v30ptr,#\reg]
	mov r1,r1,asr#16
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro jmpne flag
	stmfd sp!,{lr}
	ldr r0,[v30ptr,#v30SRegCS]
	add r0,r0,v30pc,lsr#4
	add v30pc,v30pc,#0x10000
	bl cpuReadMem20
	ldr r3,[v30ptr,#\flag]
	cmp r3,#0
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#8
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	ldmfd sp!,{pc}
	.endm

	.macro jmpeq flag
	stmfd sp!,{lr}
	ldr r0,[v30ptr,#v30SRegCS]
	add r0,r0,v30pc,lsr#4
	add v30pc,v30pc,#0x10000
	bl cpuReadMem20
	ldr r3,[v30ptr,#\flag]
	cmp r3,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#8
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	ldmfd sp!,{pc}
	.endm
;@----------------------------------------------------------------------------
	.macro or8 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#24
	orr \src,\dst,\src,lsl#24
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro or16 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#16
	orr \src,\dst,\src,lsl#16
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro rol8 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	and \src,\src,#0xF
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eorpl v30f,v30f,#PSR_V
	mov \src,\dst,lsr#24
	.endm

	.macro rol16 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	cmp \src,#0x10
	andne \src,\src,#0xF
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	eorpl v30f,v30f,#PSR_V
	mov \src,\dst,lsr#16
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
	eorpl v30f,v30f,#PSR_V
	mov \src,\dst,lsr#24
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
	eorpl v30f,v30f,#PSR_V
	mov \src,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro ror8 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	mov r2,#0
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	tst \dst,#0x40000000
	eorne v30f,v30f,#PSR_V
	mov \src,\dst,lsr#24
	.endm

	.macro ror16 dst src
	bic v30f,v30f,#PSR_C+PSR_V	;@ Clear C & V.
	orr \dst,\dst,\dst,lsl#16
	mov r2,#0
	movs \dst,\dst,ror \src
	orrcs v30f,v30f,#PSR_C+PSR_V
	tst \dst,#0x40000000
	eorne v30f,v30f,#PSR_V
	mov \src,\dst,lsr#16
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
	movs \src,\dst,lsr#24
	orrcs v30f,v30f,#PSR_C
	eor r2,\src,\src,lsr#1
	tst r2,#0x40
	orrne v30f,v30f,#PSR_V
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
	movs \src,\dst,lsr#16
	orrcs v30f,v30f,#PSR_C
	eor r2,\src,\src,lsr#1
	tst r2,#0x4000
	orrne v30f,v30f,#PSR_V
	.endm
;@----------------------------------------------------------------------------
	.macro shl8 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	add \src,\src,#24
	movs \dst,\dst,lsl \src
	mov \src,\dst,asr#24
	orrcs v30f,v30f,#PSR_C+PSR_V
	eorpl v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shl16 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	add \src,\src,#16
	movs \dst,\dst,lsl \src
	mov \src,\dst,asr#16
	orrcs v30f,v30f,#PSR_C+PSR_V
	eorpl v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shr8 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	movs \src,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	tst \src,#0x40
	orrne v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shr16 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	movs \src,\dst,lsr \src
	orrcs v30f,v30f,#PSR_C
	tst \src,#0x4000
	orrne v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shra8 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#24
	mov \dst,\dst,asr \src
	movs \src,\dst,asr#24
	orrcs v30f,v30f,#PSR_C
	eor r2,\src,\src,lsr#1
	tst r2,#0x40
	orrne v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shra16 dst src
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#16
	mov \dst,\dst,asr \src
	movs \src,\dst,asr#16
	orrcs v30f,v30f,#PSR_C
	eor r2,\src,\src,lsr#1
	tst \src,#0x4000
	orrne v30f,v30f,#PSR_V
	tst \src,#0x10
	orrne v30f,v30f,#PSR_A
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro sub8 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	subs \src,\dst,\src,lsl#24
	eor r2,r2,\src
	orrcc v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x10000000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro sub16 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	subs \src,\dst,\src,lsl#16
	eor r2,r2,\src
	orrcc v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x00100000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro subc8 src dst
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	orrne \src,\src,#0x80000000
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	subs \src,\dst,\src,ror#8
	eor r2,r2,\src
	orrcc v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x10000000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro subc16 src dst
	tst v30f,#PSR_C
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	orrne \src,\src,#0x80000000
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	subs \src,\dst,\src,ror#16
	eor r2,r2,\src
	orrcc v30f,v30f,#PSR_C
	orrvs v30f,v30f,#PSR_V
	tst r2,#0x00100000
	orrne v30f,v30f,#PSR_A
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro xor8 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \src,\src,lsl#24
	eor \src,\src,\dst,lsl#24
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro xor16 src dst
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V, P & A.
	mov \src,\src,lsl#16
	eor \src,\src,\dst,lsl#16
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@---------------------------------------
