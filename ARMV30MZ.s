//
//  ARMV30MZ.s
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-12-19.
//  Copyright © 2021-2023 Fredrik Ahlström. All rights reserved.
//

#ifdef __arm__

#include "ARMV30MZmac.h"

	.syntax unified
	.arm

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2


	.global V30Init
	.global V30Reset
	.global V30SetIRQPin
	.global V30SetNMIPin
	.global V30SetResetPin
	.global V30RestoreAndRunXCycles
	.global V30RunXCycles
	.global V30CheckIRQs
	.global V30SaveState
	.global V30LoadState
	.global V30GetStateSize
	.global V30RedirectOpcode
	.global V30DecodePC
	.global V30EncodePC

	.global defaultV30

	.global V30OpTable
	.global PZSTable

	.global i_bv
	.global i_bnv
	.global i_bc
	.global i_bnc
	.global i_be
	.global i_bne
	.global i_bnh
	.global i_bh
	.global i_bn
	.global i_bp
	.global i_bpe
	.global i_bpo
	.global i_blt
	.global i_bge
	.global i_ble
	.global i_bgt

//
// All opcodes are free to also use r4-r5 without pushing to stack.
// If an opcode calls another opcode, the caller is responsible for
// saving r4-r5 before the call if needed.
//
;@----------------------------------------------------------------------------
i_add_br8:
_00:	;@ ADD BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	add8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	add8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_add_wr16:
_01:	;@ ADD WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	add16 r0,r4

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	add16 r0,r4

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_add_r8b:
_02:	;@ ADD R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	add8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_add_r16w:
_03:	;@ ADD R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	add16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_add_ald8:
_04:	;@ ADD ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	add8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_add_axd16:
_05:	;@ ADD AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	add16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_es:
_06:	;@ PUSH ES
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegES+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_pop_es:
_07:	;@ POP ES
;@----------------------------------------------------------------------------
	popWord
	strh r0,[v30ptr,#v30SRegES+2]
	fetch 3
;@----------------------------------------------------------------------------
i_or_br8:
_08:	;@ OR BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	andpl v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	or8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	or8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_or_wr16:
_09:	;@ OR WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	or16 r0,r4

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	or16 r0,r4

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_or_r8b:
_0A:	;@ OR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r3,r4,#0xff
	ldrbpl r0,[v30ptr,-r3]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	or8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_or_r16w:
_0B:	;@ OR R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	or16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_or_ald8:
_0C:	;@ OR ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	or8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_or_axd16:
_0D:	;@ OR AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	or16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_cs:
_0E:	;@ PUSH CS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegCS+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_adc_br8:
_10:	;@ ADDC/ADC BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	adc8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	adc8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_adc_wr16:
_11:	;@ ADDC/ADC WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	adc16 r0,r4

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	adc16 r0,r4

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_adc_r8b:
_12:	;@ ADDC/ADC R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	adc8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_adc_r16w:
_13:	;@ ADDC/ADC R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	adc16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_adc_ald8:
_14:	;@ ADDC/ADC ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	adc8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_adc_axd16:
_15:	;@ ADDC/ADC AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	adc16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_ss:
_16:	;@ PUSH SS
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegSS]
	ldr v30ofs,[v30ptr,#v30RegSP]
	mov r1,v30csr,lsr#16
	bl v30PushLastW
	fetch 2
;@----------------------------------------------------------------------------
i_pop_ss:
_17:	;@ POP SS
;@----------------------------------------------------------------------------
	popWord
	strh r0,[v30ptr,#v30SRegSS+2]
//	orr v30cyc,v30cyc,#LOCK_PREFIX
	fetchForce 3
;@----------------------------------------------------------------------------
i_sbb_br8:
_18:	;@ SUBC/SBB BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	subc8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	subc8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_wr16:
_19:	;@ SUBC/SBB WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldr r0,[v30ofs,#v30Regs2]
	subc16 r4,r0

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	mov r0,r0,lsl#16
	subc16 r4,r0

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_r8b:
_1A:	;@ SUBC/SBB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	subc8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_r16w:
_1B:	;@ SUBC/SBB R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	subc16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_ald8:
_1C:	;@ SUBC/SBB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	subc8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_axd16:
_1D:	;@ SUBC/SBB AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	subc16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_ds:
_1E:	;@ PUSH DS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegDS+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_pop_ds:
_1F:	;@ POP DS
;@----------------------------------------------------------------------------
	popWord
	strh r0,[v30ptr,#v30SRegDS+2]
	fetch 3
;@----------------------------------------------------------------------------
i_and_br8:
_20:	;@ AND BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	and8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	and8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_and_wr16:
_21:	;@ AND WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	and16 r0,r4

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	and16 r0,r4

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_and_r8b:
_22:	;@ AND R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	and8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_and_r16w:
_23:	;@ AND R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	and16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_and_ald8:
_24:	;@ AND ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	and8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_and_axd16:
_25:	;@ AND AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_es:
_26:	;@ ES prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30cyc,v30cyc,r1		;@ SEG_PREFIX
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]

;@----------------------------------------------------------------------------
i_daa:
_27:	;@ ADJ4A/DAA
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	and v30f,v30f,#PSR_A|PSR_C
	mov r1,#0x66000000
	cmn r1,r0,lsl#24
	orrcs v30f,v30f,#PSR_C
	cmn r1,r0,lsl#28
	orrcs v30f,v30f,#PSR_A
	tst v30f,#PSR_C
	biceq r1,r1,#0x60000000
	tst v30f,#PSR_A
	biceq r1,r1,#0x06000000
	adds r0,r1,r0,lsl#24
	mrs r1,cpsr				;@ S, Z, V & C.
	orr v30f,v30f,r1,lsr#28
	mov r0,r0,lsr#24
	strb r0,[v30ptr,#v30RegAL]
	strb r0,[v30ptr,#v30ParityVal]
	fetch 10
;@----------------------------------------------------------------------------
i_sub_br8:
_28:	;@ SUB BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	sub8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	sub8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_sub_wr16:
_29:	;@ SUB WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldr r0,[v30ofs,#v30Regs2]
	sub16 r4,r0

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	mov r0,r0,lsl#16
	sub16 r4,r0

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_sub_r8b:
_2A:	;@ SUB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	sub8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_sub_r16w:
_2B:	;@ SUB R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	sub16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_sub_ald8:
_2C:	;@ SUB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_sub_axd16:
_2D:	;@ SUB AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_cs:
_2E:	;@ CS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegCS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30cyc,v30cyc,r1		;@ SEG_PREFIX
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_das:
_2F:	;@ ADJ4S/DAS
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	and v30f,v30f,#PSR_A|PSR_C
	mov r2,r0,ror#4
	cmp r0,#0x9A
	orrcs v30f,v30f,#PSR_C
	tst v30f,#PSR_C
	subne r0,r0,#0x60
	cmp r2,#0xA0000000
	orrcs v30f,v30f,#PSR_A
	tst v30f,#PSR_A
	subne r0,r0,#0x06
	strb r0,[v30ptr,#v30RegAL]
	movs r1,r0,lsl#24
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	cmp r1,r2,ror#4
	orrvs v30f,v30f,#PSR_V
	strb r0,[v30ptr,#v30ParityVal]
	fetch 11
;@----------------------------------------------------------------------------
i_xor_br8:
_30:	;@ XOR BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
	ldrb r0,[v30ptr,-v30ofs]
	xor8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEA
	xor8 r4,r0

	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_xor_wr16:
_31:	;@ XOR WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	xor16 r0,r4

	strh r1,[v30ofs,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	bl v30ReadEAW
	xor16 r0,r4

	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_xor_r8b:
_32:	;@ XOR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	xor8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_xor_r16w:
_33:	;@ XOR R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	xor16 r0,r1
	strh r1,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_xor_ald8:
_34:	;@ XOR ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	xor8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_xor_axd16:
_35:	;@ XOR AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	xor16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_ss:
_36:	;@ SS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegSS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30cyc,v30cyc,r1		;@ SEG_PREFIX
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_aaa:
_37:	;@ ADJBA/AAA
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	mov r1,r0,lsl#28
	cmp r1,#0xA0000000
	orrcs v30f,v30f,#PSR_A			;@ Set Aux.
	tst v30f,#PSR_A
	moveq v30f,#PSR_S
	movne v30f,#PSR_Z+PSR_A+PSR_C
	strb r1,[v30ptr,#v30ParityVal]	;@ Parity allways set
	orrne r0,r0,#0x00F0
	addne r0,r0,#0x0016
	bic r0,r0,#0x00F0
	strh r0,[v30ptr,#v30RegAW]
	fetch 9
;@----------------------------------------------------------------------------
i_cmp_br8:
_38:	;@ CMP BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	andpl r1,r1,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	sub8 r4,r0
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_wr16:
_39:	;@ CMP WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	mov r0,r0,lsl#16
	sub16 r4,r0
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_r8b:
_3A:	;@ CMP R8b
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	andpl r1,r1,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	sub8 r0,r4
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_r16w:
_3B:	;@ CMP R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	sub16 r0,r4
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_ald8:
_3C:	;@ CMP ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r0,r1
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_axd16:
_3D:	;@ CMP AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	fetch 1
;@----------------------------------------------------------------------------
i_ds:
_3E:	;@ DS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegDS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30cyc,v30cyc,r1		;@ SEG_PREFIX
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_aas:
_3F:	;@ ADJBS / AAS
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	mov r1,r0,lsl#28
	cmp r1,#0xA0000000
	tstcc v30f,v30f,lsr#5			;@ Shift out PSR_A
	movcs v30f,#PSR_Z+PSR_A+PSR_C
	movcc v30f,#PSR_S
	strb r1,[v30ptr,#v30ParityVal]	;@ Parity allways set
	bic r0,r0,#0x00F0
	subcs r0,r0,#0x16
	bic r0,r0,#0x00F0
	strh r0,[v30ptr,#v30RegAW]
	fetch 9

;@----------------------------------------------------------------------------
i_inc_ax:
_40:	;@ INC AW/AX
;@----------------------------------------------------------------------------
	incWord v30RegAW
;@----------------------------------------------------------------------------
i_inc_cx:
_41:	;@ INC CW/CX
;@----------------------------------------------------------------------------
	incWord v30RegCW
;@----------------------------------------------------------------------------
i_inc_dx:
_42:	;@ INC DW/DX
;@----------------------------------------------------------------------------
	incWord v30RegDW
;@----------------------------------------------------------------------------
i_inc_bx:
_43:	;@ INC BW/BX
;@----------------------------------------------------------------------------
	incWord v30RegBW
;@----------------------------------------------------------------------------
i_inc_sp:
_44:	;@ INC SP
;@----------------------------------------------------------------------------
	incWord v30RegSP+2
;@----------------------------------------------------------------------------
i_inc_bp:
_45:	;@ INC BP
;@----------------------------------------------------------------------------
	incWord v30RegBP+2
;@----------------------------------------------------------------------------
i_inc_si:
_46:	;@ INC IX/SI
;@----------------------------------------------------------------------------
	incWord v30RegIX+2
;@----------------------------------------------------------------------------
i_inc_di:
_47:	;@ INC IY/DI
;@----------------------------------------------------------------------------
	incWord v30RegIY+2
;@----------------------------------------------------------------------------
i_dec_ax:
_48:	;@ DEC AW/AX
;@----------------------------------------------------------------------------
	decWord v30RegAW
;@----------------------------------------------------------------------------
i_dec_cx:
_49:	;@ DEC CW/CX
;@----------------------------------------------------------------------------
	decWord v30RegCW
;@----------------------------------------------------------------------------
i_dec_dx:
_4A:	;@ DEC DW/DX
;@----------------------------------------------------------------------------
	decWord v30RegDW
;@----------------------------------------------------------------------------
i_dec_bx:
_4B:	;@ DEC BW/BX
;@----------------------------------------------------------------------------
	decWord v30RegBW
;@----------------------------------------------------------------------------
i_dec_sp:
_4C:	;@ DEC SP
;@----------------------------------------------------------------------------
	decWord v30RegSP+2
;@----------------------------------------------------------------------------
i_dec_bp:
_4D:	;@ DEC BP
;@----------------------------------------------------------------------------
	decWord v30RegBP+2
;@----------------------------------------------------------------------------
i_dec_si:
_4E:	;@ DEC IX/SI
;@----------------------------------------------------------------------------
	decWord v30RegIX+2
;@----------------------------------------------------------------------------
i_dec_di:
_4F:	;@ DEC IY/DI
;@----------------------------------------------------------------------------
	decWord v30RegIY+2
;@----------------------------------------------------------------------------
i_push_ax:
_50:	;@ PUSH AW/AX
;@----------------------------------------------------------------------------
	pushRegister v30RegAW
;@----------------------------------------------------------------------------
i_push_cx:
_51:	;@ PUSH CW/CX
;@----------------------------------------------------------------------------
	pushRegister v30RegCW
;@----------------------------------------------------------------------------
i_push_dx:
_52:	;@ PUSH DW/DX
;@----------------------------------------------------------------------------
	pushRegister v30RegDW
;@----------------------------------------------------------------------------
i_push_bx:
_53:	;@ PUSH BW/BX
;@----------------------------------------------------------------------------
	pushRegister v30RegBW
;@----------------------------------------------------------------------------
i_push_sp:
_54:	;@ PUSH SP
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	sub v30ofs,v30ofs,#0x20000
	str v30ofs,[v30ptr,#v30RegSP]
	mov r1,v30ofs,lsr#16
	bl v30WriteSegOfsW
	fetch 1
;@----------------------------------------------------------------------------
i_push_bp:
_55:	;@ PUSH BP
;@----------------------------------------------------------------------------
	pushRegister v30RegBP+2
;@----------------------------------------------------------------------------
i_push_si:
_56:	;@ PUSH IX/SI
;@----------------------------------------------------------------------------
	pushRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_push_di:
_57:	;@ PUSH IY/DI
;@----------------------------------------------------------------------------
	pushRegister v30RegIY+2

;@----------------------------------------------------------------------------
i_pop_ax:
_58:	;@ POP AW/AX
;@----------------------------------------------------------------------------
	popRegister v30RegAW
;@----------------------------------------------------------------------------
i_pop_cx:
_59:	;@ POP CW/CX
;@----------------------------------------------------------------------------
	popRegister v30RegCW
;@----------------------------------------------------------------------------
i_pop_dx:
_5A:	;@ POP DW/DX
;@----------------------------------------------------------------------------
	popRegister v30RegDW
;@----------------------------------------------------------------------------
i_pop_bx:
_5B:	;@ POP BW/BX
;@----------------------------------------------------------------------------
	popRegister v30RegBW
;@----------------------------------------------------------------------------
i_pop_sp:
_5C:	;@ POP SP
;@----------------------------------------------------------------------------
	bl v30StackReadW
	strh r0,[v30ptr,#v30RegSP+2]
	fetch 1
;@----------------------------------------------------------------------------
i_pop_bp:
_5D:	;@ POP BP
;@----------------------------------------------------------------------------
	popRegister v30RegBP+2
;@----------------------------------------------------------------------------
i_pop_si:
_5E:	;@ POP IX/SI
;@----------------------------------------------------------------------------
	popRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_pop_di:
_5F:	;@ POP IY/DI
;@----------------------------------------------------------------------------
	popRegister v30RegIY+2

;@----------------------------------------------------------------------------
i_pusha:
_60:	;@ PUSHA
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	ldrh r1,[v30ptr,#v30RegAW]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegCW]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegDW]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegBW]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegSP+2]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegBP+2]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegIX+2]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	ldrh r1,[v30ptr,#v30RegIY+2]
	bl v30PushLastW
	fetch 9
;@----------------------------------------------------------------------------
i_popa:
_61:	;@ POPA
;@----------------------------------------------------------------------------
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegIY+2]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegIX+2]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x40000	;@ Skip one
	strh r0,[v30ptr,#v30RegBP+2]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegBW]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegDW]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegCW]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30RegAW]
	str v30ofs,[v30ptr,#v30RegSP]
	fetch 9
;@----------------------------------------------------------------------------
i_chkind:
_62:	;@ CHKIND/BOUND
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	bl v30ReadEAW
	add v30ofs,v30ofs,#0x20000
	mov r5,r0
	bl v30ReadSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	cmp r4,r5
	cmppl r0,r4
	submi v30cyc,v30cyc,#21*CYCLE
	movmi r0,#5
	bmi nec_interrupt
	fetch 14

;@----------------------------------------------------------------------------
i_push_d16:
_68:	;@ PUSH D16
;@----------------------------------------------------------------------------
	getNextWordTo r1, r0
	bl v30PushW
	fetch 1
;@----------------------------------------------------------------------------
i_imul_d16:
_69:	;@ MUL/IMUL D16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	getNextWordto r1, r2

	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mul r2,r0,r1
	movs r1,r2,asr#15
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V	;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]

	strh r2,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_push_d8:
_6A:	;@ PUSH D8
;@----------------------------------------------------------------------------
	getNextSignedByteTo r1
	bl v30PushW
	fetch 1
;@----------------------------------------------------------------------------
i_imul_d8:
_6B:	;@ MUL/IMUL D8
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	getNextSignedByteTo r1

	mov v30f,#PSR_Z					;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mul r2,r0,r1
	movs r1,r2,asr#15
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V	;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]

	strh r2,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3

;@----------------------------------------------------------------------------
f36c:	;@ REP INMB/INSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort
	mov r1,r0
	bl v30WriteSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_inmb:
_6C:	;@ INMB/INSB
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort
	mov r1,r0
	bl v30WriteSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIY]
	fetch 5

;@----------------------------------------------------------------------------
f36d:	;@ REP INMW/INSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldrh r4,[v30ptr,#v30RegDW]
0:
	mov r0,r4
	bl v30ReadPort
	mov r6,r0
	add r0,r4,#1
	bl v30ReadPort
	ldrsb r3,[v30ptr,#v30DF]
	orr r1,r6,r0,lsl#8
	ldr v30ofs,[v30ptr,#v30RegIY]
	add r3,v30ofs,r3,lsl#17
	str r3,[v30ptr,#v30RegIY]
	bl v30WriteSegOfsW
	eatCycles 6
	subs r5,r5,#1
	bne 0b
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_inmw:
_6D:	;@ INMW/INSW
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldrh r4,[v30ptr,#v30RegDW]
	mov r0,r4
	bl v30ReadPort
	mov r5,r0
	add r0,r4,#1
	bl v30ReadPort
	ldrsb r4,[v30ptr,#v30DF]
	ldr v30ofs,[v30ptr,#v30RegIY]
	orr r1,r5,r0,lsl#8
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	fetch 5

;@----------------------------------------------------------------------------
f36e:	;@ REP OUTMB/OUTSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	mov r1,r0
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30WritePort
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_outmb:
_6E:	;@ OUTMB/OUTSB
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIX]
	mov r1,r0
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30WritePort
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5

;@----------------------------------------------------------------------------
f36f:	;@ REP OUTMW/OUTSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
0:
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	add r2,v30ofs,r4,lsl#17
	str r2,[v30ptr,#v30RegIX]
	bl v30ReadSegOfsW
	and r1,r0,#0xFF
	mov r4,r0
	ldrh r6,[v30ptr,#v30RegDW]
	mov r0,r6
	bl v30WritePort
	mov r1,r4,lsr#8
	add r0,r6,#1
	bl v30WritePort
	eatCycles 6
	subs r5,r5,#1
	bne 0b
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_outmw:
_6F:	;@ OUTMW/OUTSW
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	and r1,r0,#0xFF
	mov r4,r0
	ldrh r5,[v30ptr,#v30RegDW]
	mov r0,r5
	bl v30WritePort
	mov r1,r4,lsr#8
	add r0,r5,#1
	bl v30WritePort
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5

;@----------------------------------------------------------------------------
i_bv:
_70:	;@ BV. Branch if oVerflow (V=1)
		;@ JO. Jump if Overflow (OF=1)
;@----------------------------------------------------------------------------
	jmpne PSR_V
;@----------------------------------------------------------------------------
i_bnv:
_71:	;@ BNV. Branch if Not oVerflow (V=0)
		;@ JNO. Jump if Not Overflow (OF=0)
;@----------------------------------------------------------------------------
	jmpeq PSR_V
;@----------------------------------------------------------------------------
i_bc:
i_bl:
_72:	;@ BC/BL. Branch if Carry/Lower (C=1)
		;@ JB/JNAE/JC. Jump if Below/Not Above or Equal/Carry (CF=1)
;@----------------------------------------------------------------------------
	jmpne PSR_C
;@----------------------------------------------------------------------------
i_bnc:
i_bnl:
_73:	;@ BNC/BNL. Branch if Not Carry/Not Lower (C=0)
		;@ JNB/JAE/JNC. Jump if Not Below/Above or Equal/Not Carry (CF=0)
;@----------------------------------------------------------------------------
	jmpeq PSR_C
;@----------------------------------------------------------------------------
i_be:
i_bz:
_74:	;@ BE/BZ. Branch if Equal/Zero (Z=1)
		;@ JE/JZ. Jump if Equal/Zero (ZF=1)
;@----------------------------------------------------------------------------
	jmpne PSR_Z
;@----------------------------------------------------------------------------
i_bne:
i_bnz:
_75:	;@ BNE/BNZ. Branch if Not Equal/Not Zero (Z=0)
		;@ JNE/JNZ. Jump if Not Equal/Not Zero (ZF=0)
;@----------------------------------------------------------------------------
	jmpeq PSR_Z
;@----------------------------------------------------------------------------
i_bnh:
_76:	;@ BNH. Branch if Not Higher (C | Z = 1)
		;@ JBE/JNA. Jump if Below or Equal/Not Above (CF=1 OR ZF=1)
;@----------------------------------------------------------------------------
	jmpne PSR_C|PSR_Z
;@----------------------------------------------------------------------------
i_bh:
_77:	;@ BH. Branch if Higher (C | Z = 0)
		;@ JNBE/JA. Jump if Not Below or Equal/Above (CF=0 AND ZF=0)
;@----------------------------------------------------------------------------
	jmpeq PSR_C|PSR_Z
;@----------------------------------------------------------------------------
i_bn:
_78:	;@ BN. Branch if Negative
		;@ JS. Jump if Sign (SF=1)
;@----------------------------------------------------------------------------
	jmpne PSR_S
;@----------------------------------------------------------------------------
i_bp:
_79:	;@ BP. Branch if Positive
		;@ JNS. Jump if Not Sign (SF=0)
;@----------------------------------------------------------------------------
	jmpeq PSR_S
;@----------------------------------------------------------------------------
i_bpe:
_7A:	;@ BPE. Branch if Parity Even
		;@ JP/JPE. Branch if Parity/Parity Even
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30ParityVal]	;@ Top of ParityVal is pointer to v30PZST
	ldrb r2,[v30ptr,r2]
	tst r2,#PSR_P
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_bpo:
_7B:	;@ BPO. Branch if Parity Odd
		;@ JNP/JPO. Branch if Not Parity/Parity Odd
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30ParityVal]	;@ Top of ParityVal is pointer to v30PZST
	ldrb r2,[v30ptr,r2]
	tst r2,#PSR_P
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_blt:
_7C:	;@ BLT. Branch if Less Than, S ^ V = 1.
		;@ JL/JNGE. Jump if Less/Not Greater or Equal (SF!=OF)
;@----------------------------------------------------------------------------
	getNextSignedByte
	eor r2,v30f,v30f,lsr#3
	tst r2,#PSR_V
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_bge:
_7D:	;@ BGE. Branch if Greater than or Equal, S ^ V = 0.
		;@ JNL/JGE. Jump if Not Less/Greater or Equal (SF=OF)
;@----------------------------------------------------------------------------
	getNextSignedByte
	eor r2,v30f,v30f,lsr#3
	tst r2,#PSR_V
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_ble:
_7E:	;@ BLE. Branch if Less than or Equal, (S ^ V) | Z = 1.
		;@ JLE/JNG. Jump if Less or Equal/Not Greater ((ZF=1) OR (SF!=OF))
;@----------------------------------------------------------------------------
	getNextSignedByte
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addle v30pc,v30pc,r0
	suble v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_bgt:
_7F:	;@ BGT. Branch if Greater Than, (S ^ V) | Z = 0.
		;@ JNLE/JG. Jump if Not Less nor Equal/Greater ((ZF=0) AND (SF=OF))
;@----------------------------------------------------------------------------
	getNextSignedByte
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addgt v30pc,v30pc,r0
	subgt v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_80pre:
_80:	;@ PRE 80
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
i_82pre:
_82:	;@ PRE 82
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	bmi 1f
	ldrb v30ofs,[r2,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
0:
	bic v30cyc,v30cyc,#SEG_PREFIX
	getNextByteTo r1

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add80, or80, adc80, subc80, and80, sub80, xor80, cmp80
1:
	eatCycles 2
	adr lr,0b
	b v30ReadEA
add80:
	add8 r1,r0
	b 2f
or80:
	or8 r1,r0
	b 2f
adc80:
	adc8 r1,r0
	b 2f
subc80:
	subc8 r1,r0
	b 2f
and80:
	and8 r1,r0
	b 2f
sub80:
	sub8 r1,r0
	b 2f
xor80:
	xor8 r1,r0
	b 2f
cmp80:
	sub8 r1,r0
	fetch 1
2:
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-v30ofs]
	blmi v30WriteSegOfs
	fetch 1
;@----------------------------------------------------------------------------
i_81pre:
_81:	;@ PRE 81
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldr r5,[v30ofs,#v30Regs2]
0:
	getNextWord
pre81Continue:

	bic v30cyc,v30cyc,#SEG_PREFIX
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add81, or81, adc81, subc81, and81, sub81, xor81, cmp81
1:
	eatCycles 2
	bl v30ReadEAWr4
	mov r5,r0,lsl#16
	b 0b
add81:
	add16 r0,r5
	b 2f
or81:
	or16 r0,r5
	b 2f
adc81:
	adc16 r0,r5
	b 2f
subc81:
	subc16 r0,r5
	b 2f
and81:
	and16 r0,r5
	b 2f
sub81:
	sub16 r0,r5
	b 2f
xor81:
	xor16 r0,r5
	b 2f
cmp81:
	sub16 r0,r5
	fetch 1
2:
	cmp r4,#0xC0
	strhpl r1,[v30ofs,#v30Regs]
	blmi v30WriteSegOfsW
	fetch 1
;@----------------------------------------------------------------------------
i_83pre:
_83:	;@ PRE 83
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldr r5,[v30ofs,#v30Regs2]
0:
	getNextByte
	tst r0,#0x80
	orrne r0,r0,#0xFF00
	b pre81Continue
1:
	eatCycles 2
	bl v30ReadEAWr4
	mov r5,r0,lsl#16
	b 0b
;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r1,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	andpl r1,r1,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	and8 r4,r0
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_test_wr16:
_85:	;@ TEST WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	and16 r0,r4
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_xchg_br8:
_86:	;@ XCH/XCHG BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 0f

	and r2,r4,#0xff
	ldrb r0,[v30ptr,-r2]
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	strb r1,[v30ptr,-r2]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
0:
	bl v30ReadEA
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5

;@----------------------------------------------------------------------------
i_xchg_wr16:
_87:	;@ XCH/XCHG WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrh r0,[r2,#v30Regs]
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	strh r1,[r2,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
0:
	bl v30ReadEAW
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_mov_br8:
_88:	;@ MOV BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r3,[r2,#v30ModRmReg]
//	cmp r0,#0xDB				;@ mov bl,bl
//	bne noBreak
//	mov r11,r11
//noBreak:
	cmp r0,#0xC0
	ldrb r1,[v30ptr,-r3,lsr#24]

	andpl r3,r3,#0xff
	strbpl r1,[v30ptr,-r3]
	blmi v30WriteEA
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_wr16:
_89:	;@ MOV WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r1,[r2,#v30Regs]
	cmp r0,#0xC0

	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	strhpl r1,[r2,#v30Regs]
	blmi v30WriteEAW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_r8b:
_8A:	;@ MOV R8B
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,r0,lsl#2
	ldr r4,[r2,#v30ModRmReg]
	cmp r0,#0xC0

	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA
	strb r0,[v30ptr,-r4,lsr#24]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_r16w:
_8B:	;@ MOV R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0

	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW_noAdd
	strh r0,[r4,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_wsreg:
_8C:	;@ MOV WSREG
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x18				;@ This is correct.
	add r4,v30ptr,r1,lsr#1
	ldrh r1,[r4,#v30SRegs+2]
	cmp r0,#0xC0

	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	strhpl r1,[r2,#v30Regs]
	blmi v30WriteEAW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_lea:
_8D:	;@ LDEA/LEA
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
//	tst r0,#4					;@ 2 reg ModRm? LEA, LES & LDS don't take 2 extra cycles, just one.
//	addeq v30cyc,v30cyc,#1*CYCLE
	add r2,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[r2,#v30EATable]		;@ EATable return EO in v30ofs
	str v30ofs,[r4,#v30Regs2]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x18				;@ This is correct.
	cmp r0,#0xC0
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	ldrhpl r0,[r2,#v30Regs]
	blmi v30ReadEAW1

	add r1,v30ptr,r4,lsr#1
	strh r0,[r1,#v30SRegs+2]
//	orr v30cyc,v30cyc,#LOCK_PREFIX
	bic v30cyc,v30cyc,#SEG_PREFIX
	cmp r4,#0x08			;@ CS?
	bleq V30ReEncodePC
	fetch 2
;@----------------------------------------------------------------------------
i_popw:
_8F:	;@ POPW
;@----------------------------------------------------------------------------
	popWord8F
	mov r1,r0
	getNextByte
	cmp r0,#0xC0
	bmi 0f

	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	strhpl r1,[r2,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	add r2,v30ptr,r0,lsl#2
	bl v30WriteEAW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3
;@----------------------------------------------------------------------------
i_nop:
_90:	;@ NOP (XCH AXAX)
;@----------------------------------------------------------------------------
	ldrb r0,[v30pc]				;@ Check for 3 NOPs
	cmp r0,#0x90
	ldrbeq r1,[v30pc,#1]
	cmpeq r1,#0x90
	subeq v30cyc,v30cyc,#1*CYCLE
	fetch 1
;@----------------------------------------------------------------------------
i_xchg_axcx:
_91:	;@ XCH/XCHG AXCX
;@----------------------------------------------------------------------------
	xchgreg v30RegCW
;@----------------------------------------------------------------------------
i_xchg_axdx:
_92:	;@ XCH/XCHG AXDX
;@----------------------------------------------------------------------------
	xchgreg v30RegDW
;@----------------------------------------------------------------------------
i_xchg_axbx:
_93:	;@ XCH/XCHG AXBX
;@----------------------------------------------------------------------------
	xchgreg v30RegBW
;@----------------------------------------------------------------------------
i_xchg_axsp:
_94:	;@ XCH/XCHG AXSP
;@----------------------------------------------------------------------------
	xchgreg v30RegSP+2
;@----------------------------------------------------------------------------
i_xchg_axbp:
_95:	;@ XCH/XCHG AXBP
;@----------------------------------------------------------------------------
	xchgreg v30RegBP+2
;@----------------------------------------------------------------------------
i_xchg_axsi:
_96:	;@ XCH/XCHG AXSI
;@----------------------------------------------------------------------------
	xchgreg v30RegIX+2
;@----------------------------------------------------------------------------
i_xchg_axdi:
_97:	;@ XCH/XCHG AXDI
;@----------------------------------------------------------------------------
	xchgreg v30RegIY+2
;@----------------------------------------------------------------------------
i_cbw:
_98:	;@ CVTBW / CBW. Convert Byte to Word
;@----------------------------------------------------------------------------
	ldrsb r0,[v30ptr,#v30RegAL]
	strh r0,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_cwd:
_99:	;@ CVTWL / CWD. Convert Word to Long/Double
;@----------------------------------------------------------------------------
	ldrsb r0,[v30ptr,#v30RegAH]
	mov r0,r0,asr#8
	strh r0,[v30ptr,#v30RegDW]
	fetch 1
;@----------------------------------------------------------------------------
i_call_far:
_9A:	;@ CALL FAR
;@----------------------------------------------------------------------------
	getNextWordTo r4, r0
	getNextWord
	ldrh r1,[v30ptr,#v30SRegCS+2]
	strh r0,[v30ptr,#v30SRegCS+2]
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	v30DecodeFastPCToReg r1
	bl v30PushLastW
	mov v30pc,r4,lsl#16
	v30EncodeFastPC
	fetch 10

;@----------------------------------------------------------------------------
i_poll:
_9B:	;@ POLL / WAIT
;@----------------------------------------------------------------------------
	eatCycles 9
	b i_undefined
;@----------------------------------------------------------------------------
i_pushf:
_9C:	;@ PUSH F
;@----------------------------------------------------------------------------
	bl pushFlags
	fetch 2
;@----------------------------------------------------------------------------
pushFlags:
	ldrh r2,[v30ptr,#v30ParityVal]	;@ Top of ParityVal is pointer to v30PZST
	ldr r1,=0xF002
	ldrb r2,[v30ptr,r2]
	ldrb r0,[v30ptr,#v30TF]
	tst v30f,#PSR_A
	orrne r1,r1,#AF
	ldrb r3,[v30ptr,#v30IF]
	tst r2,#PSR_P
	orrne r1,r1,#PF
	ldrsb r2,[v30ptr,#v30DF]
	cmp r0,#0
	orrne r1,r1,#TF
	cmp r3,#0
	orrne r1,r1,#IF
	cmp r2,#0
	orrmi r1,r1,#DF

	mov r2,v30f,lsl#28
	msr cpsr_flg,r2
	orrmi r1,r1,#SF
	orreq r1,r1,#ZF
	orrcs r1,r1,#CF
	orrvs r1,r1,#OF

	b v30PushW
	.pool
;@----------------------------------------------------------------------------
i_popf:
_9D:	;@ POP F
;@----------------------------------------------------------------------------
	popWord
	bic v30f,v30f,#PSR_ALL	;@ Clear S, Z, C, V & A.
	and r1,r0,#PF
	eor r1,r1,#PF
	strb r1,[v30ptr,#v30ParityVal]
	tst r0,#SF
	orrne v30f,v30f,#PSR_S
	tst r0,#ZF
	orrne v30f,v30f,#PSR_Z
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	tst r0,#OF
	orrne v30f,v30f,#PSR_V
	tst r0,#AF
	orrne v30f,v30f,#PSR_A
	ands r1,r0,#TF
	movne r1,#4
	strb r1,[v30ptr,#v30TF]
	ands r1,r0,#IF
	movne r1,#1
	strb r1,[v30ptr,#v30IF]
	tst r0,#DF
	moveq r1,#1
	movne r1,#-1
	strb r1,[v30ptr,#v30DF]

	eatCycles 3
	b v30ChkIrqInternal
;@----------------------------------------------------------------------------
i_sahf:
_9E:	;@ SAHF
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAH]

	bic v30f,v30f,#PSR_S+PSR_Z+PSR_C+PSR_A	;@ Clear S, Z, C & A.
	and r1,r0,#PF
	eor r1,r1,#PF
	strb r1,[v30ptr,#v30ParityVal]
	tst r0,#SF
	orrne v30f,v30f,#PSR_S
	tst r0,#ZF
	orrne v30f,v30f,#PSR_Z
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	tst r0,#AF
	orrne v30f,v30f,#PSR_A

	fetch 4
;@----------------------------------------------------------------------------
i_lahf:
_9F:	;@ LAHF
;@----------------------------------------------------------------------------
	mov r1,#0x02
	ldrh r2,[v30ptr,#v30ParityVal]	;@ Top of ParityVal is pointer to v30PZST
	mov r0,v30f,lsl#28
	ldrb r2,[v30ptr,r2]
	msr cpsr_flg,r0
	orrmi r1,r1,#SF
	orreq r1,r1,#ZF
	orrcs r1,r1,#CF
	tst r2,#PSR_P
	orrne r1,r1,#PF
	tst v30f,#PSR_A
	orrne r1,r1,#AF

	strb r1,[v30ptr,#v30RegAH]
	fetch 2
;@----------------------------------------------------------------------------
i_mov_aldisp:
_A0:	;@ MOV ALDISP
;@----------------------------------------------------------------------------
	getNextWord
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add r0,v30csr,r0,lsl#12
	bl cpuReadMem20
	strb r0,[v30ptr,#v30RegAL]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_axdisp:
_A1:	;@ MOV AXDISP
;@----------------------------------------------------------------------------
	getNextWord
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add r0,v30csr,r0,lsl#12
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegAW]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dispal:
_A2:	;@ MOV DISPAL
;@----------------------------------------------------------------------------
	getNextWord
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldrb r1,[v30ptr,#v30RegAL]
	add r0,v30csr,r0,lsl#12
	bl cpuWriteMem20
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dispax:
_A3:	;@ MOV DISPAX
;@----------------------------------------------------------------------------
	getNextWord
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldrh r1,[v30ptr,#v30RegAW]
	add r0,v30csr,r0,lsl#12
	bl cpuWriteMem20W
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1

;@----------------------------------------------------------------------------
f3a4:	;@ REP MOVMB/MOVSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#16
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20
	eatCycles 7
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_movsb:
_A4:	;@ MOVMB/MOVSB
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIX]
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#16
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5

;@----------------------------------------------------------------------------
f3a5:	;@ REP MOVMW/MOVSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#17
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20W
	eatCycles 7
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_movsw:
_A5:	;@ MOVMW/MOVSW
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#17
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20W
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5

;@----------------------------------------------------------------------------
f2a6:	;@ REPNZ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#16
	mov r4,r0
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
f3a6:	;@ REPZ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#16
	mov r4,r0
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsb:
_A6:	;@ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIX]

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#16
	mov r4,r0
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 6

;@----------------------------------------------------------------------------
f2a7:	;@ REPNZ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
f3a7:	;@ REPZ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsw:
_A7:	;@ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 6
;@----------------------------------------------------------------------------
i_test_ald8:
_A8:	;@ TEST ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	and8 r0,r1
	fetch 1
;@----------------------------------------------------------------------------
i_test_axd16:
_A9:	;@ TEST AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	fetch 1

;@----------------------------------------------------------------------------
f3aa:	;@ REP STMB/STOSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrb r1,[v30ptr,#v30RegAL]
	bl v30WriteSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STMB/STOSB
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
	ldrb r1,[v30ptr,#v30RegAL]
	bl v30WriteSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIY]
	fetch 3

;@----------------------------------------------------------------------------
f3ab:	;@ REP STMW/STOSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrh r1,[v30ptr,#v30RegAW]
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STMW/STOSW
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegAW]
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	fetch 3

;@----------------------------------------------------------------------------
f3ac:	;@ REP LDMB/LODSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_lodsb:
_AC:	;@ LDMB/LODSB
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIX]
	strb r0,[v30ptr,#v30RegAL]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3

;@----------------------------------------------------------------------------
f3ad:	;@ REP LDMW/LODSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_lodsw:
_AD:	;@ LDMW/LODSW
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	strh r0,[v30ptr,#v30RegAW]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 3

;@----------------------------------------------------------------------------
f2ae:	;@ REPNE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	eatCycles 9
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
f3ae:	;@ REPE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	eatCycles 9
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_scasb:
_AE:	;@ CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIY]
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	fetch 4

;@----------------------------------------------------------------------------
f2af:	;@ REPNE CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r0,r1

	eatCycles 9
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
f3af:	;@ REPE CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#1
	bmi 1f
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r0,r1

	eatCycles 9
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
1:
	strh r5,[v30ptr,#v30RegCW]
	bic v30cyc,v30cyc,#SEG_PREFIX+REP_PREFIX+LOCK_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_scasw:
_AF:	;@ CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegES]
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r0,r1

	fetch 4
;@----------------------------------------------------------------------------
i_mov_ald8:
_B0:	;@ MOV ALD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_cld8:
_B1:	;@ MOV CLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegCL]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dld8:
_B2:	;@ MOV DLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegDL]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_bld8:
_B3:	;@ MOV BLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegBL]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_ahd8:
_B4:	;@ MOV AHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegAH]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_chd8:
_B5:	;@ MOV CHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegCH]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dhd8:
_B6:	;@ MOV DHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegDH]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_bhd8:
_B7:	;@ MOV BHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegBH]
	fetch 1

;@----------------------------------------------------------------------------
i_mov_axd16:
_B8:	;@ MOV AXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_cxd16:
_B9:	;@ MOV CXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegCW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dxd16:
_BA:	;@ MOV DXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegDW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_bxd16:
_BB:	;@ MOV BXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegBW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_spd16:
_BC:	;@ MOV SPD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegSP+2]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_bpd16:
_BD:	;@ MOV BPD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegBP+2]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_sid16:
_BE:	;@ MOV SID16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIX+2]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_did16:
_BF:	;@ MOV DID16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIY+2]
	fetch 1

;@----------------------------------------------------------------------------
i_rotshft_bd8:
_C0:	;@ ROTSHFT BD8
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	bmi 1f
	ldrb v30ofs,[r2,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	eatCycles 2
0:
	getNextByteTo r1
d2Continue:
	ands r1,r1,#0x1F

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long rolC0, rorC0, rolcC0, rorcC0, shlC0, shrC0, undC0, shraC0
1:
	eatCycles 4
	adr lr,0b
	b v30ReadEA
rolC0:
	rol8 r0,r1
	b 2f
rorC0:
	ror8 r0,r1
	b 2f
rolcC0:
	rolc8 r0,r1
	b 2f
rorcC0:
	rorc8 r0,r1
	b 2f
shlC0:
	shl8 r0,r1
	b 2f
shrC0:
	shr8 r0,r1
	b 2f
undC0:
	bl logUndefinedOpcode
	mov r1,#0
	b 2f
shraC0:
	shra8 r0,r1
2:
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-v30ofs]
	blmi v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_rotshft_wd8:
_C1:	;@ ROTSHFT WD8
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	eatCycles 2
0:
	getNextByteTo r1
d3Continue:
	ands r1,r1,#0x1F

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long rolC1, rorC1, rolcC1, rorcC1, shlC1, shrC1, undC1, shraC1
1:
	eatCycles 4
	adr lr,0b
	b v30ReadEAWr4
rolC1:
	rol16 r0,r1
	b 2f
rorC1:
	ror16 r0,r1
	b 2f
rolcC1:
	rolc16 r0,r1
	b 2f
rorcC1:
	rorc16 r0,r1
	b 2f
shlC1:
	shl16 r0,r1
	b 2f
shrC1:
	shr16 r0,r1
	b 2f
undC1:
	bl logUndefinedOpcode
	mov r1,#0
	b 2f
shraC1:
	shra16 r0,r1
2:
	cmp r4,#0xC0
	strhpl r1,[v30ofs,#v30Regs]
	blmi v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_ret_d16:
_C2:	;@ RET D16
;@----------------------------------------------------------------------------
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	getNextWordTo r2, r1
	add v30ofs,v30ofs,r2,lsl#16
	str v30ofs,[v30ptr,#v30RegSP]
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	fetch 6
;@----------------------------------------------------------------------------
i_ret:
_C3:	;@ RET
;@----------------------------------------------------------------------------
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	str v30ofs,[v30ptr,#v30RegSP]
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	fetch 6
;@----------------------------------------------------------------------------
i_les_dw:
_C4:	;@ LES DW
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
//	tst r0,#4					;@ 2 reg ModRm? LEA, LES & LDS don't take 2 extra cycles, just one.
//	addeq v30cyc,v30cyc,#1*CYCLE
	bl v30ReadEAW
	add v30ofs,v30ofs,#0x20000
	strh r0,[r4,#v30Regs]
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30SRegES+2]

	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 6
;@----------------------------------------------------------------------------
i_lds_dw:
_C5:	;@ LDS DW
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
//	tst r0,#4					;@ 2 reg ModRm? LEA, LES & LDS don't take 2 extra cycles, just one.
//	addeq v30cyc,v30cyc,#1*CYCLE
	bl v30ReadEAW
	add v30ofs,v30ofs,#0x20000
	strh r0,[r4,#v30Regs]
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30SRegDS+2]

	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 6
;@----------------------------------------------------------------------------
i_mov_bd8:
_C6:	;@ MOV BD8
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	add r2,v30ptr,r0,lsl#2
	bmi 0f
	ldrb r4,[r2,#v30ModRmRm]
	getNextByteTo r1
	strb r1,[v30ptr,-r4]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	mov r12,pc					;@ Return reg for EA
	ldr pc,[r2,#v30EATable]
	getNextByteTo r1
	bl v30WriteSegOfs
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1

;@----------------------------------------------------------------------------
i_mov_wd16:
_C7:	;@ MOV WD16
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	bmi 0f
	andpl r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	getNextWordTo r1, r0
	strh r1,[r2,#v30Regs]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
0:
	add r2,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[r2,#v30EATable]
	getNextWordTo r1, r0
	bl v30WriteSegOfsW
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 1
;@----------------------------------------------------------------------------
i_prepare:
_C8:	;@ PREPARE/ENTER
;@----------------------------------------------------------------------------
	getNextWord
	stmfd sp!,{r0,r8}			;@ temp + flags
	getNextByte
	and r5,r0,#0x1F				;@ V30MZ specific

	ldr r4,[v30ptr,#v30RegSP]
	ldr r8,[v30ptr,#v30SRegSS]
	ldr v30ofs,[v30ptr,#v30RegBP]
	sub r4,r4,#0x20000
	add r0,r8,r4,lsr#4
	mov r1,v30ofs,lsr#16
	bl cpuWriteMem20W
	str r4,[v30ptr,#v30RegBP]
	subs r5,r5,#1
	bmi 2f
	beq 1f
	tst v30cyc,#SEG_PREFIX
	moveq v30csr,r8
0:
	sub v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW
	mov r1,r0
	sub r4,r4,#0x20000
	add r0,r8,r4,lsr#4
	bl cpuWriteMem20W
	eatCycles 4
	subs r5,r5,#1
	bne 0b
1:
	ldrh r1,[v30ptr,#v30RegBP+2]
	sub r4,r4,#0x20000
	add r0,r8,r4,lsr#4
	bl cpuWriteMem20W
	eatCycles 6
2:
	ldmfd sp!,{r0, r8}
	sub r4,r4,r0,lsl#16
	str r4,[v30ptr,#v30RegSP]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 8
;@----------------------------------------------------------------------------
i_dispose:
_C9:	;@ DISPOSE/LEAVE
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	add r2,v30ofs,#0x20000
	str r2,[v30ptr,#v30RegSP]
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30RegBP+2]
	fetch 3
;@----------------------------------------------------------------------------
i_retf_d16:
_CA:	;@ RETF D16
;@----------------------------------------------------------------------------
	getNextWordTo r4, r0
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	add v30ofs,v30ofs,r4,lsl#16
	strh r0,[v30ptr,#v30SRegCS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	fetch 9
;@----------------------------------------------------------------------------
i_retf:
_CB:	;@ RETF
;@----------------------------------------------------------------------------
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30SRegCS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	fetch 8
;@----------------------------------------------------------------------------
i_int3:
_CC:	;@ INT3
;@----------------------------------------------------------------------------
	eatCycles 9
	mov r0,#3
	b nec_interrupt
;@----------------------------------------------------------------------------
i_int:
_CD:	;@ INT
;@----------------------------------------------------------------------------
	eatCycles 10
	getNextByte
	b nec_interrupt
;@----------------------------------------------------------------------------
i_into:
_CE:	;@ BRKV				;@ Break if Overflow
;@----------------------------------------------------------------------------
	tst v30f,#PSR_V
	subne v30cyc,v30cyc,#13*CYCLE
	movne r0,#4
	bne nec_interrupt
	fetch 6
;@----------------------------------------------------------------------------
i_iret:
_CF:	;@ IRET
;@----------------------------------------------------------------------------
	bl v30StackReadW
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30SRegCS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	eatCycles 10-3				;@ i_popf eats 3 cycles
	b i_popf

;@----------------------------------------------------------------------------
i_rotshft_b:
_D0:	;@ ROTSHFT B
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	bmi 0f
	ldrb v30ofs,[r2,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	mov r1,#1
	b d2Continue
0:
	eatCycles 2
	bl v30ReadEA
	mov r1,#1
	b d2Continue
;@----------------------------------------------------------------------------
i_rotshft_w:
_D1:	;@ ROTSHFT W
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 0f

	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	mov r1,#1
	b d3Continue
0:
	eatCycles 2
	bl v30ReadEAWr4
	mov r1,#1
	b d3Continue
;@----------------------------------------------------------------------------
i_rotshft_bcl:
_D2:	;@ ROTSHFT BCL
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	bmi 0f
	eatCycles 2
	ldrb v30ofs,[r2,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	ldrb r1,[v30ptr,#v30RegCL]
	b d2Continue
0:
	eatCycles 4
	bl v30ReadEA
	ldrb r1,[v30ptr,#v30RegCL]
	b d2Continue
;@----------------------------------------------------------------------------
i_rotshft_wcl:
_D3:	;@ ROTSHFT WCL
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 0f

	eatCycles 2
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	ldrb r1,[v30ptr,#v30RegCL]
	b d3Continue
0:
	eatCycles 4
	bl v30ReadEAWr4
	ldrb r1,[v30ptr,#v30RegCL]
	b d3Continue
;@----------------------------------------------------------------------------
i_aam:
_D4:	;@ CVTBD/AAM	;@ Convert Binary to Decimal / Adjust After Multiply
;@----------------------------------------------------------------------------
	getNextByte

	movs r1,r0,lsl#8
	ldrb r0,[v30ptr,#v30RegAL]
	beq d4DivideError
	rsb r1,r1,#1

	bl division8

	mov r0,r0,ror#8
	orr r0,r0,r0,lsr#16
	strh r0,[v30ptr,#v30RegAW]

	strb r0,[v30ptr,#v30ParityVal]
	movs v30f,r0,lsl#24					;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	fetch 16
d4DivideError:
	eatCycles 16
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	tst r0,#0xC0
	bicne v30f,v30f,#PSR_Z
	b divideError
;@----------------------------------------------------------------------------
i_aad:
_D5:	;@ CVTDB/AAD	;@ Convert Decimal to Binary / Adjust After Division
;@----------------------------------------------------------------------------
	getNextByte
	ldrh r1,[v30ptr,#v30RegAW]
	mov r2,r1,lsr#8
	mul r0,r2,r0
	eor r2,r1,r0
	mov r1,r1,lsl#24
	adds r0,r1,r0,lsl#24
	eor r2,r2,r0,lsr#24
	and r2,r2,#PSR_A
	mrs v30f,cpsr				;@ S, Z, V & C.
	orr v30f,r2,v30f,lsr#28
	mov r0,r0,lsr#24
	strh r0,[v30ptr,#v30RegAW]
	strb r0,[v30ptr,#v30ParityVal]
	fetch 6
;@----------------------------------------------------------------------------
i_salc:
_D6:	;@ SALC			;@ Set AL on Carry
;@----------------------------------------------------------------------------
	ands r0,v30f,PSR_C
	movne r0,#0xFF
	strb r0,[v30ptr,#v30RegAL]
	fetch 8
;@----------------------------------------------------------------------------
i_trans:
_D7:	;@ TRANS/XLAT	;@ Translate al via LUT.
;@----------------------------------------------------------------------------
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	ldrb r0,[v30ptr,#v30RegAL]
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	add v30ofs,v30ofs,r0,lsl#16
	bl v30ReadSegOfs
	strb r0,[v30ptr,#v30RegAL]
	bic v30cyc,v30cyc,#SEG_PREFIX
	fetch 5
;@----------------------------------------------------------------------------
i_fpo1:
_D8:	;@ FPO1
;@----------------------------------------------------------------------------
	getNextByte
	b i_undefined
;@----------------------------------------------------------------------------
i_loopne:
_E0:	;@ DBNZNE/LOOPNE
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	andne r3,v30f,#PSR_Z
	cmpne r3,#PSR_Z
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	strh r2,[v30ptr,#v30RegCW]
	v30ReEncodeFastPC
	fetch 3
;@----------------------------------------------------------------------------
i_loope:
_E1:	;@ DBNZE/LOOPE
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	tstne v30f,#PSR_Z
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	strh r2,[v30ptr,#v30RegCW]
	v30ReEncodeFastPC
	fetch 3
;@----------------------------------------------------------------------------
i_loop:
_E2:	;@ DBNZ/LOOP
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	strh r2,[v30ptr,#v30RegCW]
	v30ReEncodeFastPC
	fetch 2
;@----------------------------------------------------------------------------
i_jcxz:
_E3:	;@ BCWZ/JCXZ
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	cmp r2,#0
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1

;@----------------------------------------------------------------------------
i_inal:
_E4:	;@ INAL
;@----------------------------------------------------------------------------
	getNextByte
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAL]
	fetch 7
;@----------------------------------------------------------------------------
i_inax:
_E5:	;@ INAX
;@----------------------------------------------------------------------------
	getNextByte
	mov r4,r0
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAH]
	fetch 7
;@----------------------------------------------------------------------------
i_outal:
_E6:	;@ OUTAL
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	bl v30WritePort
	fetch 7
;@----------------------------------------------------------------------------
i_outax:
_E7:	;@ OUTAX
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	mov r4,r0
	bl v30WritePort
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	bl v30WritePort
	fetch 7

;@----------------------------------------------------------------------------
i_call_d16:
_E8:	;@ CALL D16
;@----------------------------------------------------------------------------
	getNextWord
	v30DecodeFastPCToReg r1
	add v30pc,r0,r1
	bl v30PushW
	mov v30pc,v30pc,lsl#16
	v30EncodeFastPC
	fetch 5
;@----------------------------------------------------------------------------
i_jmp_d16:
_E9:	;@ BR/JMP D16
;@----------------------------------------------------------------------------
	getNextWord
	v30DecodeFastPCToReg r1
	add v30pc,r0,r1
	mov v30pc,v30pc,lsl#16
	v30EncodeFastPC
	fetch 4
;@----------------------------------------------------------------------------
i_jmp_far:
_EA:	;@ BR/JMP FAR
;@----------------------------------------------------------------------------
	getNextWordTo r4, r0
	getNextWord
	strh r0,[v30ptr,#v30SRegCS+2]
	mov v30pc,r4,lsl#16
	v30EncodeFastPC
	fetch 7
;@----------------------------------------------------------------------------
i_br_d8:
_EB:	;@ BR/JMP short
;@----------------------------------------------------------------------------
	getNextSignedByte
	add v30pc,v30pc,r0
	cmp r0,#-4
	andcs v30cyc,v30cyc,#CYC_MASK
	v30ReEncodeFastPC
	fetch 4
;@----------------------------------------------------------------------------
i_inaldx:
_EC:	;@ INALDX
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAL]
	fetch 5
;@----------------------------------------------------------------------------
i_inaxdx:
_ED:	;@ INAXDX
;@----------------------------------------------------------------------------
	ldrh r4,[v30ptr,#v30RegDW]
	mov r0,r4
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAH]
	fetch 5
;@----------------------------------------------------------------------------
i_outdxal:
_EE:	;@ OUTDXAL
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	bl v30WritePort
	fetch 5
;@----------------------------------------------------------------------------
i_outdxax:
_EF:	;@ OUTDXAX
;@----------------------------------------------------------------------------
	ldrh r4,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	mov r0,r4
	bl v30WritePort
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	bl v30WritePort
	fetch 5

;@----------------------------------------------------------------------------
i_lock:
_F0:	;@ BUS LOCK
;@----------------------------------------------------------------------------
//	orr v30cyc,v30cyc,#LOCK_PREFIX
	fetch 0
;@----------------------------------------------------------------------------
i_brks:
_F1:	;@ BRKS, Break to Security Mode. Not working on V30MZ?
;@----------------------------------------------------------------------------
	b i_crash
;@----------------------------------------------------------------------------
i_repne:
_F2:	;@ REPNE
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF2Prefix
	orr v30cyc,v30cyc,#SEG_PREFIX
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	ldr v30csr,[r1,#v30SRegs]

//	eatCycles 1
	getNextByte
noF2Prefix:
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	tst r1,#1
	biceq v30cyc,v30cyc,#SEG_PREFIX
	sub r3,r0,#0x6C
	cmp r3,#0x43
	ldrls pc,[pc,r3,lsl#2]
	b f3Default
	.long f36c
	.long f36d
	.long f36e
	.long f36f
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long f3a4
	.long f3a5
	.long f2a6
	.long f2a7
	.long	f3Default
	.long	f3Default
	.long f3aa
	.long f3ab
	.long f3ac
	.long f3ad
	.long f2ae
	.long f2af

;@----------------------------------------------------------------------------
i_repe:
_F3:	;@ REPE
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF3Prefix
	orr v30cyc,v30cyc,#SEG_PREFIX
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	ldr v30csr,[r1,#v30SRegs]

//	eatCycles 1
	getNextByte
noF3Prefix:
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	tst r1,#1
	biceq v30cyc,v30cyc,#SEG_PREFIX
	sub r3,r0,#0x6C
	cmp r3,#0x43
	ldrls pc,[pc,r3,lsl#2]
	b f3Default
	.long f36c
	.long f36d
	.long f36e
	.long f36f
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long	f3Default
	.long f3a4
	.long f3a5
	.long f3a6
	.long f3a7
	.long	f3Default
	.long	f3Default
	.long f3aa
	.long f3ab
	.long f3ac
	.long f3ad
	.long f3ae
	.long f3af

f3Default:
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_hlt:
_F4:	;@ HALT
;@----------------------------------------------------------------------------
	eatCycles 12
	ldrb r0,[v30ptr,#v30IrqPin]
	cmp r0,#0
	bne v30ChkIrqInternal
	orr v30cyc,v30cyc,#HALT_FLAG
	mvns r0,v30cyc,asr#CYC_SHIFT			;@
	addmi v30cyc,v30cyc,r0,lsl#CYC_SHIFT	;@ Consume all remaining cycles in steps of 1.
	fetch 0
;@----------------------------------------------------------------------------
i_cmc:
_F5:	;@ NOT1 CY/CMC		;@ Not Carry/Complement Carry
;@----------------------------------------------------------------------------
	eor v30f,v30f,#PSR_C
	fetch 4
;@----------------------------------------------------------------------------
i_f6pre:
_F6:	;@ PRE F6
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	ldrbpl v30ofs,[r2,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA1

	bic v30cyc,v30cyc,#SEG_PREFIX
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF6, undefF6, notF6, negF6, muluF6, mulF6, divubF6, divbF6
;@----------------------------------------------------------------------------
testF6:
	getNextByteTo r1
	and8 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
notF6:
	mvn r1,r0
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-v30ofs]
	submi v30cyc,v30cyc,#1*CYCLE
	blmi v30WriteSegOfs
	fetch 1
;@----------------------------------------------------------------------------
negF6:
	mov r1,r0,lsl#24
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#24
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-v30ofs]
	submi v30cyc,v30cyc,#1*CYCLE
	blmi v30WriteSegOfs
	fetch 1
;@----------------------------------------------------------------------------
muluF6:			;@ MULU/MUL
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrb r1,[v30ptr,#v30RegAL]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#8
	orrne v30f,v30f,#PSR_C+PSR_V
	strb v30f,[v30ptr,#v30MulOverflow]
	fetch 3
;@----------------------------------------------------------------------------
mulF6:			;@ MUL/IMUL
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrsb r1,[v30ptr,#v30RegAL]
	mov r0,r0,lsl#24
	mov r0,r0,asr#24
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r1,r2,asr#7
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V
	strb v30f,[v30ptr,#v30MulOverflow]
	fetch 3
;@----------------------------------------------------------------------------
divubF6:		;@ DIVU/DIV
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mov r1,r0,lsl#8
	ldrh r0,[v30ptr,#v30RegAW]
	cmp r0,r1
	bcs divubF6Error
	rsb r1,r1,#1

	bl division8

	strh r0,[v30ptr,#v30RegAW]
	bic r0,r0,#0xFE
	cmp r0,#1
	bicne v30f,v30f,#PSR_Z
	fetch 15
divubF6Error:
	eatCycles 16
	b divideError
;@----------------------------------------------------------------------------
divbF6:			;@ DIV/IDIV
	movs r1,r0,lsl#24
	ldr r0,[v30ptr,#v30RegAW-2]
	beq divbF6Error
	eor r3,r1,r0,asr#16
	rsbpl r1,r1,#0
	cmp r0,#0
	rsbmi r0,r0,#0
	cmn r0,r1,asr#1
	bcs divbF6Error2
	add r1,r1,#1

	bl division8

	mov r1,r0,lsr#24
	movs r3,r3,asr#16
	rsbcs r1,r1,#0
	rsbmi r0,r0,#0
1:
	movs v30f,r0,lsl#24					;@ Test S, Z.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r0,[v30ptr,#v30RegAL]
	strb r1,[v30ptr,#v30RegAH]
	strb r0,[v30ptr,#v30ParityVal]		;@ Set parity
	fetch 17
divbF6Error:
	cmp r0,#0x80000000
	moveq r0,#0x0081
	beq 1b
divbF6Error2:
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	eatCycles 19
	b divideError
;@----------------------------------------------------------------------------
i_f7pre:
_F7:	;@ PRE F7
;@----------------------------------------------------------------------------
	getNextByteTo r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
0:
	bic v30cyc,v30cyc,#SEG_PREFIX
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF7, undefF7, notF7, negF7, muluF7, mulF7, divuwF7, divwF7
1:
	eatCycles 1
	adr lr,0b
	b v30ReadEAWr4
;@----------------------------------------------------------------------------
testF7:
	mov r4,r0,lsl#16
	getNextWord
	and16 r0,r4
	fetch 1
;@----------------------------------------------------------------------------
notF7:
	mvn r1,r0
	cmp r4,#0xC0
	strhpl r1,[v30ofs,#v30Regs]
	submi v30cyc,v30cyc,#1*CYCLE
	blmi v30WriteSegOfsW
	fetch 1
;@----------------------------------------------------------------------------
negF7:
	mov r1,r0,lsl#16
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#16
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	cmp r4,#0xC0
	strhpl r1,[v30ofs,#v30Regs]
	submi v30cyc,v30cyc,#1*CYCLE
	blmi v30WriteSegOfsW
	fetch 1
;@----------------------------------------------------------------------------
muluF7:			;@ MULU/MUL
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#16
	strh r2,[v30ptr,#v30RegDW]
	orrne v30f,v30f,#PSR_C+PSR_V		;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]
	fetch 3
;@----------------------------------------------------------------------------
mulF7:			;@ MUL/IMUL
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrsh r1,[v30ptr,#v30RegAW]
	mov r0,r0,lsl#16
	mov r0,r0,asr#16
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	mov r1,r2,lsr#16
	strh r1,[v30ptr,#v30RegDW]
	movs r1,r2,asr#15
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V		;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]
	fetch 3
;@----------------------------------------------------------------------------
divuwF7:		;@ DIVU/DIV
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mov r1,r0,lsl#16
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16
	cmp r0,r1
	bcs divuwF7Error
	rsb r1,r1,#1

	bl division16

	mov r1,r0,lsr#16
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	fetch 23
divuwF7Error:
	eatCycles 16
	b divideError
;@----------------------------------------------------------------------------
divwF7:			;@ DIV/IDIV
	movs r1,r0,lsl#16
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16
	beq divwF7Error
	eor r3,r1,r0,asr#16
	rsbpl r1,r1,#0
	cmp r0,#0
	rsbmi r0,r0,#0
	cmn r0,r1,asr#1
	bcs divwF7Error2
	add r1,r1,#1

	bl division16

	mov r1,r0,lsr#16
	movs r3,r3,asr#16
	rsbcs r1,r1,#0
	rsbmi r0,r0,#0
1:
	movs v30f,r0,lsl#16					;@ Test S, Z.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	strb r0,[v30ptr,#v30ParityVal]		;@ Set parity
	fetch 24
divwF7Error:
	cmp r0,#0x80000000
	moveq r0,#0x0081
	beq 1b
divwF7Error2:
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	eatCycles 19
	b divideError
;@----------------------------------------------------------------------------
i_clc:
_F8:	;@ CLR1 CY/CLC		;@ Clear Carry.
;@----------------------------------------------------------------------------
	bic v30f,v30f,#PSR_C
	fetch 4
;@----------------------------------------------------------------------------
i_stc:
_F9:	;@ SET1 CY/STC		;@ Set Carry.
;@----------------------------------------------------------------------------
	orr v30f,v30f,#PSR_C
	fetch 4
;@----------------------------------------------------------------------------
i_di:
_FA:	;@ DI/CLI			;@ Disable/Clear Interrupt
;@----------------------------------------------------------------------------
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	fetch 4
;@----------------------------------------------------------------------------
i_ei:
_FB:	;@ EI/STI			;@ Enable/Set Interrupt
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30IF]
	eatCycles 4
	b v30ChkIrqInternal
;@----------------------------------------------------------------------------
i_cld:
_FC:	;@ CLR1 DIR/CLD		;@ Clear Direction
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30DF]
	fetch 4
;@----------------------------------------------------------------------------
i_std:
_FD:	;@ SET1 DIR/STD		;@ Set Direction
;@----------------------------------------------------------------------------
	mov r0,#-1
	strb r0,[v30ptr,#v30DF]
	fetch 4
;@----------------------------------------------------------------------------
i_fepre:
_FE:	;@ PRE FE
;@----------------------------------------------------------------------------
	getNextByteTo r4
	tst r4,#0x30
	bne contFF
	cmp r4,#0xC0
	add r2,v30ptr,r4,lsl#2
	bmi 1f
	ldrb v30ofs,[r2,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
0:
	bic v30cyc,v30cyc,#SEG_PREFIX
	mov r1,r0,lsl#24
	tst r4,#0x08
	bne decFE
incFE:
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A		;@ Clear S, Z, V & A.
	adds r1,r1,#0x1000000
	orrvs v30f,v30f,#PSR_V						;@ Set Overflow.
	tst r1,#0xF000000
	b writeBackFE
decFE:
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A		;@ Clear S, Z, V & A.
	subs r1,r1,#0x1000000
	orrvs v30f,v30f,#PSR_V						;@ Set Overflow.
	tst r0,#0xF
writeBackFE:
	orreq v30f,v30f,#PSR_A
	movs r1,r1,asr#24
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-v30ofs]
	blmi v30WriteSegOfs
	fetch 1
1:
	eatCycles 2
	adr lr,0b
	b v30ReadEA

;@----------------------------------------------------------------------------
i_ffpre:
_FF:	;@ PRE FF
;@----------------------------------------------------------------------------
	getNextByteTo r4
contFF:
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add v30ofs,v30ptr,r2,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
0:
	bic v30cyc,v30cyc,#SEG_PREFIX
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long incFF, decFF, callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
1:
	eatCycles 1
	adr lr,0b
	b v30ReadEAWr4
;@----------------------------------------------------------------------------
incFF:
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A		;@ Clear S, Z, V & A.
	mov r1,r0,lsl#16
	adds r1,r1,#0x10000
	orrvs v30f,v30f,#PSR_V						;@ Set Overflow.
	tst r1,#0xF0000
	b writeBackFF
;@----------------------------------------------------------------------------
decFF:
	bic v30f,v30f,#PSR_S+PSR_Z+PSR_V+PSR_A		;@ Clear S, Z, V & A.
	mov r1,r0,lsl#16
	subs r1,r1,#0x10000
	orrvs v30f,v30f,#PSR_V						;@ Set Overflow.
	tst r0,#0xF
writeBackFF:
	orreq v30f,v30f,#PSR_A
	movs r1,r1,asr#16
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	strb r1,[v30ptr,#v30ParityVal]
	cmp r4,#0xC0
	strhpl r1,[v30ofs,#v30Regs]
	submi v30cyc,v30cyc,#1*CYCLE
	blmi v30WriteSegOfsW
	fetch 1
;@----------------------------------------------------------------------------
callFF:
	v30DecodeFastPCToReg r1
	mov v30pc,r0,lsl#16
	bl v30PushW
	V30EncodeFastPC
	fetch 5
;@----------------------------------------------------------------------------
callFarFF:
	v30DecodeFastPCToReg r4
	mov v30pc,r0,lsl#16
	add v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW

	ldrh r1,[v30ptr,#v30SRegCS+2]
	strh r0,[v30ptr,#v30SRegCS+2]
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW

	mov r1,r4
	bl v30PushLastW
	V30EncodeFastPC
	fetch 11
;@----------------------------------------------------------------------------
braFF:
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	fetch 5
;@----------------------------------------------------------------------------
braFarFF:
	mov v30pc,r0,lsl#16
	add v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30SRegCS+2]
	v30EncodeFastPC
	fetch 9
;@----------------------------------------------------------------------------
pushFF:
	mov r1,r0
	bl v30PushW
	fetch 1

;@----------------------------------------------------------------------------
division16:
;@----------------------------------------------------------------------------
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
division8:
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	bx lr

;@----------------------------------------------------------------------------
// All EA functions must leave EO (EffectiveOffset) in top 16bits of v30ofs!
;@----------------------------------------------------------------------------
EA_000:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_001:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_002:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_003:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_004:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	bx r12
;@----------------------------------------------------------------------------
EA_005:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	bx r12
;@----------------------------------------------------------------------------
EA_006:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	mov v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_007:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	bx r12
;@----------------------------------------------------------------------------
EA_100:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_101:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_102:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r2,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_103:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r2,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_104:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_105:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_106:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBP]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_107:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_200:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_201:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_202:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r2,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_203:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r2,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	add v30ofs,v30ofs,r2
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_204:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_205:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_206:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBP]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_207:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_300:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegAW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_301:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegCW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_302:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegDW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_303:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegBW-2]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_304:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldr r0,[v30ptr,#v30RegSP]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_305:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30RegBP]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_306:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIX]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_307:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIY]
	tst v30cyc,#SEG_PREFIX
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add v30ofs,v30ofs,r0
	bx r12

;@----------------------------------------------------------------------------
V30DecodePC:
;@----------------------------------------------------------------------------
	loadLastBank r0
	sub v30pc,v30pc,r0
	mov v30pc,v30pc,lsl#16
	bx lr
;@----------------------------------------------------------------------------
V30ReEncodePC:
;@----------------------------------------------------------------------------
	loadLastBank r0
	sub v30pc,v30pc,r0
	mov v30pc,v30pc,lsl#16
;@----------------------------------------------------------------------------
V30EncodePC:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,[v30ptr,#v30SRegCS]
	add r0,r0,v30pc,lsr#4
	bl cpuReadMem20
	sub r0,r1,v30pc,lsr#16
	str r0,[v30ptr,#v30LastBank]
	mov v30pc,r1
//	tst v30pc,#1
//	subne v30cyc,v30cyc,#1*CYCLE
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
V30SetIRQPin:			;@ r0=pin state
;@----------------------------------------------------------------------------
	cmp r0,#0
	movne r0,#0x01
	strb r0,[v30ptr,#v30IrqPin]
	bx lr
;@----------------------------------------------------------------------------
V30FetchIRQ:
;@----------------------------------------------------------------------------
	eatCycles 8
	mov lr,pc
	ldr pc,[v30ptr,#v30IrqVectorFunc]
;@----------------------------------------------------------------------------
V30TakeIRQ:
nec_interrupt:				;@ r0 = vector number
;@----------------------------------------------------------------------------
	mov r4,r0,lsl#12+2
	bl pushFlags				;@ This should setup v30ofs & v30csr for stack
	strb r4,[v30ptr,#v30IF]		;@ Clear IF
	strb r4,[v30ptr,#v30TF]		;@ Clear TF
	bic v30cyc,v30cyc,#HALT_FLAG

	ldrh r1,[v30ptr,#v30SRegCS+2]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	v30DecodeFastPCToReg r1
	bl v30PushLastW

	mov r0,r4
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	add r0,r4,#0x2000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegCS+2]

	v30EncodeFastPC
	fetch 32
;@----------------------------------------------------------------------------
V30RestoreAndRunXCycles:	;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add r1,v30ptr,#v30PrefixBase
	ldmia r1,{v30csr-v30cyc}	;@ Restore V30MZ state
;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add v30cyc,v30cyc,r0,lsl#CYC_SHIFT
;@----------------------------------------------------------------------------
V30CheckIRQs:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
v30ChkIrqInternal:				;@ This can be used on EI/IRET/POPF/HALT
	ldr r0,[v30ptr,#v30IrqPin]	;@ NMI, Irq pin and IF
	movs r1,r0,lsr#24
	bne doV30NMI
	ands r1,r0,r0,lsr#8
	bne V30FetchIRQ
	tst v30cyc,#HALT_FLAG
	bne v30InHalt
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
	fetch 0
v30InHalt:
	tst r0,#1					;@ IRQ Pin ?
	bicne v30cyc,v30cyc,#HALT_FLAG
	bne V30Go
	mvns r0,v30cyc,asr#CYC_SHIFT			;@
	addmi v30cyc,v30cyc,r0,lsl#CYC_SHIFT	;@ Consume all remaining cycles in steps of 1.
outOfCycles:
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
V30SetNMIPin:			;@ r0=pin state
;@----------------------------------------------------------------------------
	cmp r0,#0
	movne r0,#2					;@ NMI vector
	ldrb r1,[v30ptr,#v30NmiPin]
	strb r0,[v30ptr,#v30NmiPin]
	bics r0,r0,r1
	strbne r0,[v30ptr,#v30NmiPending]
	bicne v30cyc,v30cyc,#HALT_FLAG
	bx lr
;@----------------------------------------------------------------------------
doV30NMI:
;@----------------------------------------------------------------------------
	eatCycles 1
	mov r0,#0
	strb r0,[v30ptr,#v30NmiPending]
	mov r0,#2
	b nec_interrupt
;@----------------------------------------------------------------------------
divideError:
;@----------------------------------------------------------------------------
//	stmfd sp!,{lr}
//	ldr r0,=debugDivideError
//	mov lr,pc
//	bx r0
//	ldmfd sp!,{lr}

	mov r11,r11					;@ NoCash breakpoint
	mov r0,#0					;@ 0 = division error
	b nec_interrupt

;@----------------------------------------------------------------------------
logUndefinedOpcode:
;@----------------------------------------------------------------------------
	mov r11,r11					;@ NoCash breakpoint
	ldr r0,=debugUndefinedInstruction
	bx r0
;@----------------------------------------------------------------------------
i_undefined:
undefF6:
undefF7:
undefFF:
;@----------------------------------------------------------------------------
	bl logUndefinedOpcode
	fetch 1
;@----------------------------------------------------------------------------
i_crash:
;@----------------------------------------------------------------------------
	ldr r0,=debugCrashInstruction
	mov lr,pc
	bx r0

	sub v30pc,v30pc,#1
	mov r11,r11					;@ NoCash breakpoint
	fetch 10
;@----------------------------------------------------------------------------
V30IrqVectorDummy:
;@----------------------------------------------------------------------------
	mov r0,#-1
	bx lr

;@----------------------------------------------------------------------------
V30Init:					;@ r0=v30ptr
;@ Called by cpuReset
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	mov v30ptr,r0
	add r0,v30ptr,#v30ModRmRm
	adr r1,regConvert
	mov r2,#0xC0
regConvLoop:
	and r3,r2,#7
	ldr r3,[r1,r3,lsl#2]
	rsb r3,r3,#0
	strb r3,[r0,r2,lsl#2]
	add r2,r2,#1
	cmp r2,#0x100
	bne regConvLoop

	add r0,v30ptr,#v30ModRmReg
	add r0,r0,#3
	mov r2,#0
regConv2Loop:
	and r3,r2,#0x38
	ldr r3,[r1,r3,lsr#1]
	rsb r3,r3,#0
	strb r3,[r0,r2,lsl#2]
	add r2,r2,#1
	cmp r2,#0x100
	bne regConv2Loop

	ldmfd sp!,{v30ptr,lr}
	bx lr
regConvert:
	.long v30RegAL,v30RegCL,v30RegDL,v30RegBL,v30RegAH,v30RegCH,v30RegDH,v30RegBH
;@----------------------------------------------------------------------------
V30Reset:					;@ r0=v30ptr
;@ Called by cpuReset
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	mov v30ptr,r0

	add r0,v30ptr,#v30I			;@ Clear CPU state
	mov r1,#(v30IEnd-v30I)/4
	bl memclr_

	ldr r0,=0xFFFF0000
	str r0,[v30ptr,#v30SRegCS]
	ldr r0,=0xFFFE0000
	str r0,[v30ptr,#v30RegSP]
	mov r0,#v30PZST
	strh r0,[v30ptr,#v30ParityVal]
	mov r0,#1
	strb r0,[v30ptr,#v30DF]

	mov v30pc,#0
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30IP]

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
V30SaveState:				;@ In r0=destination, r1=v30ptr. Out r0=size.
	.type   V30SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,v30pc,v30ptr,lr}

	sub r4,r0,#v30I
	mov v30ptr,r1

	add r1,v30ptr,#v30I
	mov r2,#v30StateEnd-v30StateStart
	bl memcpy

	;@ Convert copied PC to not offseted.
	ldr v30pc,[r4,#v30IP]				;@ Offseted v30pc
	v30DecodeFastPC
	str v30pc,[r4,#v30IP]				;@ Normal v30pc

	ldmfd sp!,{r4,v30pc,v30ptr,lr}
	mov r0,#v30StateEnd-v30StateStart
	bx lr
;@----------------------------------------------------------------------------
V30LoadState:				;@ In r0=v30ptr, r1=source. Out r0=size.
	.type   V30LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{v30pc,v30ptr,lr}

	mov v30ptr,r0
	add r0,v30ptr,#v30I
	mov r2,#v30StateEnd-v30StateStart
	bl memcpy

	ldr v30pc,[v30ptr,#v30IP]			;@ Normal v30pc
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30IP]			;@ Rewrite offseted v30pc

	ldmfd sp!,{v30pc,v30ptr,lr}
;@----------------------------------------------------------------------------
V30GetStateSize:			;@ Out r0=state size.
	.type   V30GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#v30StateEnd-v30StateStart
	bx lr
;@----------------------------------------------------------------------------
V30RedirectOpcode:			;@ In r0=opcode, r1=address.
	.type   V30RedirectOpcode STT_FUNC
;@----------------------------------------------------------------------------
	ldr r2,=V30OpTable
	str r1,[r2,r0,lsl#2]
	bx lr
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits				;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits			;@ For the GBA
#else
	.section .text
#endif
;@----------------------------------------------------------------------------
defaultV30:
v30StateStart:
I:	.space 19*4
v30StateEnd:
	.long 0			;@ v30LastBank
	.long 0			;@ v30IrqVectorFunc
	.space 16*4		;@ v30MemTbl $00000-FFFFF

V30OpTable:
	.long i_add_br8
	.long i_add_wr16
	.long i_add_r8b
	.long i_add_r16w
	.long i_add_ald8
	.long i_add_axd16
	.long i_push_es
	.long i_pop_es
	.long i_or_br8
	.long i_or_wr16
	.long i_or_r8b
	.long i_or_r16w
	.long i_or_ald8
	.long i_or_axd16
	.long i_push_cs
	.long i_undefined
	.long i_adc_br8
	.long i_adc_wr16
	.long i_adc_r8b
	.long i_adc_r16w
	.long i_adc_ald8
	.long i_adc_axd16
	.long i_push_ss
	.long i_pop_ss
	.long i_sbb_br8
	.long i_sbb_wr16
	.long i_sbb_r8b
	.long i_sbb_r16w
	.long i_sbb_ald8
	.long i_sbb_axd16
	.long i_push_ds
	.long i_pop_ds
	.long i_and_br8
	.long i_and_wr16
	.long i_and_r8b
	.long i_and_r16w
	.long i_and_ald8
	.long i_and_axd16
	.long i_es
	.long i_daa
	.long i_sub_br8
	.long i_sub_wr16
	.long i_sub_r8b
	.long i_sub_r16w
	.long i_sub_ald8
	.long i_sub_axd16
	.long i_cs
	.long i_das
	.long i_xor_br8
	.long i_xor_wr16
	.long i_xor_r8b
	.long i_xor_r16w
	.long i_xor_ald8
	.long i_xor_axd16
	.long i_ss
	.long i_aaa
	.long i_cmp_br8
	.long i_cmp_wr16
	.long i_cmp_r8b
	.long i_cmp_r16w
	.long i_cmp_ald8
	.long i_cmp_axd16
	.long i_ds
	.long i_aas
	.long i_inc_ax
	.long i_inc_cx
	.long i_inc_dx
	.long i_inc_bx
	.long i_inc_sp
	.long i_inc_bp
	.long i_inc_si
	.long i_inc_di
	.long i_dec_ax
	.long i_dec_cx
	.long i_dec_dx
	.long i_dec_bx
	.long i_dec_sp
	.long i_dec_bp
	.long i_dec_si
	.long i_dec_di
	.long i_push_ax
	.long i_push_cx
	.long i_push_dx
	.long i_push_bx
	.long i_push_sp
	.long i_push_bp
	.long i_push_si
	.long i_push_di
	.long i_pop_ax
	.long i_pop_cx
	.long i_pop_dx
	.long i_pop_bx
	.long i_pop_sp
	.long i_pop_bp
	.long i_pop_si
	.long i_pop_di
	.long i_pusha
	.long i_popa
	.long i_chkind
	.long i_undefined	// arpl
	.long i_undefined	// repnc
	.long i_undefined	// repc
	.long i_undefined	// fpo2
	.long i_undefined	// fpo2
	.long i_push_d16
	.long i_imul_d16
	.long i_push_d8
	.long i_imul_d8
	.long i_inmb
	.long i_inmw
	.long i_outmb
	.long i_outmw
	.long i_bv
	.long i_bnv
	.long i_bc
	.long i_bnc
	.long i_be
	.long i_bne
	.long i_bnh
	.long i_bh
	.long i_bn
	.long i_bp
	.long i_bpe
	.long i_bpo
	.long i_blt
	.long i_bge
	.long i_ble
	.long i_bgt
	.long i_80pre
	.long i_81pre
	.long i_82pre
	.long i_83pre
	.long i_test_br8
	.long i_test_wr16
	.long i_xchg_br8
	.long i_xchg_wr16
	.long i_mov_br8
	.long i_mov_wr16
	.long i_mov_r8b
	.long i_mov_r16w
	.long i_mov_wsreg
	.long i_lea
	.long i_mov_sregw
	.long i_popw
	.long i_nop
	.long i_xchg_axcx
	.long i_xchg_axdx
	.long i_xchg_axbx
	.long i_xchg_axsp
	.long i_xchg_axbp
	.long i_xchg_axsi
	.long i_xchg_axdi
	.long i_cbw
	.long i_cwd
	.long i_call_far
	.long i_poll
	.long i_pushf
	.long i_popf
	.long i_sahf
	.long i_lahf
	.long i_mov_aldisp
	.long i_mov_axdisp
	.long i_mov_dispal
	.long i_mov_dispax
	.long i_movsb
	.long i_movsw
	.long i_cmpsb
	.long i_cmpsw
	.long i_test_ald8
	.long i_test_axd16
	.long i_stosb
	.long i_stosw
	.long i_lodsb
	.long i_lodsw
	.long i_scasb
	.long i_scasw
	.long i_mov_ald8
	.long i_mov_cld8
	.long i_mov_dld8
	.long i_mov_bld8
	.long i_mov_ahd8
	.long i_mov_chd8
	.long i_mov_dhd8
	.long i_mov_bhd8
	.long i_mov_axd16
	.long i_mov_cxd16
	.long i_mov_dxd16
	.long i_mov_bxd16
	.long i_mov_spd16
	.long i_mov_bpd16
	.long i_mov_sid16
	.long i_mov_did16
	.long i_rotshft_bd8
	.long i_rotshft_wd8
	.long i_ret_d16
	.long i_ret
	.long i_les_dw
	.long i_lds_dw
	.long i_mov_bd8
	.long i_mov_wd16
	.long i_prepare
	.long i_dispose
	.long i_retf_d16
	.long i_retf
	.long i_int3
	.long i_int
	.long i_into
	.long i_iret
	.long i_rotshft_b
	.long i_rotshft_w
	.long i_rotshft_bcl
	.long i_rotshft_wcl
	.long i_aam
	.long i_aad
	.long i_salc 	// D6 undefined opcode
	.long i_trans  	// xlat
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_fpo1	// fpo1
	.long i_loopne
	.long i_loope
	.long i_loop
	.long i_jcxz
	.long i_inal
	.long i_inax
	.long i_outal
	.long i_outax
	.long i_call_d16
	.long i_jmp_d16
	.long i_jmp_far
	.long i_br_d8
	.long i_inaldx
	.long i_inaxdx
	.long i_outdxal
	.long i_outdxax
	.long i_lock
	.long i_brks	// 0xF1
	.long i_repne
	.long i_repe
	.long i_hlt
	.long i_cmc
	.long i_f6pre
	.long i_f7pre
	.long i_clc
	.long i_stc
	.long i_di
	.long i_ei
	.long i_cld
	.long i_std
	.long i_fepre
	.long i_ffpre

PZSTable:
	.byte PSR_Z|PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0, 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P
	.byte 0      , PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0
	.byte 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_P, 0, 0 ,PSR_P, 0, PSR_P, PSR_P, 0
	.byte PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0, 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P
	.byte 0      , PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0
	.byte PSR_P,       0, 0, PSR_P, 0, PSR_P, PSR_P, 0, 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P
	.byte PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0, 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P
	.byte 0, PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S
GetEA:
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007
	.long EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007

	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107
	.long EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107

	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
	.long EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207

	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
	.long EA_300, EA_301, EA_302, EA_303, EA_304, EA_305, EA_306, EA_307
Mod_RM:
	.space 0x400
SegmentTable:
	.byte 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1
;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
