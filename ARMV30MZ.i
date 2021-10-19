
				;@ r0,r1,r2=temp regs.
	v30f		.req r3			;@
	v30a		.req r4			;@ Bits 0-23=0
	v30bc		.req r5			;@ Bits 0-15=0
	v30de		.req r6			;@ Bits 0-15=0
	v30hl		.req r7			;@ Bits 0-15=0
	cycles		.req r8
	v30pc		.req r9
	v30optbl	.req r10
	v30sp		.req r11		;@ Bits 0-15=0
	v30xy		.req lr			;@ Pointer to IX or IY reg
	addy		.req r12		;@ Keep this at r12 (scratch for APCS)

	.struct -(105*4)			;@ Changes section so make sure it's set before real code.
v30MemTbl:			.space 64*4
v30ReadTbl:			.space 8*4
v30WriteTbl:		.space 8*4

v30Regs:			.space 8*4
v30Regs2:			.space 5*4
v30IX:				.long 0
v30IY:				.long 0
v30I:				.byte 0
v30R:				.byte 0
v30IM:				.byte 0
v30Iff2:			.byte 0

v30IrqPin:			.byte 0
v30Iff1:			.byte 0
v30NmiPending:		.byte 0
v30ResetPin:		.space 1

v30NmiPin:			.byte 0
v30Out0:			.byte 0
v30Padding1:		.space 2

v30LastBank:		.long 0
v30OldCycles:		.long 0
v30NextTimeout_:	.long 0
v30NextTimeout:		.long 0
v30IMFunction:		.long 0
v30IrqVectorFunc:	.long 0
v30IrqAckFunc:		.long 0
v30Opz:				.space 256*4
v30PZST:			.space 256
v30Size:

;@----------------------------------------------------------------------------
