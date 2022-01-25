
#include "ARMV30MZ.i"
							;@ ARM flags
	.equ PSR_S, 0x00000008		;@ Sign (negative)
	.equ PSR_Z, 0x00000004		;@ Zero
	.equ PSR_C, 0x00000002		;@ Carry
	.equ PSR_V, 0x00000001		;@ Overflow/Parity
	.equ PSR_P, 0x00000001		;@ Overflow/Parity

	.equ PSR_n, 0x00000080		;@ Was the last opcode add or sub?
	.equ PSR_X, 0x00000040		;@ v30_X (unused)
	.equ PSR_Y, 0x00000020		;@ v30_Y (unused)
	.equ PSR_H, 0x00000010		;@ Half carry


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

	.macro reEncodePC			;@ Translate v30pc from V30 PC to rom offset
	loadLastBank r0
	sub v30pc,v30pc,r0
	encodePC
	.endm

	.macro encodeFLG			;@ Pack Z80 flags into r0
	and r0,v30f,#PSR_H|PSR_Y
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
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add v30pc,v30pc,#1
	strh v30pc,[v30ptr,#v30IP]
	bl cpu_readmem20
	.endm

	.macro getNextWord
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add v30pc,v30pc,#2
	strh v30pc,[v30ptr,#v30IP]
	bl cpu_readmem20w
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

	.macro writeMem8HL
	mov addy,z80hl,lsr#16
	writeMem8
	.endm

	.macro writeMem8HLe adr
	mov addy,z80hl,lsr#16
	writeMem8e \adr
	.endm

	.macro writeMem8HLminus adr
	mov addy,z80hl,lsr#16
	sub z80hl,z80hl,#0x00010000
	writeMem8e \adr
	.endm

	.macro writeMem8HLplus adr
	mov addy,z80hl,lsr#16
	add z80hl,z80hl,#0x00010000
	writeMem8e \adr
	.endm

	.macro writeMem16 reg
	mov r0,\reg,lsr#16
	writeMem8
	add addy,addy,#1
	mov r0,\reg,lsr#24
	writeMem8
	.endm

	.macro copyMem8HL_DE
	readMem8HL
	writeMem8DE
	.endm

	.macro calcIXd
	ldrsb r1,[z80pc],#1
	ldr addy,[z80xy]
	add addy,addy,r1,lsl#16
	mov addy,addy,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro add8 src dst
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	adds \src,\dst,\src,lsl#24
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov \src,\src,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro add16 src dst
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	adds \src,\dst,\src,lsl#16
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x00100000
	mov \src,\src,asr#16
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro adc8 src dst
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	subne \src,\src,#0x100
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	adcs \src,\dst,\src,ror#8
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov \src,\src,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro adc16 src dst
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	subne \src,\src,#0x10000
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	adcs \src,\dst,\src,ror#16
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x00100000
	mov \src,\src,asr#16
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro and8 src dst
	mov \src,\src,lsl#24
	and \src,\src,\dst,lsl#24
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro and16 src dst
	mov \src,\src,lsl#16
	and \src,\src,\dst,lsl#16
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro decWord reg
	ldrh r0,[v30ptr,#\reg]
	mov r2,#0
	mov r3,#0
	mov r1,r0,lsl#16
	subs r1,r1,#0x10000
	movvs r2,#1
	tst r0,#0xF
	moveq r3,#1
	mov r1,r1,asr#16
	strh r1,[v30ptr,#\reg]
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro incWord reg
	ldrh r0,[v30ptr,#\reg]
	mov r2,#0
	mov r3,#0
	mov r1,r0,lsl#16
	adds r1,r1,#0x10000
	movvs r2,#1
	tst r1,#0xF0000
	moveq r3,#1
	mov r1,r1,asr#16
	strh r1,[v30ptr,#\reg]
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro jmpne flag
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,lsl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r3,[v30ptr,#\flag]
	cmp	r3,#0
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
	.endm

	.macro jmpeq flag
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,lsl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r3,[v30ptr,#\flag]
	cmp	r3,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
	.endm
;@----------------------------------------------------------------------------
	.macro or8 src dst
	mov \dst,\dst,lsl#24
	orr \src,\dst,\src,lsl#24
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro or16 src dst
	mov \dst,\dst,lsl#16
	orr \src,\dst,\src,lsl#16
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro rol8 dst src
	and \src,\src,#0xF
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	mov \src,\dst,lsr#24
	and r2,\src,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	.endm

	.macro rol16 dst src
	cmp \src,#0x10
	andne \src,\src,#0xF
	orr \dst,\dst,\dst,lsl#16
	movs \dst,\dst,lsl \src
	mov \src,\dst,lsr#16
	and r2,\src,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	.endm
;@----------------------------------------------------------------------------
	.macro rolc8 dst src
	ldr r2,[v30ptr,#v30CarryVal]
	cmp r2,#0
	orrne \dst,\dst,#0x100
9:
	tst \dst,\dst,lsr#9
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 9b
	movs \dst,\dst,lsl#24
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	mov \src,\dst,lsr#24
	.endm

	.macro rolc16 dst src
	ldr r2,[v30ptr,#v30CarryVal]
	cmp r2,#0
	orrne \dst,\dst,#0x10000
10:
	tst \dst,\dst,lsr#17
	adc \dst,\dst,\dst
	subs \src,\src,#1
	bhi 10b
	movs \dst,\dst,lsl#16
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	mov \src,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro ror8 dst src
	orr \dst,\dst,\dst,lsl#8
	orr \dst,\dst,\dst,lsl#16
	mov r2,#0
	movs \dst,\dst,ror \src
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	tst \dst,#0x40000000
	eorne r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	mov \src,\dst,lsr#24
	.endm

	.macro ror16 dst src
	orr \dst,\dst,\dst,lsl#16
	mov r2,#0
	movs \dst,\dst,ror \src
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	tst \dst,#0x40000000
	eorne r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	mov \src,\dst,lsr#16
	.endm
;@----------------------------------------------------------------------------
	.macro rorc8 dst src
	mov \dst,\dst,lsl#24
	ldr r2,[v30ptr,#v30CarryVal]
	cmp r2,#0
	orrne \dst,\dst,#0x00800000
11:
	tst \dst,\dst,lsr#24
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 11b
	movs \src,\dst,lsr#24
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eor r2,\src,\src,lsr#1
	ands r2,r2,#0x40
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	.endm

	.macro rorc16 dst src
	mov \dst,\dst,lsl#16
	ldr r2,[v30ptr,#v30CarryVal]
	cmp r2,#0
	orrne \dst,\dst,#0x00008000
12:
	tst \dst,\dst,lsr#16
	rrx \dst,\dst
	subs \src,\src,#1
	bhi 12b
	movs \src,\dst,lsr#16
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eor r2,\src,\src,lsr#1
	ands r2,r2,#0x4000
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shl8 dst src
	add \src,\src,#24
	movs \dst,\dst,lsl \src
	mov \src,\dst,asr#24
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shl16 dst src
	add \src,\src,#16
	movs \dst,\dst,lsl \src
	mov \src,\dst,asr#16
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eorpl r2,r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shr8 dst src
	movs \src,\dst,lsr \src
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	ands r2,\src,#0x40
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shr16 dst src
	movs \src,\dst,lsr \src
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	ands r2,\src,#0x4000
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro shra8 dst src
	mov \dst,\dst,lsl#24
	mov \dst,\dst,asr \src
	movs \src,\dst,asr#24
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eor r2,\src,\src,lsr#1
	ands r2,r2,#0x40
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro shra16 dst src
	mov \dst,\dst,lsl#16
	mov \dst,\dst,asr \src
	movs \src,\dst,asr#16
	movcc r2,#0
	movcs r2,#1
	str r2,[v30ptr,#v30CarryVal]
	eor r2,\src,\src,lsr#1
	ands r2,\src,#0x4000
	movne r2,#1
	str r2,[v30ptr,#v30OverVal]
	and r2,\src,#0x10
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro sub8 src dst
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	subs \src,\dst,\src,lsl#24
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	eor r3,r3,#1
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov \src,\src,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro sub16 src dst
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	subs \src,\dst,\src,lsl#16
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	eor r3,r3,#1
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x00100000
	mov \src,\src,asr#16
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm
;@----------------------------------------------------------------------------
	.macro subc8 src dst
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	orrne \src,\src,#0x80000000
	mov \dst,\dst,lsl#24
	eor r2,\dst,\src,lsl#24
	subs \src,\dst,\src,ror#8
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	eor r3,r3,#1
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov \src,\src,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro subc16 src dst
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	orrne \src,\src,#0x80000000
	mov \dst,\dst,lsl#16
	eor r2,\dst,\src,lsl#16
	subs \src,\dst,\src,ror#16
	eor r2,r2,\src
	mov \dst,#0
	adc r3,\dst,#0
	eor r3,r3,#1
	movvs \dst,#1
	str r3,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	and r2,r2,#0x00100000
	mov \src,\src,asr#16
	str r2,[v30ptr,#v30AuxVal]
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@----------------------------------------------------------------------------
	.macro xor8 src dst
	mov \src,\src,lsl#24
	eor \src,\src,\dst,lsl#24
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#24
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

	.macro xor16 src dst
	mov \src,\src,lsl#16
	eor \src,\src,\dst,lsl#16
	mov \dst,#0
	str \dst,[v30ptr,#v30CarryVal]
	str \dst,[v30ptr,#v30OverVal]
	str \dst,[v30ptr,#v30AuxVal]
	mov \src,\src,asr#16
	str \src,[v30ptr,#v30SignVal]
	str \src,[v30ptr,#v30ZeroVal]
	str \src,[v30ptr,#v30ParityVal]
	.endm

;@---------------------------------------
