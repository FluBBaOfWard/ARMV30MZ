//
//  ARMV30MZ.s
//  ARMV30MZ
//
//  Created by Fredrik Ahlström on 2021-12-19.
//  Copyright © 2021-2022 Fredrik Ahlström. All rights reserved.
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
// All opcodes are free to also use r4-r7 wihtout pushing to stack.
// If an opcode calls another opcode, the caller is responsible for
// saving r4-r7 before the call if needed.
//
;@----------------------------------------------------------------------------
i_add_br8:
_00:	;@ ADD BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	add8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_add_wr16:
_01:	;@ ADD WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldrh r1,[r2,#v30Regs]
	mov r0,r0,lsl#16
	add16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_add_r8b:
_02:	;@ ADD R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	add8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_add_r16w:
_03:	;@ ADD R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	eatCycles 1
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
0:
	ldr r1,[r4,#v30Regs2]
	add16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_add_ald8:
_04:	;@ ADD ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	add8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_add_axd16:
_05:	;@ ADD AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	add16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_push_es:
_06:	;@ PUSH ES
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegES+2]
	eatCycles 2
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_pop_es:
_07:	;@ POP ES
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	popWord
	strh r0,[v30ptr,#v30SRegES+2]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_or_br8:
_08:	;@ OR BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	or8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_or_wr16:
_09:	;@ OR WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	eatCycles 1
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldr r1,[r2,#v30Regs2]
	or16 r0,r1

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_or_r8b:
_0A:	;@ OR R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	or8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_or_r16w:
_0B:	;@ OR R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	or16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_or_ald8:
_0C:	;@ OR ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	or8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_or_axd16:
_0D:	;@ OR AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	or16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_push_cs:
_0E:	;@ PUSH CS
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegCS+2]
	eatCycles 2
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_adc_br8:
_10:	;@ ADC BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	adc8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_adc_wr16:
_11:	;@ ADC WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldrh r1,[r2,#v30Regs]
	mov r0,r0,lsl#16
	adc16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_adc_r8b:
_12:	;@ ADC R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	adc8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_adc_r16w:
_13:	;@ ADC R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	adc16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_adc_ald8:
_14:	;@ ADC ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	adc8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_adc_axd16:
_15:	;@ ADC AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	adc16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_push_ss:
_16:	;@ PUSH SS
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30RegSP]
	ldr r1,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r1,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	mov r1,r1,lsr#16
	eatCycles 2
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_pop_ss:
_17:	;@ POP SS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	popWord
	strh r0,[v30ptr,#v30SRegSS+2]
	eatCycles 3
	mov r0,#1
	strb r0,[v30ptr,#v30NoInterrupt]			;@ What is this?
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sbb_br8:
_18:	;@ SBB BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	subc8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_sbb_wr16:
_19:	;@ SBB WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldrh r1,[r2,#v30Regs]
	mov r0,r0,lsl#16
	subc16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_sbb_r8b:
_1A:	;@ SBB R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	subc8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_sbb_r16w:
_1B:	;@ SBB R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	subc16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_sbb_ald8:
_1C:	;@ SBB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	subc8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_sbb_axd16:
_1D:	;@ SBB AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	subc16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_push_ds:
_1E:	;@ PUSH DS
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegDS+2]
	eatCycles 2
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_pop_ds:
_1F:	;@ POP DS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	popWord
	strh r0,[v30ptr,#v30SRegDS+2]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_and_br8:
_20:	;@ AND BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	and8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_and_wr16:
_21:	;@ AND WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldr r1,[r2,#v30Regs2]
	and16 r0,r1

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_and_r8b:
_22:	;@ AND R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	and8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_and_r16w:
_23:	;@ AND R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	and16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_and_ald8:
_24:	;@ AND ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	and8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_and_axd16:
_25:	;@ AND AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_es:
_26:	;@ ES prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegES+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r1,[v30ptr,#v30PrefixBase+2]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_daa:
_27:	;@ DAA / ADJ4A
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
	eatCycles 10
	bx lr
;@----------------------------------------------------------------------------
i_sub_br8:
_28:	;@ SUB BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	sub8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_sub_wr16:
_29:	;@ SUB WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldrh r1,[r2,#v30Regs]
	mov r0,r0,lsl#16
	sub16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_sub_r8b:
_2A:	;@ SUB R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	sub8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_sub_r16w:
_2B:	;@ SUB R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	sub16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_sub_ald8:
_2C:	;@ SUB ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_sub_axd16:
_2D:	;@ SUB AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_cs:
_2E:	;@ CS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegCS+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r1,[v30ptr,#v30PrefixBase+2]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_das:
_2F:	;@ DAS / ADJ4S
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
	eatCycles 11
	bx lr
;@----------------------------------------------------------------------------
i_xor_br8:
_30:	;@ XOR BR8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	add r1,v30ptr,r4
	ldrb r6,[r1,#v30ModRmReg]
	cmp r4,#0xC0
	bmi 1f
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	ldrb r1,[v30ptr,-r6]
	xor8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_xor_wr16:
_31:	;@ XOR WR16
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#1
	ldr r1,[r2,#v30Regs2]
	xor16 r0,r1

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_xor_r8b:
_32:	;@ XOR R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	ldrb r1,[v30ptr,-r4]
	xor8 r0,r1
	strb r1,[v30ptr,-r4]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_xor_r16w:
_33:	;@ XOR R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldr r1,[r4,#v30Regs2]
	xor16 r0,r1
	strh r1,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_xor_ald8:
_34:	;@ XOR ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	xor8 r0,r1
	strb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_xor_axd16:
_35:	;@ XOR AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	xor16 r0,r1
	strh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_ss:
_36:	;@ SS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegSS+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r1,[v30ptr,#v30PrefixBase+2]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_aaa:
_37:	;@ AAA / ADJBA
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
	eatCycles 9
	bx lr
;@----------------------------------------------------------------------------
i_cmp_br8:
_38:	;@ CMP BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	ldrb r4,[v30ptr,-r2]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	sub8 r4,r0
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_cmp_wr16:
_39:	;@ CMP WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	cmp r0,#0xC0
	bmi 1f
	and r1,r0,#7
	add r2,v30ptr,r1,lsl#2
	ldrh r0,[r2,#v30Regs]
	eatCycles 1
0:
	mov r0,r0,lsl#16
	sub16 r4,r0
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_cmp_r8b:
_3A:	;@ CMP R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	ldrb r4,[v30ptr,-r2]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	sub8 r0,r4
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_cmp_r16w:
_3B:	;@ CMP R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 1f
	and r1,r0,#7
	add r2,v30ptr,r1,lsl#2
	ldrh r0,[r2,#v30Regs]
	eatCycles 1
0:
	sub16 r0,r4
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_cmp_ald8:
_3C:	;@ CMP ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	sub8 r0,r1
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_cmp_axd16:
_3D:	;@ CMP AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	sub16 r0,r1
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_ds:
_3E:	;@ DS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegDS+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r1,[v30ptr,#v30PrefixBase+2]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_aas:
_3F:	;@ AAS / ADJBS
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	mov r1,r0,lsl#28
	cmp r1,#0xA0000000
	orrcs v30f,v30f,#PSR_A			;@ Set Aux.
	tst v30f,#PSR_A
	moveq v30f,#PSR_S
	movne v30f,#PSR_Z+PSR_A+PSR_C
	strb r1,[v30ptr,#v30ParityVal]	;@ Parity allways set
	bic r0,r0,#0x00F0
	subne r0,r0,#0x16
	bic r0,r0,#0x00F0
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 9
	bx lr

;@----------------------------------------------------------------------------
i_inc_ax:
_40:	;@ INC AX
;@----------------------------------------------------------------------------
	incWord v30RegAW
;@----------------------------------------------------------------------------
i_inc_cx:
_41:	;@ INC CX
;@----------------------------------------------------------------------------
	incWord v30RegCW
;@----------------------------------------------------------------------------
i_inc_dx:
_42:	;@ INC DX
;@----------------------------------------------------------------------------
	incWord v30RegDW
;@----------------------------------------------------------------------------
i_inc_bx:
_43:	;@ INC BX
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
	incWord v30RegBP
;@----------------------------------------------------------------------------
i_inc_si:
_46:	;@ INC SI
;@----------------------------------------------------------------------------
	incWord v30RegIX+2
;@----------------------------------------------------------------------------
i_inc_di:
_47:	;@ INC DI
;@----------------------------------------------------------------------------
	incWord v30RegIY+2
;@----------------------------------------------------------------------------
i_dec_ax:
_48:	;@ DEC AX
;@----------------------------------------------------------------------------
	decWord v30RegAW
;@----------------------------------------------------------------------------
i_dec_cx:
_49:	;@ DEC CX
;@----------------------------------------------------------------------------
	decWord v30RegCW
;@----------------------------------------------------------------------------
i_dec_dx:
_4A:	;@ DEC DX
;@----------------------------------------------------------------------------
	decWord v30RegDW
;@----------------------------------------------------------------------------
i_dec_bx:
_4B:	;@ DEC BX
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
	decWord v30RegBP
;@----------------------------------------------------------------------------
i_dec_si:
_4E:	;@ DEC SI
;@----------------------------------------------------------------------------
	decWord v30RegIX+2
;@----------------------------------------------------------------------------
i_dec_di:
_4F:	;@ DEC DI
;@----------------------------------------------------------------------------
	decWord v30RegIY+2
;@----------------------------------------------------------------------------
i_push_ax:
_50:	;@ PUSH AX
;@----------------------------------------------------------------------------
	pushRegister v30RegAW
;@----------------------------------------------------------------------------
i_push_cx:
_51:	;@ PUSH CX
;@----------------------------------------------------------------------------
	pushRegister v30RegCW
;@----------------------------------------------------------------------------
i_push_dx:
_52:	;@ PUSH DX
;@----------------------------------------------------------------------------
	pushRegister v30RegDW
;@----------------------------------------------------------------------------
i_push_bx:
_53:	;@ PUSH BX
;@----------------------------------------------------------------------------
	pushRegister v30RegBW
;@----------------------------------------------------------------------------
i_push_sp:
_54:	;@ PUSH SP
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r1,[v30ptr,#v30RegSP]
	mov r1,r1,lsr#16
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_push_bp:
_55:	;@ PUSH BP
;@----------------------------------------------------------------------------
	pushRegister v30RegBP
;@----------------------------------------------------------------------------
i_push_si:
_56:	;@ PUSH SI
;@----------------------------------------------------------------------------
	pushRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_push_di:
_57:	;@ PUSH DI
;@----------------------------------------------------------------------------
	pushRegister v30RegIY+2

;@----------------------------------------------------------------------------
i_pop_ax:
_58:	;@ POP AX
;@----------------------------------------------------------------------------
	popRegister v30RegAW
;@----------------------------------------------------------------------------
i_pop_cx:
_59:	;@ POP CX
;@----------------------------------------------------------------------------
	popRegister v30RegCW
;@----------------------------------------------------------------------------
i_pop_dx:
_5A:	;@ POP DX
;@----------------------------------------------------------------------------
	popRegister v30RegDW
;@----------------------------------------------------------------------------
i_pop_bx:
_5B:	;@ POP BX
;@----------------------------------------------------------------------------
	popRegister v30RegBW
;@----------------------------------------------------------------------------
i_pop_sp:
_5C:	;@ POP SP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	add r0,r0,r1,lsr#4
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegSP+2]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_bp:
_5D:	;@ POP BP
;@----------------------------------------------------------------------------
	popRegister v30RegBP
;@----------------------------------------------------------------------------
i_pop_si:
_5E:	;@ POP SI
;@----------------------------------------------------------------------------
	popRegister v30RegIX+2
;@----------------------------------------------------------------------------
i_pop_di:
_5F:	;@ POP DI
;@----------------------------------------------------------------------------
	popRegister v30RegIY+2

;@----------------------------------------------------------------------------
i_pusha:
_60:	;@ PUSHA
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r4,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegCW]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegDW]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegBW]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegSP+2]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegBP]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegIX+2]
	bl cpuWriteMem20W
	sub r4,r4,#0x20000
	add r0,r5,r4,lsr#4
	ldrh r1,[v30ptr,#v30RegIY+2]
	bl cpuWriteMem20W
	str r4,[v30ptr,#v30RegSP]
	eatCycles 9
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_popa:
_61:	;@ POPA
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	add r4,r1,#0x20000
	add r0,r5,r1,lsr#4
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegIY+2]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegIX+2]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x40000			;@ Skip one
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegBP]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegBW]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegDW]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegCW]
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegAW]
	str r4,[v30ptr,#v30RegSP]
	eatCycles 8
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_chkind:
_62:	;@ CHKIND
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	sub r5,r0,r1,lsr#4
	add r1,r1,#0x20000
	add r5,r5,r1,lsr#4
	bl cpuReadMem20W
0:
	mov r6,r0
	mov r0,r5
	bl cpuReadMem20W
	ldrh r1,[r4,#v30Regs]

	eatCycles 13
	cmp r1,r6
	cmppl r0,r1
	ldmfdpl sp!,{pc}
	ldmfd sp!,{lr}
	sub v30cyc,v30cyc,#7*CYCLE
	mov r0,#5
	b nec_interrupt
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	b 0b

;@----------------------------------------------------------------------------
i_push_d16:
_68:	;@ PUSH D16
;@----------------------------------------------------------------------------
	getNextWord
	mov r1,r0
	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_imul_d16:
_69:	;@ IMUL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r1,r0,#7
	add r2,v30ptr,r1,lsl#2
	ldrh r0,[r2,#v30Regs]
	eatCycles 3
0:
	mov r5,r0
	getNextWord

	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mul r0,r5,r0
	movs r1,r0,asr#15
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V	;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 4
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_push_d8:
_6A:	;@ PUSH D8
;@----------------------------------------------------------------------------
	getNextSignedByteToReg r1
	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_imul_d8:
_6B:	;@ IMUL D8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	eatCycles 3
0:
	getNextSignedByteToReg r1

	mov v30f,#PSR_Z					;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mul r2,r0,r1
	movs r1,r2,asr#15
	mvnsne r1,r1
	orrne v30f,v30f,#PSR_C+PSR_V	;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]

	strh r2,[r4,#v30Regs]
	ldmfd sp!,{pc}
1:
	eatCycles 4
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_inmb:
_6C:	;@ INMB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegDW]
	bl cpu_readport
	ldrsb r3,[v30ptr,#v30DF]
	ldr r2,[v30ptr,#v30RegIY]
	mov r1,r0
	ldr r0,[v30ptr,#v30SRegES]
	add r3,r2,r3,lsl#16
	add r0,r0,r2,lsr#4
	str r3,[v30ptr,#v30RegIY]
	eatCycles 6
	ldmfd sp!,{lr}
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_inmw:
_6D:	;@ INMW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegDW]
	add r4,r0,#1
	bl cpu_readport
	mov r5,r0
	mov r0,r4
	bl cpu_readport
	ldrsb r3,[v30ptr,#v30DF]
	ldr r2,[v30ptr,#v30RegIY]
	orr r1,r5,r0,lsl#8
	ldr r0,[v30ptr,#v30SRegES]
	add r3,r2,r3,lsl#17
	add r0,r0,r2,lsr#4
	str r3,[v30ptr,#v30RegIY]
	eatCycles 6
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_outmb:
_6E:	;@ OUTMB
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r2,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r2,lsl#16
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20
	mov r1,r0
	ldrh r0,[v30ptr,#v30RegDW]
	eatCycles 7
	ldmfd sp!,{lr}
	b cpu_writeport
;@----------------------------------------------------------------------------
i_outmw:
_6F:	;@ OUTMW
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r2,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r2,lsl#17
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20W
	and r1,r0,#0xFF
	mov r4,r0
	ldrh r0,[v30ptr,#v30RegDW]
	mov r5,r0
	bl cpu_writeport
	mov r1,r4,lsr#8
	add r0,r5,#1
	ldmfd sp!,{lr}
	eatCycles 7
	b cpu_writeport

;@----------------------------------------------------------------------------
i_bv:
_70:	;@ Branch if Overflow
;@----------------------------------------------------------------------------
	jmpne PSR_V
;@----------------------------------------------------------------------------
i_bnv:
_71:	;@ Branch if Not Overflow
;@----------------------------------------------------------------------------
	jmpeq PSR_V
;@----------------------------------------------------------------------------
i_bc:
i_bl:
_72:	;@ Branch if Carry / Branch if Lower
;@----------------------------------------------------------------------------
	jmpne PSR_C
;@----------------------------------------------------------------------------
i_bnc:
i_bnl:
_73:	;@ Branch if Not Carry / Branch if Not Lower
;@----------------------------------------------------------------------------
	jmpeq PSR_C
;@----------------------------------------------------------------------------
i_be:
i_bz:
_74:	;@ Branch if Equal / Branch if Zero
;@----------------------------------------------------------------------------
	jmpne PSR_Z
;@----------------------------------------------------------------------------
i_bne:
i_bnz:
_75:	;@ Branch if Not Equal / Branch if Not Zero
;@----------------------------------------------------------------------------
	jmpeq PSR_Z
;@----------------------------------------------------------------------------
i_bnh:
_76:	;@ Branch if Not Higher, C | Z = 1.
;@----------------------------------------------------------------------------
	jmpne PSR_C|PSR_Z
;@----------------------------------------------------------------------------
i_bh:
_77:	;@ Branch if Higher, C | Z = 0.
;@----------------------------------------------------------------------------
	jmpeq PSR_C|PSR_Z
;@----------------------------------------------------------------------------
i_bn:
_78:	;@ Branch if Negative
;@----------------------------------------------------------------------------
	jmpne PSR_S
;@----------------------------------------------------------------------------
i_bp:
_79:	;@ Branch if Positive
;@----------------------------------------------------------------------------
	jmpeq PSR_S
;@----------------------------------------------------------------------------
i_bpe:
_7A:	;@ Branch if Parity Even
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	tst r2,#PSR_P
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_bpo:
_7B:	;@ Branch if Parity Odd
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	tst r2,#PSR_P
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_blt:
_7C:	;@ Branch if Less Than, S ^ V = 1.
;@----------------------------------------------------------------------------
	getNextSignedByte
	eor r2,v30f,v30f,lsr#3
	tst r2,#PSR_V
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_bge:
_7D:	;@ Branch if Greater than or Equal, S ^ V = 0.
;@----------------------------------------------------------------------------
	getNextSignedByte
	eor r2,v30f,v30f,lsr#3
	tst r2,#PSR_V
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_ble:
_7E:	;@ Branch if Less than or Equal, (S ^ V) | Z = 1.
;@----------------------------------------------------------------------------
	getNextSignedByte
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addle v30pc,v30pc,r0
	suble v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_bgt:
_7F:	;@ Branch if Greater Than, (S ^ V) | Z = 0.
;@----------------------------------------------------------------------------
	getNextSignedByte
	mov r1,v30f,lsl#28
	msr cpsr_flg,r1
	addgt v30pc,v30pc,r0
	subgt v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_80pre:
_80:	;@ PRE 80
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
i_82pre:
_82:	;@ PRE 82
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r5]
0:
	getNextByteToReg r1

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add80, or80, adc80, subc80, and80, sub80, xor80, cmp80
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
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
	bx lr
2:
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_81pre:
_81:	;@ PRE 81
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldr r6,[r5,#v30Regs2]
	eatCycles 1
0:
	getNextWord
pre81Continue:

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add81, or81, adc81, subc81, and81, sub81, xor81, cmp81
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	mov r6,r0,lsl#16
	ldmfd sp!,{lr}
	b 0b
add81:
	add16 r0,r6
	b 2f
or81:
	or16 r0,r6
	b 2f
adc81:
	adc16 r0,r6
	b 2f
subc81:
	subc16 r0,r6
	b 2f
and81:
	and16 r0,r6
	b 2f
sub81:
	sub16 r0,r6
	b 2f
xor81:
	xor16 r0,r6
	b 2f
cmp81:
	sub16 r0,r6
	bx lr
2:
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_83pre:
_83:	;@ PRE 83
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldr r6,[r5,#v30Regs2]
	eatCycles 1
0:
	getNextByte
	tst r0,#0x80
	orrne r0,r0,#0xFF00
	b pre81Continue
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	mov r6,r0,lsl#16
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	ldrb r4,[v30ptr,-r2]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	eatCycles 1
	ldrb r0,[v30ptr,-r2]
0:
	and8 r4,r0
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20
;@----------------------------------------------------------------------------
i_test_wr16:
_85:	;@ TEST WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldr r4,[r2,#v30Regs2]
	cmp r0,#0xC0
	bmi 1f
	and r1,r0,#7
	add r2,v30ptr,r1,lsl#2
	ldrh r0,[r2,#v30Regs]
	eatCycles 1
0:
	and16 r0,r4
	ldmfd sp!,{pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpuReadMem20W
;@----------------------------------------------------------------------------
i_xchg_br8:
_86:	;@ XCHG BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	cmp r0,#0xC0
	bmi 0f

	ldrb r2,[r1,#v30ModRmRm]
	ldrb r1,[v30ptr,-r4]
	ldrb r0,[v30ptr,-r2]
	strb r1,[v30ptr,-r2]
	strb r0,[v30ptr,-r4]
	eatCycles 3
	bx lr
0:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldrb r1,[v30ptr,-r4]
	strb r0,[v30ptr,-r4]
	mov r0,r5
	ldmfd sp!,{lr}
	b cpuWriteMem20

;@----------------------------------------------------------------------------
i_xchg_wr16:
_87:	;@ XCHG WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x38
	add r4,v30ptr,r4,lsr#1
	cmp r0,#0xC0
	bmi 0f

	and r2,r0,#7
	add r2,v30ptr,r2,lsl#2
	ldrh r0,[r2,#v30Regs]
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	strh r1,[r2,#v30Regs]
	eatCycles 3
	bx lr
0:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldrh r1,[r4,#v30Regs]
	strh r0,[r4,#v30Regs]
	mov r0,r5
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_mov_br8:
_88:	;@ MOV BR8
;@----------------------------------------------------------------------------
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	eatCycles 1
	ldrb r4,[v30ptr,-r2]
	cmp r0,#0xC0
	bmi 0f

	ldrb r2,[r1,#v30ModRmRm]
	strb r4,[v30ptr,-r2]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{lr}
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_mov_wr16:
_89:	;@ MOV WR16
;@----------------------------------------------------------------------------
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#1
	ldrh r4,[r2,#v30Regs]
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f

	and r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	strh r4,[r2,#v30Regs]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_mov_r8b:
_8A:	;@ MOV R8B
;@----------------------------------------------------------------------------
	getNextByte
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmReg]
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f

	ldrb r2,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r2]
	strb r0,[v30ptr,-r4]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	bl cpuReadMem20
	strb r0,[v30ptr,-r4]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_r16w:
_8B:	;@ MOV R16W
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x38
	add r4,v30ptr,r4,lsr#1
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f
Str_8B:
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	strh r0,[r4,#v30Regs]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	bl cpuReadMem20W
	strh r0,[r4,#v30Regs]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_wsreg:
_8C:	;@ MOV WSREG
;@----------------------------------------------------------------------------
	getNextByte
	and r2,r0,#0x38				;@ Mask with 0x18?
	add r1,v30ptr,r2,lsr#1
	ldrh r4,[r1,#v30SRegs+2]
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f

	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	strh r4,[r1,#v30Regs]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_lea:
_8D:	;@ LEA
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x38
	add r4,v30ptr,r4,lsr#1
	eatCycles 1
	cmp r0,#0xC0
	bpl Str_8B

	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]		;@ EATable return EO in r1
	str r1,[r4,#v30Regs2]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	eatCycles 2
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
0:
	tst r4,#0x20
	addeq r1,v30ptr,r4,lsr#1
	strheq r0,[r1,#v30SRegs+2]
	mov r1,#1
	strb r1,[v30ptr,#v30NoInterrupt]
	cmp r4,#0x08			;@ CS?
	beq V30EncodePC
	bx lr
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
i_popw:
_8F:	;@ POPW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	popWord
	mov r4,r0
	getNextByte
	cmp r0,#0xC0
	bmi 0f
	eatCycles 1
	and r0,r0,#7
	add r2,v30ptr,r0,lsl#2
	strh r4,[r2,#v30Regs]
	ldmfd sp!,{pc}
0:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_nop:
_90:	;@ NOP (XCHG AXAX)
;@----------------------------------------------------------------------------
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axcx:
_91:	;@ XCHG AXCX
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegCW]
	eatCycles 3
	strh r0,[v30ptr,#v30RegCW]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axdx:
_92:	;@ XCHG AXDX
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegDW]
	eatCycles 3
	strh r0,[v30ptr,#v30RegDW]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axbx:
_93:	;@ XCHG AXBX
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegBW]
	eatCycles 3
	strh r0,[v30ptr,#v30RegBW]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axsp:
_94:	;@ XCHG AXSP
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegSP+2]
	eatCycles 3
	strh r0,[v30ptr,#v30RegSP+2]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axbp:
_95:	;@ XCHG AXBP
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegBP]
	eatCycles 3
	strh r0,[v30ptr,#v30RegBP]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axsi:
_96:	;@ XCHG AXSI
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegIX+2]
	eatCycles 3
	strh r0,[v30ptr,#v30RegIX+2]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axdi:
_97:	;@ XCHG AXDI
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegIY+2]
	eatCycles 3
	strh r0,[v30ptr,#v30RegIY+2]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_cbw:
_98:	;@ CVTBW
;@----------------------------------------------------------------------------
	ldrsb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	strh r0,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_cwd:
_99:	;@ CVTWL
;@----------------------------------------------------------------------------
	ldrsb r0,[v30ptr,#v30RegAH]
	eatCycles 1
	mov r0,r0,asr#8
	strh r0,[v30ptr,#v30RegDW]
	bx lr
;@----------------------------------------------------------------------------
i_call_far:
_9A:	;@ CALL FAR
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	mov r4,r0
	getNextWord
	ldrh r1,[v30ptr,#v30SRegCS+2]
	strh r0,[v30ptr,#v30SRegCS+2]
	ldr r6,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	sub r6,r6,#0x20000
	add r0,r5,r6,lsr#4
	bl cpuWriteMem20W
	sub r6,r6,#0x20000
	str r6,[v30ptr,#v30RegSP]
	v30DecodeFastPCToReg r7
	mov v30pc,r4,lsl#16
	v30EncodeFastPC
	add r0,r5,r6,lsr#4
	mov r1,r7
	eatCycles 7
	ldmfd sp!,{lr}
	b cpuWriteMem20W

;@----------------------------------------------------------------------------
i_pushf:
_9C:	;@ PUSH F
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldr r1,=0xF002
	ldrb r2,[r3,r2]
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

	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	eatCycles 2
	b cpuWriteMem20W
	.pool
;@----------------------------------------------------------------------------
i_popf:
_9D:	;@ POP F
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
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
	movne r1,#1
	strb r1,[v30ptr,#v30TF]
	ands r1,r0,#IF
	movne r1,#1
	strb r1,[v30ptr,#v30IF]
	tst r0,#DF
	moveq r1,#1
	movne r1,#-1
	strb r1,[v30ptr,#v30DF]

	eatCycles 3
	ldmfd sp!,{lr}
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

	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_lahf:
_9F:	;@ LAHF
;@----------------------------------------------------------------------------
	mov r1,#0x02
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	tst v30f,#PSR_S
	orrne r1,r1,#SF
	tst v30f,#PSR_Z
	orrne r1,r1,#ZF
	tst v30f,#PSR_C
	orrne r1,r1,#CF
	tst r2,#PSR_P
	orrne r1,r1,#PF
	tst v30f,#PSR_A
	orrne r1,r1,#AF

	strb r1,[v30ptr,#v30RegAH]
	eatCycles 2
	bx lr
;@----------------------------------------------------------------------------
i_mov_aldisp:
_A0:	;@ MOV ALDISP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r1,[v30ptr,#v30PrefixBase]
	ldreq r1,[v30ptr,#v30SRegDS]
	add r0,r1,r0,lsl#12
	bl cpuReadMem20
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_axdisp:
_A1:	;@ MOV AXDISP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r1,[v30ptr,#v30PrefixBase]
	ldreq r1,[v30ptr,#v30SRegDS]
	add r0,r1,r0,lsl#12
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dispal:
_A2:	;@ MOV DISPAL
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r1,[v30ptr,#v30PrefixBase]
	ldreq r1,[v30ptr,#v30SRegDS]
	add r0,r1,r0,lsl#12
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_mov_dispax:
_A3:	;@ MOV DISPAX
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r1,[v30ptr,#v30PrefixBase]
	ldreq r1,[v30ptr,#v30SRegDS]
	add r0,r1,r0,lsl#12
	ldrh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_movsb:
_A4:	;@ MOVSB
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r4,lsl#16
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#16
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	eatCycles 5
	ldmfd sp!,{lr}
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_movsw:
_A5:	;@ MOVSW
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r4,lsl#17
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20W
	mov r1,r0
	ldr r3,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30SRegES]
	add r2,r3,r4,lsl#17
	add r0,r0,r3,lsr#4
	str r2,[v30ptr,#v30RegIY]
	eatCycles 5
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_cmpsb:
_A6:	;@ CMPSB
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r4,lsl#16
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#16
	mov r4,r0
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20

	sub8 r0,r4

	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_cmpsw:
_A7:	;@ CMPSW
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r4,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r4,lsl#17
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20W

	ldr r1,[v30ptr,#v30RegIY]
	ldr r3,[v30ptr,#v30SRegES]
	add r2,r1,r4,lsl#17
	mov r4,r0,lsl#16
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20W

	sub16 r0,r4

	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_test_ald8:
_A8:	;@ TEST ALD8
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	and8 r0,r1
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_test_axd16:
_A9:	;@ TEST AXD16
;@----------------------------------------------------------------------------
	getNextWord
	ldr r1,[v30ptr,#v30RegAW-2]
	and16 r0,r1
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STOSB
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30SRegES]
	ldr r1,[v30ptr,#v30RegIY]
	ldrsb r3,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r3,lsl#16
	str r2,[v30ptr,#v30RegIY]
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 3
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STOSW
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30SRegES]
	ldr r1,[v30ptr,#v30RegIY]
	ldrsb r3,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r3,lsl#17
	str r2,[v30ptr,#v30RegIY]
	ldrh r1,[v30ptr,#v30RegAW]
	eatCycles 3
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_lodsb:
_AC:	;@ LODSB
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r2,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r2,lsl#16
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_lodsw:
_AD:	;@ LODSW
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegIX]
	ldrsb r2,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r2,lsl#17
	str r2,[v30ptr,#v30RegIX]
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_scasb:
_AE:	;@ SCASB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,[v30ptr,#v30SRegES]
	ldr r1,[v30ptr,#v30RegIY]
	ldrsb r3,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r3,lsl#16
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_scasw:
_AF:	;@ SCASW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,[v30ptr,#v30SRegES]
	ldr r1,[v30ptr,#v30RegIY]
	ldrsb r3,[v30ptr,#v30DF]
	add r0,r0,r1,lsr#4
	add r2,r1,r3,lsl#17
	str r2,[v30ptr,#v30RegIY]
	bl cpuReadMem20W
	ldr r1,[v30ptr,#v30RegAW-2]

	sub16 r0,r1

	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ald8:
_B0:	;@ MOV ALD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_cld8:
_B1:	;@ MOV CLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegCL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_dld8:
_B2:	;@ MOV DLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegDL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_bld8:
_B3:	;@ MOV BLD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegBL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_ahd8:
_B4:	;@ MOV AHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_chd8:
_B5:	;@ MOV CHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegCH]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_dhd8:
_B6:	;@ MOV DHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegDH]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_bhd8:
_B7:	;@ MOV BHD8
;@----------------------------------------------------------------------------
	getNextByte
	strb r0,[v30ptr,#v30RegBH]
	eatCycles 1
	bx lr

;@----------------------------------------------------------------------------
i_mov_axd16:
_B8:	;@ MOV AXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_cxd16:
_B9:	;@ MOV CXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegCW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_dxd16:
_BA:	;@ MOV DXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegDW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_bxd16:
_BB:	;@ MOV BXD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegBW]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_spd16:
_BC:	;@ MOV SPD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegSP+2]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_bpd16:
_BD:	;@ MOV BPD16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegBP]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_sid16:
_BE:	;@ MOV SID16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIX+2]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_mov_did16:
_BF:	;@ MOV DID16
;@----------------------------------------------------------------------------
	getNextWord
	strh r0,[v30ptr,#v30RegIY+2]
	eatCycles 1
	bx lr

;@----------------------------------------------------------------------------
i_rotshft_bd8:
_C0:	;@ ROTSHFT BD8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r5]
	eatCycles 3
0:
	getNextByteToReg r1
d2Continue:
	ands r1,r1,#0x1F

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long rolC0, rorC0, rolcC0, rorcC0, shlC0, shrC0, undC0, shraC0
1:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
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
	stmfd sp!,{lr}
	bl i_undefined
	ldmfd sp!,{lr}
	mov r1,#0
	b 2f
shraC0:
	shra8 r0,r1
2:
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
;@----------------------------------------------------------------------------
i_rotshft_wd8:
_C1:	;@ ROTSHFT WD8
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 3
0:
	getNextByteToReg r1
d3Continue:
	ands r1,r1,#0x1F

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long rolC1, rorC1, rolcC1, rorcC1, shlC1, shrC1, undC1, shraC1
1:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
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
	stmfd sp!,{lr}
	bl i_undefined
	ldmfd sp!,{lr}
	mov r1,#0
	b 2f
shraC1:
	shra16 r0,r1
2:
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_ret_d16:
_C2:	;@ RET D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldr r1,[v30ptr,#v30RegSP]
	ldr r3,[v30ptr,#v30SRegSS]
	add r2,r1,#0x20000
	add r2,r2,r0,lsl#16
	add r0,r3,r1,lsr#4
	str r2,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_ret:
_C3:	;@ RET
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	add r2,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r2,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_les_dw:
_C4:	;@ LES DW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	sub r5,r0,r1,lsr#4
	add r6,r1,#0x20000
	bl cpuReadMem20W
0:
	add r1,v30ptr,r4,lsr#1
	strh r0,[r1,#v30Regs]
	add r0,r5,r6,lsr#4
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegES+2]

	eatCycles 6
	ldmfd sp!,{pc}
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	b 0b
;@----------------------------------------------------------------------------
i_lds_dw:
_C5:	;@ LDS DW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	sub r5,r0,r1,lsr#4
	add r6,r1,#0x20000
	bl cpuReadMem20W
0:
	add r1,v30ptr,r4,lsr#1
	strh r0,[r1,#v30Regs]
	add r0,r5,r6,lsr#4
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegDS+2]

	eatCycles 6
	ldmfd sp!,{pc}
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#2
	ldrh r0,[r1,#v30Regs]
	b 0b
;@----------------------------------------------------------------------------
i_mov_bd8:
_C6:	;@ MOV BD8
;@----------------------------------------------------------------------------
	getNextByte
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f
	add r1,v30ptr,r0
	ldrb r4,[r1,#v30ModRmRm]
	getNextByte
	strb r0,[v30ptr,-r4]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	getNextByteToReg r1
	ldmfd sp!,{lr}
	b cpuWriteMem20

;@----------------------------------------------------------------------------
i_mov_wd16:
_C7:	;@ MOV WD16
;@----------------------------------------------------------------------------
	getNextByte
	eatCycles 1
	cmp r0,#0xC0
	bmi 0f
	and r1,r0,#7
	add r4,v30ptr,r1,lsl#2
	getNextWord
	strh r0,[r4,#v30Regs]
	bx lr
0:
	stmfd sp!,{lr}
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r4,r0
	getNextWord
	mov r1,r0
	mov r0,r4
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_prepare:
_C8:	;@ PREPARE
;@----------------------------------------------------------------------------
	stmfd sp!,{r8,lr}
	eatCycles 8
	getNextWord
	stmfd sp!,{r0}				;@ temp
	getNextByte
	and r5,r0,#0x1F				;@ V30MZ specific

	ldr r8,[v30ptr,#v30RegSP]
	ldr r6,[v30ptr,#v30SRegSS]
	ldr r4,[v30ptr,#v30RegBP-2]
	sub r8,r8,#0x20000
	add r0,r6,r8,lsr#4
	mov r1,r4,lsr#16
	bl cpuWriteMem20W
	str r8,[v30ptr,#v30RegBP-2]
	subs r5,r5,#1
	bmi 2f
	beq 1f
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	moveq r7,r6
	ldrne r7,[v30ptr,#v30PrefixBase]
0:
	sub r4,r4,#0x20000
	add r0,r7,r4,lsr#4
	bl cpuReadMem20W
	mov r1,r0
	sub r8,r8,#0x20000
	add r0,r6,r8,lsr#4
	bl cpuWriteMem20W
	eatCycles 4
	subs r5,r5,#1
	bne 0b
1:
	ldrh r1,[v30ptr,#v30RegBP]
	sub r8,r8,#0x20000
	add r0,r6,r8,lsr#4
	bl cpuWriteMem20W
	eatCycles 6
2:
	ldmfd sp!,{r0}
	sub r8,r8,r0,lsl#16
	str r8,[v30ptr,#v30RegSP]
	ldmfd sp!,{r8,pc}
;@----------------------------------------------------------------------------
i_dispose:
_C9:	;@ DISPOSE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r0,[v30ptr,#v30SRegSS]
	add r2,r1,#0x20000
	add r0,r0,r1,lsr#4
	str r2,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30RegBP]
	eatCycles 2
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_retf_d16:
_CA:	;@ RETF D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	add r6,r0,#2
	ldr r1,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	add r4,r1,#0x20000
	add r0,r5,r1,lsr#4
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	add r0,r5,r4,lsr#4
	add r4,r4,r6,lsl#16
	str r4,[v30ptr,#v30RegSP]
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegCS+2]
	v30EncodeFastPC
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_retf:
_CB:	;@ RETF
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	add r4,r1,#0x20000
	add r0,r5,r1,lsr#4
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegCS+2]
	str r4,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	eatCycles 8
	ldmfd sp!,{pc}
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
_CE:	;@ BRKV					;@ Break if Overflow
;@----------------------------------------------------------------------------
	tst v30f,#PSR_V
	subeq v30cyc,v30cyc,#6*CYCLE
	bxeq lr
	eatCycles 13
	mov r0,#4
	b nec_interrupt
;@----------------------------------------------------------------------------
i_iret:
_CF:	;@ IRET
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,[v30ptr,#v30RegSP]
	ldr r5,[v30ptr,#v30SRegSS]
	add r4,r1,#0x20000
	add r0,r5,r1,lsr#4
	bl cpuReadMem20W
	mov v30pc,r0,lsl#16
	add r0,r5,r4,lsr#4
	add r4,r4,#0x20000
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegCS+2]
	str r4,[v30ptr,#v30RegSP]
	v30EncodeFastPC
	eatCycles 10					;@ -3?
	ldmfd sp!,{lr}
	b i_popf

;@----------------------------------------------------------------------------
i_rotshft_b:
_D0:	;@ ROTSHFT B
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 0f

	eatCycles 1
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r5]
	mov r1,#1
	b d2Continue
0:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	mov r1,#1
	b d2Continue
;@----------------------------------------------------------------------------
i_rotshft_w:
_D1:	;@ ROTSHFT W
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 0f

	eatCycles 1
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	mov r1,#1
	b d3Continue
0:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	mov r1,#1
	b d3Continue
;@----------------------------------------------------------------------------
i_rotshft_bcl:
_D2:	;@ ROTSHFT BCL
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 0f

	eatCycles 3
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r5]
	ldrb r1,[v30ptr,#v30RegCL]
	b d2Continue
0:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	ldrb r1,[v30ptr,#v30RegCL]
	b d2Continue
;@----------------------------------------------------------------------------
i_rotshft_wcl:
_D3:	;@ ROTSHFT WCL
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 0f

	eatCycles 3
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	ldrb r1,[v30ptr,#v30RegCL]
	b d3Continue
0:
	stmfd sp!,{lr}
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	ldrb r1,[v30ptr,#v30RegCL]
	b d3Continue
;@----------------------------------------------------------------------------
i_aam:
_D4:	;@ AAM/CVTBD	;@ Adjust After Multiply / Convert Binary to Decimal
;@----------------------------------------------------------------------------
	eatCycles 17
	getNextByte

	movs r1,r0,lsl#8
	ldrb r0,[v30ptr,#v30RegAL]
	beq d4DivideError
	rsb r1,r1,#1

	mov r2,#8
0:	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	subs r2,r2,#1
	bne 0b
	mov r0,r0,ror#8
	orr r0,r0,r0,lsr#16
	strh r0,[v30ptr,#v30RegAW]

	strb r0,[v30ptr,#v30ParityVal]
	movs v30f,r0,lsl#24					;@ Clear S, Z, C, V & A.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	bx lr
d4DivideError:
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	tst r0,#0xC0
	bicne v30f,v30f,#PSR_Z
	b divideError
;@----------------------------------------------------------------------------
i_aad:
_D5:	;@ AAD/CVTDB	;@ Adjust After Division / Convert Decimal to Binary
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
	eatCycles 6
	bx lr
;@----------------------------------------------------------------------------
i_salc:
_D6:	;@ SALC			;@ Set AL on Carry
;@----------------------------------------------------------------------------
	ands r0,v30f,PSR_C
	movne r0,#0xFF
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_trans:
_D7:	;@ TRANS
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	stmfd sp!,{lr}
	ldrb r2,[v30ptr,#v30RegAL]
	ldrh r1,[v30ptr,#v30RegBW]
	mov r1,r1,lsl#16
	add r1,r1,r2,lsl#16
	add r0,r0,r1,lsr#4
	bl cpuReadMem20
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 5
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_fpo1:
_D8:	;@ FPO1
;@----------------------------------------------------------------------------
	getNextByte
	eatCycles 1
	b i_undefined
;@----------------------------------------------------------------------------
i_loopne:
_E0:	;@ LOOPNE
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
	eatCycles 3
	bx lr
;@----------------------------------------------------------------------------
i_loope:
_E1:	;@ LOOPE
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	tstne v30f,#PSR_Z
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	strh r2,[v30ptr,#v30RegCW]
	v30ReEncodeFastPC
	eatCycles 3
	bx lr
;@----------------------------------------------------------------------------
i_loop:
_E2:	;@ LOOP
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	addne v30pc,v30pc,r0
	subne v30cyc,v30cyc,#3*CYCLE
	strh r2,[v30ptr,#v30RegCW]
	v30ReEncodeFastPC
	eatCycles 2
	bx lr
;@----------------------------------------------------------------------------
i_jcxz:
_E3:	;@ JCXZ
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrh r2,[v30ptr,#v30RegCW]
	cmp r2,#0
	addeq v30pc,v30pc,r0
	subeq v30cyc,v30cyc,#3*CYCLE
	v30ReEncodeFastPC
	eatCycles 1
	bx lr

;@----------------------------------------------------------------------------
i_inal:
_E4:	;@ INAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_inax:
_E5:	;@ INAX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	mov r4,r0
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_outal:
_E6:	;@ OUTAL
;@----------------------------------------------------------------------------
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 6
	b cpu_writeport
;@----------------------------------------------------------------------------
i_outax:
_E7:	;@ OUTAX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	mov r4,r0
	bl cpu_writeport
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	eatCycles 6
	ldmfd sp!,{lr}
	b cpu_writeport

;@----------------------------------------------------------------------------
i_call_d16:
_E8:	;@ CALL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	v30DecodeFastPCToReg r4
	mov r1,r4,lsl#16
	add v30pc,r1,r0,lsl#16
	v30EncodeFastPC
	mov r1,r4
	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	eatCycles 5
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
i_jmp_d16:
_E9:	;@ JMP D16
;@----------------------------------------------------------------------------
	getNextWord
	v30DecodeFastPCToReg r1
	mov r1,r1,lsl#16
	add v30pc,r1,r0,lsl#16
	stmfd sp!,{lr}
	v30EncodeFastPC
	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_jmp_far:
_EA:	;@ JMP FAR
;@----------------------------------------------------------------------------
	getNextWord
	mov r4,r0
	getNextWord
	strh r0,[v30ptr,#v30SRegCS+2]
	mov v30pc,r4,lsl#16
	stmfd sp!,{lr}
	v30EncodeFastPC
	eatCycles 7
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_br_d8:
_EB:	;@ Branch short
;@----------------------------------------------------------------------------
	getNextByte
	mov r1,r0,lsl#24
	add v30pc,v30pc,r1,asr#PC_OFS_COUNT
	eatCycles 4
	cmp r0,#0xFC
	andhi v30cyc,v30cyc,#CYC_MASK
	v30ReEncodeFastPC
	bx lr
;@----------------------------------------------------------------------------
i_inaldx:
_EC:	;@ INALDX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegDW]
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_inaxdx:
_ED:	;@ INAXDX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r4,[v30ptr,#v30RegDW]
	mov r0,r4
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_outdxal:
_EE:	;@ OUTDXAL
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 6
	b cpu_writeport
;@----------------------------------------------------------------------------
i_outdxax:
_EF:	;@ OUTDXAX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r4,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	mov r0,r4
	bl cpu_writeport
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	eatCycles 6
	ldmfd sp!,{lr}
	b cpu_writeport

;@----------------------------------------------------------------------------
i_lock:
_F0:	;@ BUS LOCK
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30NoInterrupt]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_brks:
_F1:	;@ BRKS, Break to Security Mode. Not working on V30MZ?
;@----------------------------------------------------------------------------
	b i_crash
;@----------------------------------------------------------------------------
i_repne:
_F2:	;@ REPNE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF2Prefix
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	mov r0,#1
	ldrh r2,[r1,#v30SRegs+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r2,[v30ptr,#v30PrefixBase+2]

	eatCycles 2
	getNextByte
noF2Prefix:
	ldrh r7,[v30ptr,#v30RegCW]
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

f2a6:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_cmpsb
	eatCycles 3
	subs r7,r7,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	b f3End

f2a7:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_cmpsw
	eatCycles 3
	subs r7,r7,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	b f3End

f2ae:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_scasb
	eatCycles 5
	subs r7,r7,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	b f3End

f2af:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_scasw
	eatCycles 5
	subs r7,r7,#1
	andne r0,v30f,#PSR_Z
	cmpne r0,#PSR_Z
	bne 0b
	b f3End
;@----------------------------------------------------------------------------
i_repe:
_F3:	;@ REPE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF3Prefix
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	mov r0,#1
	ldrh r2,[r1,#v30SRegs+2]
	strb r0,[v30ptr,#v30SegPrefix]
	strh r2,[v30ptr,#v30PrefixBase+2]

	eatCycles 2
	getNextByte
noF3Prefix:
	ldrh r7,[v30ptr,#v30RegCW]
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

f36c:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_inmb
	subs r7,r7,#1
	bne 0b
	b f3End

f36d:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_inmw
	subs r7,r7,#1
	bne 0b
	b f3End

f36e:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_outmb
	eatCycles -1
	subs r7,r7,#1
	bne 0b
	b f3End

f36f:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_outmw
	eatCycles -1
	subs r7,r7,#1
	bne 0b
	b f3End

f3a4:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_movsb
	eatCycles 2
	subs r7,r7,#1
	bne 0b
	b f3End

f3a5:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_movsw
	eatCycles 2
	subs r7,r7,#1
	bne 0b
	b f3End

f3a6:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_cmpsb
	eatCycles 4
	subs r7,r7,#1
	tstne v30f,#PSR_Z
	bne 0b
	b f3End

f3a7:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_cmpsw
	eatCycles 4
	subs r7,r7,#1
	tstne v30f,#PSR_Z
	bne 0b
	b f3End

f3aa:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_stosb
	eatCycles 3
	subs r7,r7,#1
	bne 0b
	b f3End

f3ab:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_stosw
	eatCycles 3
	subs r7,r7,#1
	bne 0b
	b f3End

f3ac:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_lodsb
	eatCycles 3
	subs r7,r7,#1
	bne 0b
	b f3End

f3ad:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_lodsw
	eatCycles 3
	subs r7,r7,#1
	bne 0b
	b f3End

f3ae:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_scasb
	eatCycles 4
	subs r7,r7,#1
	tstne v30f,#PSR_Z
	bne 0b
	b f3End

f3af:
	eatCycles 5
	cmp r7,#1
	bmi f3End
0:	bl i_scasw
	eatCycles 4
	subs r7,r7,#1
	tstne v30f,#PSR_Z
	bne 0b
	b f3End

f3Default:
	adr lr,f3DefEnd
	ldr pc,[v30ptr,r0,lsl#2]

f3End:
	strh r7,[v30ptr,#v30RegCW]
f3DefEnd:
	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_hlt:
_F4:	;@ HLT
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30IrqPin]
	cmp r0,#0
	andeq v30cyc,v30cyc,#CYC_MASK
	moveq r0,#1
	strbeq r0,[v30ptr,#v30Halt]
	bx lr
;@----------------------------------------------------------------------------
i_cmc:
_F5:	;@ CMC
;@----------------------------------------------------------------------------
	eor v30f,v30f,#PSR_C
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_f6pre:
_F6:	;@ PRE F6
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r5]
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF6, undefF6, notF6, negF6, muluF6, mulF6, divubF6, divbF6
1:
	stmfd sp!,{lr}
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
testF6:
	getNextByteToReg r1
	and8 r1,r0
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
notF6:
	eatCycles 1
	mvn r1,r0
	cmp r4,#0xC0
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	eatCycles 1
	b cpuWriteMem20
;@----------------------------------------------------------------------------
negF6:
	eatCycles 1
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
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	eatCycles 1
	b cpuWriteMem20
;@----------------------------------------------------------------------------
muluF6:
	eatCycles 3
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrb r1,[v30ptr,#v30RegAL]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#8
	orrne v30f,v30f,#PSR_C+PSR_V
	strb v30f,[v30ptr,#v30MulOverflow]
	bx lr
;@----------------------------------------------------------------------------
mulF6:
	eatCycles 3
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
	bx lr
;@----------------------------------------------------------------------------
divubF6:
	eatCycles 15
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mov r1,r0,lsl#8
	ldrh r0,[v30ptr,#v30RegAW]
	cmp r0,r1
	bcs divideError
	rsb r1,r1,#1

	mov r2,#8
0:	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	subs r2,r2,#1
	bne 0b

	strh r0,[v30ptr,#v30RegAW]
	bic r0,#0xFE
	cmp r0,#1
	bicne v30f,v30f,#PSR_Z
	bx lr
;@----------------------------------------------------------------------------
divbF6:
	eatCycles 17
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

	mov r2,#8
0:	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	subs r2,r2,#1
	bne 0b

	mov r1,r0,lsr#24
	tst r3,#0x8000
	rsbne r1,r1,#0
	cmp r3,#0
	rsbmi r0,r0,#0
1:
	movs v30f,r0,lsl#24					;@ Test S, Z.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strb r0,[v30ptr,#v30RegAL]
	strb r1,[v30ptr,#v30RegAH]
	strb r0,[v30ptr,#v30ParityVal]		;@ Set parity
	bx lr
divbF6Error:
	cmp r0,#0x80000000
	moveq r0,#0x0081
	beq 1b
divbF6Error2:
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	b divideError
;@----------------------------------------------------------------------------
i_f7pre:
_F7:	;@ PRE F7
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF7, undefF7, notF7, negF7, muluF7, mulF7, divuwF7, divwF7
1:
	stmfd sp!,{lr}
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20W
	ldmfd sp!,{lr}
	b 0b
;@----------------------------------------------------------------------------
testF7:
	eatCycles 1
	mov r4,r0,lsl#16
	getNextWord
	and16 r0,r4
	bx lr
;@----------------------------------------------------------------------------
notF7:
	eatCycles 1
	mvn r1,r0
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
negF7:
	eatCycles 1
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
	strhpl r1,[r5,#v30Regs]
	bxpl lr
	mov r0,r5
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
muluF7:
	eatCycles 3
	mov v30f,#PSR_Z						;@ Set Z and clear others.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#16
	strh r2,[v30ptr,#v30RegDW]
	orrne v30f,v30f,#PSR_C+PSR_V		;@ Set Carry & Overflow.
	strb v30f,[v30ptr,#v30MulOverflow]
	bx lr
;@----------------------------------------------------------------------------
mulF7:
	eatCycles 3
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
	bx lr
;@----------------------------------------------------------------------------
divuwF7:
	eatCycles 23
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	mov r1,r0,lsl#16
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16
	cmp r0,r1
	bcs divideError
	rsb r1,r1,#1

	mov r2,#16
0:	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	subs r2,r2,#1
	bne 0b

	mov r1,r0,lsr#16
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	bx lr
;@----------------------------------------------------------------------------
divwF7:
	eatCycles 24
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

	mov r2,#16
0:	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	subs r2,r2,#1
	bne 0b

	mov r1,r0,lsr#16
	tst r3,#0x8000
	rsbne r1,r1,#0
	cmp r3,#0
	rsbmi r0,r0,#0
1:
	movs v30f,r0,lsl#16					;@ Test S, Z.
	movmi v30f,#PSR_S
	moveq v30f,#PSR_Z
	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	strb r0,[v30ptr,#v30ParityVal]		;@ Set parity
	bx lr
divwF7Error:
	cmp r0,#0x80000000
	moveq r0,#0x0081
	beq 1b
divwF7Error2:
	ldrb v30f,[v30ptr,#v30MulOverflow]	;@ C & V from last mul, Z always set.
	strb v30f,[v30ptr,#v30ParityVal]	;@ Clear parity
	b divideError
;@----------------------------------------------------------------------------
i_clc:
_F8:	;@ CLC
;@----------------------------------------------------------------------------
	bic v30f,v30f,#PSR_C				;@ Clear Carry.
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_stc:
_F9:	;@ STC
;@----------------------------------------------------------------------------
	orr v30f,v30f,#PSR_C				;@ Set Carry.
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_di:
_FA:	;@ DI
;@----------------------------------------------------------------------------
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_ei:
_FB:	;@ EI
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30IF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_cld:
_FC:	;@ CLD
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30DF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_std:
_FD:	;@ STD
;@----------------------------------------------------------------------------
	mov r0,#-1
	strb r0,[v30ptr,#v30DF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_fepre:
_FE:	;@ PRE FE
;@----------------------------------------------------------------------------
	getNextByteToReg r4
	tst r4,#0x30
	bne contFF
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r4
	ldrb r5,[r1,#v30ModRmRm]
	ldrb r0,[v30ptr,-r5]
	eatCycles 1
0:
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
	strbpl r1,[v30ptr,-r5]
	bxpl lr
	mov r0,r5
	b cpuWriteMem20
1:
	stmfd sp!,{lr}
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	bl cpuReadMem20
	ldmfd sp!,{lr}
	b 0b

;@----------------------------------------------------------------------------
i_ffpre:
_FF:	;@ PRE FF
;@----------------------------------------------------------------------------
	getNextByteToReg r4
contFF:
	stmfd sp!,{lr}
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#2
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long incFF, decFF, callFF, callFarFF, braFF, braFarFF, pushFF, undefFF
1:
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r4,lsl#2]
	mov r5,r0
	mov r6,r1
	adr lr,0b
	b cpuReadMem20W
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
	eatCycles 1
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfdpl sp!,{pc}
	mov r0,r5
	ldmfd sp!,{lr}
	eatCycles 1
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
callFF:
	eatCycles 5
	v30DecodeFastPCToReg r5
	mov v30pc,r0,lsl#16
	V30EncodeFastPC
	mov r1,r5
	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
callFarFF:
	eatCycles 11
	v30DecodeFastPCToReg r4
	mov v30pc,r0,lsl#16
	sub r5,r5,r6,lsr#4
	add r6,r6,#0x20000
	add r0,r5,r6,lsr#4
	bl cpuReadMem20W

	ldrh r1,[v30ptr,#v30SRegCS+2]
	strh r0,[v30ptr,#v30SRegCS+2]
	ldr r5,[v30ptr,#v30RegSP]
	ldr r6,[v30ptr,#v30SRegSS]
	sub r5,r5,#0x20000
	add r0,r6,r5,lsr#4
	bl cpuWriteMem20W

	V30EncodeFastPC
	mov r1,r4
	sub r5,r5,#0x20000
	add r0,r6,r5,lsr#4
	str r5,[v30ptr,#v30RegSP]
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
braFF:
	eatCycles 4
	mov v30pc,r0,lsl#16
	v30EncodeFastPC
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
braFarFF:
	eatCycles 9
	mov v30pc,r0,lsl#16
	sub r5,r5,r6,lsr#4
	add r6,r6,#0x20000
	add r0,r5,r6,lsr#4
	bl cpuReadMem20W
	strh r0,[v30ptr,#v30SRegCS+2]
	v30EncodeFastPC
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
pushFF:
	eatCycles 1
	mov r1,r0
	ldr r2,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#0x20000
	add r0,r0,r2,lsr#4
	str r2,[v30ptr,#v30RegSP]
	ldmfd sp!,{lr}
	b cpuWriteMem20W
;@----------------------------------------------------------------------------
undefFF:
	eatCycles 1
	ldmfd sp!,{lr}
	b i_undefined

;@----------------------------------------------------------------------------
division16:
;@----------------------------------------------------------------------------
	adds r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
	subcc r0,r0,r1
	adcs r0,r1,r0,lsl#1
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
// All EA functions must leave EO in top 16bits of r1!
;@----------------------------------------------------------------------------
EA_000:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_001:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_002:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_003:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_004:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_005:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_006:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	mov r1,r0,lsl#16
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_007:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	cmp r2,#0
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldreq r0,[v30ptr,#v30SRegDS]
	add r0,r0,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_100:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_101:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_102:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_103:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_104:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_105:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_106:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_107:	;@
;@----------------------------------------------------------------------------
	getNextSignedByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_200:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_201:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_202:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_203:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	ldr r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r3
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_204:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_205:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_206:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBP-2]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegSS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr
;@----------------------------------------------------------------------------
EA_207:	;@
;@----------------------------------------------------------------------------
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldr r1,[v30ptr,#v30RegBW-2]
	cmp r2,#0
	ldrne r2,[v30ptr,#v30PrefixBase]
	ldreq r2,[v30ptr,#v30SRegDS]
	add r1,r1,r0,lsl#16
	add r0,r2,r1,lsr#4
	bx lr

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
	bl cpuReadMem20				;@ Returns phyAdr in r1
	sub r0,r1,v30pc,lsr#16
	str r0,[v30ptr,#v30LastBank]
	mov v30pc,r1
	ldmfd sp!,{pc}
/*
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
doV30NMI:
;@----------------------------------------------------------------------------
	mov r11,r11
	mov r0,#0
	strb r0,[v30ptr,#v30NmiPending]
	mov r0,#2
	bl nec_interrupt
	b V30Go
 */
;@----------------------------------------------------------------------------
V30SetIRQPin:			;@ r0=pin state
;@----------------------------------------------------------------------------
	cmp r0,#0
	movne r0,#0x01
	strb r0,[v30ptr,#v30IrqPin]
	movne r0,#0
	strbne r0,[v30ptr,#v30Halt]
	bx lr
;@----------------------------------------------------------------------------
doV30IRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov lr,pc
	ldr pc,[v30ptr,#v30IrqVectorFunc]
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
V30SetIRQ:
nec_interrupt:				;@ r0 = vector number
	.type   nec_interrupt STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r4,r0,lsl#12+2
	bl i_pushf
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	strb r0,[v30ptr,#v30TF]
	mov r0,r4
	bl cpuReadMem20W
	mov r5,r0
	add r0,r4,#0x2000
	bl cpuReadMem20W

	ldr r6,[v30ptr,#v30RegSP]
	ldr r4,[v30ptr,#v30SRegSS]
	sub r6,r6,#0x20000
	ldrh r1,[v30ptr,#v30SRegCS+2]
	strh r0,[v30ptr,#v30SRegCS+2]
	add r0,r4,r6,lsr#4
	bl cpuWriteMem20W
	v30DecodeFastPCToReg r1
	sub r6,r6,#0x20000
	add r0,r4,r6,lsr#4
	str r6,[v30ptr,#v30RegSP]
	bl cpuWriteMem20W

	mov v30pc,r5,lsl#16
	v30EncodeFastPC
	eatCycles 22
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
V30RestoreAndRunXCycles:	;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	ldr v30cyc,[v30ptr,#v30ICount]
	ldr v30pc,[v30ptr,#v30IP]
	ldr v30f,[v30ptr,#v30Flags]
	v30EncodeFastPC
;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add v30cyc,v30cyc,r0,lsl#CYC_SHIFT
;@----------------------------------------------------------------------------
V30CheckIRQs:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
v30ChkIrqInternal:					;@ This can be used on EI/IRET/POPF
	ldrh r0,[v30ptr,#v30IrqPin]		;@ NMI, Irq pin and IF
//	movs r1,r0,lsr#24
//	bne doV30NMI
	ands r1,r0,r0,lsr#8
	blne doV30IRQ
	ldrb r1,[v30ptr,#v30Halt]
	cmp r1,#0
	andne v30cyc,v30cyc,#CYC_MASK
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
xLoop:
	adr lr,xLoop
	fetch 0
xOut:
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
i_undefined:
undefF6:
undefF7:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=debugUndefinedInstruction
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}

	mov r11,r11					;@ NoCash breakpoint
	bx lr
;@----------------------------------------------------------------------------
i_crash:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=debugCrashInstruction
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}

	sub v30pc,v30pc,#1
	mov r11,r11					;@ NoCash breakpoint
	bx lr
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
	strb r3,[r0,r2]
	add r2,r2,#1
	cmp r2,#0x100
	bne regConvLoop

	add r0,v30ptr,#v30ModRmReg
	mov r2,#0
regConv2Loop:
	and r3,r2,#0x38
	ldr r3,[r1,r3,lsr#1]
	rsb r3,r3,#0
	strb r3,[r0,r2]
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

nec_instruction:
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
	.long i_undefined	// poll
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
Mod_RM:
	.space 0x100
	.space 0x100
;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
