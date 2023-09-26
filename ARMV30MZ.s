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
	.global v30OutOfCycles

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
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
add80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	add8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
add80EA:
	add8 r4,r0
	bl v30WriteSegOfs
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
add81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	add16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
add81EA:
	add16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_add_r8b:
_02:	;@ ADD R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	add8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	add16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_add_awd16:
_05:	;@ ADD AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	add16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_ds1:
_06:	;@ PUSH DS1/ES
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegDS1+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_pop_ds1:
_07:	;@ POP DS1/ES
;@----------------------------------------------------------------------------
	popWord
	strh r0,[v30ptr,#v30SRegDS1+2]
	fetch 3
;@----------------------------------------------------------------------------
i_or_br8:
_08:	;@ OR BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
or80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	or8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
or80EA:
	or8 r4,r0
	bl v30WriteSegOfs
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
or81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	or16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
or81EA:
	or16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_or_r8b:
_0A:	;@ OR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r3,r4,#0xff
	ldrbpl r0,[v30ptr,-r3]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	or8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	or16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_or_awd16:
_0D:	;@ OR AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	or16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_ps:
_0E:	;@ PUSH PS/CS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegPS+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_adc_br8:
_10:	;@ ADDC/ADC BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
adc80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	adc8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
adc80EA:
	adc8 r4,r0
	bl v30WriteSegOfs
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
adc81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	adc16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
adc81EA:
	adc16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_adc_r8b:
_12:	;@ ADDC/ADC R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	adc8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	adc16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_adc_awd16:
_15:	;@ ADDC/ADC AWD16
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
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
subc80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	subc8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
subc80EA:
	subc8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_wr16:
_19:	;@ SUBC/SBB WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f
subc81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	rsbc16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
subc81EA:
	rsbc16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_r8b:
_1A:	;@ SUBC/SBB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	subc8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	subc16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_sbb_awd16:
_1D:	;@ SUBC/SBB AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	subc16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_push_ds0:
_1E:	;@ PUSH DS0/DS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30SRegDS0+2]
	bl v30PushW
	fetch 2
;@----------------------------------------------------------------------------
i_pop_ds0:
_1F:	;@ POP DS0/DS
;@----------------------------------------------------------------------------
	popWord
	strh r0,[v30ptr,#v30SRegDS0+2]
	fetch 3
;@----------------------------------------------------------------------------
i_and_br8:
_20:	;@ AND BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
and80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	and8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
and80EA:
	and8 r4,r0
	bl v30WriteSegOfs
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
and81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	and16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
and81EA:
	and16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_and_r8b:
_22:	;@ AND R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	and8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	and16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_and_awd16:
_25:	;@ AND AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_ds1:
_26:	;@ DS1/ES prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegDS1]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30f,v30f,r1		;@ SEG_PF
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]

;@----------------------------------------------------------------------------
i_daa:
_27:	;@ ADJ4A/DAA
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	and v30f,v30f,#PSR_A|PSR_C
	mov r1,#0x66000000
	cmn r1,r0,lsl#28
	orrcs v30f,v30f,#PSR_A
	cmp r0,#0x9A
	tstcc v30f,v30f,lsr#2	;@ #PSR_C
	biccc r1,r1,#0x60000000
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
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
sub80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	sub8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
sub80EA:
	sub8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_sub_wr16:
_29:	;@ SUB WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 0f
sub81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	rsb16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
sub81EA:
	rsb16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_sub_r8b:
_2A:	;@ SUB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	sub8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	sub16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_sub_awd16:
_2D:	;@ SUB AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_ps:
_2E:	;@ PS/CS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegPS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30f,v30f,r1		;@ SEG_PF
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_das:
_2F:	;@ ADJ4S/DAS
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	mov r2,r0,ror#4
	cmp r2,#0xA0000000
	orrcs v30f,v30f,#PSR_A
	cmp r0,#0x9A
	tstcc v30f,v30f,lsr#2	;@ #PSR_C
	ands v30f,v30f,#PSR_A
	orrcs v30f,v30f,#PSR_C
	subcs r0,r0,#0x60
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
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	bmi 0f

	and v30ofs,r1,#0xff
xor80Reg:
	ldrb r0,[v30ptr,-v30ofs]
	xor8 r4,r0

	strb r1,[v30ptr,-v30ofs]
	fetch 1
0:
	bl v30ReadEA
xor80EA:
	xor8 r4,r0
	bl v30WriteSegOfs
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
xor81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]

	xor16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
0:
	bl v30ReadEAW
xor81EA:
	xor16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_xor_r8b:
