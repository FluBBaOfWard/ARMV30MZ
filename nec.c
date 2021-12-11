/****************************************************************************

	NEC V30MZ(V20/V30/V33) emulator

	Small changes made by toshi (Cycle count macros changed  , "THROUGH" macro added)

	Small changes made by dox@space.pl (Corrected bug in NEG instruction , different AUX flag handling in some opcodes)

	(Re)Written June-September 2000 by Bryan McPhail (mish@tendril.co.uk) based
	on code by Oliver Bergmann (Raul_Bloodworth@hotmail.com) who based code
	on the i286 emulator by Fabrice Frances which had initial work based on
	David Hedley's pcemu(!).

	This new core features 99% accurate cycle counts for each processor,
	there are still some complex situations where cycle counts are wrong,
	typically where a few instructions have differing counts for odd/even
	source and odd/even destination memory operands.

	Flag settings are also correct for the NEC processors rather than the
	I86 versions.

	Nb:  This emulation should be faster than previous NEC cores, but
	because the old cycle count values were far too high in many cases
	the processor has to do more 'work' than before, so the overall effect
	may	be a slower core.

****************************************************************************/


#include <nds.h>

#define UINT8 unsigned char
#define UINT16 unsigned short
#define UINT32 unsigned int
#define INT8 signed char
#define INT16 signed short
#define INT32 signed int
#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int

#include "nec.h"
#include "necintrf.h"
#include "../Memory.h"
#include "../Gfx.h"

typedef union
{					/* eight general registers */
	UINT16 w[8];	/* viewed as 16 bits registers */
	UINT8  b[16];	/* or as 8 bit registers */
} necbasicregs;

typedef struct
{
	necbasicregs regs;
	UINT16 sregs[4];

	UINT16 ip;

	INT32 SignVal;
	UINT32 AuxVal, OverVal, ZeroVal, CarryVal, ParityVal; /* 0 or non-0 valued flags */
	UINT8  TF, IF, DF, MF; 	/* 0 or 1 valued flags */	/* OB[19.07.99] added Mode Flag V30 */
	UINT32 int_vector;
	UINT32 pending_irq;
	UINT32 nmi_state;
	UINT32 irq_state;
	int (*irq_callback)(int irqline);
} nec_Regs;


/***************************************************************************/
/* cpu state															   */
/***************************************************************************/

int nec_ICount;

static nec_Regs I;

/** Base address of the latest prefix segment */
static UINT32 prefix_base;
/** Prefix segment indicator */
u8 seg_prefix;

/* The interrupt number of a pending external interrupt pending NMI is 2.	*/
/* For INTR interrupts, the level is caught on the bus during an INTA cycle */


#include "necinstr.h"
#include "necea.h"
#include "necmodrm.h"

static int no_interrupt;

static UINT8 parity_table[256];


void nec_reset (void *param)
{
	unsigned int i, j, c;
	BREGS reg_name[8] = { AL, CL, DL, BL, AH, CH, DH, BH };

	memset( &I, 0, sizeof(I) );

	no_interrupt = 0;
	I.sregs[CS] = 0xFFFF;

	for (i = 0;i < 0x100; i++) {
		for (j = i, c = 0; j > 0; j >>= 1) {
			c += (j & 1);
		}
		parity_table[i] = !(c & 1);
	}

	I.ZeroVal = I.ParityVal = 1;
	SetMD(1);						// Set the mode-flag = native mode

	for (i = 0; i < 0x100; i++) {
		Mod_RM.reg.b[i] = reg_name[(i & 0x38) >> 3];
		Mod_RM.reg.w[i] = (WREGS)( (i & 0x38) >> 3) ;
	}

	for (i = 0xc0; i < 0x100; i++) {
		Mod_RM.RM.w[i] = (WREGS)( i & 7 );
		Mod_RM.RM.b[i] = (BREGS)reg_name[i & 7];
	}

	I.regs.w[SP] = 0x2000;
}

void nec_int(unsigned int wektor)
{
	u32 dest_seg, dest_off;

	if (I.IF) {
		i_pushf();
		I.TF = I.IF = 0;

		dest_off = cpuReadByte(wektor) | cpuReadByte((wektor)+1) << 8;
		dest_seg = cpuReadByte(wektor + 2) | cpuReadByte(wektor + 3) << 8;

		I.regs.w[SP] -= 2;
		cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP], I.sregs[CS]);
		cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP] + 1, I.sregs[CS] >> 8);

		I.regs.w[SP] -= 2;
		cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP], I.ip);
		cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP] + 1, I.ip >> 8);

		I.ip = dest_off;
		I.sregs[CS] = dest_seg;
	}
}

static void nec_interrupt(unsigned int_num,int md_flag)
{
	u32 dest_seg, dest_off;

	if (int_num == -1) {
		return;
	}
	i_pushf();
	I.TF = I.IF = 0;

	dest_off = cpuReadByte(int_num << 2) | cpuReadByte((int_num << 2) + 1) << 8;
	dest_seg = cpuReadByte((int_num << 2) + 2) | cpuReadByte((int_num << 2) + 3) << 8;

	I.regs.w[SP] -= 2;

	cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP], I.sregs[CS]);
	cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP] + 1, I.sregs[CS] >> 8);

	I.regs.w[SP] -= 2;

	cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP], I.ip);
	cpuWriteByte((I.sregs[SS] << 4) + I.regs.w[SP] + 1, I.ip >> 8);

	I.ip = dest_off & 0xFFFF;
	I.sregs[CS] = dest_seg & 0xFFFF;
}

/****************************************************************************/
/*							   OPCODES										*/
/****************************************************************************/

#define OP(num,func_name) static void func_name(void)


OP( 0x00, i_add_br8 )
{
	u32 res;
	u32 ModRM = cpuReadByte((I.sregs[CS] << 4) + I.ip++), src, dst;
	src = I.regs.b[Mod_RM.reg.b[ModRM]];
	dst = (ModRM) >= 0xC0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : cpuReadByte((*GetEA[ModRM])());

	res = dst + src;
	I.CarryVal = res & 0x100;
	I.OverVal = (res ^ src) & (res ^ dst) & 0x80;
	I.AuxVal = (res ^ (src ^ dst)) & 0x10;
	I.SignVal = I.ZeroVal = I.ParityVal = (s8)res;
	dst = res & 0xFF;

	if (ModRM >= 0xC0) {
		I.regs.b[Mod_RM.RM.b[ModRM]] = dst;
		CLK(1);
	} else {
		cpuWriteByte(EA, dst);
		CLK(3);
	}
}

OP( 0x01, i_add_wr16 )
{
	u32 res;
	u32 ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst;
	src = I.regs.w[Mod_RM.reg.w[ModRM]];
	dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) ));

	res = dst + src;
	I.CarryVal = res & 0x10000;
	I.OverVal = (res ^ src) & (res ^ dst) & 0x8000;
	I.AuxVal = (res ^ (src ^ dst)) & 0x10;
	I.SignVal = I.ZeroVal = I.ParityVal = (signed short)res;
	dst = res & 0xFFFF;

	if (ModRM >= 0xc0) {
		I.regs.w[Mod_RM.RM.w[ModRM]]=dst;
		CLK(1);
	} else {
		cpuWriteByte(EA, dst);
		cpuWriteByte(EA+1, dst >> 8);
		CLK(3);
	}
}

