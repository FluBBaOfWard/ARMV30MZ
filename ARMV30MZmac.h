
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
	subs cycles,cycles,#(\count)*CYCLE
	ldrpl pc,[v30ptr,r0,lsl#2]
	b outOfCycles
	.endm

/*
	.macro fetch count
	subs cycles,cycles,#(\count)*CYCLE
	b fetchDebug
	.endm
*/
	.macro fetch count
	getNextOpcode
	executeOpcode \count
	.endm
/*	.macro fetch count
	subs cycles,cycles,#(\count)*CYCLE
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
	sub cycles,cycles,#(\count)*CYCLE
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
	.macro add8
	mov r1,r1,lsl#24
	eor r2,r1,r0,lsl#24
	adds r0,r1,r0,lsl#24
	eor r2,r2,r0
	mov r1,#0
	adc r3,r1,#0
	movvs r1,#1
	str r3,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov r0,r0,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
	.macro adc8
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	subne r0,r0,#0x100
	mov r1,r1,lsl#24
	eor r2,r1,r0,lsl#24
	adcs r0,r1,r0,ror#8
	eor r2,r2,r0
	mov r1,#0
	adc r3,r1,#0
	movvs r1,#1
	str r3,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov r0,r0,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
	.macro and8
	mov r0,r0,lsl#24
	and r0,r0,r1,lsl#24
	mov r1,#0
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	str r1,[v30ptr,#v30AuxVal]
	mov r0,r0,asr#24
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
	ldr r0,[v30ptr,#v30ICount]
	strh r1,[v30ptr,#\reg]
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	tst r1,#0xF
	moveq r3,#1
	mov r1,r1,asr#16
	ldr r0,[v30ptr,#v30ICount]
	strh r1,[v30ptr,#\reg]
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	bx lr
	.endm
;@----------------------------------------------------------------------------
	.macro jmpne flag
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldr r3,[v30ptr,#\flag]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r3,#0
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#4
	subeq r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
	.endm

	.macro jmpeq flag
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldr r3,[v30ptr,#\flag]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r3,#0
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#4
	subne r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
	.endm

;@----------------------------------------------------------------------------
	.macro or8
	mov r1,r1,lsl#24
	orr r0,r1,r0,lsl#24
	mov r1,#0
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	str r1,[v30ptr,#v30AuxVal]
	mov r0,r0,asr#24
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
	.macro sbb8
	ldr r3,[v30ptr,#v30CarryVal]
	cmp r3,#0
	orrne r0,r0,#0x80000000
	mov r1,r1,lsl#24
	eor r2,r1,r0,lsl#24
	subs r0,r1,r0,ror#8
	eor r2,r2,r0
	mov r1,#0
	adc r3,r1,#0
	eor r3,r3,#1
	movvs r1,#1
	str r3,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov r0,r0,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
	.endm

	.macro sbb16 src dst
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
	.macro sub8
	mov r1,r1,lsl#24
	eor r2,r1,r0,lsl#24
	subs r0,r1,r0,lsl#24
	eor r2,r2,r0
	mov r1,#0
	adc r3,r1,#0
	eor r3,r3,#1
	movvs r1,#1
	str r3,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	and r2,r2,#0x10000000
	mov r0,r0,asr#24
	str r2,[v30ptr,#v30AuxVal]
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
	.macro xor8
	mov r0,r0,lsl#24
	eor r0,r0,r1,lsl#24
	mov r1,#0
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	str r1,[v30ptr,#v30AuxVal]
	mov r0,r0,asr#24
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
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
