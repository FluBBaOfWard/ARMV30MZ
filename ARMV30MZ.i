
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

	.struct -(59*4)			;@ Changes section so make sure it's set before real code.
v30MemTbl:			.space 16*4
v30ReadTbl:			.space 16*4
v30WriteTbl:		.space 16*4

v30Regs:			.space 8*4
v30ICount:			.long 0
v30NoInterrupt:		.long 0
v30PrefixBase:		.long 0
v30SegPrefix:		.byte 0
					.space 3
v30Opz:				.space 256*4
v30PZST:			.space 256
v30Size:

;@----------------------------------------------------------------------------