OP( 0x02, i_add_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x03, i_add_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x04, i_add_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[AL]=dst; CLK(1); }
OP( 0x05, i_add_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[AW]=dst; CLK(1); }
OP( 0x06, i_push_es  ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.sregs[ES]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.sregs[ES])>>8); }; }; CLK(2); }
OP( 0x07, i_pop_es   ) { { I.sregs[ES] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(3); }

OP( 0x08, i_or_br8   ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x09, i_or_wr16  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x0a, i_or_r8b   ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x0b, i_or_r16w  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x0c, i_or_ald8  ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[AL]=dst; CLK(1); }
OP( 0x0d, i_or_axd16 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[AW]=dst; CLK(1); }
OP( 0x0e, i_push_cs  ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.sregs[CS]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.sregs[CS])>>8); }; }; CLK(2); }
OP( 0x0f, i_pre_nec  ) { { I.sregs[CS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(2); }

OP( 0x10, i_adc_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x11, i_adc_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x12, i_adc_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x13, i_adc_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x14, i_adc_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[AL]=dst; CLK(1); }
OP( 0x15, i_adc_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[AW]=dst; CLK(1); }
OP( 0x16, i_push_ss  ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.sregs[SS]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.sregs[SS])>>8); }; }; CLK(2); }
OP( 0x17, i_pop_ss   ) { { I.sregs[SS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(3); no_interrupt=1; }

OP( 0x18, i_sbb_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x19, i_sbb_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x1a, i_sbb_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x1b, i_sbb_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x1c, i_sbb_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[AL]=dst; CLK(1); }
OP( 0x1d, i_sbb_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[AW]=dst; CLK(1); }
OP( 0x1e, i_push_ds  ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.sregs[DS]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.sregs[DS])>>8); }; }; CLK(2); }
OP( 0x1f, i_pop_ds   ) { { I.sregs[DS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(3); }

OP( 0x20, i_and_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x21, i_and_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x22, i_and_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x23, i_and_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x24, i_and_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[AL]=dst; CLK(1); }
OP( 0x25, i_and_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[AW]=dst; CLK(1); }
OP( 0x26, i_es       ) { seg_prefix=1; prefix_base=I.sregs[ES]<<4; CLK(1); nec_instruction[(cpuReadByte((I.sregs[CS]<<4)+I.ip++))](); seg_prefix=0; }
OP( 0x27, i_daa      ) { if ((I.AuxVal!=0) || ((I.regs.b[AL] & 0xf) > 9)) { int tmp; I.regs.b[AL] = tmp = I.regs.b[AL] + 6; I.AuxVal = 1; } if ((I.CarryVal!=0) || (I.regs.b[AL] > 0x9f)) { I.regs.b[AL] += 0x60; I.CarryVal = 1; } (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(I.regs.b[AL])); CLK(10); }

OP( 0x28, i_sub_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x29, i_sub_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x2a, i_sub_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x2b, i_sub_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x2c, i_sub_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.b[AL]=dst; CLK(1); }
OP( 0x2d, i_sub_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[AW]=dst; CLK(1); }
OP( 0x2e, i_cs       ) { seg_prefix=1; prefix_base=I.sregs[CS]<<4; CLK(1); nec_instruction[(cpuReadByte((I.sregs[CS]<<4)+I.ip++))](); seg_prefix=0; }
OP( 0x2f, i_das      ) { if ((I.AuxVal!=0) || ((I.regs.b[AL] & 0xf) > 9)) { int tmp; I.regs.b[AL] = tmp = I.regs.b[AL] + -6; I.AuxVal = 1; } if ((I.CarryVal!=0) || (I.regs.b[AL] > 0x9f)) { I.regs.b[AL] += -0x60; I.CarryVal = 1; } (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(I.regs.b[AL])); CLK(10); }

OP( 0x30, i_xor_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; CLKM(3,1); }
OP( 0x31, i_xor_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; CLKM(3,1); }
OP( 0x32, i_xor_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[Mod_RM.reg.b[ModRM]]=dst; CLKM(2,1); }
OP( 0x33, i_xor_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[Mod_RM.reg.w[ModRM]]=dst; CLKM(2,1); }
OP( 0x34, i_xor_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); I.regs.b[AL]=dst; CLK(1); }
OP( 0x35, i_xor_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); I.regs.w[AW]=dst; CLK(1); }
OP( 0x36, i_ss       ) { seg_prefix=1; prefix_base=I.sregs[SS]<<4; CLK(1); nec_instruction[(cpuReadByte((I.sregs[CS]<<4)+I.ip++))](); seg_prefix=0; }
OP( 0x37, i_aaa      ) { if ((I.AuxVal!=0) || ((I.regs.b[AL] & 0xf) > 9)) { I.regs.b[AL] += 6; I.regs.b[AH] += 1; I.AuxVal = 1; I.CarryVal = 1; } else { I.AuxVal = 0; I.CarryVal = 0; } I.regs.b[AL] &= 0x0F; CLK(9); }

OP( 0x38, i_cmp_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; CLKM(2,1); }
OP( 0x39, i_cmp_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; CLKM(2,1); }
OP( 0x3a, i_cmp_r8b  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.b[Mod_RM.reg.b[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; CLKM(2,1); }
OP( 0x3b, i_cmp_r16w ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; CLKM(2,1); }
OP( 0x3c, i_cmp_ald8 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; CLK(1); }
OP( 0x3d, i_cmp_axd16) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; CLK(1); }
OP( 0x3e, i_ds       ) { seg_prefix=1; prefix_base=I.sregs[DS]<<4; CLK(1); nec_instruction[(cpuReadByte((I.sregs[CS]<<4)+I.ip++))](); seg_prefix=0; }
OP( 0x3f, i_aas      ) { if ((I.AuxVal!=0) || ((I.regs.b[AL] & 0xf) > 9)) { I.regs.b[AL] += -6; I.regs.b[AH] += -1; I.AuxVal = 1; I.CarryVal = 1; } else { I.AuxVal = 0; I.CarryVal = 0; } I.regs.b[AL] &= 0x0F; CLK(9); }

OP( 0x40, i_inc_ax ) { unsigned tmp = (unsigned)I.regs.w[AW]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[AW]=tmp1; CLK(1); }
OP( 0x40, i_inc_cx ) { unsigned tmp = (unsigned)I.regs.w[CW]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[CW]=tmp1; CLK(1); }
OP( 0x40, i_inc_dx ) { unsigned tmp = (unsigned)I.regs.w[DW]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[DW]=tmp1; CLK(1); }
OP( 0x40, i_inc_bx ) { unsigned tmp = (unsigned)I.regs.w[BW]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[BW]=tmp1; CLK(1); }
OP( 0x40, i_inc_sp ) { unsigned tmp = (unsigned)I.regs.w[SP]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[SP]=tmp1; CLK(1); }
OP( 0x40, i_inc_bp ) { unsigned tmp = (unsigned)I.regs.w[BP]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[BP]=tmp1; CLK(1); }
OP( 0x40, i_inc_si ) { unsigned tmp = (unsigned)I.regs.w[IX]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[IX]=tmp1; CLK(1); }
OP( 0x40, i_inc_di ) { unsigned tmp = (unsigned)I.regs.w[IY]; unsigned tmp1 = tmp+1; I.OverVal = (tmp == 0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[IY]=tmp1; CLK(1); }

OP( 0x40, i_dec_ax ) { unsigned tmp = (unsigned)I.regs.w[AW]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[AW]=tmp1; CLK(1); }
OP( 0x40, i_dec_cx ) { unsigned tmp = (unsigned)I.regs.w[CW]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[CW]=tmp1; CLK(1); }
OP( 0x40, i_dec_dx ) { unsigned tmp = (unsigned)I.regs.w[DW]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[DW]=tmp1; CLK(1); }
OP( 0x40, i_dec_bx ) { unsigned tmp = (unsigned)I.regs.w[BW]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[BW]=tmp1; CLK(1); }
OP( 0x40, i_dec_sp ) { unsigned tmp = (unsigned)I.regs.w[SP]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[SP]=tmp1; CLK(1); }
OP( 0x40, i_dec_bp ) { unsigned tmp = (unsigned)I.regs.w[BP]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[BP]=tmp1; CLK(1); }
OP( 0x40, i_dec_si ) { unsigned tmp = (unsigned)I.regs.w[IX]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[IX]=tmp1; CLK(1); }
OP( 0x40, i_dec_di ) { unsigned tmp = (unsigned)I.regs.w[IY]; unsigned tmp1 = tmp-1; I.OverVal = (tmp == 0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); I.regs.w[IY]=tmp1; CLK(1); }

OP( 0x50, i_push_ax ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[AW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[AW])>>8); }; }; CLK(1); }
OP( 0x51, i_push_cx ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[CW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[CW])>>8); }; }; CLK(1); }
OP( 0x52, i_push_dx ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[DW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[DW])>>8); }; }; CLK(1); }
OP( 0x53, i_push_bx ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BW])>>8); }; }; CLK(1); }
OP( 0x54, i_push_sp ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[SP]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[SP])>>8); }; }; CLK(1); }
OP( 0x55, i_push_bp ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BP]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BP])>>8); }; }; CLK(1); }
OP( 0x56, i_push_si ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[IX]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[IX])>>8); }; }; CLK(1); }
OP( 0x57, i_push_di ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[IY]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[IY])>>8); }; }; CLK(1); }

