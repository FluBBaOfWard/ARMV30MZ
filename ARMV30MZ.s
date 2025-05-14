//
//  ARMV30MZ.s
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-12-19.
//  Copyright © 2021-2025 Fredrik Ahlström. All rights reserved.
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

add80Reg:
	ldrb r1,[v30ptr,-r3]
	add8 r1,r4
	strb r1,[v30ptr,-r3]
	fetch 1

add80EA:
	getNextByteTo r4
0:
	add8 r0,r4
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_add_wr16:
_01:	;@ ADD WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	add16 r4,r0,0
	str r1,[r3,r5,lsr#27]
	fetch 1
add81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	add16 r4,r0,0
	str r1,[v30ofs,#v30Regs2]
	fetch 1
add83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
add81EA:
0:
	add16 r4,r0
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_add_r8b:
_02:	;@ ADD R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	add8 r1,r0
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_add_r16w:
_03:	;@ ADD R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	add16 r1,r0
	str r1,[r4,r5,lsr#1]
	fetch 1
;@----------------------------------------------------------------------------
i_add_ald8:
_04:	;@ ADD ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	add8 r1,r0
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_add_awd16:
_05:	;@ ADD AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	add16 r1,r0
	str r1,[v30ptr,#v30RegAW-2]
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

or80Reg:
	ldrb r0,[v30ptr,-r3]
	or8 r4,r0
	strb r1,[v30ptr,-r3]
	fetch 1

or80EA:
	getNextByteTo r4
0:
	or8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_or_wr16:
_09:	;@ OR WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	or16 r4,r0,"str v30f,[r3,r5,lsr#27]",0
	fetch 1
or81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	or16 r4,r0,"str v30f,[v30ofs,#v30Regs2]",0
	fetch 1
or83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
or81EA:
0:
	or16 r4,r0
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_or_r8b:
_0A:	;@ OR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r3,r4,#0xff
	ldrbne r0,[v30ptr,-r3]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	or8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_or_r16w:
_0B:	;@ OR R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	or16 r1,r0,"str v30f,[r4,r5,lsr#1]"
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
	or16 r1,r0,"str v30f,[v30ptr,#v30RegAW-2]"
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

adc80Reg:
	ldrb r0,[v30ptr,-r3]
	adc8 r4,r0
	strb r1,[v30ptr,-r3]
	fetch 1

adc80EA:
	getNextByteTo r4
0:
	adc8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_adc_wr16:
_11:	;@ ADDC/ADC WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
adc81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldrh r0,[v30ofs,#v30Regs]
	adc16 r4,r0
	str r1,[v30ofs,#v30Regs2]
	fetch 1
adc83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
adc81EA:
0:
	adc16 r4,r0
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_adc_r8b:
_12:	;@ ADDC/ADC R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	adc8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_adc_r16w:
_13:	;@ ADDC/ADC R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	adc16 r1,r0
	str r1,[r4,r5,lsr#1]
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
	adc16 r1,r0
	str r1,[v30ptr,#v30RegAW-2]
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
	fetchForce 3				;@ No interrupt directly after this instruction
;@----------------------------------------------------------------------------
i_sbb_br8:
_18:	;@ SUBC/SBB BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

subc80Reg:
	ldrb r0,[v30ptr,-r3]
	subc8 r0,r4
	strb r1,[v30ptr,-r3]
	fetch 1

subc80EA:
	getNextByteTo r4
0:
	subc8 r0,r4
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_wr16:
_19:	;@ SUBC/SBB WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
subc81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldrh r0,[v30ofs,#v30Regs]
	rsbc16 r0,r4
	str r1,[v30ofs,#v30Regs2]
	fetch 1
subc83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
subc81EA:
0:
	rsbc16 r0,r4
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_sbb_r8b:
_1A:	;@ SUBC/SBB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	subc8 r1,r0
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_r16w:
_1B:	;@ SUBC/SBB R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	subc16 r1,r0
	str r1,[r4,r5,lsr#1]
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_ald8:
_1C:	;@ SUBC/SBB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	subc8 r1,r0
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_sbb_awd16:
_1D:	;@ SUBC/SBB AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	subc16 r1,r0
	str r1,[v30ptr,#v30RegAW-2]
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

and80Reg:
	ldrb r0,[v30ptr,-r3]
	and8 r4,r0
	strb r1,[v30ptr,-r3]
	fetch 1

and80EA:
	getNextByteTo r4
0:
	and8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_and_wr16:
_21:	;@ AND WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	and16 r4,r0,"str v30f,[r3,r5,lsr#27]",0
	fetch 1
and81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	and16 r4,r0,"str v30f,[v30ofs,#v30Regs2]",0
	fetch 1
and83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
and81EA:
0:
	and16 r4,r0
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_and_r8b:
_22:	;@ AND R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	and8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_and_r16w:
_23:	;@ AND R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	and16 r1,r0,"str v30f,[r4,r5,lsr#1]"
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
	and16 r1,r0,"str v30f,[v30ptr,#v30RegAW-2]"
	fetch 1
;@----------------------------------------------------------------------------
i_ds1:
_26:	;@ DS1/ES prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegDS1]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetSegmentPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear prefixes if not applicable
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
	movs r2,v30f,lsr#2			;@ Test PSR_C & PSR_A
	biceq r1,r1,#0x06000000
	cmncc r1,r0,lsl#24
	biccc r1,r1,#0x60000000
	adds r0,r1,r0,lsl#24
	mrs r1,cpsr					;@ S, Z, C & V.
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

sub80Reg:
	ldrb r0,[v30ptr,-r3]
	sub8 r0,r4
	strb r1,[v30ptr,-r3]
	fetch 1

sub80EA:
	getNextByteTo r4
0:
	sub8 r0,r4
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_sub_wr16:
_29:	;@ SUB WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	rsb16 r0,r4,0
	str r1,[r3,r5,lsr#27]
	fetch 1
sub81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	rsb16 r0,r4,0
	str r1,[v30ofs,#v30Regs2]
	fetch 1
sub83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
sub81EA:
0:
	rsb16 r0,r4
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_sub_r8b:
_2A:	;@ SUB R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	sub8 r1,r0
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_sub_r16w:
_2B:	;@ SUB R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	sub16 r1,r0
	str r1,[r4,r5,lsr#1]
	fetch 1
;@----------------------------------------------------------------------------
i_sub_ald8:
_2C:	;@ SUB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r1,r0
	strb r1,[v30ptr,#v30RegAL]
	fetch 1
;@----------------------------------------------------------------------------
i_sub_awd16:
_2D:	;@ SUB AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r1,r0
	str r1,[v30ptr,#v30RegAW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_ps:
_2E:	;@ PS/CS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegPS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetSegmentPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear prefixes if not applicable
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
;@----------------------------------------------------------------------------
i_das:
_2F:	;@ ADJ4S/DAS
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	and v30f,v30f,#PSR_A|PSR_C
	mov r1,#0x66000000
	cmn r1,r0,lsl#28
	orrcs v30f,v30f,#PSR_A
	movs r2,v30f,lsr#2			;@ Test PSR_C & PSR_A
	biceq r1,r1,#0x06000000
	cmncc r1,r0,lsl#24
	orrcs v30f,v30f,#PSR_C
	biccc r1,r1,#0x60000000
	rsbs r0,r1,r0,lsl#24
	mrs r1,cpsr					;@ S, Z, C & V.
	bic r1,r1,#PSR_C<<28
	orr v30f,v30f,r1,lsr#28
	mov r0,r0,lsr#24
	strb r0,[v30ptr,#v30RegAL]
	strb r0,[v30ptr,#v30ParityVal]
	fetch 11
;@----------------------------------------------------------------------------
i_xor_br8:
_30:	;@ XOR BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

xor80Reg:
	ldrb r0,[v30ptr,-r3]
	xor8 r4,r0
	strb r1,[v30ptr,-r3]
	fetch 1

xor80EA:
	getNextByteTo r4
0:
	xor8 r4,r0
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_xor_wr16:
_31:	;@ XOR WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	xor16 r4,r0,"str v30f,[r3,r5,lsr#27]",0
	fetch 1
xor81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	xor16 r4,r0,"str v30f,[v30ofs,#v30Regs2]",0
	fetch 1
xor83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
xor81EA:
0:
	xor16 r4,r0
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
i_xor_r8b:
_32:	;@ XOR R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	xor8 r0,r1
	strb r1,[v30ptr,-r4,lsr#24]
	fetch 1
;@----------------------------------------------------------------------------
i_xor_r16w:
_33:	;@ XOR R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	xor16 r1,r0,"str v30f,[r4,r5,lsr#1]"
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
	xor16 r1,r0,"str v30f,[v30ptr,#v30RegAW-2]"
	fetch 1
;@----------------------------------------------------------------------------
i_ss:
_36:	;@ SS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegSS]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetSegmentPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear prefixes if not applicable
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
	adr lr,0f
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r3,r1,#0xff
	beq v30ReadEA

cmp80Reg:
	ldrb r0,[v30ptr,-r3]
	sub8 r0,r4
	fetch 1

cmp80EA:
	getNextByteTo r4
0:
	sub8 r0,r4
	fetch 2
;@----------------------------------------------------------------------------
i_cmp_wr16:
_39:	;@ CMP WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r3,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r3,r1,lsr#1]
	adr lr,0f
	cmp r0,#0xC0
	bmi v30ReadEAW
	mov r5,r0,ror#3
	ldr r0,[r3,r5,lsr#27]
	rsb16 r0,r4,0
	fetch 1
cmp81Reg:
	add v30ofs,v30ptr,r5,lsr#27
	ldr r0,[v30ofs,#v30Regs2]
	rsb16 r0,r4,0
	fetch 1
cmp83EA:
	getNextSignedByteTo r4
	mov r4,r4,lsl#16
cmp81EA:
0:
	rsb16 r0,r4
	fetch 2
;@----------------------------------------------------------------------------
i_cmp_r8b:
_3A:	;@ CMP R8b
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	ldrb r1,[v30ptr,-r4,lsr#24]
	sub8 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_r16w:
_3B:	;@ CMP R16W
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	ldr r1,[r4,r5,lsr#1]
	sub16 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_ald8:
_3C:	;@ CMP ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
i_cmp_awd16:
_3D:	;@ CMP AWD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
i_ds0:
_3E:	;@ DS0/DS prefix
;@----------------------------------------------------------------------------
	ldr v30csr,[v30ptr,#v30SRegDS0]

	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetSegmentPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear prefixes if not applicable
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
	subcs r0,r0,#0x0016
	bic r0,r0,#0x00F0
	strh r0,[v30ptr,#v30RegAW]
	fetch 9

;@----------------------------------------------------------------------------
i_inc_aw:
_40:	;@ INC AW/AX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegAW-2]
	incWord
	str r1,[v30ptr,#v30RegAW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_cw:
_41:	;@ INC CW/CX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegCW-2]
	incWord
	str r1,[v30ptr,#v30RegCW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_dw:
_42:	;@ INC DW/DX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegDW-2]
	incWord
	str r1,[v30ptr,#v30RegDW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_bw:
_43:	;@ INC BW/BX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegBW-2]
	incWord
	str r1,[v30ptr,#v30RegBW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_sp:
_44:	;@ INC SP
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegSP]
	incWord
	str r1,[v30ptr,#v30RegSP]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_bp:
_45:	;@ INC BP
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegBP]
	incWord
	str r1,[v30ptr,#v30RegBP]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_ix:
_46:	;@ INC IX/SI
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegIX]
	incWord
	str r1,[v30ptr,#v30RegIX]
	fetch 1
;@----------------------------------------------------------------------------
i_inc_iy:
_47:	;@ INC IY/DI
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegIY]
	incWord
	str r1,[v30ptr,#v30RegIY]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_aw:
_48:	;@ DEC AW/AX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegAW-2]
	decWord
	str r1,[v30ptr,#v30RegAW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_cw:
_49:	;@ DEC CW/CX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegCW-2]
	decWord
	str r1,[v30ptr,#v30RegCW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_dw:
_4A:	;@ DEC DW/DX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegDW-2]
	decWord
	str r1,[v30ptr,#v30RegDW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_bw:
_4B:	;@ DEC BW/BX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegBW-2]
	decWord
	str r1,[v30ptr,#v30RegBW-2]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_sp:
_4C:	;@ DEC SP
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegSP]
	decWord
	str r1,[v30ptr,#v30RegSP]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_bp:
_4D:	;@ DEC BP
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegBP]
	decWord
	str r1,[v30ptr,#v30RegBP]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_ix:
_4E:	;@ DEC IX/SI
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegIX]
	decWord
	str r1,[v30ptr,#v30RegIX]
	fetch 1
;@----------------------------------------------------------------------------
i_dec_iy:
_4F:	;@ DEC IY/DI
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegIY]
	decWord
	str r1,[v30ptr,#v30RegIY]
	fetch 1
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
	add r2,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r2,r1,lsr#1]
	bl v30ReadEAW
	add v30ofs,v30ofs,#0x20000
	mov r5,r0,lsl#16
	bl v30ReadSegOfsW
	ClearPrefixes
	cmp r5,r4
	cmple r4,r0,lsl#16
	subgt v30cyc,v30cyc,#20*CYCLE
	movgt r0,#5
	bgt V30TakeIRQ
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
	ldrshpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1
	mov r0,r0,lsl#16
	mov r0,r0,asr#16

	getNextSignedWordto r1, r2

	mul r2,r0,r1
	mov r1,r2,asr#16
	eors v30f,r1,r2,asr#15
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
	ldrshpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1
	mov r0,r0,lsl#16
	mov r0,r0,asr#16

	getNextSignedByteTo r1

	mul r2,r0,r1
	mov r1,r2,asr#16
	eors v30f,r1,r2,asr#15
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
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_inmb:
_6C:	;@ INMB/INSB
;@----------------------------------------------------------------------------
	TestRepeatPrefix
	bne f36c
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
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_inmw:
_6D:	;@ INMW/INSW
;@----------------------------------------------------------------------------
	TestRepeatPrefix
	bne f36d
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
	TestRepeatPrefix
	bne f36e
	bl v30ReadDsIx
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort
	ClearPrefixes
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
	TestRepeatPrefix
	bne f36f
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	ldrh r1,[v30ptr,#v30RegDW]
	bl v30WritePort16
	ClearPrefixes
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
	ldrb r2,[v30ptr,#v30ParityVal]
	orr r2,r2,#v30PZST
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
	ldrb r2,[v30ptr,#v30ParityVal]
	orr r2,r2,#v30PZST
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
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addlt v30pc,v30pc,r0
	sublt v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	fetch 1
;@----------------------------------------------------------------------------
i_bge:
_7D:	;@ BGE. Branch if Greater than or Equal, S ^ V = 0.
		;@ JNL/JGE. Jump if Not Less/Greater or Equal (SF=OF)
;@----------------------------------------------------------------------------
	getNextSignedByte
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addge v30pc,v30pc,r0
	subge v30cyc,v30cyc,#3*CYCLE
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
	bic r1,v30ofs,#0x1f
	ldr lr,[r1,#v3080Table]
	cmp r0,#0xC0
	bmi v30ReadEA
	ldrb r3,[v30ofs,#v30ModRmRm]

	getNextByteTo r4
	bx lr

;@----------------------------------------------------------------------------
i_81pre:
_81:	;@ PRE 81
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	mov r5,r0,ror#3
	blmi v30ReadEAW

	getNextWordTo r4, r1
	mov r4,r4,lsl#16

	ldr pc,[pc,r5,lsl#3]
	nop
_81Table:
	.long add81EA,0,  or81EA,0,  adc81EA,0,  subc81EA,0,  and81EA,0,  sub81EA,0,  xor81EA,0,  cmp81EA,0
	.long add81EA,0,  or81EA,0,  adc81EA,0,  subc81EA,0,  and81EA,0,  sub81EA,0,  xor81EA,0,  cmp81EA,0
	.long add81EA,0,  or81EA,0,  adc81EA,0,  subc81EA,0,  and81EA,0,  sub81EA,0,  xor81EA,0,  cmp81EA,0
	.long add81Reg,0, or81Reg,0, adc81Reg,0, subc81Reg,0, and81Reg,0, sub81Reg,0, xor81Reg,0, cmp81Reg,0

;@----------------------------------------------------------------------------
i_83pre:
_83:	;@ PRE 83
;@----------------------------------------------------------------------------
	getNextByte
	cmp r0,#0xC0
	mov r5,r0,ror#3
	blmi v30ReadEAW

	getNextSignedByteTo r4
	mov r4,r4,lsl#16

	adr r2,_81Table
	ldr pc,[r2,r5,lsl#3]
;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r1,[v30ofs,#v30ModRmReg]
	ldrb r4,[v30ptr,-r1,lsr#24]
	ands r1,r1,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA1

	and8 r4,r0
	fetch 1
;@----------------------------------------------------------------------------
i_test_wr16:
_85:	;@ TEST WR16
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,#v30Regs2
	and r1,r0,#0x38
	ldr r4,[r2,r1,lsr#1]
	cmp r0,#0xC0
	andpl r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW1

	tst16 r4,r0
	fetch 1
;@----------------------------------------------------------------------------
i_xchg_br8:
_86:	;@ XCH/XCHG BR8
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]
	adr lr,0f
	ands r2,r4,#0xff
	beq v30ReadEA

	ldrb r0,[v30ptr,-r2]
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	strb r1,[v30ptr,-r2]
	ClearPrefixes
	fetch 3
0:
	ldrb r1,[v30ptr,-r4,lsr#24]
	strb r0,[v30ptr,-r4,lsr#24]
	bl v30WriteSegOfs
	ClearPrefixes
	fetch 5

;@----------------------------------------------------------------------------
i_xchg_wr16:
_87:	;@ XCH/XCHG WR16
;@----------------------------------------------------------------------------
	getNextByte
	adr lr,0f
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi v30ReadEAW

	mov r5,r0,ror#3
	add v30ofs,v30ptr,#v30Regs2
	ldr r0,[v30ofs,r5,lsr#27]
	ldr r1,[v30ofs,r4,lsr#1]
	str r0,[v30ofs,r4,lsr#1]
	str r1,[v30ofs,r5,lsr#27]
	ClearPrefixes
	fetch 3
0:
	add r4,v30ptr,r4,lsr#1
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	bl v30WriteSegOfsW
	ClearPrefixes
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
	ldrb r1,[v30ptr,-r3,lsr#24]

	ands r3,r3,#0xff
	strbne r1,[v30ptr,-r3]
	bleq v30WriteEA
	ClearPrefixes
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
	ClearPrefixes
	fetch 1
;@----------------------------------------------------------------------------
i_mov_r8b:
_8A:	;@ MOV R8B
;@----------------------------------------------------------------------------
	getNextByte
	add v30ofs,v30ptr,r0,lsl#2
	ldr r4,[v30ofs,#v30ModRmReg]

	ands r1,r4,#0xff
	ldrbne r0,[v30ptr,-r1]
	bleq v30ReadEA
	strb r0,[v30ptr,-r4,lsr#24]
	ClearPrefixes
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
	ClearPrefixes
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
	ClearPrefixes
	fetch 1
;@----------------------------------------------------------------------------
i_lea:
_8D:	;@ LDEA/LEA
;@----------------------------------------------------------------------------
	getNextByte
	add r4,v30ptr,#v30Regs2
	and r5,r0,#0x38
//	tst r0,#4					;@ 2 reg ModRm? LEA, LES & LDS don't take 2 extra cycles, just one.
//	addeq v30cyc,v30cyc,#1*CYCLE
	add v30ofs,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]	;@ EATable return EO in v30ofs
	str v30ofs,[r4,r5,lsr#1]
	fetch 1
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x18				;@ This is correct.
	add r4,v30ptr,r4,lsr#1
	ldr lr,[r4,#v30SRegTable]
	cmp r0,#0xC0
	bmi v30ReadEAWF7
	and r0,r0,#7
	add v30ofs,v30ptr,r0,lsl#2
	ldrh r0,[v30ofs,#v30Regs]
	bx lr

movSRegPS:
	ClearPrefixes
	strh r0,[r4,#v30SRegs+2]
	bl V30ReEncodePC
	fetch 2
movSRegDS:
	ClearPrefixes
	strh r0,[r4,#v30SRegs+2]
	fetch 2
movSRegSS:
	ClearPrefixes
	strh r0,[r4,#v30SRegs+2]
	fetchForce 2
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
	ClearPrefixes
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
	ldrb r2,[v30ptr,#v30ParityVal]
	ldr r1,=0xF002
	orr r2,r2,#v30PZST
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
	and v30f,r0,#SF|ZF
	mov v30f,v30f,lsr#4
	tst r0,#AF
	orrne v30f,v30f,#PSR_A
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	movs r1,r0,lsl#21			;@ Check OF & DF
	orrcs v30f,v30f,#PSR_V
	movpl r1,#1
	movmi r1,#-1
	strb r1,[v30ptr,#v30DF]
	ands r1,r0,#IF
	movne r1,#IRQ_PIN
	ldrb r2,[v30ptr,#v30IF]
	eors r2,r2,r1
	strbne r1,[v30ptr,#v30IF]
	tst r0,#TF					;@ Check if Trap is set...
	orrne v30cyc,v30cyc,#TRAP_FLAG
	tsteq r2,r1					;@ or if Interrupt became enabled.
	eatCycles 3
	bne v30DelayIrqCheck
	fetch 0
;@----------------------------------------------------------------------------
i_sahf:
_9E:	;@ SAHF					Store AH to Flags
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAH]

	and v30f,v30f,#PSR_V		;@ Keep V.
	and r1,r0,#PF
	eor r1,r1,#PF
	strb r1,[v30ptr,#v30ParityVal]
	and r1,r0,#SF|ZF
	orr v30f,v30f,r1,lsr#4
	tst r0,#CF
	orrne v30f,v30f,#PSR_C
	tst r0,#AF
	orrne v30f,v30f,#PSR_A

	fetch 4
;@----------------------------------------------------------------------------
i_lahf:
_9F:	;@ LAHF					Load AH from Flags
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30ParityVal]
	and r0,v30f,#PSR_S|PSR_Z
	mov r0,r0,lsl#4
	orr r2,r2,#v30PZST
	ldrb r2,[v30ptr,r2]
	orr r0,r0,#0x02
	tst v30f,#PSR_A
	orrne r0,r0,#AF
	tst v30f,#PSR_C
	orrne r0,r0,#CF
	tst r2,#PSR_P
	orrne r0,r0,#PF

	strb r0,[v30ptr,#v30RegAH]
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
	ClearPrefixes
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
	ClearPrefixes
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
	ClearPrefixes
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
	ClearPrefixes
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
	TestRepeatPrefix
	bne f3a4
	bl v30ReadDsIx
	mov r1,r0
	bl v30WriteEsIy
	ClearPrefixes
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
	TestRepeatPrefix
	bne f3a5
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
	ClearPrefixes
	fetch 5

;@----------------------------------------------------------------------------
f2a6:	;@ REPNE CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
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

	sub8 r4,r0

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
repZero:
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
f3a6:	;@ REPE CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
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

	sub8 r4,r0

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsb:
_A6:	;@ CMPBKB/CMPSB
;@----------------------------------------------------------------------------
	TestRepeatEPrefix
	bne f3a6
	TestRepeatNEPrefix
	bne f2a6
	bl v30ReadDsIx

	GetIyOfsESegment
	add r2,v30ofs,r4,lsl#16
	mov r4,r0
	str r2,[v30ptr,#v30RegIY]
	bl v30ReadSegOfs

	sub8 r4,r0					;@ sub8 clears prefixes

	fetch 6

;@----------------------------------------------------------------------------
f2a7:	;@ REPNE CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
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

	sub16 r4,r0

	eatCycles 10
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
f3a7:	;@ REPE CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
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

	sub16 r4,r0

	eatCycles 10
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIX]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
i_cmpsw:
_A7:	;@ CMPBKW/CMPSW
;@----------------------------------------------------------------------------
	TestRepeatEPrefix
	bne f3a7
	TestRepeatNEPrefix
	bne f2a7
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

	sub16 r4,r0					;@ sub16 clears prefixes

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
	tst16 r1,r0
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
	ClearPrefixes
	fetch 5
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STMB/STOSB
;@----------------------------------------------------------------------------
	TestRepeatPrefix
	bne f3aa
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
	ClearPrefixes
	fetch 5
breakRep:
	sub r5,r5,#1
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	sub v30pc,v30pc,#2
	ClearPrefixes
	b v30OutOfCycles
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STMW/STOSW
;@----------------------------------------------------------------------------
	TestRepeatPrefix
	bne f3ab
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
	TestRepeatPrefix
	bne f3ac
	bl v30ReadDsIx
	strb r0,[v30ptr,#v30RegAL]
	ClearPrefixes
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
	TestRepeatPrefix
	bne f3ad
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldr v30ofs,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIX]
	strh r0,[v30ptr,#v30RegAW]
	ClearPrefixes
	fetch 3

;@----------------------------------------------------------------------------
f2ae:	;@ REPNE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r1,r0

	eatCycles 9
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
f3ae:	;@ REPE CMPMB/SCASB
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r1,r0

	eatCycles 9
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
i_scasb:
_AE:	;@ CMPMB/SCASB
;@----------------------------------------------------------------------------
	TestRepeatEPrefix
	bne f3ae
	TestRepeatNEPrefix
	bne f2ae
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfs
	add v30ofs,v30ofs,r4,lsl#16
	str v30ofs,[v30ptr,#v30RegIY]
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r1,r0

	fetch 4

;@----------------------------------------------------------------------------
f2af:	;@ REPNE CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r1,r0

	eatCycles 9
	subs r5,r5,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
f3af:	;@ REPE CMPMW/SCASW
;@----------------------------------------------------------------------------
	ldrh r5,[v30ptr,#v30RegCW]
	cmp r5,#0
	beq repZero
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
0:
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r1,r0

	eatCycles 9
	subs r5,r5,#1
	tstne v30f,#PSR_Z
	bne 0b
	str v30ofs,[v30ptr,#v30RegIY]
	strh r5,[v30ptr,#v30RegCW]
	fetch 5
;@----------------------------------------------------------------------------
i_scasw:
_AF:	;@ CMPMW/SCASW
;@----------------------------------------------------------------------------
	TestRepeatEPrefix
	bne f3af
	TestRepeatNEPrefix
	bne f2af
	GetIyOfsESegment
	ldrsb r4,[v30ptr,#v30DF]
	bl v30ReadSegOfsW
	add v30ofs,v30ofs,r4,lsl#17
	str v30ofs,[v30ptr,#v30RegIY]
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r1,r0

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
	eatCycles 2
	add v30ofs,v30ptr,r0,lsl#2
	cmp r0,#0xC0
	bic r5,v30ofs,#0x1f
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	ldrbpl r0,[v30ptr,-v30ofs]
	blmi v30ReadEA

	getNextByteTo r4
	and r4,r4,#0x1F

	ldr pc,[r5,#v30C0Table]

rolC0Reg:
	rol8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rorC0Reg:
	ror8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rolcC0Reg:
	rolc8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
rorcC0Reg:
	rorc8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
shlC0Reg:
	shl8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
shrC0Reg:
	shr8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1
undC0Reg:
	bl logUndefinedOpcode
	mov r1,#0
	strb r1,[v30ptr,-v30ofs]
	ClearPrefixes
	fetch 1
shraC0Reg:
	shra8 r0,r4
	strb r1,[v30ptr,-v30ofs]
	fetch 1

rolC0EA:
	rol8 r0,r4
	bl v30WriteSegOfs
	fetch 3
rorC0EA:
	ror8 r0,r4
	bl v30WriteSegOfs
	fetch 3
rolcC0EA:
	rolc8 r0,r4
	bl v30WriteSegOfs
	fetch 3
rorcC0EA:
	rorc8 r0,r4
	bl v30WriteSegOfs
	fetch 3
shlC0EA:
	shl8 r0,r4
	bl v30WriteSegOfs
	fetch 3
shrC0EA:
	shr8 r0,r4
	bl v30WriteSegOfs
	fetch 3
undC0EA:
	bl logUndefinedOpcode
	mov r1,#0
	bl v30WriteSegOfs
	ClearPrefixes
	fetch 3
shraC0EA:
	shra8 r0,r4
	bl v30WriteSegOfs
	fetch 3
;@----------------------------------------------------------------------------
i_rotshft_wd8:
_C1:	;@ ROTSHFT WD8
;@----------------------------------------------------------------------------
	getNextByte
	eatCycles 2
	cmp r0,#0xC0
	mov r5,r0,ror#3
	addpl v30ofs,v30ptr,r5,lsr#27
	ldrhpl r0,[v30ofs,#v30Regs]
	blmi v30ReadEAW

	getNextByteTo r4
	add r2,v30ptr,r5,lsl#5
	and r4,r4,#0x1F

	ldr pc,[r2,#v30C1Table]

rolC1Reg:
	rol16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rorC1Reg:
	ror16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rolcC1Reg:
	rolc16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
rorcC1Reg:
	rorc16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
shlC1Reg:
	shl16 r0,r4
	str r1,[v30ofs,#v30Regs2]
	fetch 1
shrC1Reg:
	shr16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1
undC1Reg:
	bl logUndefinedOpcode
	mov r1,#0
	strh r1,[v30ofs,#v30Regs]
	ClearPrefixes
	fetch 1
shraC1Reg:
	shra16 r0,r4
	strh r1,[v30ofs,#v30Regs]
	fetch 1

rolC1EA:
	rol16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
rorC1EA:
	ror16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
rolcC1EA:
	rolc16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
rorcC1EA:
	rorc16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
shlC1EA:
	shl16 r0,r4
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
shrC1EA:
	shr16 r0,r4
	bl v30WriteSegOfsW
	fetch 3
undC1EA:
	bl logUndefinedOpcode
	mov r1,#0
	bl v30WriteSegOfsW
	ClearPrefixes
	fetch 3
shraC1EA:
	shra16 r0,r4
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

	ClearPrefixes
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

	ClearPrefixes
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
	ClearPrefixes
	fetch 1
0:
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
	getNextByteTo r1
	bl v30WriteSegOfs
	ClearPrefixes
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
	ClearPrefixes
	fetch 1
0:
	add v30ofs,v30ptr,r0,lsl#2
	mov r12,pc					;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
	getNextWordTo r1, r0
	bl v30WriteSegOfsW
	ClearPrefixes
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
	ClearPrefixes
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
	eatCycles 8
	mov r0,#3
	b V30TakeIRQ
;@----------------------------------------------------------------------------
i_int:
_CD:	;@ BRK/INT
;@----------------------------------------------------------------------------
	eatCycles 9
	getNextByte
	b V30TakeIRQ
;@----------------------------------------------------------------------------
i_into:
_CE:	;@ BRKV				;@ Break if Overflow
;@----------------------------------------------------------------------------
	tst v30f,#PSR_V
	subne v30cyc,v30cyc,#12*CYCLE
	movne r0,#4
	bne V30TakeIRQ
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
	mov r4,#1
	add v30ofs,v30ptr,r0,lsl#2
	bic r2,v30ofs,#0x1f
	ldr lr,[r2,#v30C0Table]
	cmp r0,#0xC0
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	bmi v30ReadEA
	ldrb r0,[v30ptr,-v30ofs]
	bx lr
;@----------------------------------------------------------------------------
i_rotshft_w:
_D1:	;@ ROTSHFT W
;@----------------------------------------------------------------------------
	getNextByte
	mov r4,#1
	mov r5,r0,ror#3
	add r2,v30ptr,r5,lsl#5
	ldr lr,[r2,#v30C1Table]
	cmp r0,#0xC0
	bmi v30ReadEAW
	add v30ofs,v30ptr,r5,lsr#27
	ldrh r0,[v30ofs,#v30Regs]
	bx lr
;@----------------------------------------------------------------------------
i_rotshft_bcl:
_D2:	;@ ROTSHFT BCL
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r4,[v30ptr,#v30RegCL]
	add v30ofs,v30ptr,r0,lsl#2
	bic r2,v30ofs,#0x1f
	ldr lr,[r2,#v30C0Table]
	eatCycles 2
	and r4,r4,#0x1F
	cmp r0,#0xC0
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	bmi v30ReadEA
	ldrb r0,[v30ptr,-v30ofs]
	bx lr
;@----------------------------------------------------------------------------
i_rotshft_wcl:
_D3:	;@ ROTSHFT WCL
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r4,[v30ptr,#v30RegCL]
	mov r5,r0,ror#3
	add r2,v30ptr,r5,lsl#5
	ldr lr,[r2,#v30C1Table]
	eatCycles 2
	and r4,r4,#0x1F
	cmp r0,#0xC0
	bmi v30ReadEAW
	add v30ofs,v30ptr,r5,lsr#27
	ldrh r0,[v30ofs,#v30Regs]
	bx lr
;@----------------------------------------------------------------------------
i_aam:
_D4:	;@ CVTBD/AAM	;@ Convert Binary to Decimal / Adjust After Multiply
;@----------------------------------------------------------------------------
	getNextByteTo r1

	ldrb r0,[v30ptr,#v30RegAL]
	movs r1,r1,lsl#8
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
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	tst r0,#0xC0
	bicne v30f,v30f,#PSR_Z
	eatCycles 15
	b divideError
;@----------------------------------------------------------------------------
i_aad:
_D5:	;@ CVTDB/AAD	;@ Convert Decimal to Binary / Adjust After Division
;@----------------------------------------------------------------------------
	getNextByte
	ldr r1,[v30ptr,#v30RegAW-2]
	and r2,r1,#0xFF000000
	mul r0,r2,r0
	mov r2,r0,lsl#4
	adds r0,r0,r1,lsl#8
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	adds r2,r2,r1,lsl#12
	orrcs v30f,v30f,#PSR_A
	mov r0,r0,lsr#24
	strh r0,[v30ptr,#v30RegAW]
	strb r0,[v30ptr,#v30ParityVal]
	fetch 6
;@----------------------------------------------------------------------------
i_salc:
_D6:	;@ SALC				;@ Set AL on Carry
;@----------------------------------------------------------------------------
	ands r0,v30f,PSR_C
	movne r0,#0xFF
	strb r0,[v30ptr,#v30RegAL]
	fetch 8
;@----------------------------------------------------------------------------
i_trans:
_D7:	;@ TRANS/XLAT		;@ Translate al via LUT.
;@----------------------------------------------------------------------------
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS0]
	ldrb r0,[v30ptr,#v30RegAL]
	ldr v30ofs,[v30ptr,#v30RegBW-2]
	add v30ofs,v30ofs,r0,lsl#16
	bl v30ReadSegOfs
	strb r0,[v30ptr,#v30RegAL]
	ClearPrefixes
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
	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetLockPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear segments if not applicable
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]
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
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetRepeatNEPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear segments if not applicable
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]

;@----------------------------------------------------------------------------
i_repe:
_F3:	;@ REPE
;@----------------------------------------------------------------------------
	getNextByte
	add r2,v30ptr,#v30SegTbl
	ldrb r1,[r2,r0]
	SetRepeatEPrefix
	bic v30f,v30f,r1,lsl#6		;@ Clear segments if not applicable
//	eatCycles 1
	ldr pc,[v30ptr,r0,lsl#2]

;@----------------------------------------------------------------------------
i_hlt:
_F4:	;@ HALT
;@----------------------------------------------------------------------------
	eatCycles 12
	ldrb r0,[v30ptr,#v30IrqPin]
	cmp r0,#0
	bne v30ChkIrqInternal
	mov lr,pc
	ldr pc,[v30ptr,#v30BusStatusFunc]
	orr v30cyc,v30cyc,#HALT_FLAG
	mvns r0,v30cyc,asr#CYC_SHIFT			;@
	addmi v30cyc,v30cyc,r0,lsl#CYC_SHIFT	;@ Consume all remaining cycles in steps of 1.
	b v30OutOfCycles
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
	bic r1,v30ofs,#0x1f
	ldr lr,[r1,#v30F6Table]
	cmp r0,#0xC0
	ldrbpl v30ofs,[v30ofs,#v30ModRmRm]
	bmi v30ReadEA1
	ldrb r0,[v30ptr,-v30ofs]
	bx lr
;@----------------------------------------------------------------------------
testF6:
	getNextByteTo r1
	and8 r1,r0
	fetch 1
;@----------------------------------------------------------------------------
notF6Reg:
	mvn r1,r0
	strb r1,[v30ptr,-v30ofs]
	ClearPrefixes
	fetch 1
;@----------------------------------------------------------------------------
notF6EA:
	mvn r1,r0
	bl v30WriteSegOfs
	ClearPrefixes
	fetch 2
;@----------------------------------------------------------------------------
negF6Reg:
	subs r1,r0,r0,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	tst r0,#0xF
	orrne v30f,v30f,#PSR_A
	mov r1,r1,lsr#24
	strb r1,[v30ptr,#v30ParityVal]

	strb r1,[v30ptr,-v30ofs]
	fetch 1
;@----------------------------------------------------------------------------
negF6EA:
	subs r1,r0,r0,lsl#24
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	tst r0,#0xF
	orrne v30f,v30f,#PSR_A
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
	mov r1,r2,asr#8
	eors v30f,r1,r2,asr#7
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
	eatCycles 15
	b divideError
;@----------------------------------------------------------------------------
divbF6:			;@ DIV/IDIV
	movs r1,r0,lsl#24
	ldr r0,[v30ptr,#v30RegAW-2]
	beq divbF6Error
	eor r3,r1,r0,asr#16
	rsbmi r1,r1,#0
	cmp r0,#0
	rsbmi r0,r0,#0
	cmp r0,r1,lsr#1
	bcs divbF6Error2
	rsb r1,r1,#1

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
	eatCycles 18
	b divideError
;@----------------------------------------------------------------------------
i_f7pre:
_F7:	;@ PRE F7
;@----------------------------------------------------------------------------
	getNextByte
	mov r1,r0,ror#3
	add r2,v30ptr,r1,lsl#5
	ldr lr,[r2,#v30F7Table]
	cmp r0,#0xC0
	bmi v30ReadEAWF7
	add v30ofs,v30ptr,r1,lsr#27
	ldrh r0,[v30ofs,#v30Regs]
	bx lr

;@----------------------------------------------------------------------------
testF7:
	mov r4,r0,lsl#16
	getNextWord
	tst16 r4,r0
	fetch 1
;@----------------------------------------------------------------------------
notF7Reg:
	mvn r1,r0
	strh r1,[v30ofs,#v30Regs]
	ClearPrefixes
	fetch 1
;@----------------------------------------------------------------------------
notF7EA:
	mvn r1,r0
	bl v30WriteSegOfsW
	ClearPrefixes
	fetch 2
;@----------------------------------------------------------------------------
negF7Reg:
	subs r1,r0,r0,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	tst r0,#0xF
	orrne v30f,v30f,#PSR_A
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]

	strh r1,[v30ofs,#v30Regs]
	fetch 1
;@----------------------------------------------------------------------------
negF7EA:
	subs r1,r0,r0,lsl#16
	mrs v30f,cpsr				;@ S, Z, C & V.
	mov v30f,v30f,lsr#28
	eor v30f,v30f,#PSR_C		;@ Invert C
	tst r0,#0xF
	orrne v30f,v30f,#PSR_A
	mov r1,r1,lsr#16
	strb r1,[v30ptr,#v30ParityVal]

	bl v30WriteSegOfsW
	fetch 2
;@----------------------------------------------------------------------------
muluF7:			;@ MULU/MUL
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs v30f,r2,lsr#16
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
	mov r1,r2,asr#16
	strh r1,[v30ptr,#v30RegDW]
	eors v30f,r1,r2,asr#15
	movne v30f,#PSR_C+PSR_V				;@ Set Carry & Overflow.
	orr v30f,v30f,#PSR_Z				;@ Set Z.
	strb v30f,[v30ptr,#v30MulOverflow]
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	fetch 3
;@----------------------------------------------------------------------------
divuwF7:		;@ DIVU/DIV
	mov v30f,#PSR_Z						;@ Set Z.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mov r1,r0,lsl#15
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16
	cmp r0,r1,lsl#1
	bcs divuwF7Error
	rsb r1,r1,#0

	bl division16

	movs r1,r0,lsr#16
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	andeq r0,r0,#1
	cmpeq r0,#1
	movne v30f,#0						;@ Clear flags.

	fetch 23
divuwF7Error:
	mov v30f,#0							;@ Clear flags.
	eatCycles 15
	b divideError
;@----------------------------------------------------------------------------
divwF7:			;@ DIV/IDIV
	mov v30f,#PSR_Z						;@ Set Z.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
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
	mov r1,r1,asr#1

	bl division16

	mov r1,r0,lsr#16
	movs r3,r3,asr#16
	rsbcs r1,r1,#0
	rsbmi r0,r0,#0
1:
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	movs r1,r1,lsl#16
	andeq r0,r0,#1
	cmpeq r0,#1
	movne v30f,#0						;@ Clear flags.
	fetch 24
divwF7Error:
	cmp r0,#0x80000000
	ldreq r0,=0x8001
	beq 1b
divwF7Error2:
	mov v30f,#0							;@ Clear flags.
	eatCycles 18
	b divideError
	.pool
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
	bne v30DelayIrqCheckTrap
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
	bic r1,v30ofs,#0x1f
	ldr pc,[r1,#v30FETable]

incFEReg:
	ldrb v30ofs,[v30ofs,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	incByte
	strb r1,[v30ptr,-v30ofs]
	fetch 1

decFEReg:
	ldrb v30ofs,[v30ofs,#v30ModRmRm]
	ldrb r0,[v30ptr,-v30ofs]
	decByte
	strb r1,[v30ptr,-v30ofs]
	fetch 1

incFEEA:
	bl v30ReadEA
	incByte
	bl v30WriteSegOfs
	fetch 3

decFEEA:
	bl v30ReadEA
	decByte
	bl v30WriteSegOfs
	fetch 3

;@----------------------------------------------------------------------------
i_ffpre:
_FF:	;@ PRE FF
;@----------------------------------------------------------------------------
	getNextByte
contFF:
	mov r1,r0,ror#3
	add r2,v30ptr,r1,lsl#5
	ldr lr,[r2,#v30FFTable]
	cmp r0,#0xC0
	bmi v30ReadEAW
	add v30ofs,v30ptr,r1,lsr#27
	bx lr
;@----------------------------------------------------------------------------
incFFReg:
	ldr r0,[v30ofs,#v30Regs2]
	incWord
	str r1,[v30ofs,#v30Regs2]
	fetch 1
;@----------------------------------------------------------------------------
incFFEA:
	mov r0,r0,lsl#16
	incWord
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
decFFReg:
	ldr r0,[v30ofs,#v30Regs2]
	decWord
	str r1,[v30ofs,#v30Regs2]
	fetch 1
;@----------------------------------------------------------------------------
decFFEA:
	mov r0,r0,lsl#16
	decWord
	mov r1,r1,lsr#16
	bl v30WriteSegOfsW
	fetch 3
;@----------------------------------------------------------------------------
callFFReg:
	v30DecodeFastPCToReg r1
	ldr v30pc,[v30ofs,#v30Regs2]
	bl v30PushW
	V30EncodeFastPC
	ClearPrefixes
	fetch 5
callFFEA:
	v30DecodeFastPCToReg r1
	mov v30pc,r0,lsl#16
	bl v30PushW
	V30EncodeFastPC
	ClearPrefixes
	fetch 6
;@----------------------------------------------------------------------------
callFarFFReg:
	bl v30ReadEAW
callFarFF:
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
	ClearPrefixes
	fetch 12
;@----------------------------------------------------------------------------
braFFReg:
	ldr v30pc,[v30ofs,#v30Regs2]
	v30EncodeFastPC
	ClearPrefixes
	fetch 5
braFFEA:
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	ClearPrefixes
	fetch 6
;@----------------------------------------------------------------------------
braFarFFReg:
	bl v30ReadEAW
braFarFF:
	mov v30pc,r0,lsl#16
	add v30ofs,v30ofs,#0x20000
	bl v30ReadSegOfsW
	strh r0,[v30ptr,#v30SRegPS+2]
	v30EncodeFastPC
	ClearPrefixes
	fetch 10
;@----------------------------------------------------------------------------
pushFFReg:
	ldrh r1,[v30ofs,#v30Regs]
	bl v30PushW
	ClearPrefixes
	fetch 1
pushFFEA:
	mov r1,r0
	bl v30PushW
	ClearPrefixes
	fetch 2

;@----------------------------------------------------------------------------
division16:
;@----------------------------------------------------------------------------
	adds r0,r1,r0
	subcc r0,r0,r1

	.rept 15
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	.endr
	adc r0,r0,r0
	bx lr
;@----------------------------------------------------------------------------
division8:
;@----------------------------------------------------------------------------
	.rept 8
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	.endr
	bx lr

;@----------------------------------------------------------------------------
// All EA functions must leave EO (EffectiveOffset) in top 16bits of v30ofs!
// r1 can not be used as it's used as value during write.
// r12 is return address
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
	ldr v30ofs,[v30ptr,#v30RegBP]	;@ ldrd r2,r3?
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
	ldr v30ofs,[v30ptr,#v30RegBP]	;@ ldrd r2,r3?
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
	ldr v30ofs,[v30ptr,#v30RegBP]	;@ ldrd r2,r3?
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
	ldr v30ofs,[v30ptr,#v30RegBP]	;@ ldrd r2,r3?
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
V30SetIRQPin:				;@ r0=pin state
;@----------------------------------------------------------------------------
	cmp r0,#0
	movne r0,#IRQ_PIN
	strb r0,[v30ptr,#v30IrqPin]
	bx lr
;@----------------------------------------------------------------------------
V30FetchIRQ:
;@----------------------------------------------------------------------------
	eatCycles 7
	mov lr,pc
	ldr pc,[v30ptr,#v30IrqVectorFunc]
;@----------------------------------------------------------------------------
V30TakeIRQ:					;@ r0 = vector number
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
	fetch 33
;@----------------------------------------------------------------------------
V30RestoreAndRunXCycles:	;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add r1,v30ptr,#v30Flags
	ldmia r1,{v30f-v30cyc}	;@ Restore V30MZ state
;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add v30cyc,v30cyc,r0,lsl#CYC_SHIFT
;@----------------------------------------------------------------------------
V30CheckIRQs:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
v30ChkIrqInternal:				;@ This can be used on HALT
	ldr r1,[v30ptr,#v30IrqPin]	;@ NMI, Irq pin and IF
	ands r0,r1,r1,asr#8
	bmi doV30NMI
	bne V30FetchIRQ
	tst v30cyc,#HALT_FLAG | TRAP_FLAG
	bne v30InHaltTrap
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
	fetch 0
v30InHaltTrap:
	ands r0,v30cyc,#TRAP_FLAG	;@ Bit 0 = Trap flag = IRQ 1.
	bne V30TakeIRQ
	tst r1,#IRQ_PIN				;@ IRQ Pin ?
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
v30DelayIrqCheckTrap:		;@ This is used by EI
;@----------------------------------------------------------------------------
	ands r0,v30cyc,#TRAP_FLAG	;@ Bit 0 = Trap flag = IRQ 1.
	bne V30TakeIRQ
;@----------------------------------------------------------------------------
v30DelayIrqCheck:			;@ This is used by IRET/POPF
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
V30SetNMIPin:				;@ r0=pin state
;@----------------------------------------------------------------------------
	cmp r0,#0
	movne r0,#0x80
	ldrb r1,[v30ptr,#v30NmiPin]
	strb r0,[v30ptr,#v30NmiPin]
	bics r0,r0,r1
	strbne r0,[v30ptr,#v30NmiPending]
	bx lr
;@----------------------------------------------------------------------------
doV30NMI:					;@
;@----------------------------------------------------------------------------
	mov r1,#0
	strb r1,[v30ptr,#v30NmiPending]
	mov r0,#NEC_NMI_VECTOR		;@ (2)
	b V30TakeIRQ
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
	b V30TakeIRQ

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
	ClearPrefixes
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
;@----------------------------------------------------------------------------
V30BusStatusDummy:
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
V30Init:					;@ r0=v30ptr
;@ Called by cpuInit
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	mov v30ptr,r0
	add r0,v30ptr,#v30ModRmRm
	adr r1,regConvert
	mov r2,#0
regConvLoop:
	and r3,r2,#0x38
	ldr r3,[r1,r3,lsr#1]
	rsb r3,r3,#0
	mov r3,r3,lsl#24
	str r3,[r0,r2,lsl#2]
	add r2,r2,#1
	cmp r2,#0xC0
	bne regConvLoop

regConv2Loop:
	and r3,r2,#0x38
	ldr r3,[r1,r3,lsr#1]
	rsb r3,r3,#0
	and lr,r2,#7
	ldr lr,[r1,lr,lsl#2]
	rsb lr,lr,#0
	orr r3,lr,r3,lsl#24
	str r3,[r0,r2,lsl#2]
	add r2,r2,#1
	cmp r2,#0x100
	bne regConv2Loop

	adr r0,V30IrqVectorDummy
	str r0,[v30ptr,#v30IrqVectorFunc]
	adr r0,V30BusStatusDummy
	str r0,[v30ptr,#v30BusStatusFunc]
	ldmfd sp!,{v30ptr,lr}
	bx lr
regConvert:
	.long v30RegAL,v30RegCL,v30RegDL,v30RegBL,v30RegAH,v30RegCH,v30RegDH,v30RegBH
;@----------------------------------------------------------------------------
V30Reset:					;@ r0=v30ptr, r1=type (0=ASWAN)
;@ Called by cpuReset
;@----------------------------------------------------------------------------
	stmfd sp!,{r1,r4-r11,lr}
	mov v30ptr,r0

	;@ Clear CPU state, PC, DS1, DS0 & SS are set to 0x0000,
	;@ AW, BW, CW, DW, SP, BP, IX & IY are undefined.
	;@ PS is set to 0xFFFF
	add r0,v30ptr,#v30I
	mov r1,#(v30IEnd-v30I)/4
	bl memclr_

	ldr r0,=0xFFFF0000
	str r0,[v30ptr,#v30SRegPS]
	mov r0,#0
	strh r0,[v30ptr,#v30ParityVal]
	mov r0,#1
	strb r0,[v30ptr,#v30DF]

	mov v30pc,#0
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30PC]

	ldmfd sp!,{r1}
	cmp r1,#0			;@ Aswan?
	ldr r0,=f6Table
	ldreq r1,=muluF6Aswan
	ldrne r1,=muluF6
	str r1,[r0,#4*4]
	str r1,[r0,#12*4]
	str r1,[r0,#20*4]
	str r1,[r0,#28*4]
	ldr r0,=f7Table
	ldreq r1,=muluF7Aswan
	ldrne r1,=muluF7
	str r1,[r0,#4*32]
	str r1,[r0,#12*32]
	str r1,[r0,#20*32]
	str r1,[r0,#28*32]

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
	ldr v30pc,[r4,#v30PC]		;@ Offseted v30pc
	v30DecodeFastPC
	str v30pc,[r4,#v30PC]		;@ Normal v30pc

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

	ldr v30pc,[v30ptr,#v30PC]	;@ Normal v30pc
	v30EncodeFastPC
	str v30pc,[v30ptr,#v30PC]	;@ Rewrite offseted v30pc

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
	.section .dtcm, "ax", %progbits		;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text
#endif
;@----------------------------------------------------------------------------
	.align 6
	.space (48-42)*4
defaultV30:
v30StateStart:
	.space 19*4
v30StateEnd:
	.long 0			;@ v30LastBank
	.long 0			;@ v30IrqVectorFunc
	.long 0			;@ v30BusStatusFunc
writeSRegTbl:
	.long movSRegDS, movSRegPS, movSRegSS, movSRegDS
	.space 16*4		;@ v30MemTbl $00000-FFFFF

V30OpTable:
	.long i_add_br8, i_add_wr16, i_add_r8b, i_add_r16w, i_add_ald8, i_add_awd16, i_push_ds1, i_pop_ds1	// 0x00
	.long i_or_br8,  i_or_wr16,  i_or_r8b,  i_or_r16w,  i_or_ald8,  i_or_awd16,  i_push_ps, i_undefined	// 0x08
	.long i_adc_br8, i_adc_wr16, i_adc_r8b, i_adc_r16w, i_adc_ald8, i_adc_awd16, i_push_ss, i_pop_ss	// 0x10
	.long i_sbb_br8, i_sbb_wr16, i_sbb_r8b, i_sbb_r16w, i_sbb_ald8, i_sbb_awd16, i_push_ds0, i_pop_ds0	// 0x18
	.long i_and_br8, i_and_wr16, i_and_r8b, i_and_r16w, i_and_ald8, i_and_awd16, i_ds1,     i_daa		// 0x20
	.long i_sub_br8, i_sub_wr16, i_sub_r8b, i_sub_r16w, i_sub_ald8, i_sub_awd16, i_ps,      i_das		// 0x28
	.long i_xor_br8, i_xor_wr16, i_xor_r8b, i_xor_r16w, i_xor_ald8, i_xor_awd16, i_ss,      i_aaa		// 0x30
	.long i_cmp_br8, i_cmp_wr16, i_cmp_r8b, i_cmp_r16w, i_cmp_ald8, i_cmp_awd16, i_ds0,     i_aas		// 0x38
	.long i_inc_aw,  i_inc_cw,   i_inc_dw,  i_inc_bw,   i_inc_sp,   i_inc_bp,    i_inc_ix,  i_inc_iy	// 0x40
	.long i_dec_aw,  i_dec_cw,   i_dec_dw,  i_dec_bw,   i_dec_sp,   i_dec_bp,    i_dec_ix,  i_dec_iy	// 0x48
	.long i_push_aw, i_push_cw,  i_push_dw, i_push_bw,  i_push_sp,  i_push_bp,   i_push_ix, i_push_iy	// 0x50
	.long i_pop_aw,  i_pop_cw,   i_pop_dw,  i_pop_bw,   i_pop_sp,   i_pop_bp,    i_pop_ix,  i_pop_iy	// 0x58
	.long i_pusha,   i_popa,     i_chkind
	.long i_undefined	// arpl
	.long i_undefined	// repnc
	.long i_undefined	// repc
	.long i_undefined	// fpo2
	.long i_undefined	// fpo2
	.long i_push_d16, i_imul_d16, i_push_d8, i_imul_d8, i_inmb,     i_inmw,      i_outmb,   i_outmw		// 0x68
	.long i_bv,      i_bnv,      i_bc,      i_bnc,      i_be,       i_bne,       i_bnh,     i_bh		// 0x70
	.long i_bn,      i_bp,       i_bpe,     i_bpo,      i_blt,      i_bge,       i_ble,     i_bgt		// 0x78
	.long i_80pre,   i_81pre,    i_82pre,   i_83pre,    i_test_br8, i_test_wr16, i_xchg_br8, i_xchg_wr16	// 0x80
	.long i_mov_br8, i_mov_wr16, i_mov_r8b, i_mov_r16w, i_mov_wsreg, i_lea,      i_mov_sregw, i_popw	// 0x88
	.long i_nop, i_xchg_awcw, i_xchg_awdw, i_xchg_awbw, i_xchg_awsp, i_xchg_awbp, i_xchg_awix, i_xchg_awiy	// 0x90
	.long i_cbw,     i_cwd,      i_call_far, i_poll,    i_pushf,    i_popf,      i_sahf,    i_lahf		// 0x98
	.long i_mov_aldisp, i_mov_awdisp, i_mov_dispal, i_mov_dispaw, i_movsb, i_movsw, i_cmpsb, i_cmpsw	// 0xA0
	.long i_test_ald8, i_test_awd16, i_stosb, i_stosw,  i_lodsb,    i_lodsw,     i_scasb,    i_scasw	// 0xA8
	.long i_mov_ald8, i_mov_cld8, i_mov_dld8, i_mov_bld8, i_mov_ahd8, i_mov_chd8, i_mov_dhd8, i_mov_bhd8	// 0xB0
	.long i_mov_awd16, i_mov_cwd16, i_mov_dwd16, i_mov_bwd16, i_mov_spd16, i_mov_bpd16, i_mov_ixd16, i_mov_iyd16	// 0xB8
	.long i_rotshft_bd8, i_rotshft_wd8, i_ret_d16, i_ret, i_les_dw, i_lds_dw,    i_mov_bd8, i_mov_wd16	// 0xC0
	.long i_prepare, i_dispose, i_retf_d16, i_retf,     i_int3,     i_int,       i_into,    i_iret		// 0xC8
	.long i_rotshft_b, i_rotshft_w, i_rotshft_bcl, i_rotshft_wcl, i_aam, i_aad, i_salc, i_trans			// 0xD0
	.long i_fpo1,    i_fpo1,     i_fpo1,    i_fpo1,     i_fpo1,     i_fpo1,      i_fpo1,    i_fpo1		// 0xD8
	.long i_loopne,  i_loope,    i_loop,    i_bcwz,     i_inal,     i_inaw,      i_outal,   i_outaw		// 0xE0
	.long i_call_d16, i_jmp_d16, i_jmp_far, i_br_d8,    i_inaldw,   i_inawdw,    i_outdwal, i_outdwaw	// 0xE8
	.long i_lock,    i_brks,     i_repne,   i_repe,     i_hlt,      i_cmc,       i_f6pre,   i_f7pre		// 0xF0
	.long i_clc,     i_stc,      i_di,      i_ei,       i_cld,      i_std,       i_fepre,   i_ffpre		// 0xF8

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
SegmentTable:
	.byte      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF,      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF,      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0,      0,      0, NOT_PF, NOT_PF,      0, NOT_PF,      0,      0,      0,      0, NOT_PF, NOT_PF,      0, NOT_PF
	.byte      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF,      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte NOT_PF, NOT_PF,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF,      0, NOT_PF,      0, NOTSEG, NOTSEG,      0,      0
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0, NOT_PF,      0,      0
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0,      0,      0,      0,      0,      0,      0, NOT_PF, NOT_PF, NOTSEG, NOTSEG,      0,      0, NOTSEG, NOTSEG
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0, NOT_PF, NOT_PF,      0,      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0,      0,      0,      0, NOT_PF, NOT_PF, NOT_PF,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF
	.byte      0, NOT_PF,      0,      0, NOT_PF, NOT_PF,      0,      0, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF, NOT_PF,      0,      0

_80Table:
	.long add80EA
c0Table:
	.long rolC0EA
c1Table:
	.long rolC1EA
f6Table:
	.long testF6
f7Table:
	.long testF7
feTable:
	.long incFEEA
ffTable:
	.long incFFEA, 0
	.long or80EA,   rorC0EA,  rorC1EA,  undefF6, undefF7, decFEEA, decFFEA,   0
	.long adc80EA,  rolcC0EA, rolcC1EA, notF6EA, notF7EA, contFF,  callFFEA,  0
	.long subc80EA, rorcC0EA, rorcC1EA, negF6EA, negF7EA, contFF,  callFarFF, 0
	.long and80EA,  shlC0EA,  shlC1EA,  muluF6,  muluF7,  contFF,  braFFEA,   0
	.long sub80EA,  shrC0EA,  shrC1EA,  mulF6,   mulF7,   contFF,  braFarFF,  0
	.long xor80EA,  undC0EA,  undC1EA,  divubF6, divuwF7, contFF,  pushFFEA,  0
	.long cmp80EA,  shraC0EA, shraC1EA, divbF6,  divwF7,  undefFF, undefFF,   0

	.long add80EA,  rolC0EA,  rolC1EA,  testF6,  testF7,  incFEEA, incFFEA,   0
	.long or80EA,   rorC0EA,  rorC1EA,  undefF6, undefF7, decFEEA, decFFEA,   0
	.long adc80EA,  rolcC0EA, rolcC1EA, notF6EA, notF7EA, contFF,  callFFEA,  0
	.long subc80EA, rorcC0EA, rorcC1EA, negF6EA, negF7EA, contFF,  callFarFF, 0
	.long and80EA,  shlC0EA,  shlC1EA,  muluF6,  muluF7,  contFF,  braFFEA,   0
	.long sub80EA,  shrC0EA,  shrC1EA,  mulF6,   mulF7,   contFF,  braFarFF,  0
	.long xor80EA,  undC0EA,  undC1EA,  divubF6, divuwF7, contFF,  pushFFEA,  0
	.long cmp80EA,  shraC0EA, shraC1EA, divbF6,  divwF7,  undefFF, undefFF,   0

	.long add80EA,  rolC0EA,  rolC1EA,  testF6,  testF7,  incFEEA, incFFEA,   0
	.long or80EA,   rorC0EA,  rorC1EA,  undefF6, undefF7, decFEEA, decFFEA,   0
	.long adc80EA,  rolcC0EA, rolcC1EA, notF6EA, notF7EA, contFF,  callFFEA,  0
	.long subc80EA, rorcC0EA, rorcC1EA, negF6EA, negF7EA, contFF,  callFarFF, 0
	.long and80EA,  shlC0EA,  shlC1EA,  muluF6,  muluF7,  contFF,  braFFEA,   0
	.long sub80EA,  shrC0EA,  shrC1EA,  mulF6,   mulF7,   contFF,  braFarFF,  0
	.long xor80EA,  undC0EA,  undC1EA,  divubF6, divuwF7, contFF,  pushFFEA,  0
	.long cmp80EA,  shraC0EA, shraC1EA, divbF6,  divwF7,  undefFF, undefFF,   0

	.long add80Reg, rolC0Reg, rolC1Reg, testF6,  testF7,  incFEReg,incFFReg,  0
	.long or80Reg,  rorC0Reg, rorC1Reg, undefF6, undefF7, decFEReg,decFFReg,  0
	.long adc80Reg, rolcC0Reg,rolcC1Reg,notF6Reg,notF7Reg,contFF,  callFFReg, 0
	.long subc80Reg,rorcC0Reg,rorcC1Reg,negF6Reg,negF7Reg,contFF,  callFarFFReg,0
	.long and80Reg, shlC0Reg, shlC1Reg, muluF6,  muluF7,  contFF,  braFFReg,  0
	.long sub80Reg, shrC0Reg, shrC1Reg, mulF6,   mulF7,   contFF, braFarFFReg,0
	.long xor80Reg, undC0Reg, undC1Reg, divubF6, divuwF7, contFF, pushFFReg,  0
	.long cmp80Reg, shraC0Reg,shraC1Reg,divbF6,  divwF7,  undefFF, undefFF,   0

;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