_32:	;@ XOR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	xor8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	xor16 r0,r1
	strh r1,[r4,#v30Regs]
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
i_xor_awd16:
_35:	;@ XOR AWD16
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
	orr v30f,v30f,r1		;@ SEG_PF
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_aaa:
_37:	;@ ADJBA/AAA
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	mov r1,r0,lsl#28
	cmp r1,#0xA0000000
	tstcc v30f,v30f,lsr#5			;@ Shift out PSR_A
	movcs v30f,#PSR_Z+PSR_A+PSR_C
	movcc v30f,#PSR_S
	strb r1,[v30ptr,#v30ParityVal]	;@ Parity allways set
	orr r0,r0,#0x00F0
	addcs r0,r0,#0x0016
	bic r0,r0,#0x00F0
	strh r0,[v30ptr,#v30RegAW]
	fetch 9
;@----------------------------------------------------------------------------
i_cmp_br8:
_38:	;@ CMP BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	andpl v30ofs,r1,#0xff
cmp80Reg:
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA1

	sub8 r4,r0
	fetch 1
cmp80EA:
	sub8 r4,r0
	fetch 2
;@----------------------------------------------------------------------------
i_cmp_wr16:
_39:	;@ CMP WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
cmp81Reg:
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	rsb16 r0,r4
	fetch 1
cmp81EA:
	rsb16 r0,r4
	fetch 2
;@----------------------------------------------------------------------------
i_cmp_r8b:
_3A:	;@ CMP R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	sub8 r0,r1
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_r16w:
_3B:	;@ CMP R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,#v30Regs2]
	sub16 r0,r1
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
i_cmp_awd16:
_3D:	;@ CMP AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	fetch 1
;@----------------------------------------------------------------------------
i_ds0:
_3E:	;@ DS0/DS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegDS0]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	orr v30f,v30f,r1		;@ SEG_PF
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_aas:
_3F:	;@ ADJBS/AAS
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
i_inc_aw:
_40:	;@ INC AW/AX
;@----------------------------------------------------------------------------
	incWord v30RegAW
;@----------------------------------------------------------------------------
i_inc_cw:
_41:	;@ INC CW/CX
;@----------------------------------------------------------------------------
	incWord v30RegCW
;@----------------------------------------------------------------------------
i_inc_dw:
_42:	;@ INC DW/DX
;@----------------------------------------------------------------------------
	incWord v30RegDW
;@----------------------------------------------------------------------------
i_inc_bw:
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
i_inc_ix:
_46:	;@ INC IX/SI
;@----------------------------------------------------------------------------
	incWord v30RegIX+2
;@----------------------------------------------------------------------------
i_inc_iy:
_47:	;@ INC IY/DI
;@----------------------------------------------------------------------------
	incWord v30RegIY+2
;@----------------------------------------------------------------------------
i_dec_aw:
_48:	;@ DEC AW/AX
;@----------------------------------------------------------------------------
	decWord v30RegAW
;@----------------------------------------------------------------------------
i_dec_cw:
_49:	;@ DEC CW/CX
;@----------------------------------------------------------------------------
	decWord v30RegCW
;@----------------------------------------------------------------------------
i_dec_dw:
_4A:	;@ DEC DW/DX
;@----------------------------------------------------------------------------
	decWord v30RegDW
;@----------------------------------------------------------------------------
i_dec_bw:
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
i_dec_ix:
_4E:	;@ DEC IX/SI
;@----------------------------------------------------------------------------
	decWord v30RegIX+2
;@----------------------------------------------------------------------------
i_dec_iy:
_4F:	;@ DEC IY/DI
;@----------------------------------------------------------------------------
	decWord v30RegIY+2
;@----------------------------------------------------------------------------
i_push_aw:
_50:	;@ PUSH AW/AX
;@----------------------------------------------------------------------------
	pushRegister v30RegAW
;@----------------------------------------------------------------------------
i_push_cw:
_51:	;@ PUSH CW/CX
;@----------------------------------------------------------------------------
	pushRegister v30RegCW
;@----------------------------------------------------------------------------
i_push_dw:
_52:	;@ PUSH DW/DX
;@----------------------------------------------------------------------------
	pushRegister v30RegDW
;@----------------------------------------------------------------------------
i_push_bw:
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
i_push_ix:
_56:	;@ PUSH IX/SI
;@----------------------------------------------------------------------------
	pushRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_push_iy:
_57:	;@ PUSH IY/DI
;@----------------------------------------------------------------------------
	pushRegister v30RegIY+2

;@----------------------------------------------------------------------------
i_pop_aw:
_58:	;@ POP AW/AX
;@----------------------------------------------------------------------------
	popRegister v30RegAW
;@----------------------------------------------------------------------------
i_pop_cw:
_59:	;@ POP CW/CX
;@----------------------------------------------------------------------------
	popRegister v30RegCW
;@----------------------------------------------------------------------------
i_pop_dw:
_5A:	;@ POP DW/DX
;@----------------------------------------------------------------------------
	popRegister v30RegDW
;@----------------------------------------------------------------------------
i_pop_bw:
_5B:	;@ POP BW/BX
;@----------------------------------------------------------------------------
	popRegister v30RegBW
;@----------------------------------------------------------------------------
i_pop_sp:
_5C:	;@ POP SP
;@----------------------------------------------------------------------------
	bl v30ReadStack
	strh r0,[v30ptr,#v30RegSP+2]
	fetch 1
;@----------------------------------------------------------------------------
i_pop_bp:
_5D:	;@ POP BP
;@----------------------------------------------------------------------------
	popRegister v30RegBP+2
;@----------------------------------------------------------------------------
i_pop_ix:
_5E:	;@ POP IX/SI
;@----------------------------------------------------------------------------
	popRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_pop_iy:
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
	bl v30ReadStack
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
	ldr r4,[r2,#v30Regs-2]
	bl v30ReadEAW
	add v30ofs,v30ofs,#0x20000
	mov r5,r0,lsl#16
	bl v30ReadSegOfsW
	ClearSegmentPrefix
	cmp r5,r4
	cmple r4,r0,lsl#16
	subgt v30cyc,v30cyc,#21*CYCLE
	movgt r0,#5
	bgt nec_interrupt
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	getNextWordto r1, r2

	mul r2,r0,r1
	movs v30f,r2,asr#15
	mvnsne v30f,v30f
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity

	strh r2,[r4,#v30Regs]
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	getNextSignedByteTo r1

	mul r2,r0,r1
	movs v30f,r2,asr#15
	mvnsne v30f,v30f
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity

	strh r2,[r4,#v30Regs]
	fetch 3

;@----------------------------------------------------------------------------
f36c:	;@ REP INMB/INSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
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
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes				;@ REP_PF not used yet.
	fetch 5
;@----------------------------------------------------------------------------
i_inmb:
_6C:	;@ INMB/INSB
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort
	mov r1,r0
	ldrsb r4,[v30ptr,#v30DF]
	bl v30WriteEsIy
	fetch 5

;@----------------------------------------------------------------------------
f36d:	;@ REP INMW/INSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort16
	mov r1,r0
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes				;@ REP_PF not used yet.
	fetch 5
;@----------------------------------------------------------------------------
i_inmw:
_6D:	;@ INMW/INSW
;@----------------------------------------------------------------------------
	GetIyOfsESegment
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort16
	ldrsb r4,[v30ptr,#v30DF]
	mov r1,r0
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	fetch 5

;@----------------------------------------------------------------------------
f36e:	;@ REP OUTMB/OUTSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_outmb:
_6E:	;@ OUTMB/OUTSB
;@----------------------------------------------------------------------------
	bl v30ReadDsIx
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort
	ClearSegmentPrefix
	fetch 5

;@----------------------------------------------------------------------------
f36f:	;@ REP OUTMW/OUTSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	ldrh r1,[v30ptr,#v30RegDW]
	add v30ofs,v30ofs,r4,lsl#17
	bl v30WritePort16
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_outmw:
_6F:	;@ OUTMW/OUTSW
;@----------------------------------------------------------------------------
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort16
	ClearSegmentPrefix
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
i_82pre:
_82:	;@ PRE 82
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	and r5,r0,#0xF8
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	blmi v30ReadEA

	getNextByteTo r4

	ldr pc,[pc,r5,lsr#1]
	nop
	.long add80EA,  or80EA,  adc80EA,  subc80EA,  and80EA,  sub80EA,  xor80EA,  cmp80EA
	.long add80EA,  or80EA,  adc80EA,  subc80EA,  and80EA,  sub80EA,  xor80EA,  cmp80EA
	.long add80EA,  or80EA,  adc80EA,  subc80EA,  and80EA,  sub80EA,  xor80EA,  cmp80EA
	.long add80Reg, or80Reg, adc80Reg, subc80Reg, and80Reg, sub80Reg, xor80Reg, cmp80Reg

;@----------------------------------------------------------------------------
i_81pre:
_81:	;@ PRE 81
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	blmi v30ReadEAW

	getNextWordTo r4, r1
pre81Continue:
	mov r4,r4,lsl#16

	ldr pc,[pc,r5,lsr#1]
	nop
	.long add81EA,  or81EA,  adc81EA,  subc81EA,  and81EA,  sub81EA,  xor81EA,  cmp81EA
	.long add81EA,  or81EA,  adc81EA,  subc81EA,  and81EA,  sub81EA,  xor81EA,  cmp81EA
	.long add81EA,  or81EA,  adc81EA,  subc81EA,  and81EA,  sub81EA,  xor81EA,  cmp81EA
	.long add81Reg, or81Reg, adc81Reg, subc81Reg, and81Reg, sub81Reg, xor81Reg, cmp81Reg

;@----------------------------------------------------------------------------
i_83pre:
_83:	;@ PRE 83
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	blmi v30ReadEAW

	getNextSignedByteTo r4
	b pre81Continue
;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	ldrb r4,[v30ptr,-r1,lsr#24]
	andpl v30ofs,r1,#0xff
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA1

	and8 r4,r0
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	and16 r0,r4
	fetch 1
;@----------------------------------------------------------------------------
i_xchg_br8:
_86:	;@ XCH/XCHG BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 0f

	and r2,r4,#0xff
	ldrb r0,[v30ptr,-r2]
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	strb r1,[v30ptr,-r2]
	ClearSegmentPrefix
	fetch 3
0:
	bl v30ReadEA
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	bl v30WriteSegOfs
	ClearSegmentPrefix
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	strh r1,[v30ofs,#v30Regs]
	ClearSegmentPrefix
	fetch 3
0:
	bl v30ReadEAW
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	bl v30WriteSegOfsW
	ClearSegmentPrefix
	fetch 5
;@----------------------------------------------------------------------------
i_mov_br8:
_88:	;@ MOV BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r3,[v30ofs,#v30ModRmReg]
//	cmp r0,#0xDB				;@ mov bl,bl
//	bne noBreak
//	mov r11,r11
//noBreak:
	cmp r0,#0xC0
	ldrb r1,[v30ptr,-r3,lsr#24]

	andpl r3,r3,#0xff
	strbpl r1,[v30ptr,-r3]
	blmi v30WriteEA
	ClearSegmentPrefix
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
	add v30ofs,v30ptr,r0,lsl#2
	strhpl r1,[v30ofs,#v30Regs]
	blmi v30WriteEAW
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_mov_r8b:
_8A:	;@ MOV R8B
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	cmp r0,#0xC0

	andpl r1,r4,#0xff
	ldrbpl r0,[v30ptr,-r1]
	blmi v30ReadEA
	strb r0,[v30ptr,-r4,lsr#24]
	ClearSegmentPrefix
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
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW_noAdd
	strh r0,[r4,#v30Regs]
	ClearSegmentPrefix
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
	add v30ofs,v30ptr,r0,lsl#2
	strhpl r1,[v30ofs,#v30Regs]
	blmi v30WriteEAW
	ClearSegmentPrefix
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
	add v30ofs,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]	;@ EATable return EO in v30ofs
	str v30ofs,[r4,#v30Regs2]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x18				;@ This is correct.
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	add r1,v30ptr,r4,lsr#1
	strh r0,[r1,#v30SRegs+2]
//	orr v30cyc,v30cyc,#LOCK_PREFIX
	ClearSegmentPrefix
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

	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	strhpl r1,[v30ofs,#v30Regs]
	blmi v30WriteEAW2
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_nop:
_90:	;@ NOP (XCH AWAW)
;@----------------------------------------------------------------------------
	ldrb r0,[v30pc]				;@ Check for 3 NOPs
	cmp r0,#0x90
	ldrbeq r1,[v30pc,#1]
	cmpeq r1,#0x90
	subeq v30cyc,v30cyc,#1*CYCLE
	fetch 1
;@----------------------------------------------------------------------------
i_xchg_awcw:
_91:	;@ XCH/XCHG AWCW
;@----------------------------------------------------------------------------
	xchgreg v30RegCW
;@----------------------------------------------------------------------------
i_xchg_awdw:
_92:	;@ XCH/XCHG AWDW
;@----------------------------------------------------------------------------
	xchgreg v30RegDW
;@----------------------------------------------------------------------------
i_xchg_awbw:
_93:	;@ XCH/XCHG AWBW
;@----------------------------------------------------------------------------
	xchgreg v30RegBW
;@----------------------------------------------------------------------------
i_xchg_awsp:
_94:	;@ XCH/XCHG AWSP
;@----------------------------------------------------------------------------
	xchgreg v30RegSP+2
;@----------------------------------------------------------------------------
i_xchg_awbp:
_95:	;@ XCH/XCHG AWBP
;@----------------------------------------------------------------------------
	xchgreg v30RegBP+2
;@----------------------------------------------------------------------------
i_xchg_awix:
_96:	;@ XCH/XCHG AWIX
;@----------------------------------------------------------------------------
	xchgreg v30RegIX+2
;@----------------------------------------------------------------------------
i_xchg_awiy:
_97:	;@ XCH/XCHG AWIY
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
	ldrh r1,[v30ptr,#v30SRegPS+2]
	strh r0,[v30ptr,#v30SRegPS+2]
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
	tst v30f,#PSR_A
	orrne r1,r1,#AF
	ldrb r3,[v30ptr,#v30IF]
	tst r2,#PSR_P
	orrne r1,r1,#PF
	ldrsb r2,[v30ptr,#v30DF]
	tst v30cyc,#TRAP_FLAG
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
	and r1,r0,#PF
	eor r1,r1,#PF
	strb r1,[v30ptr,#v30ParityVal]
	and v30f,r0,#AF			;@ PSR_A is in the same place as AF
	tst r0,#SF
	orrne v30f,v30f,#PSR_S
	tst r0,#ZF
	orrne v30f,v30f,#PSR_Z
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	tst r0,#OF
	orrne v30f,v30f,#PSR_V
	tst r0,#DF
	moveq r1,#1
	movne r1,#-1
	strb r1,[v30ptr,#v30DF]
	ands r1,r0,#IF
	movne r1,#IRQ_PIN
	ldrb r2,[v30ptr,#v30IF]
	eors r2,r2,r1
	strbne r1,[v30ptr,#v30IF]
	tst r0,#TF				;@ Check if Trap is set.
	orrne v30cyc,v30cyc,#TRAP_FLAG
	tsteq r2,r1				;@ Or if Interrupt became enabled
	eatCycles 3
	bne v30DelayIrqCheck
	fetch 0
;@----------------------------------------------------------------------------
i_sahf:
_9E:	;@ SAHF
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAH]

	and v30f,v30f,#PSR_V	;@ Keep V.
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
	ldrh r2,[v30ptr,#v30ParityVal]	;@ Top of ParityVal is pointer to v30PZST
	mov r0,v30f,lsl#28
	ldrb r2,[v30ptr,r2]
	and r1,v30f,#PSR_A
	orr r1,r1,#0x02
	msr cpsr_flg,r0
	orrmi r1,r1,#SF
	orreq r1,r1,#ZF
	orrcs r1,r1,#CF
	tst r2,#PSR_P
	orrne r1,r1,#PF

	strb r1,[v30ptr,#v30RegAH]
	fetch 2
;@----------------------------------------------------------------------------
i_mov_aldisp:
_A0:	;@ MOV ALDISP
;@----------------------------------------------------------------------------
	getNextWord
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add r0,v30csr,r0,lsl#12
	bl cpuReadMem20
	strb r0,[v30ptr,#v30RegAL]
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_mov_awdisp:
_A1:	;@ MOV AWDISP
;@----------------------------------------------------------------------------
	getNextWord
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add r0,v30csr,r0,lsl#12
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegAW]
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dispal:
_A2:	;@ MOV DISPAL
;@----------------------------------------------------------------------------
	getNextWord
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldrb r1,[v30ptr,#v30RegAL]
	add r0,v30csr,r0,lsl#12
	bl cpuWriteMem20
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dispaw:
_A3:	;@ MOV DISPAW
;@----------------------------------------------------------------------------
	getNextWord
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldrh r1,[v30ptr,#v30RegAW]
	add r0,v30csr,r0,lsl#12
	bl cpuWriteMem20W
	ClearSegmentPrefix
	fetch 1

;@----------------------------------------------------------------------------
f3a4:	;@ REP MOVMB/MOVSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	GetIyOfsESegmentR2R3
	mov r1,r0
	add r0,r3,r2,lsr#4
	add r2,r2,r4,lsl#16
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20
	eatCycles 7
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_movsb:
_A4:	;@ MOVMB/MOVSB
;@----------------------------------------------------------------------------
	bl v30ReadDsIx
	mov r1,r0
	bl v30WriteEsIy
	ClearSegmentPrefix
	fetch 5

;@----------------------------------------------------------------------------
f3a5:	;@ REP MOVMW/MOVSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	GetIyOfsESegmentR2R3
	mov r1,r0
	add r0,r3,r2,lsr#4
	add r2,r2,r4,lsl#17
	str r2,[v30ptr,#v30RegIY]
	bl cpuWriteMem20W
	subs v30cyc,v30cyc,#7*CYCLE
	bmi breakRepMov
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
breakRepMov:
	sub r5,r5,#1
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
	sub v30pc,v30pc,#2
	TestSegmentPrefix
	subne v30pc,v30pc,#1
	ClearPrefixes
	b v30OutOfCycles
;@----------------------------------------------------------------------------
i_movsw:
_A5:	;@ MOVMW/MOVSW
;@----------------------------------------------------------------------------
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	GetIyOfsESegment
	mov r1,r0
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	ClearSegmentPrefix
	fetch 5

;@----------------------------------------------------------------------------
f2a6:	;@ REPNZ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16

	GetIyOfsESegmentR2R3
	add r1,r2,r4,lsl#16
	mov r4,r0
	add r0,r3,r2,lsr#4
	str r1,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
f3a6:	;@ REPZ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16

	GetIyOfsESegmentR2R3
	add r1,r2,r4,lsl#16
	mov r4,r0
	add r0,r3,r2,lsr#4
	str r1,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsb:
_A6:	;@ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	bl v30ReadDsIx

	GetIyOfsESegment
	add r2,v30ofs,r4,lsl#16
	mov r4,r0
	str r2,[v30ptr,#v30RegIY]
	bl v30ReadSegOfs

	sub8 r0,r4

//	ClearSegmentPrefix				;@ sub8 clears flags
	fetch 6

;@----------------------------------------------------------------------------
f2a7:	;@ REPNZ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17

	GetIyOfsESegmentR2R3
	add r1,r2,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r2,lsr#4
	str r1,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub16 clears flags
	fetch 5
;@----------------------------------------------------------------------------
f3a7:	;@ REPZ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
0:
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17

	GetIyOfsESegmentR2R3
	add r1,r2,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r2,lsr#4
	str r1,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub16 clears flags
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsw:
_A7:	;@ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]

	GetIyOfsESegment
	add r1,v30ofs,r4,lsl#17
	mov r4,r0,lsl#16
	str r1,[v30ptr,#v30RegIY]
	bl v30ReadSegOfsW

	sub16 r0,r4

//	ClearSegmentPrefix			;@ sub16 clears flags
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
i_test_awd16:
_A9:	;@ TEST AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	fetch 1

;@----------------------------------------------------------------------------
f3aa:	;@ REP STMB/STOSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrb r1,[v30ptr,#v30RegAL]
	bl v30WriteSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	eatCycles 6
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes				;@ REP_PF not used yet.
	fetch 5
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STMB/STOSB
;@----------------------------------------------------------------------------
	ldrb r1,[v30ptr,#v30RegAL]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30WriteEsIy
	fetch 3

;@----------------------------------------------------------------------------
f3ab:	;@ REP STMW/STOSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	ldrh r1,[v30ptr,#v30RegAW]
	bl v30WriteSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	subs v30cyc,v30cyc,#6*CYCLE
	bmi breakRep
	subs r5,r5,#1
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes				;@ REP_PF not used yet.
	fetch 5
breakRep:
	sub r5,r5,#1
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	sub v30pc,v30pc,#2
//	ClearPrefixes				;@ REP_PF not used yet.
	b v30OutOfCycles
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STMW/STOSW
;@----------------------------------------------------------------------------
	GetIyOfsESegment
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
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_lodsb:
_AC:	;@ LDMB/LODSB
;@----------------------------------------------------------------------------
	bl v30ReadDsIx
	strb r0,[v30ptr,#v30RegAL]
	ClearSegmentPrefix
	fetch 3

;@----------------------------------------------------------------------------
f3ad:	;@ REP LDMW/LODSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	strh r5,[v30ptr,#v30RegCW]
1:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_lodsw:
_AD:	;@ LDMW/LODSW
;@----------------------------------------------------------------------------
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	strh r0,[v30ptr,#v30RegAW]
	ClearSegmentPrefix
	fetch 3

;@----------------------------------------------------------------------------
f2ae:	;@ REPNE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
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
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub8 clears flags
	fetch 5
;@----------------------------------------------------------------------------
f3ae:	;@ REPE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
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
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub8 clears flags
	fetch 5
;@----------------------------------------------------------------------------
i_scasb:
_AE:	;@ CMPMB/SCASB
;@----------------------------------------------------------------------------
	GetIyOfsESegment
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
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
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
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub16 clears flags
	fetch 5
;@----------------------------------------------------------------------------
f3af:	;@ REPE CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq 1f
	GetIyOfsESegment
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
	strh r5,[v30ptr,#v30RegCW]
1:
//	ClearPrefixes					;@ sub16 clears flags
	fetch 5
;@----------------------------------------------------------------------------
i_scasw:
_AF:	;@ CMPMW/SCASW
;@----------------------------------------------------------------------------
	GetIyOfsESegment
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
i_mov_awd16:
_B8:	;@ MOV AWD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegAW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_cwd16:
_B9:	;@ MOV CWD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegCW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_dwd16:
_BA:	;@ MOV DWD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegDW]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_bwd16:
_BB:	;@ MOV BWD16
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
i_mov_ixd16:
_BE:	;@ MOV IXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIX+2]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_iyd16:
_BF:	;@ MOV IYD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIY+2]
	fetch 1

;@----------------------------------------------------------------------------
i_rotshft_bd8:
_C0:	;@ ROTSHFT BD8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	and r5,r0,#0xF8
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA

	getNextByteTo r1
d2Continue:
	eatCycles 2
	and r1,r1,#0x1F
d0Continue:

	ldr pc,[pc,r5,lsr#1]
	nop
	.long rolC0EA,  rorC0EA,  rolcC0EA,  rorcC0EA,  shlC0EA,  shrC0EA,  undC0EA,  shraC0EA
	.long rolC0EA,  rorC0EA,  rolcC0EA,  rorcC0EA,  shlC0EA,  shrC0EA,  undC0EA,  shraC0EA
	.long rolC0EA,  rorC0EA,  rolcC0EA,  rorcC0EA,  shlC0EA,  shrC0EA,  undC0EA,  shraC0EA
	.long rolC0Reg, rorC0Reg, rolcC0Reg, rorcC0Reg, shlC0Reg, shrC0Reg, undC0Reg, shraC0Reg

rolC0Reg:
	rol8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rorC0Reg:
	ror8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rolcC0Reg:
	rolc8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rorcC0Reg:
	rorc8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
shlC0Reg:
	shl8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
shrC0Reg:
	shr8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1
undC0Reg:
	bl logUndefinedOpcode
	mov r1,#0
	strb r1,[v30ptr,-v30ofs]
	ClearSegmentPrefix
	fetch 1
shraC0Reg:
	shra8 r0,r1
	strb r1,[v30ptr,-v30ofs]
	fetch 1

rolC0EA:
	rol8 r0,r1
	bl v30WriteSegOfs
	fetch 3
rorC0EA:
	ror8 r0,r1
	bl v30WriteSegOfs
	fetch 3
rolcC0EA:
	rolc8 r0,r1
	bl v30WriteSegOfs
	fetch 3
rorcC0EA:
	rorc8 r0,r1
	bl v30WriteSegOfs
	fetch 3
shlC0EA:
	shl8 r0,r1
	bl v30WriteSegOfs
	fetch 3
shrC0EA:
	shr8 r0,r1
	bl v30WriteSegOfs
	fetch 3
undC0EA:
	bl logUndefinedOpcode
	mov r1,#0
	bl v30WriteSegOfs
	ClearSegmentPrefix
	fetch 3
shraC0EA:
	shra8 r0,r1
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_rotshft_wd8:
_C1:	;@ ROTSHFT WD8
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW_noAdd

	getNextByteTo r1
d3Continue:
	eatCycles 2
	and r1,r1,#0x1F
d1Continue:

	ldr pc,[pc,r5,lsr#1]
	nop
	.long rolC1EA,  rorC1EA,  rolcC1EA,  rorcC1EA,  shlC1EA,  shrC1EA,  undC1EA,  shraC1EA
	.long rolC1EA,  rorC1EA,  rolcC1EA,  rorcC1EA,  shlC1EA,  shrC1EA,  undC1EA,  shraC1EA
	.long rolC1EA,  rorC1EA,  rolcC1EA,  rorcC1EA,  shlC1EA,  shrC1EA,  undC1EA,  shraC1EA
	.long rolC1Reg, rorC1Reg, rolcC1Reg, rorcC1Reg, shlC1Reg, shrC1Reg, undC1Reg, shraC1Reg

rolC1Reg:
	rol16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rorC1Reg:
	ror16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rolcC1Reg:
	rolc16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rorcC1Reg:
	rorc16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
shlC1Reg:
	shl16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
shrC1Reg:
	shr16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1
undC1Reg:
	bl logUndefinedOpcode
	mov r1,#0
	strh r1,[v30ofs,#v30Regs]
	ClearSegmentPrefix
	fetch 1
shraC1Reg:
	shra16 r0,r1
	strh r1,[v30ofs,#v30Regs]
	fetch 1

rolC1EA:
	rol16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
rorC1EA:
	ror16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
rolcC1EA:
	rolc16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
rorcC1EA:
	rorc16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
shlC1EA:
	shl16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
shrC1EA:
	shr16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
undC1EA:
	bl logUndefinedOpcode
	mov r1,#0
	bl v30WriteSegOfsW
	ClearSegmentPrefix
	fetch 3
shraC1EA:
	shra16 r0,r1
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_ret_d16:
_C2:	;@ RET D16
;@----------------------------------------------------------------------------
	bl v30ReadStack
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
	bl v30ReadStack
	add v30ofs,v30ofs,#0x20000
	str v30ofs,[v30ptr,#v30RegSP]
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	fetch 6
;@----------------------------------------------------------------------------
i_les_dw:
_C4:	;@ MOV DS1 / LES DW
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
	strh r0,[v30ptr,#v30SRegDS1+2]

	ClearSegmentPrefix
	fetch 6
;@----------------------------------------------------------------------------
i_lds_dw:
_C5:	;@ MOV DS0 / LDS DW
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
	strh r0,[v30ptr,#v30SRegDS0+2]

	ClearSegmentPrefix
	fetch 6
;@----------------------------------------------------------------------------
i_mov_bd8:
_C6:	;@ MOV BD8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	bmi 0f
	ldrb r4,[v30ofs,#v30ModRmRm]
	getNextByteTo r1
	strb r1,[v30ptr,-r4]
	ClearSegmentPrefix
	fetch 1
0:
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
	getNextByteTo r1
	bl v30WriteSegOfs
	ClearSegmentPrefix
	fetch 1

;@----------------------------------------------------------------------------
i_mov_wd16:
_C7:	;@ MOV WD16
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	bmi 0f
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	getNextWordTo r1, r0
	strh r1,[v30ofs,#v30Regs]
	ClearSegmentPrefix
	fetch 1
0:
	add v30ofs,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
	getNextWordTo r1, r0
	bl v30WriteSegOfsW
	ClearSegmentPrefix
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
	TestSegmentPrefix
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
	ClearSegmentPrefix
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
	bl v30ReadStack
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	add v30ofs,v30ofs,r4,lsl#16
	strh r0,[v30ptr,#v30SRegPS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	fetch 9
;@----------------------------------------------------------------------------
i_retf:
_CB:	;@ RETF
;@----------------------------------------------------------------------------
	bl v30ReadStack
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30SRegPS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	fetch 8
;@----------------------------------------------------------------------------
i_int3:
_CC:	;@ BRK3/INT3
;@----------------------------------------------------------------------------
	eatCycles 9
	mov r0,#3
	b nec_interrupt
;@----------------------------------------------------------------------------
i_int:
_CD:	;@ BRK/INT
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
	bl v30ReadStack
	add v30ofs,v30ofs,#0x20000
	mov v30pc,r0,lsl#16
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,#0x20000
	strh r0,[v30ptr,#v30SRegPS+2]
	str v30ofs,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	eatCycles 10-3				;@ i_popf eats 3 cycles
	b i_popf

;@----------------------------------------------------------------------------
i_rotshft_b:
_D0:	;@ ROTSHFT B
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	and r5,r0,#0xF8
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA
	mov r1,#1
	b d0Continue
;@----------------------------------------------------------------------------
i_rotshft_w:
_D1:	;@ ROTSHFT W
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW_noAdd
	mov r1,#1
	b d1Continue
;@----------------------------------------------------------------------------
i_rotshft_bcl:
_D2:	;@ ROTSHFT BCL
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	and r5,r0,#0xF8
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA
	ldrb r1,[v30ptr,#v30RegCL]
	b d2Continue
;@----------------------------------------------------------------------------
i_rotshft_wcl:
_D3:	;@ ROTSHFT WCL
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW_noAdd
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
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldrb r0,[v30ptr,#v30RegAL]
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	add v30ofs,v30ofs,r0,lsl#16
	bl v30ReadSegOfs
	strb r0,[v30ptr,#v30RegAL]
	ClearSegmentPrefix
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
i_bcwz:
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
i_inaw:
_E5:	;@ INAW
;@----------------------------------------------------------------------------
	getNextByte
	bl v30ReadPort16
	strh r0,[v30ptr,#v30RegAW]
	fetch 7
;@----------------------------------------------------------------------------
i_outal:
_E6:	;@ OUTAL
;@----------------------------------------------------------------------------
	getNextByteTo r1
	ldrb r0,[v30ptr,#v30RegAL]
	bl v30WritePort
	fetch 7
;@----------------------------------------------------------------------------
i_outaw:
_E7:	;@ OUTAW
;@----------------------------------------------------------------------------
	getNextByteTo r1
	ldrh r0,[v30ptr,#v30RegAW]
	bl v30WritePort16
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
	strh r0,[v30ptr,#v30SRegPS+2]
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
i_inaldw:
_EC:	;@ INALDW
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort
	strb r0,[v30ptr,#v30RegAL]
	fetch 5
;@----------------------------------------------------------------------------
i_inawdw:
_ED:	;@ INAWDW
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	bl v30ReadPort16
	strh r0,[v30ptr,#v30RegAW]
	fetch 5
;@----------------------------------------------------------------------------
i_outdwal:
_EE:	;@ OUTDWAL
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort
	fetch 5
;@----------------------------------------------------------------------------
i_outdwaw:
_EF:	;@ OUTDWAW
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort16
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
	orr v30f,v30f,#SEG_PF
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	ldr v30csr,[r1,#v30SRegs]

//	eatCycles 1
	getNextByte
noF2Prefix:
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	tst r1,#SEG_PF
	biceq v30f,v30f,#SEG_PF
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
	orr v30f,v30f,#SEG_PF
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	ldr v30csr,[r1,#v30SRegs]

//	eatCycles 1
	getNextByte
noF3Prefix:
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	tst r1,#SEG_PF
	biceq v30f,v30f,#SEG_PF
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
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	and r5,r0,#0xF8
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA1

	ldr pc,[pc,r5,lsr#1]
	nop
	.long testF6, undefF6, notF6EA,  negF6EA,  muluF6, mulF6, divubF6, divbF6
	.long testF6, undefF6, notF6EA,  negF6EA,  muluF6, mulF6, divubF6, divbF6
	.long testF6, undefF6, notF6EA,  negF6EA,  muluF6, mulF6, divubF6, divbF6
	.long testF6, undefF6, notF6Reg, negF6Reg, muluF6, mulF6, divubF6, divbF6
;@----------------------------------------------------------------------------
testF6:
	getNextByteTo r1
	and8 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
notF6Reg:
	mvn r1,r0
	strb r1,[v30ptr,-v30ofs]
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
notF6EA:
	mvn r1,r0
	bl v30WriteSegOfs
	ClearSegmentPrefix
	fetch 2
;@----------------------------------------------------------------------------
negF6Reg:
	mov r1,r0,lsl#24
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#24
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	strb r1,[v30ptr,-v30ofs]
	fetch 1
;@----------------------------------------------------------------------------
negF6EA:
	mov r1,r0,lsl#24
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#24
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	bl v30WriteSegOfs
	fetch 2
;@----------------------------------------------------------------------------
muluF6:			;@ MULU/MUL
	ldrb r1,[v30ptr,#v30RegAL]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,r2,lsr#8
	movne v30f,#PSR_C+PSR_V
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	fetch 3
;@----------------------------------------------------------------------------
muluF6Aswan:	;@ MULU/MUL
	ldrb r1,[v30ptr,#v30RegAL]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,r2,lsr#8
	movne v30f,#PSR_C+PSR_V
	orr r0,v30f,#PSR_Z				;@ Set Z, but not for flags.
	strb r0,[v30ptr,#v30MulOverflow]
	strb r0,[v30ptr,#v30ParityVal]	;@ Clear parity
	fetch 3
;@----------------------------------------------------------------------------
mulF6:			;@ MUL/IMUL
	ldrsb r1,[v30ptr,#v30RegAL]
	mov r0,r0,lsl#24
	mov r0,r0,asr#24
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,r2,asr#7
	mvnsne v30f,v30f
	movne v30f,#PSR_C+PSR_V
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
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
	getNextByte
	cmp r0,#0xC0
	and r5,r0,#0xF8
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr pc,[pc,r5,lsr#1]
	nop
	.long testF7, undefF7, notF7EA,  negF7EA,  muluF7, mulF7, divuwF7, divwF7
	.long testF7, undefF7, notF7EA,  negF7EA,  muluF7, mulF7, divuwF7, divwF7
	.long testF7, undefF7, notF7EA,  negF7EA,  muluF7, mulF7, divuwF7, divwF7
	.long testF7, undefF7, notF7Reg, negF7Reg, muluF7, mulF7, divuwF7, divwF7
;@----------------------------------------------------------------------------
testF7:
	mov r4,r0,lsl#16
	getNextWord
	and16 r0,r4
	fetch 1
;@----------------------------------------------------------------------------
notF7Reg:
	mvn r1,r0
	strh r1,[v30ofs,#v30Regs]
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
notF7EA:
	mvn r1,r0
	bl v30WriteSegOfsW
	ClearSegmentPrefix
	fetch 2
;@----------------------------------------------------------------------------
negF7Reg:
	mov r1,r0,lsl#16
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#16
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	strh r1,[v30ofs,#v30Regs]
	fetch 1
;@----------------------------------------------------------------------------
negF7EA:
	mov r1,r0,lsl#16
	rsbs r1,r1,#0
	mrs v30f,cpsr				;@ S, Z, V & C.
	eor r0,r0,r1,lsr#16
	and r0,r0,#PSR_A
	orr v30f,r0,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	bl v30WriteSegOfsW
	fetch 2
;@----------------------------------------------------------------------------
muluF7:			;@ MULU/MUL
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,v30f,lsr#16
	strh v30f,[v30ptr,#v30RegDW]
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	fetch 3
;@----------------------------------------------------------------------------
muluF7Aswan:	;@ MULU/MUL
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,r2,lsr#16
	strh v30f,[v30ptr,#v30RegDW]
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr r0,v30f,#PSR_Z					;@ Set Z, but not for flags.
	strb r0,[v30ptr,#v30MulOverflow]
	strb r0,[v30ptr,#v30ParityVal]		;@ Clear parity
	fetch 3
;@----------------------------------------------------------------------------
mulF7:			;@ MUL/IMUL
	ldrsh r1,[v30ptr,#v30RegAW]
	mov r0,r0,lsl#16
	mov r0,r0,asr#16
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	mov r1,r2,lsr#16
	strh r1,[v30ptr,#v30RegDW]
	movs v30f,r2,asr#15
	mvnsne v30f,v30f
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
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
	eatCycles 4
	ldrb r0,[v30ptr,#v30IF]
	eors r0,r0,#IRQ_PIN
	strbne r0,[v30ptr,#v30IF]
	bne v30DelayIrqCheck
	fetch 0
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
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	and r5,r0,#0xF8
	ldr pc,[pc,r5,lsr#1]
	nop
	.long incFEEA,  decFEEA,  contFF, contFF, contFF, contFF, contFF, undefFF
	.long incFEEA,  decFEEA,  contFF, contFF, contFF, contFF, contFF, undefFF
	.long incFEEA,  decFEEA,  contFF, contFF, contFF, contFF, contFF, undefFF
	.long incFEReg, decFEReg, contFF, contFF, contFF, contFF, contFF, undefFF

incFEReg:
	ldrb v30ofs,[v30ofs,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	mov r1,r0,lsl#24
	and v30f,v30f,#PSR_C		;@ Only keep C
	adds r1,r1,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF000000
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	strb r1,[v30ptr,-v30ofs]
	fetch 1

decFEReg:
	ldrb v30ofs,[v30ofs,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	mov r1,r0,lsl#24
	and v30f,v30f,#PSR_C		;@ Only keep C
	subs r1,r1,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	strb r1,[v30ptr,-v30ofs]
	fetch 1

incFEEA:
	bl v30ReadEA
	mov r1,r0,lsl#24
	and v30f,v30f,#PSR_C		;@ Only keep C
	adds r1,r1,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF000000
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	bl v30WriteSegOfs
	fetch 3

decFEEA:
	bl v30ReadEA
	mov r1,r0,lsl#24
	and v30f,v30f,#PSR_C		;@ Only keep C
	subs r1,r1,#0x1000000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	bl v30WriteSegOfs
	fetch 3

;@----------------------------------------------------------------------------
i_ffpre:
_FF:	;@ PRE FF
;@----------------------------------------------------------------------------
	getNextByte
contFF:
	cmp r0,#0xC0
	and r5,r0,#0xF8
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]

	ldr pc,[pc,r5,lsr#1]
	nop
	.long incFFEA,  decFFEA,  callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
	.long incFFEA,  decFFEA,  callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
	.long incFFEA,  decFFEA,  callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
	.long incFFReg, decFFReg, callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
;@----------------------------------------------------------------------------
incFFReg:
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r1,r0,lsl#16
	adds r1,r1,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	strh r1,[v30ofs,#v30Regs]
	fetch 1
;@----------------------------------------------------------------------------
incFFEA:
	bl v30ReadEAW_noAdd
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r1,r0,lsl#16
	adds r1,r1,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r1,#0xF0000
	orreq v30f,v30f,#PSR_A
	movs r1,r1,asr#16
	strb r1,[v30ptr,#v30ParityVal]
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
decFFReg:
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r1,r0,lsl#16
	subs r1,r1,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF
	orreq v30f,v30f,#PSR_A
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]
	strh r1,[v30ofs,#v30Regs]
	fetch 1
;@----------------------------------------------------------------------------
decFFEA:
	bl v30ReadEAW_noAdd
	and v30f,v30f,#PSR_C		;@ Only keep C
	mov r1,r0,lsl#16
	subs r1,r1,#0x10000
	orrmi v30f,v30f,#PSR_S
	orreq v30f,v30f,#PSR_Z
	orrvs v30f,v30f,#PSR_V
	tst r0,#0xF
	orreq v30f,v30f,#PSR_A
	movs r1,r1,asr#16
	strb r1,[v30ptr,#v30ParityVal]
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
callFF:
	blmi v30ReadEAW1
	v30DecodeFastPCToReg r1
	mov v30pc,r0,lsl#16
	bl v30PushW
	V30EncodeFastPC
	ClearSegmentPrefix
	fetch 5
;@----------------------------------------------------------------------------
callFarFF:
	bl v30ReadEAW_noAdd
	v30DecodeFastPCToReg r4
	mov v30pc,r0,lsl#16
	add v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW

	ldrh r1,[v30ptr,#v30SRegPS+2]
	strh r0,[v30ptr,#v30SRegPS+2]
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW

	mov r1,r4
	bl v30PushLastW
	V30EncodeFastPC
	ClearSegmentPrefix
	fetch 12
;@----------------------------------------------------------------------------
braFF:
	blmi v30ReadEAW1
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	ClearSegmentPrefix
	fetch 5
;@----------------------------------------------------------------------------
braFarFF:
	bl v30ReadEAW_noAdd
	mov v30pc,r0,lsl#16
	add v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30SRegPS+2]
	v30EncodeFastPC
	ClearSegmentPrefix
	fetch 10
;@----------------------------------------------------------------------------
pushFF:
	blmi v30ReadEAW1
	mov r1,r0
	bl v30PushW
	ClearSegmentPrefix
	fetch 1

;@----------------------------------------------------------------------------
division16:
;@----------------------------------------------------------------------------
	.rept 8
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	.endr
division8:
	.rept 8
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	.endr
	bx lr

;@----------------------------------------------------------------------------
// All EA functions must leave EO (EffectiveOffset) in top 16bits of v30ofs!
;@----------------------------------------------------------------------------
EA_000:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_001:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_002:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_003:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	eatCycles 2
	bx r12
;@----------------------------------------------------------------------------
EA_004:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	bx r12
;@----------------------------------------------------------------------------
EA_005:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	bx r12
;@----------------------------------------------------------------------------
EA_006:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	mov v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_007:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	bx r12
;@----------------------------------------------------------------------------
EA_100:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	TestSegmentPrefix
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
	TestSegmentPrefix
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
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_105:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_106:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBP]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_107:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_200:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r2,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	TestSegmentPrefix
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
	TestSegmentPrefix
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
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_205:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_206:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBP]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_207:	;@
;@----------------------------------------------------------------------------
	getNextWordTo r0, r2
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0,lsl#16
	bx r12
;@----------------------------------------------------------------------------
EA_300:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegAW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_301:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegCW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_302:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegDW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_303:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegBW-2]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_304:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldr r0,[v30ptr,#v30RegSP]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_305:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30RegBP]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_306:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegSS]
	add v30ofs,v30ofs,r0
	bx r12
;@----------------------------------------------------------------------------
EA_307:	;@
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	ldr r0,[v30ptr,#v30RegIY]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
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
	ldr r0,[v30ptr,#v30SRegPS]
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
	movne r0,#IRQ_PIN
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
	bic v30cyc,v30cyc,#HALT_FLAG | TRAP_FLAG

	ldrh r1,[v30ptr,#v30SRegPS+2]
	sub v30ofs,v30ofs,#0x20000
	bl v30WriteSegOfsW
	v30DecodeFastPCToReg r1
	bl v30PushLastW

	mov r0,r4
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	add r0,r4,#0x2000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegPS+2]

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
v30ChkIrqInternal:				;@ This can be used on HALT
	ldr r0,[v30ptr,#v30IrqPin]	;@ NMI, Irq pin and IF
	movs r1,r0,lsr#24
	bne doV30NMI
	ands r1,r0,r0,lsr#8
	bne V30FetchIRQ
	tst v30cyc,#HALT_FLAG | TRAP_FLAG
	bne v30InHaltTrap
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
	fetch 0
v30InHaltTrap:
	tst v30cyc,#TRAP_FLAG
	bne doV30Trap
	tst r0,#IRQ_PIN				;@ IRQ Pin ?
	bicne v30cyc,v30cyc,#HALT_FLAG
	bne V30Go
	mvns r0,v30cyc,asr#CYC_SHIFT			;@
	addmi v30cyc,v30cyc,r0,lsl#CYC_SHIFT	;@ Consume all remaining cycles in steps of 1.
v30OutOfCycles:
	mov v30cyc,v30cyc,lsl#2		;@ Check for delayed irq check.
	movs v30cyc,v30cyc,asr#2
	bgt v30ChkIrqInternal
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
v30DelayIrqCheck:			;@ This can be used on EI/IRET/POPF
;@----------------------------------------------------------------------------
	orr v30cyc,v30cyc,#0xC0000000
	executeNext
;@----------------------------------------------------------------------------
#ifdef GBA
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
	bx lr
;@----------------------------------------------------------------------------
doV30Trap:
;@----------------------------------------------------------------------------
	eatCycles 1
	mov r0,#1
	b nec_interrupt
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
	ClearSegmentPrefix
	fetch 1
;@----------------------------------------------------------------------------
i_crash:
;@----------------------------------------------------------------------------
	mov r11,r11					;@ NoCash breakpoint
	ldr r0,=debugCrashInstruction
	mov lr,pc
	bx r0

	sub v30pc,v30pc,#1
	and v30cyc,v30cyc,#CYC_MASK
	b v30OutOfCycles
;@----------------------------------------------------------------------------
V30IrqVectorDummy:
;@----------------------------------------------------------------------------
	mov r0,#0
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

	;@ Clear CPU state, PC, DS1, DS0 & SS are set to 0x0000,
	;@ AW, BW, CW, DW, SP, BP, IX & IY are undefined.
	;@ CS is set to 0xFFFF
	add r0,v30ptr,#v30I
	mov r1,#(v30IEnd-v30I)/4
	bl memclr_

	ldr r0,=0xFFFF0000
	str r0,[v30ptr,#v30SRegPS]
	mov r0,#v30PZST
	strh r0,[v30ptr,#v30ParityVal]
	mov r0,#1
	strb r0,[v30ptr,#v30DF]

	mov v30pc,#0
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30PC]

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
V30SaveState:				;@ In r0=destination, r1=v30ptr. Out r0=size.
	.type V30SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,v30pc,v30ptr,lr}

	sub r4,r0,#v30I
	mov v30ptr,r1

	add r1,v30ptr,#v30I
	mov r2,#v30StateEnd-v30StateStart
	bl memcpy

	;@ Convert copied PC to not offseted.
	ldr v30pc,[r4,#v30PC]				;@ Offseted v30pc
	v30DecodeFastPC
	str v30pc,[r4,#v30PC]				;@ Normal v30pc

	ldmfd sp!,{r4,v30pc,v30ptr,lr}
	mov r0,#v30StateEnd-v30StateStart
	bx lr
;@----------------------------------------------------------------------------
V30LoadState:				;@ In r0=v30ptr, r1=source. Out r0=size.
	.type V30LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{v30pc,v30ptr,lr}

	mov v30ptr,r0
	add r0,v30ptr,#v30I
	mov r2,#v30StateEnd-v30StateStart
	bl memcpy

	ldr v30pc,[v30ptr,#v30PC]			;@ Normal v30pc
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30PC]			;@ Rewrite offseted v30pc

	ldmfd sp!,{v30pc,v30ptr,lr}
;@----------------------------------------------------------------------------
V30GetStateSize:			;@ Out r0=state size.
	.type V30GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#v30StateEnd-v30StateStart
	bx lr
;@----------------------------------------------------------------------------
V30RedirectOpcode:			;@ In r0=opcode, r1=address.
	.type V30RedirectOpcode STT_FUNC
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
	.space 19*4
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
	.long i_add_awd16
	.long i_push_ds1
	.long i_pop_ds1
	.long i_or_br8
	.long i_or_wr16
	.long i_or_r8b
	.long i_or_r16w
	.long i_or_ald8
	.long i_or_awd16
	.long i_push_ps
	.long i_undefined
	.long i_adc_br8
	.long i_adc_wr16
	.long i_adc_r8b
	.long i_adc_r16w
	.long i_adc_ald8
	.long i_adc_awd16
	.long i_push_ss
	.long i_pop_ss
	.long i_sbb_br8
	.long i_sbb_wr16
	.long i_sbb_r8b
	.long i_sbb_r16w
	.long i_sbb_ald8
	.long i_sbb_awd16
	.long i_push_ds0
	.long i_pop_ds0
	.long i_and_br8
	.long i_and_wr16
	.long i_and_r8b
	.long i_and_r16w
	.long i_and_ald8
	.long i_and_awd16
	.long i_ds1
	.long i_daa
	.long i_sub_br8
	.long i_sub_wr16
	.long i_sub_r8b
	.long i_sub_r16w
	.long i_sub_ald8
	.long i_sub_awd16
	.long i_ps
	.long i_das
	.long i_xor_br8
	.long i_xor_wr16
	.long i_xor_r8b
	.long i_xor_r16w
	.long i_xor_ald8
	.long i_xor_awd16
	.long i_ss
	.long i_aaa
	.long i_cmp_br8
	.long i_cmp_wr16
	.long i_cmp_r8b
	.long i_cmp_r16w
	.long i_cmp_ald8
	.long i_cmp_awd16
	.long i_ds0
	.long i_aas
	.long i_inc_aw
	.long i_inc_cw
	.long i_inc_dw
	.long i_inc_bw
	.long i_inc_sp
	.long i_inc_bp
	.long i_inc_ix
	.long i_inc_iy
	.long i_dec_aw
	.long i_dec_cw
	.long i_dec_dw
	.long i_dec_bw
	.long i_dec_sp
	.long i_dec_bp
	.long i_dec_ix
	.long i_dec_iy
	.long i_push_aw
	.long i_push_cw
	.long i_push_dw
	.long i_push_bw
	.long i_push_sp
	.long i_push_bp
	.long i_push_ix
	.long i_push_iy
	.long i_pop_aw
	.long i_pop_cw
	.long i_pop_dw
	.long i_pop_bw
	.long i_pop_sp
	.long i_pop_bp
	.long i_pop_ix
	.long i_pop_iy
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
	.long i_xchg_awcw
	.long i_xchg_awdw
	.long i_xchg_awbw
	.long i_xchg_awsp
	.long i_xchg_awbp
	.long i_xchg_awix
	.long i_xchg_awiy
	.long i_cbw
	.long i_cwd
	.long i_call_far
	.long i_poll
	.long i_pushf
	.long i_popf
	.long i_sahf
	.long i_lahf
	.long i_mov_aldisp
	.long i_mov_awdisp
	.long i_mov_dispal
	.long i_mov_dispaw
	.long i_movsb
	.long i_movsw
	.long i_cmpsb
	.long i_cmpsw
	.long i_test_ald8
	.long i_test_awd16
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
	.long i_mov_awd16
	.long i_mov_cwd16
	.long i_mov_dwd16
	.long i_mov_bwd16
	.long i_mov_spd16
	.long i_mov_bpd16
	.long i_mov_ixd16
	.long i_mov_iyd16
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
	.long i_bcwz
	.long i_inal
	.long i_inaw
	.long i_outal
	.long i_outaw
	.long i_call_d16
	.long i_jmp_d16
	.long i_jmp_far
	.long i_br_d8
	.long i_inaldw
	.long i_inawdw
	.long i_outdwal
	.long i_outdwaw
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
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte      0,      0, SEG_PF,      0,      0,      0,      0,      0,      0, SEG_PF,      0, SEG_PF,      0,      0, SEG_PF, SEG_PF
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0, SEG_PF, SEG_PF
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0, SEG_PF, SEG_PF,      0,      0
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF,      0,      0, SEG_PF, SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0,      0,      0,      0,      0
	.byte SEG_PF, SEG_PF, SEG_PF, SEG_PF,      0,      0,      0, SEG_PF,      0,      0,      0,      0,      0,      0,      0,      0
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0
	.byte      0,      0, SEG_PF, SEG_PF,      0,      0, SEG_PF, SEG_PF,      0,      0,      0,      0,      0,      0, SEG_PF, SEG_PF
;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