OP( 0x58, i_pop_ax ) { { I.regs.w[AW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x59, i_pop_cx ) { { I.regs.w[CW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5A, i_pop_dx ) { { I.regs.w[DW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5B, i_pop_bx ) { { I.regs.w[BW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5C, i_pop_sp ) { { I.regs.w[SP] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5D, i_pop_bp ) { { I.regs.w[BP] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5E, i_pop_si ) { { I.regs.w[IX] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }
OP( 0x5F, i_pop_di ) { { I.regs.w[IY] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(1); }

OP( 0x60, i_pusha ) {
	unsigned tmp=I.regs.w[SP];
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[AW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[AW])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[CW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[CW])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[DW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[DW])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BW]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BW])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),tmp); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(tmp)>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BP]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BP])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[IX]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[IX])>>8); }; };
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[IY]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[IY])>>8); }; };
	CLK(9);
}
OP( 0x61, i_popa ) {
	unsigned tmp;
	{ I.regs.w[IY] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[IX] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[BP] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ tmp = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[BW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[DW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[CW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	{ I.regs.w[AW] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	CLK(8);
}
OP( 0x62, i_chkind ) {
	unsigned long low,high,tmp;
	unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++);
	low = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) ));
	high= (cpuReadByte((EA&0xf0000)|((EA+2)&0xffff)) | (cpuReadByte(((EA&0xf0000)|((EA+2)&0xffff))+1)<<8));
	tmp= I.regs.w[Mod_RM.reg.w[ModRM]];
	if (tmp<low || tmp>high) {
		nec_interrupt(5,0);
		CLK(7);
	}
	CLK(13);
}

/* OP 0x64 - 0x67 is nop at V30MZ */
OP( 0x64, i_repnc  ) { }
OP( 0x65, i_repc  ) { }

OP( 0x68, i_push_d16 ) { unsigned long tmp; { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),tmp); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(tmp)>>8); }; }; CLK(1); }
OP( 0x69, i_imul_d16 ) { unsigned long tmp; unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; dst = (signed long)((signed short)src)*(signed long)((signed short)tmp); I.CarryVal = I.OverVal = (((signed long)dst) >> 15 != 0) && (((signed long)dst) >> 15 != -1); I.regs.w[Mod_RM.reg.w[ModRM]]=(unsigned short)dst; CLKM(4,3); }
OP( 0x6a, i_push_d8  ) { unsigned long tmp = (unsigned short)((signed short)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)))); { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),tmp); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(tmp)>>8); }; }; CLK(1); }
OP( 0x6b, i_imul_d8  ) { unsigned long src2; unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; dst = I.regs.w[Mod_RM.reg.w[ModRM]]; src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src2= (unsigned short)((signed short)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)))); dst = (signed long)((signed short)src)*(signed long)((signed short)src2); I.CarryVal = I.OverVal = (((signed long)dst) >> 15 != 0) && (((signed long)dst) >> 15 != -1); I.regs.w[Mod_RM.reg.w[ModRM]]=(unsigned short)dst; CLKM(4,3); }
OP( 0x6c, i_insb     ) { { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),(ioReadByte(I.regs.w[DW]))); }; I.regs.w[IY]+= -2 * I.DF + 1; CLK(6); }
OP( 0x6d, i_insw     ) { { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),(ioReadByte(I.regs.w[DW]))); }; { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+((I.regs.w[IY]+1)&0xffff)),(ioReadByte((I.regs.w[DW]+1)&0xffff))); }; I.regs.w[IY]+= -4 * I.DF + 2; CLK(6); }
OP( 0x6e, i_outsb    ) { ioWriteByte(I.regs.w[DW], (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX]))))); I.regs.w[IX]+= -2 * I.DF + 1; CLK(7); }
OP( 0x6f, i_outsw    ) { ioWriteByte(I.regs.w[DW], (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX]))))); ioWriteByte((I.regs.w[DW]+1)&0xffff, (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((I.regs.w[IX]+1)&0xffff))))); I.regs.w[IX]+= -4 * I.DF + 2; CLK(7); }

OP( 0x70, i_jo      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if ((I.OverVal!=0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x71, i_jno     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!(I.OverVal!=0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x72, i_jc      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if ((I.CarryVal!=0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x73, i_jnc     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!(I.CarryVal!=0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x74, i_jz      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if ((I.ZeroVal==0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x75, i_jnz     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!(I.ZeroVal==0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x76, i_jce     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if ((I.CarryVal!=0) || (I.ZeroVal==0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x77, i_jnce    ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!((I.CarryVal!=0) || (I.ZeroVal==0))) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x78, i_js      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if ((I.SignVal<0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x79, i_jns     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!(I.SignVal<0)) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7a, i_jp      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (parity_table[(unsigned char)I.ParityVal]) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7b, i_jnp     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (!parity_table[(unsigned char)I.ParityVal]) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7c, i_jl      ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (((I.SignVal<0)!=(I.OverVal!=0))&&(!(I.ZeroVal==0))) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7d, i_jnl     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (((I.ZeroVal==0))||((I.SignVal<0)==(I.OverVal!=0))) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7e, i_jle     ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (((I.ZeroVal==0))||((I.SignVal<0)!=(I.OverVal!=0))) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }
OP( 0x7f, i_jnle    ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); if (((I.SignVal<0)==(I.OverVal!=0))&&(!(I.ZeroVal==0))) { I.ip = (unsigned short)(I.ip+tmp); CLK(3); return; }; CLK(1); }

OP( 0x80, i_80pre   ) { unsigned long dst, src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++));
	CLKM(3,1)
	switch (ModRM & 0x38) {
		case 0x00: { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x08: dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x10: src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x18: src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x20: dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x28: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x30: dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x38: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; break;
	}
}

OP( 0x81, i_81pre   ) { unsigned long dst, src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); src+= ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8);
	CLKM(3,1)
	switch (ModRM & 0x38) {
		case 0x00: { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x08: dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x10: src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x18: src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x20: dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x28: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x30: dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x38: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; break;
	}
}

OP( 0x82, i_82pre   ) { unsigned long dst, src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); src = (unsigned char)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)));
	CLKM(3,1)
	switch (ModRM & 0x38) {
		case 0x00: { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x08: dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x10: src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x18: src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x20: dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x28: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x30: dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=dst; else {cpuWriteByte((EA),dst); }; }; break;
		case 0x38: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; break;
	}
}

OP( 0x83, i_83pre   ) { unsigned long dst, src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); src = (unsigned short)((signed short)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))));
	CLKM(3,1)
	switch (ModRM & 0x38) {
		case 0x00: { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x08: dst|=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x10: src+=(I.CarryVal!=0); { unsigned long res=dst+src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((res) ^ (src)) & ((res) ^ (dst)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x18: src+=(I.CarryVal!=0); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x20: dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x28: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x30: dst^=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=dst; else {cpuWriteByte((EA),dst); cpuWriteByte(((EA)+1),(dst)>>8); }; }; break;
		case 0x38: { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; break;
	}
}

OP( 0x84, i_test_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); CLKM(2,1); }
OP( 0x85, i_test_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); CLKM(2,1); }
OP( 0x86, i_xchg_br8  ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.b[Mod_RM.reg.b[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); I.regs.b[Mod_RM.reg.b[ModRM]]=dst; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=src; else {cpuWriteByte((EA),src); }; }; CLKM(5,3); }
OP( 0x87, i_xchg_wr16 ) { unsigned long ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)),src,dst; src = I.regs.w[Mod_RM.reg.w[ModRM]]; dst = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); I.regs.w[Mod_RM.reg.w[ModRM]]=dst; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=src; else {cpuWriteByte((EA),src); cpuWriteByte(((EA)+1),(src)>>8); }; }; CLKM(5,3); }

