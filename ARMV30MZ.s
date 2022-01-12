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
	.global v30SetIRQPin
	.global V30SetNMIPin
	.global V30SetResetPin
	.global V30RestoreAndRunXCycles
	.global V30RunXCycles
	.global V30CheckIRQs
	.global V30SaveState
	.global V30LoadState
	.global V30GetStateSize
	.global V30RedirectOpcode

	.global i_insb
	.global i_insw
	.global i_outsb
	.global i_outsw
	.global i_movsb
	.global i_movsw
	.global i_cmpsb
	.global i_cmpsw
	.global i_stosb
	.global i_stosw
	.global i_lodsb
	.global i_lodsw
	.global i_scasb
	.global i_scasw

	.global I
	.global no_interrupt
	.global nec_instruction
	.global nec_interrupt
	.global nec_int
	.global Mod_RM
	.global GetEA

	.global V30OpTable
	.global PZSTable

;@----------------------------------------------------------------------------
i_add_br8:
_00:	;@ ADD BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	add8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	add16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	add8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_add_axd16:
_05:	;@ ADD AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	add16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_es:
_06:	;@ PUSH ES
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegES]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#2
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegES]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_or_br8:
_08:	;@ OR BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	or8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	or16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	or8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_or_axd16:
_0D:	;@ OR AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	or16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_cs:
_0E:	;@ PUSH CS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegCS]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#2
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegCS]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_adc_br8:
_10:	;@ ADC BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	adc8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	adc16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	adc8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_adc_axd16:
_15:	;@ ADC AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	adc16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_ss:
_16:	;@ PUSH SS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r1,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#2
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	mov r0,#1
	str r0,[v30ptr,#v30NoInterrupt]			;@ What is this?
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sbb_br8:
_18:	;@ SBB BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	sbb8 r1,r0

	cmp r4,#0xC0
	strbpl r1,[r6,#v30Regs]
	ldmfd sp!,{r4-r6,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20
1:
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	sbb16 r1,r0

	cmp r4,#0xC0
	strhpl r1,[r5,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	ldr r0,[v30ptr,#v30EA]
	b cpu_writemem20w
1:
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	sbb8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	sbb16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	sbb8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sbb_axd16:
_1D:	;@ SBB AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	sbb16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_ds:
_1E:	;@ PUSH DS
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30SRegDS]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#2
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegDS]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_and_br8:
_20:	;@ AND BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	and8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	and16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	and8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_and_axd16:
_25:	;@ AND AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	and16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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

	ldr r2,[v30ptr,#v30ICount]
	sub r2,r2,#1
	str r2,[v30ptr,#v30ICount]

	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#10
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_sub_br8:
_28:	;@ SUB BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	sub8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	sub16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_sub_axd16:
_2D:	;@ SUB AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	sub16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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

	ldr r2,[v30ptr,#v30ICount]
	sub r2,r2,#1
	str r2,[v30ptr,#v30ICount]

	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#10
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_xor_br8:
_30:	;@ XOR BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	xor8 r0,r1

	strb r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	xor16 r0,r1

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	xor8 r0,r1

	strb r0,[v30ptr,#v30RegAL]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_xor_axd16:
_35:	;@ XOR AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	xor16 r0,r1

	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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

	ldr r2,[v30ptr,#v30ICount]
	sub r2,r2,#1
	str r2,[v30ptr,#v30ICount]

	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#9
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_cmp_br8:
_38:	;@ CMP BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	sub8 r1,r0

	ldmfd sp!,{r4,r5,pc}
1:
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r2,v30ptr,r2,lsl#1
	ldrh r0,[r2,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	sub16 r1,r0

	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	add r1,v30ptr,r0
	ldrb r2,[r1,#v30ModRmReg]
	add r4,v30ptr,r2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	ldrb r2,[r1,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r1,[r4,#v30Regs]

	sub8 r0,r1

	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrh r1,[r4,#v30Regs]

	sub16 r0,r1

	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	sub8 r0,r1

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_cmp_axd16:
_3D:	;@ CMP AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	sub16 r0,r1

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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

	ldr r2,[v30ptr,#v30ICount]
	sub r2,r2,#1
	str r2,[v30ptr,#v30ICount]

	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#9
	str r1,[v30ptr,#v30ICount]
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
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_cx:
_51:	;@ PUSH CX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegCW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_dx:
_52:	;@ PUSH DX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegDW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_bx:
_53:	;@ PUSH BX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_sp:
_54:	;@ PUSH SP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_bp:
_55:	;@ PUSH BP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBP]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_si:
_56:	;@ PUSH SI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIX]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_di:
_57:	;@ PUSH DI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r1,r1,#2
	add r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIY]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#9
	str r0,[v30ptr,#v30ICount]
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
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}

;@----------------------------------------------------------------------------
i_push_d16:
_68:	;@ PUSH D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	mov r1,r0
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_imul_d16:
_69:	;@ IMUL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
0:
	mov r5,r0
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w

	mul r0,r5,r0
	movs r1,r0,asr#15
	mvnsne r1,r1
	movne r1,#1
	str r1,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30OverVal]

	strh r0,[r4,#v30Regs]
	ldmfd sp!,{r4,r5,pc}
1:
	sub r3,r3,#4
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r1,r0,lsl#24
	mov r1,r1,asr#24
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_imul_d8:
_6B:	;@ IMUL D8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r1,r0,#0x38
	add r4,v30ptr,r1,lsr#2
	ldr r3,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
0:
	mov r5,r0
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	sub r3,r3,#4
	str r3,[v30ptr,#v30ICount]
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
	bl cpu_writemem20
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#6
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#6
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}
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
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}

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
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldr r3,[v30ptr,#v30CarryVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r3,#0
	movne r2,#0
	cmp r2,#0
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#4
	subne r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bh:
_77:	;@ Branch if Higher
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldr r3,[v30ptr,#v30CarryVal]
	ldr r2,[v30ptr,#v30ZeroVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r3,#0
	movne r2,#0
	cmp r2,#0
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#4
	subeq r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bn:
_78:	;@ Branch if Negative
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r3,#1
	add r0,r3,r0,lsl#4
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	ldr r3,[v30ptr,#v30ICount]
	cmp r1,#0
	movmi r0,r0,lsl#24
	addmi r4,r4,r0,asr#24
	submi r3,r3,#4
	subpl r3,r3,#1
	strh r4,[v30ptr,#v30IP]
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bp:
_79:	;@ Branch if Positive
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r3,#1
	add r0,r3,r0,lsl#4
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	ldr r3,[v30ptr,#v30ICount]
	cmp r1,#0
	movpl r0,r0,lsl#24
	addpl r4,r4,r0,asr#24
	subpl r3,r3,#4
	submi r3,r3,#1
	strh r4,[v30ptr,#v30IP]
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bpe:
_7A:	;@ Branch if Parity Even
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldrb r2,[v30ptr,#v30ParityVal]
	ldr r1,[v30ptr,#v30ICount]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	cmp	r2,#0
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#4
	subeq r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bpo:
_7B:	;@ Branch if Parity Odd
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldrb r2,[v30ptr,#v30ParityVal]
	ldr r1,[v30ptr,#v30ICount]
	add r3,v30ptr,#v30PZST
	ldrb r2,[r3,r2]
	cmp	r2,#0
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#4
	subne r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_blt:
_7C:	;@ Branch if Less Than
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	eors r2,r2,r3
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#4
	subeq r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bge:
_7D:	;@ Branch if Greater than or Equal
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
	bl cpu_readmem20
	ldr r2,[v30ptr,#v30OverVal]
	ldr r3,[v30ptr,#v30SignVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp	r2,#0
	movne r2,#1
	cmp r3,#0
	movpl r3,#0
	movmi r3,#1
	eors r2,r2,r3
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#4
	subne r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_ble:
_7E:	;@ Branch if Less than or Equal
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
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
	ldr r1,[v30ptr,#v30ICount]
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#4
	subeq r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_bgt:
_7F:	;@ Branch if Greater Than
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#1
	add	r0,r1,r0,asl#4
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
	ldr r1,[v30ptr,#v30ICount]
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#4
	subne r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
i_test_br8:
_84:	;@ TEST BR8
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r1,v30ptr,r2
	ldrb r0,[r1,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	ldrb r2,[r5,#v30ModRmReg]
	add r2,v30ptr,r2
	ldrb r1,[r2,#v30Regs]

	and8 r1,r0

	ldmfd sp!,{r4,r5,pc}
1:
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r2,v30ptr,r2,lsl#1
	ldrh r0,[r2,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
0:
	and r2,r4,#0x38
	add r2,v30ptr,r2,lsr#2
	ldrh r1,[r2,#v30Regs]

	and16 r1,r0

	ldmfd sp!,{r4,pc}
1:
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	add r5,v30ptr,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	ldrb r2,[r5,#v30ModRmRm]
	add r6,v30ptr,r2
	ldrb r0,[r6,#v30Regs]
	sub r3,r3,#1
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	ldr r3,[v30ptr,#v30ICount]
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r5,v30ptr,r2,lsl#1
	ldrh r0,[r5,#v30Regs]
	sub r3,r3,#3
	str r3,[v30ptr,#v30ICount]
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
	sub r3,r3,#5
	str r3,[v30ptr,#v30ICount]
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	adr lr,0b
	b cpu_readmem20w
;@----------------------------------------------------------------------------
i_mov_wr16:
_89:	;@ MOV WR16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20

	and r1,r0,#0x38
	add r2,v30ptr,r1,lsr#2
	ldrh r4,[r2,#v30Regs]

	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
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
i_mov_r16w:
_8B:	;@ MOV R16W
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
0:
	ldr r2,[v30ptr,#v30ICount]
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]
	sub r2,r2,#1
	str r2,[v30ptr,#v30ICount]
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r2,r0,#0x38				;@ Mask with 0x18?
	add r1,v30ptr,r2,lsr#2
	ldrh r4,[r1,#v30SRegs]

	cmp r0,#0xC0
	bmi 1f
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	strh r4,[r1,#v30Regs]
0:
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
1:
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	mov r1,r4
	adr lr,0b
	b cpu_writemem20w
;@----------------------------------------------------------------------------
i_lea:
_8D:	;@ LEA
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r4,r0,#0x38
	add r1,v30ptr,#v30EATable
	mov lr,pc
	ldr pc,[r1,r0,lsl#2]
	ldrh r0,[v30ptr,#v30EO]
	add r1,v30ptr,r4,lsr#2
	strh r0,[r1,#v30Regs]

	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_mov_sregw:
_8E:	;@ MOV SREGW
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r5,[v30ptr,#v30ICount]
	and r4,r0,#0x38
	cmp r0,#0xC0
	bmi 1f
	sub r5,r5,#2
	and r2,r0,#7
	add r1,v30ptr,r2,lsl#1
	ldrh r0,[r1,#v30Regs]
0:
	tst r4,#0x20
	addeq r1,v30ptr,r4,lsr#2
	strheq r0,[r1,#v30SRegs]
	mov r1,#1
	str r1,[v30ptr,#v30NoInterrupt]
	str r5,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}
1:
	sub r5,r5,#3
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	cmp r0,#0xC0
	bmi 0f
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	and r0,r0,#7
	add r2,v30ptr,r0,lsl#1
	strh r4,[r2,#v30Regs]
	ldmfd sp!,{r4,pc}
0:
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axcx:
_91:	;@ XCHG AXCX
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldr r0,[v30ptr,#v30RegAW]
	sub r1,r1,#3
	mov r0,r0,ror#16
	str r1,[v30ptr,#v30ICount]
	str r0,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axdx:
_92:	;@ XCHG AXDX
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegDW]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegDW]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axbx:
_93:	;@ XCHG AXBX
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegBW]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBW]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axsp:
_94:	;@ XCHG AXSP
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegSP]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegSP]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axbp:
_95:	;@ XCHG AXBP
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegBP]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBP]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axsi:
_96:	;@ XCHG AXSI
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegIX]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIX]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axdi:
_97:	;@ XCHG AXDI
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegIY]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIY]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_cbw:
_98:	;@ CVTBW
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrsb r0,[v30ptr,#v30RegAL]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_cwd:
_99:	;@ CVTWL
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrsb r0,[v30ptr,#v30RegAH]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	mov r0,r0,asr#8
	strh r0,[v30ptr,#v30RegDW]
	bx lr
;@----------------------------------------------------------------------------
i_call_far:
_9A:	;@ CALL FAR
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	ldrh r5,[v30ptr,#v30SRegCS]
	ldrh r6,[v30ptr,#v30RegSP]
	ldrh r7,[v30ptr,#v30SRegSS]
	mov r1,r5
	sub r6,r6,#2
	add r0,r6,r7,lsl#4
	bl cpu_writemem20w

	ldrh r1,[v30ptr,#v30IP]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	add r1,r4,#2
	sub r6,r6,#2
	add r0,r6,r7,lsl#4
	bl cpu_writemem20w

	strh r6,[v30ptr,#v30RegSP]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4-r7,pc}
;@----------------------------------------------------------------------------
i_poll:
_9B:	;@ POLL, poll the "poll" pin?
;@----------------------------------------------------------------------------
	ldrh r0,[v30ptr,#v30IP]
	ldr r1,[v30ptr,#v30ICount]
	sub r0,r0,#1
	sub r1,r1,#1
	strh r0,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
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
	ldr r3,[v30ptr,#v30ICount]
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
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

	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
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

	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
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
	ldr r3,[v30ptr,#v30ICount]
	sub r3,r3,#2
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_aldisp:
_A0:	;@ MOV ALDISP
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r4,[v30ptr,#v30SRegDS]
	ldrne r4,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	add r0,r0,r4,lsl#4
	bl cpu_readmem20
	strb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_mov_axdisp:
_A1:	;@ MOV AXDISP
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r4,[v30ptr,#v30SRegDS]
	ldrne r4,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	add r0,r0,r4,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_mov_dispal:
_A2:	;@ MOV DISPAL
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r4,[v30ptr,#v30SRegDS]
	ldrne r4,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	add r0,r0,r4,lsl#4
	ldrb r1,[v30ptr,#v30RegAL]
	bl cpu_writemem20
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_mov_dispax:
_A3:	;@ MOV DISPAX
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	ldrheq r4,[v30ptr,#v30SRegDS]
	ldrne r4,[v30ptr,#v30PrefixBase]
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	add r0,r0,r4,lsl#4
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
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
	bl cpu_writemem20
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#5
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
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
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#5
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
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

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#5
	str r0,[v30ptr,#v30ICount]
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

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#5
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_test_ald8:
_A8:	;@ TEST ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]

	and8 r0,r1

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_test_axd16:
_A9:	;@ TEST AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegAW]

	and16 r0,r1

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_stosb:
_AA:	;@ STOSB
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
	ldrb r1,[v30ptr,#v30RegAL]
	bl cpu_writemem20

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#3
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_stosw:
_AB:	;@ STOSW
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
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpu_writemem20w

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#3
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#3
	str r1,[v30ptr,#v30ICount]
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

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#4
	str r0,[v30ptr,#v30ICount]
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

	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#4
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ald8:
_B0:	;@ MOV ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegAL]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cld8:
_B1:	;@ MOV CLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegCL]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dld8:
_B2:	;@ MOV DLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegDL]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bld8:
_B3:	;@ MOV BLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegBL]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ahd8:
_B4:	;@ MOV AHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegAH]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_chd8:
_B5:	;@ MOV CHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegCH]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dhd8:
_B6:	;@ MOV DHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegDH]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bhd8:
_B7:	;@ MOV BHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#1
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegBH]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_mov_axd16:
_B8:	;@ MOV AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegAW]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cxd16:
_B9:	;@ MOV CXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegCW]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dxd16:
_BA:	;@ MOV DXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegDW]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bxd16:
_BB:	;@ MOV BXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBW]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_spd16:
_BC:	;@ MOV SPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r3,#2
	add r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegSP]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bpd16:
_BD:	;@ MOV BPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBP]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_sid16:
_BE:	;@ MOV SID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIX]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_did16:
_BF:	;@ MOV DID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIY]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_ret_d16:
_C2:	;@ RET D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,r1,r0,lsl#4
	bl cpu_readmem20w
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r3,[v30ptr,#v30SRegSS]
	add r2,r1,#2
	add r2,r2,r0
	add r0,r1,r3,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30IP]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30IP]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_wd16:
_C7:	;@ MOV WD16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add	r0,r1,r0,asl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	mov r4,r0
	cmp r4,#0xC0
	bmi 1f
	and r2,r4,#7
	add r1,v30ptr,r2,lsl#1
0:
	mov r5,r0
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w

	mov r1,r0
	mov r0,r5
	cmp r4,#0xC0
	strhpl r1,[r0,#v30Regs]
	ldmfd sp!,{r4,r5,lr}
	bxpl lr
	b cpu_writemem20w
1:
	add r1,v30ptr,#v30EATable
	adr lr,0b
	ldr pc,[r1,r0,lsl#2]
;@----------------------------------------------------------------------------
i_prepare:
_C8:	;@ PREPARE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r10,lr}
	ldr r4,[v30ptr,#v30ICount]
	sub r4,r4,#8
	ldrh r1,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add r6,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	stmfd sp!,{r0}				;@ temp
	add r0,r6,r5,lsl#4
	add r6,r6,#1
	strh r6,[v30ptr,#v30IP]
	bl cpu_readmem20
	and r5,r0,#0x1F

	ldrh r6,[v30ptr,#v30RegSP]
	ldrh r8,[v30ptr,#v30SRegSS]
	ldrh r10,[v30ptr,#v30RegBP]
	sub r6,r6,#2
	add r0,r6,r8,lsl#4
	mov r1,r10
	bl cpu_writemem20w
	mov r9,r6
	subs r5,r5,#1
	bmi 2f
	beq 1f
	ldrb r2,[v30ptr,#v30SegPrefix]
	cmp r2,#0
	moveq r7,r8
	ldrne r7,[v30ptr,#v30PrefixBase]
0:
	sub r10,r10,#2
	add r0,r10,r7,lsl#4
	bl cpu_readmem20w
	mov r1,r0
	sub r6,r6,#2
	add r0,r6,r8,lsl#4
	bl cpu_writemem20w
	sub r4,r4,#4
	subs r5,r5,#1
	bne 0b
1:
	mov r1,r9
	sub r6,r6,#2
	add r0,r6,r8,lsl#4
	bl cpu_writemem20w
	sub r4,r4,#6
2:
	strh r9,[v30ptr,#v30RegBP]
	ldmfd sp!,{r0}
	sub r6,r6,r0
	strh r6,[v30ptr,#v30RegSP]
	str r4,[v30ptr,#v30ICount]
	ldmfd sp!,{r4-r10,pc}
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
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBP]
	sub r1,r1,#2
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_retf_d16:
_CA:	;@ RETF D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,r6,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,r1,r0,lsl#4
	bl cpu_readmem20w
	mov r6,r0
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r5,[v30ptr,#v30SRegSS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30IP]
	add r1,r4,r6
	add r0,r4,r5,lsl#4
	add r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegCS]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,r6,pc}
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
	strh r0,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	ldr r1,[v30ptr,#v30ICount]
	strh r4,[v30ptr,#v30RegSP]
	sub r1,r1,#8
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}
;@----------------------------------------------------------------------------
i_int3:
_CC:	;@ INT3
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#3
	sub r1,r1,#9
	str r1,[v30ptr,#v30ICount]
	b nec_interrupt
;@----------------------------------------------------------------------------
i_int:
_CD:	;@ INT
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	bl nec_interrupt
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#10
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_into:
_CE:	;@ INTO
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30OverVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp r2,#0
	movne r0,#4
	subne r1,r1,#13
	subeq r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	bne nec_interrupt
	bx lr
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
	strh r0,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	add r4,r4,#2
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	strh r4,[v30ptr,#v30RegSP]
	bl i_popf
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#10					;@ -3?
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}

;@----------------------------------------------------------------------------
i_aam:
_D4:	;@ AAM
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20				;@ Not needed?
	ldrb r2,[v30ptr,#v30RegAL]
	ldr r3,=0xCCCCCCCD				;@ 0x8_0000_000A/10)
	ldr r1,[v30ptr,#v30ICount]
	umull r0,r3,r2,r3				;@ AH = AL/10, AL%=10.
	mov r3,r3,lsr#3					;@ Divide by 8
	add r0,r3,r3,lsl#2
	sub r2,r2,r0,lsl#1
	strb r2,[v30ptr,#v30RegAL]
	strb r3,[v30ptr,#v30RegAH]
	ldrsh r3,[v30ptr,#v30RegAW]
	sub r1,r1,#17
	str r1,[v30ptr,#v30ICount]
	str r3,[v30ptr,#v30SignVal]
	str r3,[v30ptr,#v30ZeroVal]
	str r3,[v30ptr,#v30ParityVal]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_aad:
_D5:	;@ AAD
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrh r0,[v30ptr,#v30RegAW]
	mov r0,r0,ror#8
	add r0,r0,r0,lsl#24+3
	add r0,r0,r0,lsl#24+1
	ldr r1,[v30ptr,#v30ICount]
	mov r2,r0,asr#24
	mov r0,r0,lsr#24
	sub r1,r1,#6
	strh r0,[v30ptr,#v30RegAW]
	str r2,[v30ptr,#v30SignVal]
	str r2,[v30ptr,#v30ZeroVal]
	str r2,[v30ptr,#v30ParityVal]
	str r1,[v30ptr,#v30ICount]
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#5
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_loopne:
_E0:	;@ LOOPNE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#1
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	ldr r1,[v30ptr,#v30ICount]
	subs r2,r2,#1
	ldrhne r3,[v30ptr,#v30ZeroVal]
	cmpne r3,#0
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#3
	sub r1,r1,#3
	strh r2,[v30ptr,#v30RegCW]
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_loope:
_E1:	;@ LOOPE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#1
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	ldr r1,[v30ptr,#v30ICount]
	ldrh r3,[v30ptr,#v30ZeroVal]
	subs r2,r2,#1
	moveq r3,#1
	cmp r3,#0
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#3
	sub r1,r1,#3
	strh r2,[v30ptr,#v30RegCW]
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_loop:
_E2:	;@ LOOP
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#1
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	ldr r1,[v30ptr,#v30ICount]
	subs r2,r2,#1
	movne r0,r0,lsl#24
	addne r4,r4,r0,asr#24
	subne r1,r1,#3
	sub r1,r1,#2
	strh r2,[v30ptr,#v30RegCW]
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jcxz:
_E3:	;@ JCXZ
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#1
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldrh r2,[v30ptr,#v30RegCW]
	ldr r1,[v30ptr,#v30ICount]
	cmp r2,#0
	moveq r0,r0,lsl#24
	addeq r4,r4,r0,asr#24
	subeq r1,r1,#3
	sub r1,r1,#1
	strh r4,[v30ptr,#v30IP]
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
i_inal:
_E4:	;@ INAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_inax:
_E5:	;@ INAX
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	mov r4,r0
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	add r0,r4,#1
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAH]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_outal:
_E6:	;@ OUTAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_outax:
_E7:	;@ OUTAX
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldrb r1,[v30ptr,#v30RegAL]
	mov r4,r0
	bl cpu_writeport
	ldrb r1,[v30ptr,#v30RegAH]
	add r0,r4,#1
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
i_call_d16:
_E8:	;@ CALL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r4,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r0,r4,r0,lsl#4
	bl cpu_readmem20w
	add r1,r4,#2
	add r4,r1,r0
	strh r4,[v30ptr,#v30IP]
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub r2,r2,#2
	add r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#5
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jmp_d16:
_E9:	;@ JMP D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#2
	add r0,r1,r0,lsl#4
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	add r4,r4,r0
	strh r4,[v30ptr,#v30IP]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jmp_far:
_EA:	;@ JMP FAR
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add r4,r1,#2
	add r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30IP]
	add r0,r4,r5,lsl#4
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegCS]
	sub r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}
;@----------------------------------------------------------------------------
i_br_d8:
_EB:	;@ Branch short
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r4,r1,#1
	add r0,r1,r0,lsl#4
	bl cpu_readmem20
	ldr r3,[v30ptr,#v30ICount]
	mov r0,r0,lsl#24
	add r4,r4,r0,asr#24
	sub r3,r3,#4
	cmp r0,#-3
	andcs r3,r3,#7
	strh r4,[v30ptr,#v30IP]
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_inaldx:
_EC:	;@ INALDX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegDW]
	bl cpu_readport
	strb r0,[v30ptr,#v30RegAL]
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
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
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_outdxal:
_EE:	;@ OUTDXAL
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r0,[v30ptr,#v30RegDW]
	ldrb r1,[v30ptr,#v30RegAL]
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
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
	bl cpu_writeport
	ldr r1,[v30ptr,#v30ICount]
	sub r1,r1,#6
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
i_lock:
_F0:	;@ LOCK
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#1
	str r0,[v30ptr,#v30NoInterrupt]
	sub r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_hlt:
_F4:	;@ HLT
;@----------------------------------------------------------------------------
	mov r0,#0
	str r0,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_cmc:
_F5:	;@ CMC
;@----------------------------------------------------------------------------
	ldr r0,[v30ptr,#v30CarryVal]
	ldr r1,[v30ptr,#v30ICount]
	cmp r0,#0
	sub r1,r1,#4
	moveq r0,#1
	movne r0,#0
	str r0,[v30ptr,#v30CarryVal]
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_clc:
_F8:	;@ CLC
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#0
	str r0,[v30ptr,#v30CarryVal]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_stc:
_F9:	;@ STC
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#1
	str r0,[v30ptr,#v30CarryVal]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_di:
_FA:	;@ DI
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_ei:
_FB:	;@ EI
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#1
	strb r0,[v30ptr,#v30IF]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_cld:
_FC:	;@ CLD
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#0
	strb r0,[v30ptr,#v30DF]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr
;@----------------------------------------------------------------------------
i_std:
_FD:	;@ STD
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	mov r0,#1
	strb r0,[v30ptr,#v30DF]
	sub r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	bx lr


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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#2
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
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
V30SetIRQPin:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
nec_int:				;@ r0 = vector number * 4
	.type   nec_int STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[v30ptr,#v30IF]
	cmp r1,#0
	bxeq lr
	mov r0,r0,lsr#2
;@----------------------------------------------------------------------------
V30SetIRQ:
nec_interrupt:				;@ r0 = vector number
	.type   nec_interrupt STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	mov r4,r0
	bl i_pushf
	mov r0,#0
	strb r0,[v30ptr,#v30IF]
	strb r0,[v30ptr,#v30TF]
	mov r0,r4,lsl#2
	bl cpu_readmem20w
	mov r5,r0
	mov r0,r4,lsl#2
	add r0,r0,#2
	bl cpu_readmem20w
	mov r4,r0

	ldrh r6,[v30ptr,#v30RegSP]
	ldrh r7,[v30ptr,#v30SRegSS]
	sub r6,r6,#2
	add r0,r6,r7,lsl#4
	ldrh r1,[v30ptr,#v30SRegCS]
	bl cpu_writemem20w
	sub r6,r6,#2
	add r0,r6,r7,lsl#4
	strh r6,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30IP]
	bl cpu_writemem20w

	strh r5,[v30ptr,#v30IP]
	strh r4,[v30ptr,#v30SRegCS]
	ldr r0,[v30ptr,#v30ICount]
	sub r0,r0,#22
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{r4-r7,pc}
;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r9,r0
	str r0,[v30ptr,#v30ICount]
xLoop:
	ldr r0,[v30ptr,#v30ICount]
	cmp r0,#0
	ble xOut
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	adr lr,xLoop
	ldr pc,[v30ptr,r0,lsl#2]
xOut:
	sub r0,r0,r9
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
V30CheckIRQs:
;@----------------------------------------------------------------------------
//	ldr r0,[v30ptr,#v30IrqPin]
	movs addy,r0,asr#16
//	bmi handleReset
//	bne V30NMI
	ands addy,r0,r0,lsr#8
//	ldrne pc,[v30ptr,#v30IMFunction]
;@----------------------------------------------------------------------------
V30Go:						;@ Continue running
;@----------------------------------------------------------------------------
//	fetch 0


;@----------------------------------------------------------------------------
	.section .text			;@ For everything else
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
V30Reset:					;@ r11=v30ptr
;@ Called by cpuReset, (r0-r3,r12 are free to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	adr r1,registerValues		;@ Startup values for different versions of the cpu.

	mov cycles,#0
	mov v30pc,#0
//	encodePC					;@ Get RESET vector
//	ldmia r1!,{r0,v30f-z80hl,v30sp}
//	strb r0,[v30ptr,#v30Out0]
	add r2,v30ptr,#v30Regs
	stmia r2!,{v30f-v30pc,v30sp}
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
I:				.space 23*4
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
