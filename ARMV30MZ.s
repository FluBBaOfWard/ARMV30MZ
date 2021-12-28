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

	.global I
	.global no_interrupt
	.global prefix_base
	.global seg_prefix
	.global nec_instruction

	.global V30OpTable
	.global PZSTable

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
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegAW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_cx:
_51:	;@ PUSH CX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegCW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_dx:
_52:	;@ PUSH DX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegDW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_bx:
_53:	;@ PUSH BX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBW]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_sp:
_54:	;@ PUSH SP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_bp:
_55:	;@ PUSH BP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegBP]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_si:
_56:	;@ PUSH SI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIX]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_push_di:
_57:	;@ PUSH DI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r1,r1,#2
	add	r0,r1,r0,lsl#4
	strh r1,[v30ptr,#v30RegSP]
	ldrh r1,[v30ptr,#v30RegIY]
	bl cpu_writemem20w
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_pop_ax:
_58:	;@ POP AX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegAW]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_cx:
_59:	;@ POP CX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegCW]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_dx:
_5A:	;@ POP DX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegDW]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_bx:
_5B:	;@ POP BX
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBW]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_sp:
_5C:	;@ POP SP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	bl cpu_readmem20w
	add r0,r0,#2
	strh r0,[v30ptr,#v30RegSP]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_bp:
_5D:	;@ POP BP
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegBP]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_si:
_5E:	;@ POP SI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIX]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_pop_di:
_5F:	;@ POP DI
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	add	r0,r1,r0,lsl#4
	add	r1,r1,#2
	strh r1,[v30ptr,#v30RegSP]
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30RegIY]
	ldr r0,[v30ptr,#v30ICount]
	sub	r0,r0,#1
	str r0,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_push_d16:
_68:	;@ PUSH D16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r1,#2
	add	r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	mov r1,r0
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r2,r2,#2
	add	r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_jo:
_70:	;@ JMP Overflow
;@----------------------------------------------------------------------------
	jmpne v30OverVal
;@----------------------------------------------------------------------------
i_jno:
_71:	;@ JMP Not Overflow
;@----------------------------------------------------------------------------
	jmpeq v30OverVal
;@----------------------------------------------------------------------------
i_jc:
_72:	;@ JMP Carry
;@----------------------------------------------------------------------------
	jmpne v30CarryVal
;@----------------------------------------------------------------------------
i_jnc:
_73:	;@ JMP Not Carry
;@----------------------------------------------------------------------------
	jmpeq v30CarryVal
;@----------------------------------------------------------------------------
i_jz:
_74:	;@ JMP Zero
;@----------------------------------------------------------------------------
	jmpeq v30ZeroVal
;@----------------------------------------------------------------------------
i_jnz:
_75:	;@ JMP Not Zero
;@----------------------------------------------------------------------------
	jmpne v30ZeroVal
;@----------------------------------------------------------------------------
;@i_jce:
;@_76:	;@ JMP CE
;@----------------------------------------------------------------------------
;@	jmpne v30OverVal
;@----------------------------------------------------------------------------
;@i_jnce:
;@_77:	;@ JMP Not CE
;@----------------------------------------------------------------------------
;@	jmpeq v30OverVal
;@----------------------------------------------------------------------------
i_js:
_78:	;@ JMP Sign
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r3,#1
	add	r0,r3,r0,lsl#4
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	ldr r3,[v30ptr,#v30ICount]
	cmp	r1,#0
	movmi r0,r0,lsl#24
	addmi r4,r4,r0,asr#24
	submi r3,r3,#3
	subpl r3,r3,#1
	strh r4,[v30ptr,#v30IP]
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jns:
_79:	;@ JMP Not Sign
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r3,#1
	add	r0,r3,r0,lsl#4
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30SignVal]
	ldr r3,[v30ptr,#v30ICount]
	cmp	r1,#0
	movpl r0,r0,lsl#24
	addpl r4,r4,r0,asr#24
	subpl r3,r3,#3
	submi r3,r3,#1
	strh r4,[v30ptr,#v30IP]
	str r3,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
;@i_jp:
;@_7A:	;@ JMP Parity
;@----------------------------------------------------------------------------
;@	jmpne v30OverVal
;@----------------------------------------------------------------------------
;@i_jnp:
;@_7B:	;@ JMP Not Parity
;@----------------------------------------------------------------------------
;@	jmpeq v30OverVal
;@----------------------------------------------------------------------------
;@i_jl:
;@_7C:	;@ JMP Overflow
;@----------------------------------------------------------------------------
;@	jmpne v30OverVal
;@----------------------------------------------------------------------------
;@i_jnl:
;@_7D:	;@ JMP Not Overflow
;@----------------------------------------------------------------------------
;@	jmpeq v30OverVal
;@----------------------------------------------------------------------------
;@i_jle:
;@_7E:	;@ JMP Overflow
;@----------------------------------------------------------------------------
;@	jmpne v30OverVal
;@----------------------------------------------------------------------------
;@i_jnle:
;@_7F:	;@ JMP Not Overflow
;@----------------------------------------------------------------------------
;@	jmpeq v30OverVal

;@----------------------------------------------------------------------------
i_xchg_axcx:
_91:	;@ XCHG AXCX
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldr r0,[v30ptr,#v30RegAW]
	sub	r1,r1,#3
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
	sub	r1,r1,#3
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
	sub	r1,r1,#3
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
	ldrh r2,[v30ptr,#v30RegBW]
	sub	r1,r1,#3
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBW]
	strh r2,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_xchg_axbp:
_95:	;@ XCHG AXBP
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrh r0,[v30ptr,#v30RegAW]
	ldrh r2,[v30ptr,#v30RegBP]
	sub	r1,r1,#3
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
	sub	r1,r1,#3
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
	sub	r1,r1,#3
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
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegAW]
	bx lr
;@----------------------------------------------------------------------------
i_cwd:
_99:	;@ CWTWL
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	ldrsb r0,[v30ptr,#v30RegAH]
	sub	r1,r1,#1
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
	sub	r6,r6,#2
	add	r0,r6,r7,lsl#4
	bl cpu_writemem20w

	ldrh r1,[v30ptr,#v30IP]
	add	r4,r1,#2
	add	r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30IP]
	add	r0,r4,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30SRegCS]
	add	r1,r4,#2
	sub	r6,r6,#2
	add	r0,r6,r7,lsl#4
	bl cpu_writemem20w

	strh r6,[v30ptr,#v30RegSP]
	ldr r1,[v30ptr,#v30ICount]
	sub	r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4-r7,pc}
;@----------------------------------------------------------------------------
i_wait:
_9B:	;@ WAIT
;@----------------------------------------------------------------------------
	ldr r1,[v30ptr,#v30ICount]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	bx lr

;@----------------------------------------------------------------------------
i_mov_ald8:
_B0:	;@ MOV ALD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegAL]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cld8:
_B1:	;@ MOV CLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegCL]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dld8:
_B2:	;@ MOV DLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegDL]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bld8:
_B3:	;@ MOV BLD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegBL]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_ahd8:
_B4:	;@ MOV AHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegAH]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_chd8:
_B5:	;@ MOV CHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegCH]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dhd8:
_B6:	;@ MOV DHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegDH]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bhd8:
_B7:	;@ MOV BHD8
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#1
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20
	ldr r1,[v30ptr,#v30ICount]
	strb r0,[v30ptr,#v30RegBH]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_mov_axd16:
_B8:	;@ MOV AXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegAW]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_cxd16:
_B9:	;@ MOV CXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegCW]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_dxd16:
_BA:	;@ MOV DXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegDW]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bxd16:
_BB:	;@ MOV BXD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBW]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_spd16:
_BC:	;@ MOV SPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegSP]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_bpd16:
_BD:	;@ MOV BPD16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegBP]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_sid16:
_BE:	;@ MOV SID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIX]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
i_mov_did16:
_BF:	;@ MOV DID16
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrh r3,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r2,r3,#2
	add	r0,r3,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30RegIY]
	sub	r1,r1,#1
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
i_call_d16:
_E8:	;@ CALL D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r4,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r0,r4,r0,lsl#4
	bl cpu_readmem20w
	add	r1,r4,#2
	add r4,r1,r0
	strh r4,[v30ptr,#v30IP]
	ldrh r2,[v30ptr,#v30RegSP]
	ldrh r0,[v30ptr,#v30SRegSS]
	sub	r2,r2,#2
	add	r0,r2,r0,lsl#4
	strh r2,[v30ptr,#v30RegSP]
	bl cpu_writemem20w
	ldr r1,[v30ptr,#v30ICount]
	sub	r1,r1,#5
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jmp_d16:
_E9:	;@ JMP D16
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add	r4,r1,#2
	add	r0,r1,r0,lsl#4
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	add r4,r4,r0
	strh r4,[v30ptr,#v30IP]
	sub	r1,r1,#4
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
i_jmp_far:
_EA:	;@ JMP FAR
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	ldrh r1,[v30ptr,#v30IP]
	ldrh r5,[v30ptr,#v30SRegCS]
	add	r4,r1,#2
	add	r0,r1,r5,lsl#4
	bl cpu_readmem20w
	strh r0,[v30ptr,#v30IP]
	add	r0,r4,r5,lsl#4
	bl cpu_readmem20w
	ldr r1,[v30ptr,#v30ICount]
	strh r0,[v30ptr,#v30SRegCS]
	sub	r1,r1,#7
	str r1,[v30ptr,#v30ICount]
	ldmfd sp!,{r4,r5,pc}

;@----------------------------------------------------------------------------
V30RunXCycles:				;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r4,r0
	str r0,[v30ptr,#v30ICount]
xLoop:
	ldr r0,[v30ptr,#v30ICount]
	cmp r0,#0
	bmi xOut
	ldrh r1,[v30ptr,#v30IP]
	ldrh r0,[v30ptr,#v30SRegCS]
	add r2,r1,#1
	add r0,r1,r0,lsl#4
	strh r2,[v30ptr,#v30IP]
	bl cpuReadByte
	adr lr,xLoop
	ldr pc,[v30ptr,r0,lsl#2]
xOut:
	sub r0,r4,r0
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
	.section .text				;@ For everything else
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
I:				.space 20*4
no_interrupt:	.long 0
prefix_base:	.long 0
seg_prefix:		.byte 0
				.space 3
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
	.long i_jo
	.long i_jno
	.long i_jc
	.long i_jnc
	.long i_jz
	.long i_jnz
	.long i_jce
	.long i_jnce
	.long i_js
	.long i_jns
	.long i_jp
	.long i_jnp
	.long i_jl
	.long i_jnl
	.long i_jle
	.long i_jnle
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
	.long i_wait
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
	.long i_enter
	.long i_leave
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
	.long i_jmp_d8
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

;@----------------------------------------------------------------------------

#endif // #ifdef __arm__