OP( 0x88, i_mov_br8   ) { unsigned char src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = I.regs.b[Mod_RM.reg.b[ModRM]]; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=src; else {cpuWriteByte(((*GetEA[ModRM])()),src); }; }; CLKM(1,1); }
OP( 0x89, i_mov_wr16  ) { unsigned short src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = I.regs.w[Mod_RM.reg.w[ModRM]]; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=src; else { (*GetEA[ModRM])(); {cpuWriteByte((EA),src); cpuWriteByte(((EA)+1),(src)>>8); }; } }; CLKM(1,1); }
OP( 0x8a, i_mov_r8b   ) { unsigned char src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); I.regs.b[Mod_RM.reg.b[ModRM]]=src; CLKM(1,1); }
OP( 0x8b, i_mov_r16w  ) { unsigned short src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); I.regs.w[Mod_RM.reg.w[ModRM]]=src; CLKM(1,1); }
OP( 0x8c, i_mov_wsreg ) { unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=I.sregs[(ModRM & 0x38) >> 3]; else { (*GetEA[ModRM])(); {cpuWriteByte((EA),I.sregs[(ModRM & 0x38) >> 3]); cpuWriteByte(((EA)+1),(I.sregs[(ModRM & 0x38) >> 3])>>8); }; } }; CLKM(1,1); }
OP( 0x8d, i_lea       ) { unsigned short ModRM = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); (void)(*GetEA[ModRM])(); I.regs.w[Mod_RM.reg.w[ModRM]]=EO; CLK(1); }
OP( 0x8e, i_mov_sregw ) { unsigned short src; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); CLKM(3,2);
	switch (ModRM & 0x38) {
		case 0x00: I.sregs[ES] = src; break;
		case 0x08: I.sregs[CS] = src; break;
		case 0x10: I.sregs[SS] = src; break;
		case 0x18: I.sregs[DS] = src; break;
		default: ;
	}
	no_interrupt=1;
}
OP( 0x8f, i_popw ) { unsigned short tmp; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); { tmp = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=tmp; else { (*GetEA[ModRM])(); {cpuWriteByte((EA),tmp); cpuWriteByte(((EA)+1),(tmp)>>8); }; } }; CLKM(3,1); }
OP( 0x90, i_nop  ) { CLK(1);
	/* Cycle skip for idle loops (0: NOP  1:  JMP 0) */
	if (no_interrupt==0 && nec_ICount>0 && ((cpuReadByte((I.sregs[CS]<<4)+I.ip)))==0xeb && ((cpuReadByte((I.sregs[CS]<<4)+I.ip+1)))==0xfd)
		nec_ICount%=15;
}
OP( 0x91, i_xchg_axcx ) { I.regs.w[CW] ^= (I.regs.w[AW] ^= (I.regs.w[CW] ^= I.regs.w[AW])); CLK(3); }
OP( 0x92, i_xchg_axdx ) { I.regs.w[DW] ^= (I.regs.w[AW] ^= (I.regs.w[DW] ^= I.regs.w[AW])); CLK(3); }
OP( 0x93, i_xchg_axbx ) { I.regs.w[BW] ^= (I.regs.w[AW] ^= (I.regs.w[BW] ^= I.regs.w[AW])); CLK(3); }
OP( 0x94, i_xchg_axsp ) { I.regs.w[SP] ^= (I.regs.w[AW] ^= (I.regs.w[SP] ^= I.regs.w[AW])); CLK(3); }
OP( 0x95, i_xchg_axbp ) { I.regs.w[BP] ^= (I.regs.w[AW] ^= (I.regs.w[BP] ^= I.regs.w[AW])); CLK(3); }
OP( 0x96, i_xchg_axsi ) { I.regs.w[IX] ^= (I.regs.w[AW] ^= (I.regs.w[IX] ^= I.regs.w[AW])); CLK(3); }
OP( 0x97, i_xchg_axdi ) { I.regs.w[IY] ^= (I.regs.w[AW] ^= (I.regs.w[IY] ^= I.regs.w[AW])); CLK(3); }

OP( 0x98, i_cbw       ) { I.regs.b[AH] = (I.regs.b[AL] & 0x80) ? 0xff : 0; CLK(1); }
OP( 0x99, i_cwd       ) { I.regs.w[DW] = (I.regs.b[AH] & 0x80) ? 0xffff : 0; CLK(1); }
OP( 0x9a, i_call_far  ) { unsigned long tmp, tmp2; { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { tmp2=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.sregs[CS]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.sregs[CS])>>8); }; }; { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.ip); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.ip)>>8); }; }; I.ip = (unsigned short)tmp; I.sregs[CS] = (unsigned short)tmp2; CLK(10); }
OP( 0x9b, i_wait      ) {}
OP( 0x9c, i_pushf     ) { { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),(unsigned short)((I.CarryVal!=0) | (parity_table[(unsigned char)I.ParityVal] << 2) | ((I.AuxVal!=0) << 4) | ((I.ZeroVal==0) << 6) | ((I.SignVal<0) << 7) | (I.TF << 8) | (I.IF << 9) | (I.DF << 10) | ((I.OverVal!=0) << 11))); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),((unsigned short)((I.CarryVal!=0) | (parity_table[(unsigned char)I.ParityVal] << 2) | ((I.AuxVal!=0) << 4) | ((I.ZeroVal==0) << 6) | ((I.SignVal<0) << 7) | (I.TF << 8) | (I.IF << 9) | (I.DF << 10) | ((I.OverVal!=0) << 11)))>>8); }; }; CLK(2); }
OP( 0x9d, i_popf      ) { unsigned long tmp; { tmp = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; { I.CarryVal = (tmp) & 1; I.ParityVal = !((tmp) & 4); I.AuxVal = (tmp) & 16; I.ZeroVal = !((tmp) & 64); I.SignVal = (tmp) & 128 ? -1 : 0; I.TF = ((tmp) & 256) == 256; I.IF = ((tmp) & 512) == 512; I.DF = ((tmp) & 1024) == 1024; I.OverVal = (tmp) & 2048; I.MF = ((tmp) & 0x8000) == 0x8000; }; CLK(3); }
OP( 0x9e, i_sahf      ) { unsigned long tmp = ((unsigned short)((I.CarryVal!=0) | (parity_table[(unsigned char)I.ParityVal] << 2) | ((I.AuxVal!=0) << 4) | ((I.ZeroVal==0) << 6) | ((I.SignVal<0) << 7) | (I.TF << 8) | (I.IF << 9) | (I.DF << 10) | ((I.OverVal!=0) << 11)) & 0xff00) | (I.regs.b[AH] & 0xd5); { I.CarryVal = (tmp) & 1; I.ParityVal = !((tmp) & 4); I.AuxVal = (tmp) & 16; I.ZeroVal = !((tmp) & 64); I.SignVal = (tmp) & 128 ? -1 : 0; I.TF = ((tmp) & 256) == 256; I.IF = ((tmp) & 512) == 512; I.DF = ((tmp) & 1024) == 1024; I.OverVal = (tmp) & 2048; I.MF = ((tmp) & 0x8000) == 0x8000; }; CLK(4); }
OP( 0x9f, i_lahf      ) { I.regs.b[AH] = (unsigned short)((I.CarryVal!=0) | (parity_table[(unsigned char)I.ParityVal] << 2) | ((I.AuxVal!=0) << 4) | ((I.ZeroVal==0) << 6) | ((I.SignVal<0) << 7) | (I.TF << 8) | (I.IF << 9) | (I.DF << 10) | ((I.OverVal!=0) << 11)) & 0xff; CLK(2); }

OP( 0xa0, i_mov_aldisp ) { unsigned long addr; { addr=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; I.regs.b[AL] = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(addr)))); CLK(1); }
OP( 0xa1, i_mov_axdisp ) { unsigned long addr; { addr=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; I.regs.b[AL] = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(addr)))); I.regs.b[AH] = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((addr+1)&0xffff)))); CLK(1); }
OP( 0xa2, i_mov_dispal ) { unsigned long addr; { addr=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { cpuWriteByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(addr)),(I.regs.b[AL])); }; CLK(1); }
OP( 0xa3, i_mov_dispax ) { unsigned long addr; { addr=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { cpuWriteByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(addr)),(I.regs.b[AL])); }; { cpuWriteByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((addr+1)&0xffff)),(I.regs.b[AH])); }; CLK(1); }
OP( 0xa4, i_movsb      ) { unsigned long tmp = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX])))); { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),(tmp)); }; I.regs.w[IY] += -2 * I.DF + 1; I.regs.w[IX] += -2 * I.DF + 1; CLK(5); }
OP( 0xa5, i_movsw      ) { unsigned long tmp = ((unsigned short)cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX]))) + (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((I.regs.w[IX])+1)))<<8) ); { { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),((tmp)&0xFF)); }; { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+((I.regs.w[IY])+1)),((tmp)>>8)); }; }; I.regs.w[IY] += -4 * I.DF + 2; I.regs.w[IX] += -4 * I.DF + 2; CLK(5); }
OP( 0xa6, i_cmpsb      ) { unsigned long src = (cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])))); unsigned long dst = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX])))); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.w[IY] += -2 * I.DF + 1; I.regs.w[IX] += -2 * I.DF + 1; CLK(6); }
OP( 0xa7, i_cmpsw      ) { unsigned long src = ((unsigned short)cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY]))) + (cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+((I.regs.w[IY])+1)))<<8) ); unsigned long dst = ((unsigned short)cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX]))) + (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((I.regs.w[IX])+1)))<<8) ); { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[IY] += -4 * I.DF + 2; I.regs.w[IX] += -4 * I.DF + 2; CLK(6); }

