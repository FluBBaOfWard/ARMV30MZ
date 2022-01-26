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

	.global I
	.global no_interrupt
	.global Mod_RM

	.global V30OpTable
	.global PZSTable

;@----------------------------------------------------------------------------
i_add_br8:
_00:	;@ ADD BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	add8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_add_wr16:
_01:	;@ ADD WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	add16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_add_r8b:
_02:	;@ ADD R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	add8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_add_r16w:
_03:	;@ ADD R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	add16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_add_ald8:
_04:	;@ ADD ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	add8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_add_axd16:
_05:	;@ ADD AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	add16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_es:
_06:	;@ PUSH ES
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegES]
	eatCycles 2
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_pop_es:
_07:	;@ POP ES
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegES]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_or_br8:
_08:	;@ OR BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	or8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_or_wr16:
_09:	;@ OR WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	or16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_or_r8b:
_0A:	;@ OR R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	or8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_or_r16w:
_0B:	;@ OR R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	or16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_or_ald8:
_0C:	;@ OR ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	or8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_or_axd16:
_0D:	;@ OR AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	or16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_cs:
_0E:	;@ PUSH CS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegCS]
	eatCycles 2
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_pop_cs:
_0F:	;@ POP CS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_adc_br8:
_10:	;@ ADC BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	adc8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_adc_wr16:
_11:	;@ ADC WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	adc16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_adc_r8b:
_12:	;@ ADC R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	adc8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_adc_r16w:
_13:	;@ ADC R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	adc16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_adc_ald8:
_14:	;@ ADC ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	adc8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_adc_axd16:
_15:	;@ ADC AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	adc16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_ss:
_16:	;@ PUSH SS
;@----------------------------------------------------------------------------
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r1,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	eatCycles 2
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_pop_ss:
_17:	;@ POP SS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegSS]
	eatCycles 3
	mov r0,#1
	str r0,[v30ptr,#v30NoInterrupt]			;@ What is this?
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sbb_br8:
_18:	;@ SBB BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	subc8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_sbb_wr16:
_19:	;@ SBB WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	subc16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_sbb_r8b:
_1A:	;@ SBB R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	subc8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_sbb_r16w:
_1B:	;@ SBB R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	subc16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_sbb_ald8:
_1C:	;@ SBB ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	subc8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sbb_axd16:
_1D:	;@ SBB AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	subc16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_ds:
_1E:	;@ PUSH DS
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegDS]
	eatCycles 2
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_pop_ds:
_1F:	;@ POP DS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegDS]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_and_br8:
_20:	;@ AND BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	and8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_and_wr16:
_21:	;@ AND WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	and16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_and_r8b:
_22:	;@ AND R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	and8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_and_r16w:
_23:	;@ AND R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	and16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_and_ald8:
_24:	;@ AND ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	and8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_and_axd16:
_25:	;@ AND AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	and16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_es:
_26:	;@ ES prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegES]
	strb r0,[v30ptr,#v30SegPrefix]
	str r1,[v30ptr,#v30PrefixBase]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_daa:
_27:	;@ DAA
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30AuxVal]
	ldr r2,[v30ptr,#v30CarryVal]
	mov r3,r0,ror#4
	cmp r3,#0xA0000000
	movcs r1,#0x10
	cmp r1,#0
	addne r0,r0,#0x06
	str r1,[v30ptr,#v30AuxVal]
	cmp r0,#0xA0
	movpl r2,#1
	cmp r2,#0
	addne r0,r0,#0x60
	str r2,[v30ptr,#v30CarryVal]
	strb r0,[v30ptr,#v30RegAL]
	mov r0,r0,lsl#24
	mov r0,r0,asr#24
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
	eatCycles 10
	bx lr
;@----------------------------------------------------------------------------
i_sub_br8:
_28:	;@ SUB BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	sub8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_sub_wr16:
_29:	;@ SUB WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	sub16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_sub_r8b:
_2A:	;@ SUB R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	sub8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_sub_r16w:
_2B:	;@ SUB R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	sub16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_sub_ald8:
_2C:	;@ SUB ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sub_axd16:
_2D:	;@ SUB AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	sub16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_cs:
_2E:	;@ CS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegCS]
	strb r0,[v30ptr,#v30SegPrefix]
	str r1,[v30ptr,#v30PrefixBase]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_das:
_2F:	;@ DAS
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30AuxVal]
	ldr r2,[v30ptr,#v30CarryVal]
	mov r3,r0,ror#4
	cmp r3,#0xA0000000
	movcs r1,#0x10
	cmp r1,#0
	subne r0,r0,#0x06
	str r1,[v30ptr,#v30AuxVal]
	cmp r0,#0xA0
	movpl r2,#1
	cmp r2,#0
	subne r0,r0,#0x60
	str r2,[v30ptr,#v30CarryVal]
	strb r0,[v30ptr,#v30RegAL]
	mov r0,r0,lsl#24
	mov r0,r0,asr#24
	str r0,[v30ptr,#v30SignVal]
	str r0,[v30ptr,#v30ZeroVal]
	str r0,[v30ptr,#v30ParityVal]
	eatCycles 10
	bx lr
;@----------------------------------------------------------------------------
i_xor_br8:
_30:	;@ XOR BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	xor8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_xor_wr16:
_31:	;@ XOR WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	xor16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_xor_r8b:
_32:	;@ XOR R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	xor8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_xor_r16w:
_33:	;@ XOR R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	xor16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_xor_ald8:
_34:	;@ XOR ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	xor8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_xor_axd16:
_35:	;@ XOR AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	xor16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_ss:
_36:	;@ SS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegSS]
	strb r0,[v30ptr,#v30SegPrefix]
	str r1,[v30ptr,#v30PrefixBase]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_aaa:
_37:	;@ AAA
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30AuxVal]
	mov r0,r0,lsl#28
	cmp r0,#0xA0000000
	movcs r1,#0x10
	cmp r1,#0
	ldrbne r2,[v30ptr,#v30RegAH]
	addne r0,r0,#0x60000000
	addne r2,r2,#1
	strbne r2,[v30ptr,#v30RegAH]
	mov r0,r0,lsr#28
	str r1,[v30ptr,#v30AuxVal]
	mov r1,r1,lsr#4
	str r1,[v30ptr,#v30CarryVal]
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 9
	bx lr
;@----------------------------------------------------------------------------
i_cmp_br8:
_38:	;@ CMP BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r4,v30ptr,r0
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r4,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r4,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	sub8 r1,r0

	ldmfd sp!,{r4,pc}
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_cmp_wr16:
_39:	;@ CMP WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r2,v30ptr,r2,lsl#1
	ldrh r0,[r2,#v30Regs]
	eatCycles 1
0:
	add r2,v30ptr,r4,lsr#2
	ldrh r1,[r2,#v30Regs]

	sub16 r1,r0

	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_cmp_r8b:
_3A:	;@ CMP R8b
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r1,[r4,#v30Regs]

	sub8 r0,r1

	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_cmp_r16w:
_3B:	;@ CMP R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrh r1,[r4,#v30Regs]

	sub16 r0,r1

	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_cmp_ald8:
_3C:	;@ CMP ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_cmp_axd16:
_3D:	;@ CMP AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	sub16 r0,r1

	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_ds:
_3E:	;@ DS prefix
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#1
	ldrh r1,[v30ptr,#v30SRegDS]
	strb r0,[v30ptr,#v30SegPrefix]
	str r1,[v30ptr,#v30PrefixBase]

	eatCycles 1

	getNextByte
	mov lr,pc
	ldr pc,[v30ptr,r0,lsl#2]

	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_aas:
_3F:	;@ AAS
;@----------------------------------------------------------------------------
	ldrb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30AuxVal]
	mov r0,r0,lsl#28
	cmp r0,#0xA0000000
	movcs r1,#0x10
	cmp r1,#0
	ldrbne r2,[v30ptr,#v30RegAH]
	subne r0,r0,#0x60000000
	subne r2,r2,#1
	strbne r2,[v30ptr,#v30RegAH]
	mov r0,r0,lsr#28
	str r1,[v30ptr,#v30AuxVal]
	mov r1,r1,lsr#4
	str r1,[v30ptr,#v30CarryVal]
	strb r0,[v30ptr,#v30RegAL]
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
	incWord v30RegSP
;@----------------------------------------------------------------------------
i_inc_bp:
_45:	;@ INC BP
;@----------------------------------------------------------------------------
	incWord v30RegBP
;@----------------------------------------------------------------------------
i_inc_si:
_46:	;@ INC SI
;@----------------------------------------------------------------------------
	incWord v30RegIX
;@----------------------------------------------------------------------------
i_inc_di:
_47:	;@ INC DI
;@----------------------------------------------------------------------------
	incWord v30RegIY
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
	decWord v30RegSP
;@----------------------------------------------------------------------------
i_dec_bp:
_4D:	;@ DEC BP
;@----------------------------------------------------------------------------
	decWord v30RegBP
;@----------------------------------------------------------------------------
i_dec_si:
_4E:	;@ DEC SI
;@----------------------------------------------------------------------------
	decWord v30RegIX
;@----------------------------------------------------------------------------
i_dec_di:
_4F:	;@ DEC DI
;@----------------------------------------------------------------------------
	decWord v30RegIY
;@----------------------------------------------------------------------------
i_push_ax:
_50:	;@ PUSH AX
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_cx:
_51:	;@ PUSH CX
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegCW]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_dx:
_52:	;@ PUSH DX
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegDW]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_bx:
_53:	;@ PUSH BX
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBW]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_sp:
_54:	;@ PUSH SP
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_bp:
_55:	;@ PUSH BP
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBP]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_si:
_56:	;@ PUSH SI
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIX]
	eatCycles 1
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_push_di:
_57:	;@ PUSH DI
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIY]
	eatCycles 1
	b cpu_writemem20w

;@----------------------------------------------------------------------------
i_pop_ax:
_58:	;@ POP AX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_cx:
_59:	;@ POP CX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegCW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_dx:
_5A:	;@ POP DX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegDW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_bx:
_5B:	;@ POP BX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_sp:
_5C:	;@ POP SP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r0,r1,r0,lsl#4
	bl cpu_readmem20w
	add r0,r0,#2
	strh r0,[v30ptr,#v30RegSP]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_bp:
_5D:	;@ POP BP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBP]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_si:
_5E:	;@ POP SI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIX]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_di:
_5F:	;@ POP DI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIY]
	eatCycles 1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_pusha:
_60:	;@ PUSHA
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r4,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegCW]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegDW]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegBW]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	add r1,r4,#10				;@ Original SP
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegBP]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegIX]
	bl cpu_writemem20w
	sub r4,r4,#2
	add r0,r4,r5,lsl#4
	ldrh r1,[v30ptr,#v30RegIY]
	bl cpu_writemem20w
	strh r4,[v30ptr,#v30RegSP]
	eatCycles 9
	ldmfd sp!,{r4,r5,pc}
;@----------------------------------------------------------------------------
i_popa:
_61:	;@ POPA
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIY]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIX]
	add r0,r4,r5,lsl#4
	add r4,r4,#4				;@ Skip one
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBP]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBW]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegDW]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegCW]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	strh r4,[v30ptr,#v30RegSP]
	eatCycles 8
	ldmfd sp!,{r4,r5,pc}
;@----------------------------------------------------------------------------
i_chkind:
_62:	;@ CHKIND
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r6,r0,ror#16
	bl cpu_readmem20w
0:
	mov r5,r0
	add r6,r6,#0x20000
	mov r0,r6,ror#16
	bl cpu_readmem20w
	ldrh r1,[r4,#v30Regs]

	eatCycles 13
	cmp r1,r5
	cmppl r0,r1
	submi v30cyc,v30cyc,#7*CYCLE
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	mov r0,#5
	b nec_interrupt
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	b 0b

;@----------------------------------------------------------------------------
i_push_d16:
_68:	;@ PUSH D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	mov r1,r0
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	eatCycles 1
	ldmfd sp!,{lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_imul_d16:
_69:	;@ IMUL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 3
0:
	mov r5,r0
	getNextWord

	mul r0,r5,r0
	movs r1,r0,asr#15
	mvnsne r1,r1
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,r5,pc}
1:
	eatCycles 4
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_push_d8:
_6A:	;@ PUSH D8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	mov r1,r0,lsl#24
	mov r1,r1,asr#24
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	eatCycles 1
	ldmfd sp!,{lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_imul_d8:
_6B:	;@ IMUL D8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	eatCycles 3
0:
	mov r5,r0
	getNextByte
	mov r0,r0,lsl#24
	mov r0,r0,asr#24

	mul r0,r5,r0
	movs r1,r0,asr#15
	mvnsne r1,r1
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,r5,pc}
1:
	eatCycles 4
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_insb:
_6C:	;@ INSB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegCW]
	bl cpu_readport
	ldrb r1,[v30ptr,#v30DF]
	ldrh r2,[v30ptr,#v30RegIY]
	cmp r1,#0
	mov r1,r0
	ldrh r0,[v30ptr,#v30SRegES]
	addeq r3,r2,#1
	subne r3,r2,#1
	add r0,r2,r0,lsl#4
	strh r3,[v30ptr,#v30RegIY]
	eatCycles 6
	ldmfd sp!,{lr}
	b cpu_writemem20
;@----------------------------------------------------------------------------
i_insw:
_6D:	;@ INSW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r0,[v30ptr,#v30RegCW]
	add r4,r0,#1
	bl cpu_readport
	mov r5,r0
	mov r0,r4
	bl cpu_readport
	ldrb r1,[v30ptr,#v30DF]
	ldrh r2,[v30ptr,#v30RegIY]
	cmp r1,#0
	orr r1,r5,r0,lsl#8
	ldrh r0,[v30ptr,#v30SRegES]
	addeq r3,r2,#2
	subne r3,r2,#2
	add r0,r2,r0,lsl#4
	strh r3,[v30ptr,#v30RegIY]
	eatCycles 6
	ldmfd sp!,{r4,r5,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_outsb:
_6E:	;@ OUTSB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r2,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20
	mov r1,r0
	ldrh r0,[v30ptr,#v30RegDW]
	eatCycles 7
	ldmfd sp!,{lr}
	b cpu_writeport
;@----------------------------------------------------------------------------
i_outsw:
_6F:	;@ OUTSW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r2,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	addeq r2,r1,#2
	subne r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20w
	and r1,r0,#0xFF
	mov r4,r0
	ldrh r0,[v30ptr,#v30RegDW]
	mov r5,r0
	bl cpu_writeport
	mov r1,r4,lsr#8
	add r0,r5,#1
	ldmfd sp!,{r4,r5,lr}
	eatCycles 7
	b cpu_writeport

;@----------------------------------------------------------------------------
i_bv:
_70:	;@ Branch if Overflow
;@----------------------------------------------------------------------------
	jmpne v30OverVal
;@----------------------------------------------------------------------------
i_bnv:
_71:	;@ Branch if Not Overflow
;@----------------------------------------------------------------------------
	jmpeq v30OverVal
;@----------------------------------------------------------------------------
i_bc:
i_bl:
_72:	;@ Branch if Carry / Branch if Lower
;@----------------------------------------------------------------------------
	jmpne v30CarryVal
;@----------------------------------------------------------------------------
i_bnc:
i_bnl:
_73:	;@ Branch if Not Carry / Branch if Not Lower
;@----------------------------------------------------------------------------
	jmpeq v30CarryVal
;@----------------------------------------------------------------------------
i_be:
i_bz:
_74:	;@ Branch if Equal / Branch if Zero
;@----------------------------------------------------------------------------
	jmpeq v30ZeroVal
;@----------------------------------------------------------------------------
i_bne:
i_bnz:
_75:	;@ Branch if Not Equal / Branch if Not Zero
;@----------------------------------------------------------------------------
	jmpne v30ZeroVal
;@----------------------------------------------------------------------------
i_bnh:
_76:	;@ Branch if Not Higher
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r3,[v30ptr,#v30CarryVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	cmp	r3,#0
	movne r2,#0
	cmp r2,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bh:
_77:	;@ Branch if Higher
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r3,[v30ptr,#v30CarryVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	cmp	r3,#0
	movne r2,#0
	cmp r2,#0
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bn:
_78:	;@ Branch if Negative
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	cmp r1,#0
	movmi r0,r0,lsl#24
	addmi v30pc,v30pc,r0,asr#24
	submi v30cyc,v30cyc,#4*CYCLE
	subpl v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bp:
_79:	;@ Branch if Positive
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	cmp r1,#0
	movpl r0,r0,lsl#24
	addpl v30pc,v30pc,r0,asr#24
	subpl v30cyc,v30cyc,#4*CYCLE
	submi v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bpe:
_7A:	;@ Branch if Parity Even
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	cmp	r2,#0
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bpo:
_7B:	;@ Branch if Parity Odd
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	cmp	r2,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_blt:
_7C:	;@ Branch if Less Than
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	eors r2,r2,r3
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bge:
_7D:	;@ Branch if Greater than or Equal
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	eors r2,r2,r3
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_ble:
_7E:	;@ Branch if Less than or Equal
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	ldr r1,[v30ptr,#v30ZeroVal]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	cmp r1,#0
	movne r1,#0
	moveq r1,#1
	eor r2,r2,r3
	orrs r2,r2,r1
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#4*CYCLE
	subeq v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_bgt:
_7F:	;@ Branch if Greater Than
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r0,asl#4
	add	v30pc,v30pc,#1
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	ldr r1,[v30ptr,#v30ZeroVal]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	cmp r1,#0
	movne r1,#0
	moveq r1,#1
	eor r2,r2,r3
	orrs r2,r2,r1
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#4*CYCLE
	subne v30cyc,v30cyc,#1*CYCLE
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_80pre:
_80:	;@ PRE 80
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
i_82pre:
_82:	;@ PRE 82
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r6,r0
	getNextByte
	mov r1,r6

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add80, or80, adc80, subc80, and80, sub80, xor80, cmp80
add80:
	add8 r0,r1
	b 2f
or80:
	or8 r0,r1
	b 2f
adc80:
	adc8 r0,r1
	b 2f
subc80:
	subc8 r0,r1
	b 2f
and80:
	and8 r0,r1
	b 2f
sub80:
	sub8 r0,r1
	b 2f
xor80:
	xor8 r0,r1
	b 2f
cmp80:
	sub8 r0,r1
	ldmfd sp!,{r4-r6,pc}
2:
	cmp r4,#0xC0
	strbpl r0,[r5,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	mov r1,r0
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_81pre:
_81:	;@ PRE 81
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r6,r0
	getNextWord
pre81Continue:
	mov r1,r6

	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	b 2f
	.long add81, or81, adc81, subc81, and81, sub81, xor81, cmp81
add81:
	add16 r0,r1
	b 2f
or81:
	or16 r0,r1
	b 2f
adc81:
	adc16 r0,r1
	b 2f
subc81:
	subc16 r0,r1
	b 2f
and81:
	and16 r0,r1
	b 2f
sub81:
	sub16 r0,r1
	b 2f
xor81:
	xor16 r0,r1
	b 2f
cmp81:
	sub16 r0,r1
	ldmfd sp!,{r4-r6,pc}
2:
	cmp r4,#0xC0
	strhpl r0,[r5,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	mov r1,r0
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_83pre:
_83:	;@ PRE 83
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r6,r0
	getNextByte
	tst r0,#0x80
	orrne r0,r0,#0xFF00
	b pre81Continue
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r4,v30ptr,r0
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r4,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r4,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	and8 r1,r0

	ldmfd sp!,{r4,pc}
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_test_wr16:
_85:	;@ TEST WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r2,v30ptr,r2,lsl#1
	ldrh r0,[r2,#v30Regs]
	eatCycles 1
0:
	add r2,v30ptr,r4,lsr#2
	ldrh r1,[r2,#v30Regs]

	and16 r1,r0

	ldmfd sp!,{r4,pc}
1:
	eatCycles 2
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_xchg_br8:
_86:	;@ XCHG BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	add r5,v30ptr,r0
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	eatCycles 1
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]
	strb r0,[r2,#v30Regs]

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_xchg_wr16:
_87:	;@ XCHG WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 3
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]
	strh r0,[r2,#v30Regs]

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_mov_br8:
_88:	;@ MOV BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r3,v30ptr,r0
	ldrb r2,[r3,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r4,[r2,#v30Regs]

	eatCycles 1
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r3,#v30ModRmRm]
	add r2,v30ptr,r2
	strb r4,[r2,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	add r2,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r2,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20
;@----------------------------------------------------------------------------
i_mov_wr16:
_89:	;@ MOV WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#2
	ldrh r4,[r2,#v30Regs]

	eatCycles 1
	cmp r0,#0xC0
	bmi 0f
	and r0,r0,#7
	add r2,v30ptr,r0,lsl#1
	strh r4,[r2,#v30Regs]
	ldmfd sp!,{r4,pc}
0:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_mov_r8b:
_8A:	;@ MOV R8B
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	add r4,v30ptr,r0
	eatCycles 1
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r4,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
0:
	ldrb r2,[r4,#v30ModRmReg]
	add r2,v30ptr,r2
	strb r0,[r2,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_mov_r16w:
_8B:	;@ MOV R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
0:
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]
	eatCycles 1
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_mov_wsreg:
_8C:	;@ MOV WSREG
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r2,r0,#0x38				;@ Mask with 0x18?
	add r1,v30ptr,r2,lsr#1
	ldrh r4,[r1,#v30SRegs]

	eatCycles 1
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	strh r4,[r1,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_lea:
_8D:	;@ LEA
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r4,r0,#0x38
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	ldrh r0,[v30ptr,#v30EO]
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]

	eatCycles 1
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	eatCycles 2
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
0:
	tst r4,#0x20
	addeq r1,v30ptr,r4,lsr#1
	strheq r0,[r1,#v30SRegs]
	mov r1,#1
	str r1,[v30ptr,#v30NoInterrupt]
	ldmfd sp!,{r4,pc}
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_popw:
_8F:	;@ POPW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	mov r4,r0
	getNextByte
	cmp r0,#0xC0
	bmi 0f
	eatCycles 1
	and r0,r0,#7
	add r2,v30ptr,r0,lsl#1
	strh r4,[r2,#v30Regs]
	ldmfd sp!,{r4,pc}
0:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_nop:
_90:	;@ NOP
;@----------------------------------------------------------------------------
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axcx:
_91:	;@ XCHG AXCX
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30RegAW]
	eatCycles 3
	mov r0,r0,ror#16
	str r0,[v30ptr,#v30RegAW]
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
	ldrh r1,[v30ptr,#v30RegSP]
	eatCycles 3
	strh r0,[v30ptr,#v30RegSP]
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
	ldrh r1,[v30ptr,#v30RegIX]
	eatCycles 3
	strh r0,[v30ptr,#v30RegIX]
	strh r1,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axdi:
_97:	;@ XCHG AXDI
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r1,[v30ptr,#v30RegIY]
	eatCycles 3
	strh r0,[v30ptr,#v30RegIY]
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
	stmfd sp!,{r4-r6,lr}
	ldrh r5,[v30ptr,#v30SRegCS]
	ldrh v30pc,[v30ptr,#v30IP]
	add r0,v30pc,r5,lsl#4
	add v30pc,v30pc,#2
	bl cpu_readmem20w
	mov r4,r0
	add r0,v30pc,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	mov r1,r5
	ldrh r6,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	sub r6,r6,#2
	add r0,r6,r5,lsl#4
	bl cpu_writemem20w
	add r1,v30pc,#2
	mov v30pc,r4
	strh v30pc,[v30ptr,#v30IP]
	sub r6,r6,#2
	add r0,r6,r5,lsl#4
	strh r6,[v30ptr,#v30RegSP]
	eatCycles 7
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20w

;@----------------------------------------------------------------------------
i_poll:
_9B:	;@ POLL, poll the "poll" pin?
;@----------------------------------------------------------------------------
	ldrh v30pc,[v30ptr,#v30IP]
	eatCycles 1
	sub v30pc,v30pc,#1
	strh v30pc,[v30ptr,#v30IP]
	bx lr
;@----------------------------------------------------------------------------
i_pushf:
_9C:	;@ PUSH F
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r1,=0x7002
	ldr r0,[v30ptr,#v30CarryVal]
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	cmp r0,#0
	orrne r1,r1,#CF
	ldrb r2,[r3,r2]
	ldr r0,[v30ptr,#v30AuxVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	cmp r2,#0
	orrne r1,r1,#PF
	ldr r3,[v30ptr,#v30SignVal]
	cmp r0,#0
	orrne r1,r1,#AF
	ldrb r0,[v30ptr,#v30TF]
	cmp r2,#0
	orreq r1,r1,#ZF
	ldrb r2,[v30ptr,#v30IF]
	cmp r3,#0
	orrmi r1,r1,#SF
	ldrb r3,[v30ptr,#v30DF]
	cmp r0,#0
	orrne r1,r1,#TF
	ldr r0,[v30ptr,#v30OverVal]
	cmp r2,#0
	orrne r1,r1,#IF
	cmp r3,#0
	orrne r1,r1,#DF
	cmp r0,#0
	orrne r1,r1,#OF

	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	eatCycles 2
	ldmfd sp!,{lr}
	b cpu_writemem20w
	.pool
;@----------------------------------------------------------------------------
i_popf:
_9D:	;@ POP F
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	mov r1,#0
	mov r2,#1
	mov r3,#-1
	tst r0,#CF
	streq r1,[v30ptr,#v30CarryVal]
	strne r2,[v30ptr,#v30CarryVal]
	tst r0,#PF
	strne r1,[v30ptr,#v30ParityVal]
	streq r2,[v30ptr,#v30ParityVal]
	tst r0,#AF
	streq r1,[v30ptr,#v30AuxVal]
	strne r2,[v30ptr,#v30AuxVal]
	tst r0,#ZF
	strne r1,[v30ptr,#v30ZeroVal]
	streq r2,[v30ptr,#v30ZeroVal]
	tst r0,#SF
	streq r1,[v30ptr,#v30SignVal]
	strne r3,[v30ptr,#v30SignVal]
	tst r0,#TF
	strbeq r1,[v30ptr,#v30TF]
	strbne r2,[v30ptr,#v30TF]
	tst r0,#IF
	strbeq r1,[v30ptr,#v30IF]
	strbne r2,[v30ptr,#v30IF]
	tst r0,#DF
	strbeq r1,[v30ptr,#v30DF]
	strbne r2,[v30ptr,#v30DF]
	tst r0,#OF
	streq r1,[v30ptr,#v30OverVal]
	strne r2,[v30ptr,#v30OverVal]

	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sahf:
_9E:	;@ SAHF
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r0,[v30ptr,#v30RegAH]

	mov r1,#0
	mov r2,#1
	mov r3,#-1
	tst r0,#CF
	streq r1,[v30ptr,#v30CarryVal]
	strne r2,[v30ptr,#v30CarryVal]
	tst r0,#PF
	strne r1,[v30ptr,#v30ParityVal]
	streq r2,[v30ptr,#v30ParityVal]
	tst r0,#AF
	streq r1,[v30ptr,#v30AuxVal]
	strne r2,[v30ptr,#v30AuxVal]
	tst r0,#ZF
	strne r1,[v30ptr,#v30ZeroVal]
	streq r2,[v30ptr,#v30ZeroVal]
	tst r0,#SF
	streq r1,[v30ptr,#v30SignVal]
	strne r3,[v30ptr,#v30SignVal]

	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_lahf:
_9F:	;@ LAHF
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r1,#0x02
	ldr r0,[v30ptr,#v30CarryVal]
	ldrb r2,[v30ptr,#v30ParityVal]
	add r3,v30ptr,#v30PZST
	cmp r0,#0
	orrne r1,r1,#CF
	ldrb r2,[r3,r2]
	ldr r0,[v30ptr,#v30AuxVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	cmp r2,#0
	orrne r1,r1,#PF
	ldr r3,[v30ptr,#v30SignVal]
	cmp r0,#0
	orrne r1,r1,#AF
	cmp r2,#0
	orreq r1,r1,#ZF
	cmp r3,#0
	orrmi r1,r1,#SF

	strb r1,[v30ptr,#v30RegAH]
	eatCycles 2
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_aldisp:
_A0:	;@ MOV ALDISP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r1,[v30ptr,#v30SRegDS]
	ldrne r1,[v30ptr,#v30PrefixBase]
	add r0,r0,r1,lsl#4
	bl cpu_readmem20
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
	ldrheq r1,[v30ptr,#v30SRegDS]
	ldrne r1,[v30ptr,#v30PrefixBase]
	add r0,r0,r1,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dispal:
_A2:	;@ MOV DISPAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r1,[v30ptr,#v30SRegDS]
	ldrne r1,[v30ptr,#v30PrefixBase]
	add r0,r0,r1,lsl#4
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{lr}
	b cpu_writemem20
;@----------------------------------------------------------------------------
i_mov_dispax:
_A3:	;@ MOV DISPAX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r1,[v30ptr,#v30SRegDS]
	ldrne r1,[v30ptr,#v30PrefixBase]
	add r0,r0,r1,lsl#4
	ldrh r1,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_movsb:
_A4:	;@ MOVSB
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r4,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r4,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20
	mov r1,r0
	ldrh r3,[v30ptr,#v30RegIY]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r4,#0
	addeq r2,r3,#1
	subne r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	eatCycles 5
	ldmfd sp!,{r4,lr}
	b cpu_writemem20
;@----------------------------------------------------------------------------
i_movsw:
_A5:	;@ MOVSW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r4,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r4,#0
	addeq r2,r1,#2
	subne r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20w
	mov r1,r0
	ldrh r3,[v30ptr,#v30RegIY]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r4,#0
	addeq r2,r3,#2
	subne r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	eatCycles 5
	ldmfd sp!,{r4,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_cmpsb:
_A6:	;@ CMPSB
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30RegIX]
	ldrb r4,[v30ptr,#v30DF]
	cmp r4,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20

	ldrh r1,[v30ptr,#v30RegIY]
	ldrh r3,[v30ptr,#v30SRegES]
	cmp r4,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	mov r4,r0
	add r0,r1,r3,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	bl cpu_readmem20
	mov r1,r4

	sub8 r0,r1

	eatCycles 6
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_cmpsw:
_A7:	;@ CMPSW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30RegIX]
	ldrb r4,[v30ptr,#v30DF]
	cmp r4,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20w

	ldrh r1,[v30ptr,#v30RegIY]
	ldrh r3,[v30ptr,#v30SRegES]
	cmp r4,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	mov r4,r0
	add r0,r1,r3,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	bl cpu_readmem20w
	mov r1,r4

	sub16 r0,r1

	eatCycles 6
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_test_ald8:
_A8:	;@ TEST ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]

	and8 r0,r1

	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_test_axd16:
_A9:	;@ TEST AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrh r1,[v30ptr,#v30RegAW]

	and16 r0,r1

	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STOSB
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegIY]
	ldrb r3,[v30ptr,#v30DF]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r3,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 3
	b cpu_writemem20
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STOSW
;@----------------------------------------------------------------------------
	ldrh r1,[v30ptr,#v30RegIY]
	ldrb r3,[v30ptr,#v30DF]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r3,#0
	addeq r2,r1,#2
	subne r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	ldrh r1,[v30ptr,#v30RegAW]
	eatCycles 3
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_lodsb:
_AC:	;@ LODSB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r2,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_lodsw:
_AD:	;@ LODSW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r2,[v30ptr,#v30DF]
	ldrh r1,[v30ptr,#v30RegIX]
	cmp r2,#0
	addeq r2,r1,#2
	subne r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIX]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 3
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_scasb:
_AE:	;@ SCASB
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegIY]
	ldrb r3,[v30ptr,#v30DF]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r3,#0
	addeq r2,r1,#1
	subne r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_scasw:
_AF:	;@ SCASW
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegIY]
	ldrb r3,[v30ptr,#v30DF]
	ldrh r0,[v30ptr,#v30SRegES]
	cmp r3,#0
	addeq r2,r1,#2
	subne r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegIY]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	sub16 r0,r1

	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ald8:
_B0:	;@ MOV ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cld8:
_B1:	;@ MOV CLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegCL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dld8:
_B2:	;@ MOV DLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegDL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bld8:
_B3:	;@ MOV BLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegBL]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ahd8:
_B4:	;@ MOV AHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_chd8:
_B5:	;@ MOV CHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegCH]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dhd8:
_B6:	;@ MOV DHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegDH]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bhd8:
_B7:	;@ MOV BHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	strb r0,[v30ptr,#v30RegBH]
	eatCycles 1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_mov_axd16:
_B8:	;@ MOV AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegAW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cxd16:
_B9:	;@ MOV CXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegCW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dxd16:
_BA:	;@ MOV DXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegDW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bxd16:
_BB:	;@ MOV BXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegBW]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_spd16:
_BC:	;@ MOV SPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegSP]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bpd16:
_BD:	;@ MOV BPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegBP]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_sid16:
_BE:	;@ MOV SID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegIX]
	eatCycles 1
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_did16:
_BF:	;@ MOV DID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	strh r0,[v30ptr,#v30RegIY]
	eatCycles 1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_rotshft_bd8:
_C0:	;@ ROTSHFT BD8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
	eatCycles 3
0:
	mov r6,r0
	getNextByte
d2Continue:
	ands r1,r0,#0x1F
	mov r0,r6

	and r2,r4,#0x38
	ldrne pc,[pc,r2,lsr#1]
	b invC0
	.long rolC0, rorC0, rolcC0, rorcC0, shlC0, shrC0, invC0, shraC0
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
invC0:
	ldmfd sp!,{r4-r6,pc}
shraC0:
	shra8 r0,r1
2:
	cmp r4,#0xC0
	strbpl r1,[r5,#v30Regs]
	ldmfdpl sp!,{r4-r6,pc}
	ldr r0,[v30ptr,#v30EA]
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20
1:
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_rotshft_wd8:
_C1:	;@ ROTSHFT WD8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r0,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 3
0:
	mov r6,r0
	getNextByte
d3Continue:
	ands r1,r0,#0x1F
	mov r0,r6

	and r2,r4,#0x38
	ldrne pc,[pc,r2,lsr#1]
	b invC1
	.long rolC1, rorC1, rolcC1, rorcC1, shlC1, shrC1, invC1, shraC1
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
invC1:
	ldmfd sp!,{r4-r6,pc}
shraC1:
	shra16 r0,r1
2:
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfdpl sp!,{r4-r6,pc}
	ldr r0,[v30ptr,#v30EA]
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20w
1:
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_ret_d16:
_C2:	;@ RET D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r3,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r2,r2,r0
	add r0,r1,r3,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_ret:
_C3:	;@ RET
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	eatCycles 6
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_les_dw:
_C4:	;@ LES DW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0,ror#16
	bl cpu_readmem20w
0:
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]
	add r5,r5,#0x20000
	mov r0,r5,ror#16
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegES]

	eatCycles 6
	ldmfd sp!,{r4,r5,pc}
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	b 0b
;@----------------------------------------------------------------------------
i_lds_dw:
_C5:	;@ LDS DW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	and r4,r0,#0x38
	cmp r0,#0xC0
	bpl 1f
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0,ror#16
	bl cpu_readmem20w
0:
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]
	add r5,r5,#0x20000
	mov r0,r5,ror#16
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegDS]

	eatCycles 6
	ldmfd sp!,{r4,r5,pc}
1:
	mov r11,r11					;@ Not correct?
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	b 0b
;@----------------------------------------------------------------------------
i_mov_bd8:
_C6:	;@ MOV BD8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	eatCycles 1
	cmp r0,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r4,v30ptr,r2
	getNextByte
	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r4,r0
	getNextByte
	mov r1,r0
	mov r0,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20

;@----------------------------------------------------------------------------
i_mov_wd16:
_C7:	;@ MOV WD16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	eatCycles 1
	cmp r0,#0xC0
	bmi 1f
	and r1,r0,#7
	add r4,v30ptr,r1,lsl#1
	getNextWord
	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r4,r0
	getNextWord
	mov r1,r0
	mov r0,r4
	ldmfd sp!,{r4,lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_prepare:
_C8:	;@ PREPARE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	eatCycles 8
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add r0,v30pc,r5,lsl#4
	add v30pc,v30pc,#2
	bl cpu_readmem20w
	stmfd sp!,{r0}				;@ temp
	add r0,v30pc,r5,lsl#4
	add v30pc,v30pc,#1
	strh v30pc,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r5,r0,#0x1F

	ldrh r8,[v30ptr,#v30RegSP]
	ldrh r6,[v30ptr,#v30SRegSS]
	ldrh r4,[v30ptr,#v30RegBP]
	sub r8,r8,#2
	add r0,r8,r6,lsl#4
	mov r1,r4
	bl cpu_writemem20w
	strh r8,[v30ptr,#v30RegBP]
	subs r5,r5,#1
	bmi 2f
	beq 1f
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	moveq r7,r6
	ldrne r7,[v30ptr,#v30PrefixBase]
0:
	sub r4,r4,#2
	add r0,r4,r7,lsl#4
	bl cpu_readmem20w
	mov r1,r0
	sub r8,r8,#2
	add r0,r8,r6,lsl#4
	bl cpu_writemem20w
	eatCycles 4
	subs r5,r5,#1
	bne 0b
1:
	ldrh r1,[v30ptr,#v30RegBP]
	sub r8,r8,#2
	add r0,r8,r6,lsl#4
	bl cpu_writemem20w
	eatCycles 6
2:
	ldmfd sp!,{r0}
	sub r8,r8,r0
	strh r8,[v30ptr,#v30RegSP]
	ldmfd sp!,{r4-r8,pc}
;@----------------------------------------------------------------------------
i_dispose:
_C9:	;@ DISPOSE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBP]
	eatCycles 2
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_retf_d16:
_CA:	;@ RETF D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	bl cpu_readmem20w
	mov r6,r0
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	add r1,r4,r6
	add r0,r4,r5,lsl#4
	add r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	eatCycles 6
	ldmfd sp!,{r4-r6,pc}
;@----------------------------------------------------------------------------
i_retf:
_CB:	;@ RETF
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	strh r4,[v30ptr,#v30RegSP]
	eatCycles 8
	ldmfd sp!,{r4,r5,pc}
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
	stmfd sp!,{lr}
	getNextByte
	eatCycles 10
	ldmfd sp!,{lr}
	b nec_interrupt
;@----------------------------------------------------------------------------
i_into:
_CE:	;@ INTO
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30OverVal]
	cmp r2,#0
	subeq v30cyc,v30cyc,#6*CYCLE
	bxeq lr
	eatCycles 13
	mov r0,#4
	b nec_interrupt
;@----------------------------------------------------------------------------
i_iret:
_CF:	;@ IRET
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	strh r4,[v30ptr,#v30RegSP]
	eatCycles 10					;@ -3?
	ldmfd sp!,{r4,r5,lr}
	b i_popf

;@----------------------------------------------------------------------------
i_rotshft_b:
_D0:	;@ ROTSHFT B
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r6,r0
	mov r0,#1
	b d2Continue
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_rotshft_w:
_D1:	;@ ROTSHFT W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r0,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r6,r0
	mov r0,#1
	b d3Continue
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_rotshft_bcl:
_D2:	;@ ROTSHFT BCL
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
	eatCycles 3
0:
	mov r6,r0
	ldrb r0,[v30ptr,#v30RegCL]
	b d2Continue
1:
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_rotshft_wcl:
_D3:	;@ ROTSHFT WCL
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r0,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 3
0:
	mov r6,r0
	ldrb r0,[v30ptr,#v30RegCL]
	b d3Continue
1:
	eatCycles 5
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_aam:
_D4:	;@ AAM
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte						;@ Mem read not needed?
	ldrb r2,[v30ptr,#v30RegAL]
	ldr r3,=0xCCCCCCCD				;@ 0x8_0000_000A/10)
	umull r0,r3,r2,r3				;@ AH = AL/10, AL%=10.
	mov r3,r3,lsr#3					;@ Divide by 8
	add r0,r3,r3,lsl#2
	sub r2,r2,r0,lsl#1
	strb r2,[v30ptr,#v30RegAL]
	strb r3,[v30ptr,#v30RegAH]
	ldrsh r3,[v30ptr,#v30RegAW]
	eatCycles 17
	str r3,[v30ptr,#v30SignVal]
	str r3,[v30ptr,#v30ZeroVal]
	str r3,[v30ptr,#v30ParityVal]
	ldmfd sp!,{pc}
	.pool
;@----------------------------------------------------------------------------
i_aad:
_D5:	;@ AAD
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte						;@ Mem read not needed?
	ldrh r0,[v30ptr,#v30RegAW]
	mov r0,r0,ror#8
	add r0,r0,r0,lsl#24+3
	add r0,r0,r0,lsl#24+1
	mov r2,r0,asr#24
	mov r0,r0,lsr#24
	eatCycles 6
	strh r0,[v30ptr,#v30RegAW]
	str r2,[v30ptr,#v30SignVal]
	str r2,[v30ptr,#v30ZeroVal]
	str r2,[v30ptr,#v30ParityVal]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_trans:
_D7:	;@ TRANS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	ldrb r2,[v30ptr,#v30RegAL]
	ldrh r1,[v30ptr,#v30RegBW]
	mov r1,r1,lsl#16
	add r1,r1,r2,lsl#16
	mov r1,r1,lsr#16
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	strb r0,[v30ptr,#v30RegAL]
	eatCycles 5
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_loopne:
_E0:	;@ LOOPNE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	ldrhne r3,[v30ptr,#v30ZeroVal]
	cmpne r3,#0
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#3*CYCLE
	eatCycles 3
	strh r2,[v30ptr,#v30RegCW]
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_loope:
_E1:	;@ LOOPE
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	ldrh r3,[v30ptr,#v30ZeroVal]
	subs r2,r2,#1
	moveq r3,#1
	cmp r3,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#3*CYCLE
	eatCycles 3
	strh r2,[v30ptr,#v30RegCW]
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_loop:
_E2:	;@ LOOP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	subs r2,r2,#1
	movne r0,r0,lsl#24
	addne v30pc,v30pc,r0,asr#24
	subne v30cyc,v30cyc,#3*CYCLE
	eatCycles 2
	strh r2,[v30ptr,#v30RegCW]
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_jcxz:
_E3:	;@ JCXZ
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	cmp r2,#0
	moveq r0,r0,lsl#24
	addeq v30pc,v30pc,r0,asr#24
	subeq v30cyc,v30cyc,#3*CYCLE
	eatCycles 1
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}

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
	stmfd sp!,{r4,lr}
	getNextByte
	mov r4,r0
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 6
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_outal:
_E6:	;@ OUTAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	eatCycles 6
	ldmfd sp!,{lr}
	b cpu_writeport
;@----------------------------------------------------------------------------
i_outax:
_E7:	;@ OUTAX
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	getNextByte
	ldrb r1,[v30ptr,#v30RegAL]
	mov r4,r0
	bl cpu_writeport
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	eatCycles 6
	ldmfd sp!,{r4,lr}
	b cpu_writeport

;@----------------------------------------------------------------------------
i_call_d16:
_E8:	;@ CALL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	bl cpu_readmem20w
	add r1,v30pc,#2
	add v30pc,r1,r0
	strh v30pc,[v30ptr,#v30IP]
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	eatCycles 5
	ldmfd sp!,{lr}
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_jmp_d16:
_E9:	;@ JMP D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#2
	bl cpu_readmem20w
	add v30pc,v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	eatCycles 4
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_jmp_far:
_EA:	;@ JMP FAR
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r4,[v30ptr,#v30SRegCS]
	add r0,v30pc,r4,lsl#4
	bl cpu_readmem20w
	add r1,v30pc,#2
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	add r0,r1,r4,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	eatCycles 7
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_br_d8:
_EB:	;@ Branch short
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	mov r1,r0,lsl#24
	add v30pc,v30pc,r1,asr#24
	eatCycles 4
	cmp r0,#0xFC
	andhi v30cyc,v30cyc,#CYC_MASK
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{pc}
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
	stmfd sp!,{r4,lr}
	ldrh r4,[v30ptr,#v30RegDW]
	mov r0,r4
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAH]
	eatCycles 6
	ldmfd sp!,{r4,pc}
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
	stmfd sp!,{r4,lr}
	ldrh r4,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	mov r0,r4
	bl cpu_writeport
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	eatCycles 6
	ldmfd sp!,{r4,lr}
	b cpu_writeport

;@----------------------------------------------------------------------------
i_lock:
_F0:	;@ LOCK
;@----------------------------------------------------------------------------
	mov r0,#1
	str r0,[v30ptr,#v30NoInterrupt]
	eatCycles 1
	bx lr
;@----------------------------------------------------------------------------
i_repne:
_F2:	;@ REPNE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r5,asl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF2Prefix
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	mov r0,#1
	ldrh r2,[r1,#v30SRegs]
	strb r0,[v30ptr,#v30SegPrefix]
	str r2,[v30ptr,#v30PrefixBase]

	eatCycles 2
	add	r0,v30pc,r5,asl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
noF2Prefix:
	strh v30pc,[v30ptr,#v30IP]
	ldrh r4,[v30ptr,#v30RegCW]
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
	cmp r4,#1
	bmi f3End
0:	bl i_cmpsb
	eatCycles 3
	subs r4,r4,#1
	ldrne r0,[v30ptr,#v30ZeroVal]
	cmpne r0,#0
	bne 0b
	b f3End

f2a7:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_cmpsw
	eatCycles 3
	subs r4,r4,#1
	ldrne r0,[v30ptr,#v30ZeroVal]
	cmpne r0,#0
	bne 0b
	b f3End

f2ae:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_scasb
	eatCycles 5
	subs r4,r4,#1
	ldrne r0,[v30ptr,#v30ZeroVal]
	cmpne r0,#0
	bne 0b
	b f3End

f2af:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_scasw
	eatCycles 5
	subs r4,r4,#1
	ldrne r0,[v30ptr,#v30ZeroVal]
	cmpne r0,#0
	bne 0b
	b f3End
;@----------------------------------------------------------------------------
i_repe:
_F3:	;@ REPE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add	r0,v30pc,r5,asl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
	and r1,r0,#0xE7
	cmp r1,#0x26
	bne noF3Prefix
	and r1,r0,#0x18
	add r1,v30ptr,r1,lsr#1
	mov r0,#1
	ldrh r2,[r1,#v30SRegs]
	strb r0,[v30ptr,#v30SegPrefix]
	str r2,[v30ptr,#v30PrefixBase]

	eatCycles 2
	add	r0,v30pc,r5,asl#4
	add v30pc,v30pc,#1
	bl cpu_readmem20
noF3Prefix:
	strh v30pc,[v30ptr,#v30IP]
	ldrh r4,[v30ptr,#v30RegCW]
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
	cmp r4,#1
	bmi f3End
0:	bl i_insb
	subs r4,r4,#1
	bne 0b
	b f3End

f36d:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_insw
	subs r4,r4,#1
	bne 0b
	b f3End

f36e:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_outsb
	eatCycles -1
	subs r4,r4,#1
	bne 0b
	b f3End

f36f:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_outsw
	eatCycles -1
	subs r4,r4,#1
	bne 0b
	b f3End

f3a4:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_movsb
	eatCycles 2
	subs r4,r4,#1
	bne 0b
	b f3End

f3a5:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_movsw
	eatCycles 2
	subs r4,r4,#1
	bne 0b
	b f3End

f3a6:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_cmpsb
	eatCycles 4
	ldr r0,[v30ptr,#v30ZeroVal]
	cmp r0,#0
	movne r0,#0
	moveq r0,#1
	subs r4,r4,#1
	cmpne r0,#0
	bne 0b
	b f3End

f3a7:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_cmpsw
	eatCycles 4
	ldr r0,[v30ptr,#v30ZeroVal]
	cmp r0,#0
	movne r0,#0
	moveq r0,#1
	subs r4,r4,#1
	cmpne r0,#0
	bne 0b
	b f3End

f3aa:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_stosb
	eatCycles 3
	subs r4,r4,#1
	bne 0b
	b f3End

f3ab:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_stosw
	eatCycles 3
	subs r4,r4,#1
	bne 0b
	b f3End

f3ac:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_lodsb
	eatCycles 3
	subs r4,r4,#1
	bne 0b
	b f3End

f3ad:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_lodsw
	eatCycles 3
	subs r4,r4,#1
	bne 0b
	b f3End

f3ae:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_scasb
	eatCycles 4
	ldr r0,[v30ptr,#v30ZeroVal]
	cmp r0,#0
	movne r0,#0
	moveq r0,#1
	subs r4,r4,#1
	cmpne r0,#0
	bne 0b
	b f3End

f3af:
	eatCycles 5
	cmp r4,#1
	bmi f3End
0:	bl i_scasw
	eatCycles 4
	ldr r0,[v30ptr,#v30ZeroVal]
	cmp r0,#0
	movne r0,#0
	moveq r0,#1
	subs r4,r4,#1
	cmpne r0,#0
	bne 0b
	b f3End

f3Default:
	adr lr,f3DefEnd
	ldr pc,[v30ptr,r0,lsl#2]

f3End:
	strh r4,[v30ptr,#v30RegCW]
f3DefEnd:
	mov r0,#0
	strb r0,[v30ptr,#v30SegPrefix]
	ldmfd sp!,{r4-r6,pc}
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
	ldr r0,[v30ptr,#v30CarryVal]
	cmp r0,#0
	moveq r0,#1
	movne r0,#0
	str r0,[v30ptr,#v30CarryVal]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_f6pre:
_F6:	;@ PRE F6
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF6, testF6, notF6, negF6, muluF6, mulF6, divubF6, divbF6
testF6:
	eatCycles 1
	mov r4,r0
	getNextByte
	and8 r0,r4
	ldmfd sp!,{r4-r5,pc}
notF6:
	eatCycles 1
	mvn r1,r0
	cmp r4,#0xC0
	strbpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4-r5,lr}
	bxpl lr
	eatCycles 1
	b cpu_writemem20
negF6:
	eatCycles 1
	movs r1,r0
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	mov r0,r0,lsl#24
	rsb r1,r0,#0
	mov r1,r1,asr#24
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	cmp r4,#0xC0
	strbpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4-r5,lr}
	bxpl lr
	eatCycles 1
	b cpu_writemem20
muluF6:
	eatCycles 3
	ldrb r1,[v30ptr,#v30RegAL]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#8
	movne r2,#1
	str r2,[v30ptr,#v30CarryVal]
	str r2,[v30ptr,#v30OverVal]
	ldmfd sp!,{r4-r5,pc}
mulF6:
	eatCycles 3
	ldrsb r1,[v30ptr,#v30RegAL]
	mov r0,r0,lsl#24
	mov r0,r0,asr#24
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r1,r2,asr#7
	mvnsne r1,r1
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	ldmfd sp!,{r4-r5,pc}
divubF6:
	eatCycles 15
	ldmfd sp!,{r4-r5,lr}
	movs r1,r0
	beq nec_interrupt			;@ r0 = 0
	ldrh r0,[v30ptr,#v30RegAW]

#ifdef GBA
	swi 0x060000				;@ GBA BIOS Div, r0/r1.
#elif NDS
	swi 0x090000				;@ NDS BIOS Div, r0/r1.
#else
	#error "Needs an implementation of division"
#endif

	strb r0,[v30ptr,#v30RegAL]
	strb r1,[v30ptr,#v30RegAH]
	movs r0,r0,lsr#8
	bxeq lr
	mov r0,#0
	b nec_interrupt				;@ r0 = 0
divbF6:
	eatCycles 17
	ldmfd sp!,{r4-r5,lr}
	movs r0,r0,lsl#24
	mov r1,r0,asr#24
	beq nec_interrupt			;@ r0 = 0
	ldrsh r0,[v30ptr,#v30RegAW]

#ifdef GBA
	swi 0x060000				;@ GBA BIOS Div, r0/r1.
#elif NDS
	swi 0x090000				;@ NDS BIOS Div, r0/r1.
#else
	#error "Needs an implementation of division"
#endif

	strb r0,[v30ptr,#v30RegAL]
	strb r1,[v30ptr,#v30RegAH]
	movs r1,r0,asr#7
	mvnsne r1,r1
	movne r0,#0
	bne nec_interrupt			;@ r0 = 0
	bx lr
1:
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_f7pre:
_F7:	;@ PRE F7
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long testF7, testF7, notF7, negF7, muluF7, mulF7, divuwF7, divwF7
testF7:
	eatCycles 1
	mov r4,r0
	getNextWord
	and16 r0,r4
	ldmfd sp!,{r4-r5,pc}
notF7:
	eatCycles 1
	mvn r1,r0
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4-r5,lr}
	bxpl lr
	eatCycles 1
	b cpu_writemem20w
negF7:
	eatCycles 1
	movs r1,r0
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	mov r0,r0,lsl#16
	rsb r1,r0,#0
	mov r1,r1,asr#16
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4-r5,lr}
	bxpl lr
	eatCycles 1
	b cpu_writemem20w
muluF7:
	eatCycles 3
	ldrh r1,[v30ptr,#v30RegAW]
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	movs r2,r2,lsr#16
	strh r2,[v30ptr,#v30RegDW]
	movne r2,#1
	str r2,[v30ptr,#v30CarryVal]
	str r2,[v30ptr,#v30OverVal]
	ldmfd sp!,{r4-r5,pc}
mulF7:
	eatCycles 3
	ldrsh r1,[v30ptr,#v30RegAW]
	mov r0,r0,lsl#16
	mov r0,r0,asr#16
	mul r2,r0,r1
	strh r2,[v30ptr,#v30RegAW]
	mov r1,r2,lsr#16
	strh r1,[v30ptr,#v30RegDW]
	movs r1,r2,asr#15
	mvnsne r1,r1
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]
	ldmfd sp!,{r4-r5,pc}
divuwF7:
	eatCycles 23
	ldmfd sp!,{r4-r5,lr}
	movs r1,r0
	beq nec_interrupt			;@ r0 = 0
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16

#ifdef GBA
	swi 0x060000				;@ GBA BIOS Div, r0/r1.
#elif NDS
	swi 0x090000				;@ NDS BIOS Div, r0/r1.
#else
	#error "Needs an implementation of division"
#endif

	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	movs r0,r0,lsr#16
	movne r0,#0
	bne nec_interrupt			;@ r0 = 0
	bx lr
divwF7:
	eatCycles 24
	ldmfd sp!,{r4-r5,lr}
	movs r0,r0,lsl#16
	mov r1,r0,asr#16
	beq nec_interrupt			;@ r0 = 0
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	orr r0,r0,r2,lsl#16

#ifdef GBA
	swi 0x060000				;@ GBA BIOS Div, r0/r1.
#elif NDS
	swi 0x090000				;@ NDS BIOS Div, r0/r1.
#else
	#error "Needs an implementation of division"
#endif

	strh r0,[v30ptr,#v30RegAW]
	strh r1,[v30ptr,#v30RegDW]
	movs r1,r0,asr#15
	mvnsne r1,r1
	bxeq lr
	mov r0,#0
	b nec_interrupt				;@ r0 = 0
1:
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_clc:
_F8:	;@ CLC
;@----------------------------------------------------------------------------
	mov r0,#0
	str r0,[v30ptr,#v30CarryVal]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_stc:
_F9:	;@ STC
;@----------------------------------------------------------------------------
	mov r0,#1
	str r0,[v30ptr,#v30CarryVal]
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
	mov r0,#0
	strb r0,[v30ptr,#v30DF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_std:
_FD:	;@ STD
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,[v30ptr,#v30DF]
	eatCycles 4
	bx lr
;@----------------------------------------------------------------------------
i_fepre:
_FE:	;@ PRE FE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmRm]
	add r5,v30ptr,r2
	ldrb r0,[r5,#v30Regs]
	eatCycles 1
0:
	mov r2,#0			;@ Overflow
	mov r1,r0,lsl#24
	ands r3,r4,#0x38
	beq incFE
	cmp r3,#0x08
	bne invalidFE
decFE:
	subs r1,r1,#0x1000000
	movvs r2,#1
	tst r0,#0xF
	b endFE
incFE:
	adds r1,r1,#0x1000000
	movvs r2,#1
	tst r1,#0xF000000
endFE:
	mov r3,#0
	moveq r3,#1
	mov r1,r1,asr#24
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	cmp r4,#0xC0
	strbpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	b cpu_writemem20
invalidFE:
	ldmfd sp!,{r4,r5,lr}
	b i_invalid
1:
	eatCycles 3
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	adr lr,0b
	b cpu_readmem20
;@----------------------------------------------------------------------------
i_ffpre:
_FF:	;@ PRE FF
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	getNextByte
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	eatCycles 1
0:
	and r2,r4,#0x38
	ldr pc,[pc,r2,lsr#1]
	nop
	.long incFF, decFF, callFF, callFarFF, braFF, braFarFF, pushFF, pushFF
incFF:
	mov r2,#0
	mov r1,r0,lsl#16
	adds r1,r1,#0x10000
	movvs r2,#1
	tst r1,#0xF0000
	b writeBackFF
decFF:
	mov r2,#0
	mov r1,r0,lsl#16
	subs r1,r1,#0x10000
	movvs r2,#1
	tst r0,#0xF
writeBackFF:
	mov r3,#0
	moveq r3,#1
	mov r1,r1,asr#16
	str r2,[v30ptr,#v30OverVal]
	str r3,[v30ptr,#v30AuxVal]
	str r1,[v30ptr,#v30SignVal]
	str r1,[v30ptr,#v30ZeroVal]
	str r1,[v30ptr,#v30ParityVal]
	eatCycles 1
	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	mov r0,r5
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	eatCycles 1
	b cpu_writemem20w
callFF:
	eatCycles 5
	ldrh v30pc,[v30ptr,#v30IP]
	mov r1,v30pc
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20w
callFarFF:
	eatCycles 11
	mov r4,r0
	mov r0,r5,ror#16
	add r0,r0,#0x20000
	mov r0,r0,ror#16
	bl cpu_readmem20w

	ldrh r1,[v30ptr,#v30SRegCS]
	strh r0,[v30ptr,#v30SRegCS]
	ldrh r5,[v30ptr,#v30RegSP]
	ldrh r6,[v30ptr,#v30SRegSS]
	sub r5,r5,#2
	add r0,r5,r6,lsl#4
	bl cpu_writemem20w

	ldrh v30pc,[v30ptr,#v30IP]
	mov r1,v30pc
	mov v30pc,r4
	strh v30pc,[v30ptr,#v30IP]
	sub r5,r5,#2
	add r0,r5,r6,lsl#4
	strh r5,[v30ptr,#v30RegSP]
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20w
braFF:
	eatCycles 4
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	ldmfd sp!,{r4-r6,pc}
braFarFF:
	eatCycles 9
	mov v30pc,r0
	strh v30pc,[v30ptr,#v30IP]
	mov r0,r5,ror#16
	add r0,r0,#0x20000
	mov r0,r0,ror#16
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	ldmfd sp!,{r4-r6,pc}
pushFF:
	eatCycles 1
	mov r1,r0
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	ldmfd sp!,{r4-r6,lr}
	b cpu_writemem20w
1:
	eatCycles 1
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r5,r0
	adr lr,0b
	b cpu_readmem20w


;@----------------------------------------------------------------------------
EA_000:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r0,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_001:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r0,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_002:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegSS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r0,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_003:	;@
;@----------------------------------------------------------------------------
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r0,[v30ptr,#v30SRegSS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r0,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_004:	;@
;@----------------------------------------------------------------------------
	ldrb r1,[v30ptr,#v30SegPrefix]
	ldrh r2,[v30ptr,#v30RegIX]
	cmp r1,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_005:	;@
;@----------------------------------------------------------------------------
	ldrb r1,[v30ptr,#v30SegPrefix]
	ldrh r2,[v30ptr,#v30RegIY]
	cmp r1,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_006:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r1,[v30ptr,#v30SegPrefix]
	mov r2,r0
	cmp r1,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_007:	;@
;@----------------------------------------------------------------------------
	ldrb r1,[v30ptr,#v30SegPrefix]
	ldrh r2,[v30ptr,#v30RegBW]
	cmp r1,#0
	ldrheq r0,[v30ptr,#v30SRegDS]
	ldrne r0,[v30ptr,#v30PrefixBase]
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	bx lr
;@----------------------------------------------------------------------------
EA_100:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r1
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_101:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r1
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_102:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r1
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_103:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r1
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_104:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_105:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_106:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegBP]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_107:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegBW]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	mov r0,r0,lsl#24
	add r3,r3,r0,asr#24
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_200:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_201:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBW]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_202:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_203:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r1,[v30ptr,#v30RegBP]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r1
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_204:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegIX]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_205:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegIY]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_206:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegBP]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegSS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
EA_207:	;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextWord
	ldrb r2,[v30ptr,#v30SegPrefix]
	ldrh r3,[v30ptr,#v30RegBW]
	cmp r2,#0
	ldrheq r2,[v30ptr,#v30SRegDS]
	ldrne r2,[v30ptr,#v30PrefixBase]
	add r3,r3,r0
	mov r3,r3,lsl#16
	mov r3,r3,lsr#16
	add r0,r3,r2,lsl#4
	strh r3,[v30ptr,#v30EO]
	str r0,[v30ptr,#v30EA]
	ldmfd sp!,{pc}

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
	bl nec_interrupt
	ldmfd sp!,{lr}
	b contExe
;@----------------------------------------------------------------------------
V30SetIRQ:
nec_interrupt:				;@ r0 = vector number
	.type   nec_interrupt STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	mov r4,r0,lsl#2
	bl i_pushf
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	strb r0,[v30ptr,#v30TF]
	mov r0,r4
	bl cpu_readmem20w
	mov r5,r0
	add r0,r4,#2
	bl cpu_readmem20w
	mov r4,r0

	ldrh r7,[v30ptr,#v30RegSP]
	ldrh r6,[v30ptr,#v30SRegSS]
	sub r7,r7,#2
	add r0,r7,r6,lsl#4
	ldrh r1,[v30ptr,#v30SRegCS]
	bl cpu_writemem20w
	sub r7,r7,#2
	add r0,r7,r6,lsl#4
	strh r7,[v30ptr,#v30RegSP]
	ldrh v30pc,[v30ptr,#v30IP]
	mov r1,v30pc
	bl cpu_writemem20w

	mov v30pc,r5
	strh v30pc,[v30ptr,#v30IP]
	strh r4,[v30ptr,#v30SRegCS]
	eatCycles 22
	ldmfd sp!,{r4-r7,pc}
;@----------------------------------------------------------------------------
V30RestoreAndRunXCycles:	;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	ldr v30cyc,[v30ptr,#v30ICount]
	ldr v30pc,[v30ptr,#v30IP]
;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	add v30cyc,v30cyc,r0,lsl#CYC_SHIFT
;@----------------------------------------------------------------------------
V30CheckIRQs:
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30IrqPin]		;@ Irq pin and IF
	ands r1,r0,r0,lsr#8
	bne doV30IRQ
contExe:
	ldrb r1,[v30ptr,#v30Halt]
	cmp r1,#0
	andne v30cyc,v30cyc,#CYC_MASK
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
xLoop:
	cmp v30cyc,#0
	ble xOut
	ldrh v30pc,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,v30pc,r0,lsl#4
	add v30pc,v30pc,#1
	strh v30pc,[v30ptr,#v30IP]
	bl cpu_readmem20
	adr lr,xLoop
	ldr pc,[v30ptr,r0,lsl#2]
xOut:
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
	.section .text			;@ For everything else
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
i_invalid:
;@----------------------------------------------------------------------------
	eatCycles 10
	bx lr
;@----------------------------------------------------------------------------
V30IrqVectorDummy:
;@----------------------------------------------------------------------------
	mov r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
V30Reset:					;@ r11=v30ptr
;@ Called by cpuReset, (r0-r3,r12 are free to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	adr r1,registerValues		;@ Startup values for different versions of the cpu.

	mov v30cyc,#0
	mov v30pc,#0
//	encodePC					;@ Get RESET vector
//	ldmia r1!,{r0,v30f-z80hl,v30sp}
//	strb r0,[v30ptr,#v30Out0]
	add r2,v30ptr,#v30Regs
//	stmia r2!,{v30f-v30pc,v30sp}
	ldmia r1!,{r0,r3}
//	str r0,[v30ptr,#v30IX]
//	str r3,[v30ptr,#v30IY]
	ldmia r1,{v30f-v30hl}
	stmia r2,{v30f-v30hl}

;@ Clear other registers
	mov r0,#0
//	str r0,[v30ptr,#v30I]

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
registerValues:
	;@(SMS) OUT0, F  , A		 , BC		 , DE		 , HL		 , SP		 , IX		 , IY		 , F'		 , A'		 , BC'		 , DE'		 , HL'
	.long 0x00, 0xFF , 0xFF000000, 0xBDBF0000, 0xFFFF0000, 0xFFFF0000, 0xFFFF0000, 0xBDFF0000, 0xFFBD0000, 0x000000FF, 0xFF000000, 0xBFBD0000, 0xFFFF0000, 0xFFFF0000

;@----------------------------------------------------------------------------
V30SaveState:				;@ In r0=destination, r1=v30ptr. Out r0=size.
	.type   V30SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,v30ptr,lr}

	sub r4,r0,#v30Regs
	mov v30ptr,r1

	add r1,v30ptr,#v30Regs
	mov r2,#v30StateEnd-v30StateStart	;@ Right now?
	bl memcpy

	;@ Convert copied PC to not offseted.
//	ldr r0,[r4,#v30Regs+6*4]			;@ Offsetted v30pc
//	loadLastBank r2
//	sub r0,r0,r2
//	str r0,[r4,#v30Regs+6*4]			;@ Normal v30pc

	ldmfd sp!,{r4,v30ptr,lr}
	mov r0,#v30StateEnd-v30StateStart	;@ Right now?
	bx lr
;@----------------------------------------------------------------------------
V30LoadState:				;@ In r0=v30ptr, r1=source. Out r0=size.
	.type   V30LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{v30pc,v30ptr,lr}

	mov v30ptr,r0
	add r0,v30ptr,#v30Regs
	mov r2,#v30StateEnd-v30StateStart	;@ Right now?
	bl memcpy

	ldr v30pc,[v30ptr,#v30Regs+6*4]		;@ Normal v30pc
//	encodePC
	str v30pc,[v30ptr,#v30Regs+6*4]		;@ Rewrite offseted v30pc

//	ldr r1,=V30IRQMode0
//	ldrb r0,[v30ptr,#v30IM]
	cmp r0,#1
//	ldreq r1,=V30IRQMode1
	cmp r0,#2
//	ldreq r1,=V30IRQMode2
//	str r1,[v30ptr,#v30IMFunction]

	ldmfd sp!,{v30pc,v30ptr,lr}
;@----------------------------------------------------------------------------
V30GetStateSize:			;@ Out r0=state size.
	.type   V30GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#v30StateEnd-v30StateStart	;@ Right now?
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
	.space 16*4		;@ v30MemTbl $00000-FFFFF
	.space 16*4		;@ v30ReadTbl $00000-FFFFF
	.space 16*4		;@ v30WriteTbl $00000-FFFFF
v30StateStart:
I:				.space 22*4
no_interrupt:	.long 0

v30StateEnd:

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
	.long i_pop_cs
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
	.long i_invalid
	.long i_invalid	// repnc
	.long i_invalid	// repc
	.long i_invalid	// fpo2
	.long i_invalid	// fpo2
	.long i_push_d16
	.long i_imul_d16
	.long i_push_d8
	.long i_imul_d8
	.long i_insb
	.long i_insw
	.long i_outsb
	.long i_outsw
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
	.long i_trans  	//xlat (undocumented mirror)
	.long i_trans  	//xlat
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
	.long i_invalid	// fpo1
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
	.long i_invalid
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
	.byte PSR_Z|PSR_P, 0, 0, PSR_P, 0, PSR_P, PSR_P, 0, PSR_X, PSR_P+PSR_X, PSR_X+PSR_P, PSR_X, PSR_X+PSR_P, PSR_X, PSR_X, PSR_P+PSR_X
	.byte 0      , PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_X+PSR_P, PSR_X, PSR_X, PSR_P+PSR_X, PSR_X, PSR_P+PSR_X, PSR_X+PSR_P, PSR_X
	.byte PSR_Y, PSR_Y+PSR_P, PSR_Y+PSR_P, PSR_Y, PSR_Y+PSR_P, PSR_Y, PSR_Y, PSR_Y+PSR_P, PSR_Y+PSR_X+PSR_P, PSR_X+PSR_Y, PSR_Y+PSR_X ,PSR_P+PSR_X+PSR_Y, PSR_Y+PSR_X, PSR_P+PSR_X+PSR_Y, PSR_X+PSR_Y+PSR_P, PSR_X+PSR_Y
	.byte PSR_Y+PSR_P, PSR_Y, PSR_Y, PSR_Y+PSR_P, PSR_Y, PSR_Y+PSR_P, PSR_Y+PSR_P, PSR_Y, PSR_Y+PSR_X, PSR_P+PSR_X+PSR_Y, PSR_Y+PSR_X+PSR_P, PSR_X+PSR_Y, PSR_Y+PSR_X+PSR_P, PSR_X+PSR_Y, PSR_X+PSR_Y, PSR_P+PSR_X+PSR_Y
	.byte 0      , PSR_P, PSR_P, 0, PSR_P, 0, 0, PSR_P, PSR_X+PSR_P, PSR_X, PSR_X, PSR_P+PSR_X, PSR_X, PSR_P+PSR_X, PSR_X+PSR_P, PSR_X
	.byte PSR_P,       0, 0, PSR_P, 0, PSR_P, PSR_P, 0, PSR_X, PSR_P+PSR_X, PSR_X+PSR_P, PSR_X, PSR_X+PSR_P, PSR_X, PSR_X, PSR_P+PSR_X
	.byte PSR_Y+PSR_P, PSR_Y, PSR_Y, PSR_P+PSR_Y, PSR_Y, PSR_P+PSR_Y, PSR_Y+PSR_P, PSR_Y, PSR_Y+PSR_X, PSR_P+PSR_X+PSR_Y, PSR_Y+PSR_X+PSR_P, PSR_X+PSR_Y, PSR_X+PSR_Y+PSR_P, PSR_X+PSR_Y, PSR_X+PSR_Y, PSR_P+PSR_X+PSR_Y
	.byte PSR_Y, PSR_P+PSR_Y, PSR_Y+PSR_P, PSR_Y, PSR_Y+PSR_P, PSR_Y, PSR_Y, PSR_P+PSR_Y, PSR_Y+PSR_X+PSR_P, PSR_X+PSR_Y, PSR_Y+PSR_X, PSR_P+PSR_X+PSR_Y, PSR_X+PSR_Y, PSR_P+PSR_X+PSR_Y, PSR_X+PSR_Y+PSR_P, PSR_X+PSR_Y
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_X+PSR_P, PSR_X+PSR_S, PSR_S+PSR_X, PSR_P+PSR_X+PSR_S, PSR_X+PSR_S, PSR_P+PSR_X+PSR_S, PSR_X+PSR_S+PSR_P, PSR_X+PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_X, PSR_P+PSR_X+PSR_S, PSR_S+PSR_X+PSR_P, PSR_X+PSR_S, PSR_X+PSR_S+PSR_P, PSR_X+PSR_S, PSR_X+PSR_S, PSR_P+PSR_X+PSR_S
	.byte PSR_S+PSR_Y+PSR_P, PSR_Y+PSR_S, PSR_Y+PSR_S, PSR_P+PSR_Y+PSR_S, PSR_Y+PSR_S, PSR_P+PSR_Y+PSR_S, PSR_Y+PSR_S+PSR_P, PSR_Y+PSR_S, PSR_Y+PSR_X+PSR_S, PSR_P+PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S+PSR_P, PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S+PSR_P, PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S, PSR_P+PSR_Y+PSR_X+PSR_S
	.byte PSR_S+PSR_Y, PSR_P+PSR_Y+PSR_S, PSR_Y+PSR_S+PSR_P, PSR_Y+PSR_S, PSR_Y+PSR_S+PSR_P, PSR_Y+PSR_S, PSR_Y+PSR_S, PSR_P+PSR_Y+PSR_S, PSR_Y+PSR_X+PSR_S+PSR_P, PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S, PSR_P+PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S, PSR_P+PSR_Y+PSR_X+PSR_S, PSR_Y+PSR_X+PSR_S+PSR_P, PSR_Y+PSR_X+PSR_S
	.byte PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_X, PSR_P+PSR_X+PSR_S, PSR_S+PSR_X+PSR_P, PSR_X+PSR_S, PSR_X+PSR_S+PSR_P, PSR_X+PSR_S, PSR_X+PSR_S, PSR_P+PSR_X+PSR_S
	.byte PSR_S, PSR_P+PSR_S, PSR_S+PSR_P, PSR_S, PSR_S+PSR_P, PSR_S, PSR_S, PSR_P+PSR_S, PSR_S+PSR_X+PSR_P, PSR_X+PSR_S, PSR_S+PSR_X, PSR_P+PSR_X+PSR_S, PSR_X+PSR_S, PSR_P+PSR_X+PSR_S, PSR_X+PSR_S+PSR_P, PSR_X+PSR_S
	.byte PSR_S+PSR_Y, PSR_P+PSR_S+PSR_Y, PSR_S+PSR_Y+PSR_P, PSR_S+PSR_Y, PSR_S+PSR_Y+PSR_P, PSR_S+PSR_Y, PSR_S+PSR_Y, PSR_P+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y+PSR_P, PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y, PSR_P+PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y, PSR_P+PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y+PSR_P, PSR_X+PSR_S+PSR_Y
	.byte PSR_S+PSR_Y+PSR_P, PSR_S+PSR_Y, PSR_S+PSR_Y, PSR_P+PSR_S+PSR_Y, PSR_S+PSR_Y, PSR_P+PSR_S+PSR_Y, PSR_S+PSR_Y+PSR_P, PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y, PSR_P+PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y+PSR_P, PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y+PSR_P, PSR_X+PSR_S+PSR_Y, PSR_X+PSR_S+PSR_Y, PSR_P+PSR_X+PSR_S+PSR_Y
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
