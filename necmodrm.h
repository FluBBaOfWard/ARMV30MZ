
static struct {
	struct {
		WREGS w[256];
		BREGS b[256];
	} reg;
	struct {
		WREGS w[256];
		BREGS b[256];
	} RM;
} Mod_RM __attribute__((section(".dtcm")));

#define RegWord(ModRM) I.regs.w[Mod_RM.reg.w[ModRM]]
#define RegByte(ModRM) I.regs.b[Mod_RM.reg.b[ModRM]]

#define GetRMWord(ModRM) \
	((ModRM) >= 0xc0 ? I.regs.w[Mod_RM.RM.w[ModRM]] : ( (*GetEA[ModRM])(), ReadWord( EA ) ))

#define PutbackRMWord(ModRM,val) 			     \
{ 							     \
	if (ModRM >= 0xc0) I.regs.w[Mod_RM.RM.w[ModRM]]=val; \
    else WriteWord(EA,val);  \
}

#define GetNextRMWord ReadWord((EA&0xf0000)|((EA+2)&0xffff))

#define PutRMWord(ModRM,val)				\
{							\
	if (ModRM >= 0xc0)				\
		I.regs.w[Mod_RM.RM.w[ModRM]]=val;	\
	else {						\
		(*GetEA[ModRM])();			\
		WriteWord( EA ,val);			\
	}						\
}

#define PutImmRMWord(ModRM) 				\
{							\
	WORD val;					\
	if (ModRM >= 0xc0)				\
		FETCHWORD(I.regs.w[Mod_RM.RM.w[ModRM]]) \
	else {						\
		(*GetEA[ModRM])();			\
		FETCHWORD(val)				\
		WriteWord( EA , val);			\
	}						\
}
	
#define GetRMByte(ModRM) \
	((ModRM) >= 0xc0 ? I.regs.b[Mod_RM.RM.b[ModRM]] : ReadByte( (*GetEA[ModRM])() ))
	
#define PutRMByte(ModRM,val)				\
{							\
	if (ModRM >= 0xc0)				\
		I.regs.b[Mod_RM.RM.b[ModRM]]=val;	\
	else						\
		WriteByte( (*GetEA[ModRM])() ,val); 	\
}

#define PutImmRMByte(ModRM) 				\
{							\
	if (ModRM >= 0xc0)				\
		I.regs.b[Mod_RM.RM.b[ModRM]]=FETCH; 	\
	else {						\
		(*GetEA[ModRM])();			\
		WriteByte( EA , FETCH );		\
	}						\
}
	
#define PutbackRMByte(ModRM,val)			\
{							\
	if (ModRM >= 0xc0)				\
		I.regs.b[Mod_RM.RM.b[ModRM]]=val;	\
	else						\
		WriteByte(EA,val);			\
}

#define DEF_br8							\
	GetModRM;							\
	UINT32 src = RegByte(ModRM);		\
    UINT32 dst = GetRMByte(ModRM)
    
#define DEF_wr16						\
	GetModRM;							\
	UINT32 src = RegWord(ModRM);		\
    UINT32 dst = GetRMWord(ModRM)

#define DEF_r8b							\
	GetModRM;							\
	UINT32 src = GetRMByte(ModRM);		\
	UINT32 dst = RegByte(ModRM)

#define DEF_r16w						\
	GetModRM;							\
	UINT32 src = GetRMWord(ModRM);		\
	UINT32 dst = RegWord(ModRM)

#define DEF_ald8						\
	UINT32 src = FETCH;					\
	UINT32 dst = I.regs.b[AL]

#define DEF_axd16						\
	UINT32 src;							\
	FETCHWORD(src);						\
	UINT32 dst = I.regs.w[AW]