OP( 0xa8, i_test_ald8  ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.b[AL]; dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); CLK(1); }
OP( 0xa9, i_test_axd16 ) { unsigned long src = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned long dst = I.regs.w[AW]; src += ((cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8); dst&=src; I.CarryVal=I.OverVal=I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); CLK(1); }
OP( 0xaa, i_stosb      ) { { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),(I.regs.b[AL])); }; I.regs.w[IY] += -2 * I.DF + 1; CLK(3); }
OP( 0xab, i_stosw      ) { { { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])),((I.regs.w[AW])&0xFF)); }; { cpuWriteByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+((I.regs.w[IY])+1)),((I.regs.w[AW])>>8)); }; }; I.regs.w[IY] += -4 * I.DF + 2; CLK(3); }
OP( 0xac, i_lodsb      ) { I.regs.b[AL] = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX])))); I.regs.w[IX] += -2 * I.DF + 1; CLK(3); }
OP( 0xad, i_lodsw      ) { I.regs.w[AW] = ((unsigned short)cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(I.regs.w[IX]))) + (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+((I.regs.w[IX])+1)))<<8) ); I.regs.w[IX] += -4 * I.DF + 2; CLK(3); }
OP( 0xae, i_scasb      ) { unsigned long src = (cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY])))); unsigned long dst = I.regs.b[AL]; { unsigned long res=dst-src; (I.CarryVal = (res) & 0x100); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x80); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(res)); dst=(unsigned char)res; }; I.regs.w[IY] += -2 * I.DF + 1; CLK(4); }
OP( 0xaf, i_scasw      ) { unsigned long src = ((unsigned short)cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+(I.regs.w[IY]))) + (cpuReadByte((((seg_prefix && (ES==DS || ES==SS)) ? prefix_base : I.sregs[ES] << 4)+((I.regs.w[IY])+1)))<<8) ); unsigned long dst = I.regs.w[AW]; { unsigned long res=dst-src; (I.CarryVal = (res) & 0x10000); (I.OverVal = ((dst) ^ (src)) & ((dst) ^ (res)) & 0x8000); (I.AuxVal = ((res) ^ ((src) ^ (dst))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(res)); dst=(unsigned short)res; }; I.regs.w[IY] += -4 * I.DF + 2; CLK(4); }

