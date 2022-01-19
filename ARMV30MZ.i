
				;@ r0,r1,r2=temp regs.
	v30f		.req r3			;@
	v30a		.req r4			;@ Bits 0-23=0
	v30bc		.req r5			;@ Bits 0-15=0
	v30de		.req r6			;@ Bits 0-15=0
	v30hl		.req r7			;@ Bits 0-15=0
	cycles		.req r8
	v30pc		.req r9
	v30sp		.req r10		;@ Bits 0-15=0
	v30ptr		.req r11
	v30xy		.req lr			;@ Pointer to IX or IY reg
	addy		.req r12		;@ Keep this at r12 (scratch for APCS)

	.struct -(72*4)			;@ Changes section so make sure it's set before real code.
v30MemTbl:			.space 16*4
v30ReadTbl:			.space 16*4
v30WriteTbl:		.space 16*4

;@--------------------------------
v30I:
v30Regs:
v30RegAW:
v30RegAL:			.byte 0
v30RegAH:			.byte 0
v30RegCW:
v30RegCL:			.byte 0
v30RegCH:			.byte 0
v30RegDW:
v30RegDL:			.byte 0
v30RegDH:			.byte 0
v30RegBW:
v30RegBL:			.byte 0
v30RegBH:			.byte 0
v30RegSP:
v30RegSPL:			.byte 0
v30RegSPH:			.byte 0
v30RegBP:
v30RegBPL:			.byte 0
v30RegBPH:			.byte 0
v30RegIX:
v30RegIXL:			.byte 0
v30RegIXH:			.byte 0
v30RegIY:
v30RegIYL:			.byte 0
v30RegIYH:			.byte 0

v30SRegs:
v30SRegES:			.short 0
v30SRegCS:			.short 0
v30SRegSS:			.short 0
v30SRegDS:			.short 0

v30ICount:			.long 0
v30SignVal:			.long 0
v30AuxVal:			.long 0
v30OverVal:			.long 0
v30ZeroVal:			.long 0
v30CarryVal:		.long 0
v30ParityVal:		.long 0
v30EA:				.long 0
v30IntVector:		.long 0
v30PendingIrq:		.long 0
v30NmiState:		.long 0
v30IrqState:		.long 0
v30IrqCallback:		.long 0
v30PrefixBase:		.long 0
v30IP:				.short 0
v30EO:				.short 0
v30TF:				.byte 0
v30IF:				.byte 0
v30DF:				.byte 0
v30MF:				.byte 0
v30SegPrefix:		.byte 0
v30Halt:			.byte 0
					.space 2
;@--------------------------------

v30NoInterrupt:		.long 0
v30Opz:				.space 256*4
v30PZST:			.space 256
v30EATable:			.space 192*4
v30ModRm:
v30ModRmReg:		.space 256
v30ModRmRm:			.space 256
v30Size:

;@----------------------------------------------------------------------------
