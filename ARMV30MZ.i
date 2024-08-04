//
//  ARMV30MZ.i
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2024 Fredrik Ahlström. All rights reserved.
//

#define NEC_NMI_VECTOR 2

	v30ofs		.req r6			;@ Effective Offset 
	v30csr		.req r7			;@ Current Segment Register
	v30f		.req r8			;@ CPU flags A, S, Z, C & V
	v30pc		.req r9
	v30cyc		.req r10		;@ Bit 0-7 = Misc flags, see below.
	v30ptr		.req r11

;@----------------------------------------------------------------------------
	.equ CYC_SHIFT, 8
	.equ CYCLE, 1<<CYC_SHIFT	;@ One cycle
	.equ CYC_MASK, CYCLE-1		;@ Mask
;@----------------------------------------------------------------------------
;@ v30cyc flags in lower bits
//	.equ SEG_PREFIX, 1<<0		;@ Bit 0
//	.equ REP_PREFIX, 1<<1		;@ Bit 1
//	.equ REPN_PREFIX, 1<<2		;@ Bit 2
	.equ LOCK_PREFIX, 1<<3		;@ Bit 3
	.equ HALT_FLAG, 1<<4		;@ Bit 4
	.equ TRAP_FLAG, 1<<5		;@ Bit 5
;@----------------------------------------------------------------------------
	.equ IRQ_PIN, 1			;@ Which value is set when INT pin is set.

	.struct -(37*4)
v30I:
v30Regs2:
					.short 0
v30Regs:
v30RegAW:						;@ AX on Intel
v30RegAL:			.byte 0
v30RegAH:			.byte 0
					.short 0
v30RegCW:						;@ CX on Intel
v30RegCL:			.byte 0
v30RegCH:			.byte 0
					.short 0
v30RegDW:						;@ DX on Intel
v30RegDL:			.byte 0
v30RegDH:			.byte 0
					.short 0
v30RegBW:						;@ BX on Intel
v30RegBL:			.byte 0
v30RegBH:			.byte 0

v30RegSP:			.short 0
v30RegSPL:			.byte 0
v30RegSPH:			.byte 0

v30RegBP:			.short 0
v30RegBPL:			.byte 0
v30RegBPH:			.byte 0

v30RegIX:			.short 0	;@ SI on Intel
v30RegIXL:			.byte 0
v30RegIXH:			.byte 0

v30RegIY:			.short 0	;@ DI on Intel. Must be right before DS1 so we can use "ldrd v30ofs, v30csr".
v30RegIYL:			.byte 0
v30RegIYH:			.byte 0

v30SRegs:
v30SRegDS1:			.long 0		;@ ES on Intel
v30SRegPS:			.long 0		;@ CS on Intel
v30SRegSS:			.long 0
v30SRegDS0:			.long 0		;@ DS on Intel

v30PrefixBase:		.long 0		;@ Mapped to v30csr/r7
v30Flags:			.long 0		;@ Mapped to v30f/r8
v30PC:				.long 0		;@ Mapped to v30pc/r9
v30Cycles:			.long 0		;@ Mapped to v30cyc/r10
v30IrqPin:			.byte 0		;@ IrqPin, IF  & NmiPending needs to be together in the same Word.
v30IF:				.byte 0
v30Empty:			.byte 0		;@ Was TRAP/BREAK flag
v30NmiPending:		.byte 0
v30ParityVal:		.short 0
v30NmiPin:			.byte 0
v30DF:				.byte 0		;@ Direction flag, this is either 1 or -1.
v30MulOverflow:		.byte 0
					.space 3

v30IEnd:
;@--------------------------------
v30LastBank:		.long 0
v30IrqVectorFunc:	.long 0

v30MemTbl:			.space 16*4
v30MemTblInv:

v30Opz:				.space 256*4
v30PZST:			.space 256
v30EATable:			.space 256*4
v30ModRm:
v30ModRmRm:
v30ModRmReg:		.space 256*4
v30SegTbl:			.space 256
v30Size:
	.previous
;@----------------------------------------------------------------------------