OP( 0xb0, i_mov_ald8  ) { I.regs.b[AL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb1, i_mov_cld8  ) { I.regs.b[CL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb2, i_mov_dld8  ) { I.regs.b[DL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb3, i_mov_bld8  ) { I.regs.b[BL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb4, i_mov_ahd8  ) { I.regs.b[AH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb5, i_mov_chd8  ) { I.regs.b[CH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb6, i_mov_dhd8  ) { I.regs.b[DH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb7, i_mov_bhd8  ) { I.regs.b[BH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }

OP( 0xb8, i_mov_axd16 ) { I.regs.b[AL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[AH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xb9, i_mov_cxd16 ) { I.regs.b[CL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[CH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xba, i_mov_dxd16 ) { I.regs.b[DL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[DH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xbb, i_mov_bxd16 ) { I.regs.b[BL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[BH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xbc, i_mov_spd16 ) { I.regs.b[SPL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[SPH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xbd, i_mov_bpd16 ) { I.regs.b[BPL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[BPH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xbe, i_mov_sid16 ) { I.regs.b[IXL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[IXH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }
OP( 0xbf, i_mov_did16 ) { I.regs.b[IYL] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[IYH] = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(1); }

OP( 0xc0, i_rotshft_bd8 ) {
	unsigned long src, dst; unsigned char c;
	unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned)((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst=src;
	c=(cpuReadByte((I.sregs[CS]<<4)+I.ip++));
	c&=0x1f;
	CLKM(5,3);
	if (c) switch (ModRM & 0x38) {
		case 0x00: do { I.CarryVal = dst & 0x80; dst = (dst << 1)+(I.CarryVal!=0); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x08: do { I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<7); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x10: do { dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x100); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x18: do { dst = ((I.CarryVal!=0)<<8)+dst; I.CarryVal = dst & 0x01; dst >>= 1; c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x20: dst <<= c; (I.CarryVal = (dst) & 0x100); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.AuxVal = 1; break;
		case 0x28: dst >>= c-1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.AuxVal = 1; break;
		case 0x30: break;
		case 0x38: dst = ((signed char)dst) >> (c-1); I.CarryVal = dst & 0x1; dst = ((signed char)((unsigned char)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
	}
}

OP( 0xc1, i_rotshft_wd8 ) {
	unsigned long src, dst; unsigned char c;
	unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned)((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst=src;
	c=(cpuReadByte((I.sregs[CS]<<4)+I.ip++));
	c&=0x1f;
	CLKM(5,3);
	if (c) switch (ModRM & 0x38) {
		case 0x00: do { I.CarryVal = dst & 0x8000; dst = (dst << 1)+(I.CarryVal!=0); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x08: do { I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<15); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x10: do { dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x10000); c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x18: do { dst = ((I.CarryVal!=0)<<16)+dst; I.CarryVal = dst & 0x01; dst >>= 1; c--; } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x20: dst <<= c; (I.CarryVal = (dst) & 0x10000); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1; break;
		case 0x28: dst >>= c-1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1; break;
		case 0x30: break;
		case 0x38: dst = ((signed short)dst) >> (c-1); I.CarryVal = dst & 0x1; dst = ((signed short)((unsigned short)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
	}
}

OP( 0xc2, i_ret_d16  ) { unsigned long count = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); count += (cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8; { I.ip = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; I.regs.w[SP]+=count; CLK(6); }
OP( 0xc3, i_ret      ) { { I.ip = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(6); }
OP( 0xc4, i_les_dw   ) { unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); unsigned short tmp = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); I.regs.w[Mod_RM.reg.w[ModRM]]=tmp; I.sregs[ES] = (cpuReadByte((EA&0xf0000)|((EA+2)&0xffff)) | (cpuReadByte(((EA&0xf0000)|((EA+2)&0xffff))+1)<<8)); CLK(6); }
OP( 0xc5, i_lds_dw   ) { unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); unsigned short tmp = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); I.regs.w[Mod_RM.reg.w[ModRM]]=tmp; I.sregs[DS] = (cpuReadByte((EA&0xf0000)|((EA+2)&0xffff)) | (cpuReadByte(((EA&0xf0000)|((EA+2)&0xffff))+1)<<8)); CLK(6); }
OP( 0xc6, i_mov_bd8  ) { unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); else { (*GetEA[ModRM])(); {cpuWriteByte((EA),(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); }; } }; CLK(1); }
OP( 0xc7, i_mov_wd16 ) { unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); { unsigned short val; if (ModRM >= 0xc0) { I.regs.w[Mod_RM.RM.w[ModRM]]=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; } else { (*GetEA[ModRM])(); { val=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; } {cpuWriteByte((EA),val); cpuWriteByte(((EA)+1),(val)>>8); }; } }; CLK(1); }

OP( 0xc8, i_enter ) {
	unsigned long nb = (cpuReadByte((I.sregs[CS]<<4)+I.ip++));
	unsigned long i,level;

	CLK(19);
	nb += (cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8;
	level = (cpuReadByte((I.sregs[CS]<<4)+I.ip++));
	{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BP]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BP])>>8); }; };
	I.regs.w[BP]=I.regs.w[SP];
	I.regs.w[SP] -= nb;
	for (i=1;i<level;i++) {
		{ I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),((unsigned short)cpuReadByte((((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+(I.regs.w[BP]-i*2))) + (cpuReadByte((((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+((I.regs.w[BP]-i*2)+1)))<<8) )); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(((unsigned short)cpuReadByte((((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+(I.regs.w[BP]-i*2))) + (cpuReadByte((((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+((I.regs.w[BP]-i*2)+1)))<<8) ))>>8); }; };
		CLK(4);
	}
	if (level) { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.regs.w[BP]); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.regs.w[BP])>>8); }; };
}
OP( 0xc9, i_leave ) {
	I.regs.w[SP]=I.regs.w[BP];
	{ I.regs.w[BP] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; };
	CLK(2);
}
OP( 0xca, i_retf_d16 ) { unsigned long count = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); count += (cpuReadByte((I.sregs[CS]<<4)+I.ip++)) << 8; { I.ip = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; { I.sregs[CS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; I.regs.w[SP]+=count; CLK(9); }
OP( 0xcb, i_retf     ) { { I.ip = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; { I.sregs[CS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; CLK(8); }
OP( 0xcc, i_int3     ) { nec_interrupt(3,0); CLK(9); }
OP( 0xcd, i_int      ) { nec_interrupt((cpuReadByte((I.sregs[CS]<<4)+I.ip++)),0); CLK(10); }
OP( 0xce, i_into     ) { if ((I.OverVal!=0)) { nec_interrupt(4,0); CLK(13); } else CLK(6); }
OP( 0xcf, i_iret     ) { { I.ip = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; { I.sregs[CS] = (cpuReadByte((((I.sregs[SS]<<4)+I.regs.w[SP]))) | (cpuReadByte(((((I.sregs[SS]<<4)+I.regs.w[SP])))+1)<<8)); I.regs.w[SP]+=2; }; i_popf(); CLK(10); }

OP( 0xd0, i_rotshft_b ) {
	unsigned long src, dst; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned long)((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst=src;
	CLKM(3,1);
	switch (ModRM & 0x38) {
		case 0x00: I.CarryVal = dst & 0x80; dst = (dst << 1)+(I.CarryVal!=0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80; break;
		case 0x08: I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<7); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80; break;
		case 0x10: dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x100); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80; break;
		case 0x18: dst = ((I.CarryVal!=0)<<8)+dst; I.CarryVal = dst & 0x01; dst >>= 1; { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80; break;
		case 0x20: dst <<= 1; (I.CarryVal = (dst) & 0x100); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80;I.AuxVal = 1; break;
		case 0x28: dst >>= 1 -1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = (src^dst)&0x80;I.AuxVal = 1; break;
		case 0x30: break;
		case 0x38: dst = ((signed char)dst) >> (1 -1); I.CarryVal = dst & 0x1; dst = ((signed char)((unsigned char)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.OverVal = 0; break;
	}
}

OP( 0xd1, i_rotshft_w ) {
	unsigned long src, dst; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned long)((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst=src;
	CLKM(3,1);
	switch (ModRM & 0x38) {
		case 0x00: I.CarryVal = dst & 0x8000; dst = (dst << 1)+(I.CarryVal!=0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.OverVal = (src^dst)&0x8000; break;
		case 0x08: I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<15); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.OverVal = (src^dst)&0x8000; break;
		case 0x10: dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x10000); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.OverVal = (src^dst)&0x8000; break;
		case 0x18: dst = ((I.CarryVal!=0)<<16)+dst; I.CarryVal = dst & 0x01; dst >>= 1; { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.OverVal = (src^dst)&0x8000; break;
		case 0x20: dst <<= 1; (I.CarryVal = (dst) & 0x10000); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1;I.OverVal = (src^dst)&0x8000; break;
		case 0x28: dst >>= 1 -1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1;I.OverVal = (src^dst)&0x8000; break;
		case 0x30: break;
		case 0x38: dst = ((signed short)dst) >> (1 -1); I.CarryVal = dst & 0x1; dst = ((signed short)((unsigned short)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1;I.OverVal = 0; break;
	}
}

OP( 0xd2, i_rotshft_bcl ) {
	unsigned long src, dst; unsigned char c; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned long)((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])()))); dst=src;
	c=I.regs.b[CL];
	CLKM(5,3);
	c&=0x1f;
	if (c) switch (ModRM & 0x38) {
		case 0x00: do { I.CarryVal = dst & 0x80; dst = (dst << 1)+(I.CarryVal!=0); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x08: do { I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<7); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x10: do { dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x100); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x18: do { dst = ((I.CarryVal!=0)<<8)+dst; I.CarryVal = dst & 0x01; dst >>= 1; c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
		case 0x20: dst <<= c; (I.CarryVal = (dst) & 0x100); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.AuxVal = 1; break;
		case 0x28: dst >>= c-1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; I.AuxVal = 1;break;
		case 0x30: break;
		case 0x38: dst = ((signed char)dst) >> (c-1); I.CarryVal = dst & 0x1; dst = ((signed char)((unsigned char)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(dst)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)dst; else {cpuWriteByte((EA),(unsigned char)dst); }; }; break;
	}
}

OP( 0xd3, i_rotshft_wcl ) {
	unsigned long src, dst; unsigned char c; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); src = (unsigned long)((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) )); dst=src;
	c=I.regs.b[CL];
	c&=0x1f;
	CLKM(5,3);
	if (c) switch (ModRM & 0x38) {
		case 0x00: do { I.CarryVal = dst & 0x8000; dst = (dst << 1)+(I.CarryVal!=0); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x08: do { I.CarryVal = dst & 0x1; dst = (dst >> 1)+((I.CarryVal!=0)<<15); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x10: do { dst = (dst << 1) + (I.CarryVal!=0); (I.CarryVal = (dst) & 0x10000); c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x18: do { dst = ((I.CarryVal!=0)<<16)+dst; I.CarryVal = dst & 0x01; dst >>= 1; c--; CLK(1); } while (c>0); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
		case 0x20: dst <<= c; (I.CarryVal = (dst) & 0x10000); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1; break;
		case 0x28: dst >>= c-1; I.CarryVal = dst & 0x1; dst >>= 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; I.AuxVal = 1; break;
		case 0x30: break;
		case 0x38: dst = ((signed short)dst) >> (c-1); I.CarryVal = dst & 0x1; dst = ((signed short)((unsigned short)dst)) >> 1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(dst)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)dst; else {cpuWriteByte((EA),(unsigned short)dst); cpuWriteByte(((EA)+1),((unsigned short)dst)>>8); }; }; break;
	}
}

OP( 0xd4, i_aam    ) { unsigned long mult=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); mult=0; I.regs.b[AH] = I.regs.b[AL] / 10; I.regs.b[AL] %= 10; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(I.regs.w[AW])); CLK(17); }
OP( 0xd5, i_aad    ) { unsigned long mult=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); mult=0; I.regs.b[AL] = I.regs.b[AH] * 10 + I.regs.b[AL]; I.regs.b[AH] = 0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(I.regs.b[AL])); CLK(6); }
OP( 0xd6, i_setalc ) { I.regs.b[AL] = ((I.CarryVal!=0))?0xff:0x00; CLK(3); } /* nop at V30MZ? */

OP( 0xd7, i_trans  ) { unsigned long dest = (I.regs.w[BW]+I.regs.b[AL])&0xffff; I.regs.b[AL] = (cpuReadByte((((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+(dest)))); CLK(5); }
OP( 0xd8, i_fpo    ) { } /* nop at V30MZ? */

OP( 0xe0, i_loopne ) { signed char disp = (signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.w[CW]--; if (!(I.ZeroVal==0) && I.regs.w[CW]) { I.ip = (unsigned short)(I.ip+disp); CLK(6); } else CLK(3); }
OP( 0xe1, i_loope  ) { signed char disp = (signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.w[CW]--; if ( (I.ZeroVal==0) && I.regs.w[CW]) { I.ip = (unsigned short)(I.ip+disp); CLK(6); } else CLK(3); }
OP( 0xe2, i_loop   ) { signed char disp = (signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.w[CW]--; if (I.regs.w[CW]) { I.ip = (unsigned short)(I.ip+disp); CLK(5); } else CLK(2); }
OP( 0xe3, i_jcxz   ) { signed char disp = (signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); if (I.regs.w[CW] == 0) { I.ip = (unsigned short)(I.ip+disp); CLK(4); } else CLK(1); }
OP( 0xe4, i_inal   ) { unsigned char port = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[AL] = ioReadByte(port); CLK(6); }
OP( 0xe5, i_inax   ) { unsigned char port = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.regs.b[AL] = ioReadByte(port); I.regs.b[AH] = ioReadByte(port+1); CLK(6); }
OP( 0xe6, i_outal  ) { unsigned char port = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); ioWriteByte(port, I.regs.b[AL]); CLK(6); }
OP( 0xe7, i_outax  ) { unsigned char port = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); ioWriteByte(port, I.regs.b[AL]); ioWriteByte(port+1, I.regs.b[AH]); CLK(6); }

OP( 0xe8, i_call_d16 ) { unsigned long tmp; { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.ip); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.ip)>>8); }; }; I.ip = (unsigned short)(I.ip+(signed short)tmp); CLK(5); }
OP( 0xe9, i_jmp_d16  ) { unsigned long tmp; { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; I.ip = (unsigned short)(I.ip+(signed short)tmp); CLK(4); }
OP( 0xea, i_jmp_far  ) { unsigned long tmp,tmp1; { tmp=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; { tmp1=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; I.sregs[CS] = (unsigned short)tmp1; I.ip = (unsigned short)tmp; CLK(7); }
OP( 0xeb, i_jmp_d8   ) { int tmp = (int)((signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); CLK(4);
	if (tmp==-2 && no_interrupt==0 && nec_ICount>0) nec_ICount%=12; /* cycle skip */
	I.ip = (unsigned short)(I.ip+tmp);
}
OP( 0xec, i_inaldx   ) { I.regs.b[AL] = ioReadByte(I.regs.w[DW]); CLK(6);}
OP( 0xed, i_inaxdx   ) { unsigned long port = I.regs.w[DW]; I.regs.b[AL] = ioReadByte(port); I.regs.b[AH] = ioReadByte(port+1); CLK(6); }
OP( 0xee, i_outdxal  ) { ioWriteByte(I.regs.w[DW], I.regs.b[AL]); CLK(6); }
OP( 0xef, i_outdxax  ) { unsigned long port = I.regs.w[DW]; ioWriteByte(port, I.regs.b[AL]); ioWriteByte(port+1, I.regs.b[AH]); CLK(6); }

OP( 0xf0, i_lock     ) { no_interrupt=1; CLK(1); }

OP( 0xf2, i_repne   ) { UINT32 next = FETCHOP; UINT16 c = I.regs.w[CW];
	switch(next) { /* Segments */
		case 0x26: seg_prefix=1; prefix_base=I.sregs[ES]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x2e: seg_prefix=1; prefix_base=I.sregs[CS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x36: seg_prefix=1; prefix_base=I.sregs[SS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x3e: seg_prefix=1; prefix_base=I.sregs[DS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
	}

	switch(next) {
		case 0x6c: CLK(2); if (c) do { i_insb(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0x6d: CLK(2); if (c) do { i_insw(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0x6e: CLK(2); if (c) do { i_outsb(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0x6f: CLK(2); if (c) do { i_outsw(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xa4: CLK(2); if (c) do { i_movsb(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xa5: CLK(2); if (c) do { i_movsw(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xa6: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_cmpsb(); c--; CLK(3); } while (c>0 && (I.ZeroVal==0)==0); I.regs.w[CW]=c; break;
		case 0xa7: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_cmpsw(); c--; CLK(3); } while (c>0 && (I.ZeroVal==0)==0); I.regs.w[CW]=c; break;
		case 0xaa: CLK(2); if (c) do { i_stosb(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xab: CLK(2); if (c) do { i_stosw(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xac: CLK(2); if (c) do { i_lodsb(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xad: CLK(2); if (c) do { i_lodsw(); c--; } while (c>0); I.regs.w[CW]=c; break;
		case 0xae: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_scasb(); c--; CLK(5); } while (c>0 && (I.ZeroVal==0)==0); I.regs.w[CW]=c; break;
		case 0xaf: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_scasw(); c--; CLK(5); } while (c>0 && (I.ZeroVal==0)==0); I.regs.w[CW]=c; break;
		default: nec_instruction[next]();
	}
	seg_prefix=0;
}
OP( 0xf3, i_repe	 ) { unsigned long next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); unsigned short c = I.regs.w[CW];
	switch(next) { /* Segments */
		case 0x26: seg_prefix=1; prefix_base=I.sregs[ES]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x2e: seg_prefix=1; prefix_base=I.sregs[CS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x36: seg_prefix=1; prefix_base=I.sregs[SS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
		case 0x3e: seg_prefix=1; prefix_base=I.sregs[DS]<<4; next = (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); CLK(2); break;
	}

	switch(next) {
		case 0x6c: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_insb(); c--; CLK(0); } while (c>0); I.regs.w[CW]=c; break;
		case 0x6d: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_insw(); c--; CLK(0); } while (c>0); I.regs.w[CW]=c; break;
		case 0x6e: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_outsb(); c--; CLK(-1); } while (c>0); I.regs.w[CW]=c; break;
		case 0x6f: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_outsw(); c--; CLK(-1); } while (c>0); I.regs.w[CW]=c; break;
		case 0xa4: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_movsb(); c--; CLK(2); } while (c>0); I.regs.w[CW]=c; break;
		case 0xa5: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_movsw(); c--; CLK(2); } while (c>0); I.regs.w[CW]=c; break;
		case 0xa6: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_cmpsb(); c--; CLK(4); } while (c>0 && (I.ZeroVal==0)==1); I.regs.w[CW]=c; break;
		case 0xa7: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_cmpsw(); c--; CLK(4); } while (c>0 && (I.ZeroVal==0)==1); I.regs.w[CW]=c; break;
		case 0xaa: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_stosb(); c--; CLK(3); } while (c>0); I.regs.w[CW]=c; break;
		case 0xab: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_stosw(); c--; CLK(3); } while (c>0); I.regs.w[CW]=c; break;
		case 0xac: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_lodsb(); c--; CLK(3); } while (c>0); I.regs.w[CW]=c; break;
		case 0xad: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_lodsw(); c--; CLK(3); } while (c>0); I.regs.w[CW]=c; break;
		case 0xae: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_scasb(); c--; CLK(4); } while (c>0 && (I.ZeroVal==0)==1); I.regs.w[CW]=c; break;
		case 0xaf: CLK(5); if (c) do { if(nec_ICount<0){ if(seg_prefix) I.ip-=(unsigned short)3; else I.ip-=(unsigned short)2; break;}; i_scasw(); c--; CLK(4); } while (c>0 && (I.ZeroVal==0)==1); I.regs.w[CW]=c; break;
		default: nec_instruction[next]();
	}
	seg_prefix=0;
}
OP( 0xf4, i_hlt ) { nec_ICount=0; }




OP( 0xf5, i_cmc ) { I.CarryVal = !(I.CarryVal!=0); CLK(4); }
OP( 0xf6, i_f6pre ) { unsigned long tmp; unsigned long uresult,uresult2; signed long result,result2;
	unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); tmp = ((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])())));
	switch (ModRM & 0x38) {
		case 0x00: tmp &= (cpuReadByte((I.sregs[CS]<<4)+I.ip++)); I.CarryVal = I.OverVal = I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(tmp)); CLKM(2,1); break; /* TEST */
		case 0x08: break;
		case 0x10: { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=~tmp; else {cpuWriteByte((EA),~tmp); }; }; CLKM(3,1); break; /* NOT */
		
		case 0x18: I.CarryVal=(tmp!=0);tmp=(~tmp)+1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(tmp)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=tmp&0xff; else {cpuWriteByte((EA),tmp&0xff); }; }; CLKM(3,1); break; /* NEG */
		case 0x20: uresult = I.regs.b[AL]*tmp; I.regs.w[AW]=(unsigned short)uresult; I.CarryVal=I.OverVal=(I.regs.b[AH]!=0); CLKM(4,3); break; /* MULU */
		case 0x28: result = (signed short)((signed char)I.regs.b[AL])*(signed short)((signed char)tmp); I.regs.w[AW]=(unsigned short)result; I.CarryVal=I.OverVal=(I.regs.b[AH]!=0); CLKM(4,3); break; /* MUL */
		case 0x30: if (tmp) { uresult = I.regs.w[AW]; uresult2 = uresult % tmp; if ((uresult /= tmp) > 0xff) { nec_interrupt(0,0); break; } else { I.regs.b[AL] = uresult; I.regs.b[AH] = uresult2; }; } else nec_interrupt(0,0); CLKM(16,15); break;
		case 0x38: if (tmp) { result = (signed short)I.regs.w[AW]; result2 = result % (signed short)((signed char)tmp); if ((result /= (signed short)((signed char)tmp)) > 0xff) { nec_interrupt(0,0); break; } else { I.regs.b[AL] = result; I.regs.b[AH] = result2; }; } else nec_interrupt(0,0); CLKM(18,17); break;
	}
}

OP( 0xf7, i_f7pre	) { unsigned long tmp,tmp2; unsigned long uresult,uresult2; signed long result,result2;
	unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); tmp = ((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) ));
	switch (ModRM & 0x38) {
		case 0x00: { tmp2=cpuReadByte((((I.sregs[CS]<<4)+I.ip)))+(cpuReadByte((((I.sregs[CS]<<4)+I.ip+1)))<<8); I.ip+=2; }; tmp &= tmp2; I.CarryVal = I.OverVal = I.AuxVal=0; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp)); CLKM(2,1); break;
		case 0x08: break;
		case 0x10: { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=~tmp; else {cpuWriteByte((EA),~tmp); cpuWriteByte(((EA)+1),(~tmp)>>8); }; }; CLKM(3,1); break;
		case 0x18: I.CarryVal=(tmp!=0); tmp=(~tmp)+1; (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=tmp&0xffff; else {cpuWriteByte((EA),tmp&0xffff); cpuWriteByte(((EA)+1),(tmp&0xffff)>>8); }; }; CLKM(3,1); break;
		case 0x20: uresult = I.regs.w[AW]*tmp; I.regs.w[AW]=uresult&0xffff; I.regs.w[DW]=((unsigned long)uresult)>>16; I.CarryVal=I.OverVal=(I.regs.w[DW]!=0); CLKM(4,3); break;
		case 0x28: result = (signed long)((signed short)I.regs.w[AW])*(signed long)((signed short)tmp); I.regs.w[AW]=result&0xffff; I.regs.w[DW]=result>>16; I.CarryVal=I.OverVal=(I.regs.w[DW]!=0); CLKM(4,3); break;
		case 0x30: if (tmp) { uresult = (((unsigned long)I.regs.w[DW]) << 16) | I.regs.w[AW]; uresult2 = uresult % tmp; if ((uresult /= tmp) > 0xffff) { nec_interrupt(0,0); break; } else { I.regs.w[AW]=uresult; I.regs.w[DW]=uresult2; }; } else nec_interrupt(0,0); CLKM(24,23); break;
		case 0x38: if (tmp) { result = ((unsigned long)I.regs.w[DW] << 16) + I.regs.w[AW]; result2 = result % (signed long)((signed short)tmp); if ((result /= (signed long)((signed short)tmp)) > 0xffff) { nec_interrupt(0,0); break; } else { I.regs.w[AW]=result; I.regs.w[DW]=result2; }; } else nec_interrupt(0,0); CLKM(25,24); break;
	}
}

OP( 0xf8, i_clc   ) { I.CarryVal = 0; CLK(4); }
OP( 0xf9, i_stc   ) { I.CarryVal = 1; CLK(4); }
OP( 0xfa, i_di    ) { (I.IF = (0)); CLK(4); }
OP( 0xfb, i_ei    ) { (I.IF = (1)); CLK(4); }
OP( 0xfc, i_cld   ) { (I.DF = (0)); CLK(4); }
OP( 0xfd, i_std   ) { (I.DF = (1)); CLK(4); }
OP( 0xfe, i_fepre ) { unsigned long tmp, tmp1; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); tmp=((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : (cpuReadByte((*GetEA[ModRM])())));
	switch(ModRM & 0x38) {
		case 0x00: tmp1 = tmp+1; I.OverVal = (tmp==0x7f); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(tmp1)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)tmp1; else {cpuWriteByte((EA),(unsigned char)tmp1); }; }; CLKM(3,1); break;
		case 0x08: tmp1 = tmp-1; I.OverVal = (tmp==0x80); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed char)(tmp1)); { if (ModRM >= 0xc0) I.regs.b[Mod_RM.RM.b[ModRM]]=(unsigned char)tmp1; else {cpuWriteByte((EA),(unsigned char)tmp1); }; }; CLKM(3,1); break;
		default: i_invalid();
	}
}
OP( 0xff, i_ffpre ) { unsigned long tmp, tmp1; unsigned long ModRM=cpuReadByte((I.sregs[CS]<<4)+I.ip++); tmp=((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), (cpuReadByte(EA) | (cpuReadByte((EA)+1)<<8)) ));
	switch(ModRM & 0x38) {
		case 0x00: tmp1 = tmp+1; I.OverVal = (tmp==0x7fff); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)tmp1; else {cpuWriteByte((EA),(unsigned short)tmp1); cpuWriteByte(((EA)+1),((unsigned short)tmp1)>>8); }; }; CLKM(3,1); break;
		case 0x08: tmp1 = tmp-1; I.OverVal = (tmp==0x8000); (I.AuxVal = ((tmp1) ^ ((tmp) ^ (1))) & 0x10); (I.SignVal=I.ZeroVal=I.ParityVal=(signed short)(tmp1)); { if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=(unsigned short)tmp1; else {cpuWriteByte((EA),(unsigned short)tmp1); cpuWriteByte(((EA)+1),((unsigned short)tmp1)>>8); }; }; CLKM(3,1); break;
		case 0x10: { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.ip); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.ip)>>8); }; }; I.ip = (unsigned short)tmp; CLKM(6,5); break;
		case 0x18: tmp1 = I.sregs[CS]; I.sregs[CS] = (cpuReadByte((EA&0xf0000)|((EA+2)&0xffff)) | (cpuReadByte(((EA&0xf0000)|((EA+2)&0xffff))+1)<<8)); { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),tmp1); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(tmp1)>>8); }; }; { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),I.ip); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(I.ip)>>8); }; }; I.ip = tmp; CLKM(12,1); break;
		case 0x20: I.ip = tmp; CLKM(5,4); break;
		case 0x28: I.ip = tmp; I.sregs[CS] = (cpuReadByte((EA&0xf0000)|((EA+2)&0xffff)) | (cpuReadByte(((EA&0xf0000)|((EA+2)&0xffff))+1)<<8)); CLKM(10,1); break;
		case 0x30: { I.regs.w[SP] -= 2; {cpuWriteByte(((((I.sregs[SS]<<4)+I.regs.w[SP]))),tmp); cpuWriteByte((((((I.sregs[SS]<<4)+I.regs.w[SP])))+1),(tmp)>>8); }; }; CLKM(2,1); break;
		default: i_invalid();
	}
}

static void i_invalid(void)
{
	CLK(10);
}

int nec_execute(int cycles)
{
	nec_ICount = cycles;

	while(nec_ICount > 0) {
		nec_instruction[FETCHOP]();
	}
	return cycles - nec_ICount;
}
