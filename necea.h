
static u32 EA;
static u16 EO;
static u16 E16;

ITCM_CODE static unsigned EA_000(void) { EO=I.regs.w[BW]+I.regs.w[IX]; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_001(void) { EO=I.regs.w[BW]+I.regs.w[IY]; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_002(void) { EO=I.regs.w[BP]+I.regs.w[IX]; EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_003(void) { EO=I.regs.w[BP]+I.regs.w[IY]; EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_004(void) { EO=I.regs.w[IX]; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_005(void) { EO=I.regs.w[IY]; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_006(void) { FETCHWORD(EO); EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_007(void) { EO=I.regs.w[BW]; EA=DefaultBase(DS)+EO; return EA; }

ITCM_CODE static unsigned EA_100(void) { EO=(I.regs.w[BW]+I.regs.w[IX]+(signed char)(FETCH)); EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_101(void) { EO=(I.regs.w[BW]+I.regs.w[IY]+(signed char)(FETCH)); EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_102(void) { EO=(I.regs.w[BP]+I.regs.w[IX]+(signed char)(FETCH)); EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_103(void) { EO=(I.regs.w[BP]+I.regs.w[IY]+(signed char)(FETCH)); EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_104(void) { EO=(I.regs.w[IX]+(signed char)(FETCH)); EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_105(void) { EO=(I.regs.w[IY]+(signed char)(FETCH)); EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_106(void) { EO=(I.regs.w[BP]+(signed char)(FETCH)); EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_107(void) { EO=(I.regs.w[BW]+(signed char)(FETCH)); EA=DefaultBase(DS)+EO; return EA; }

ITCM_CODE static unsigned EA_200(void) { FETCHWORD(E16); EO=I.regs.w[BW]+I.regs.w[IX]+(signed short)E16; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_201(void) { FETCHWORD(E16); EO=I.regs.w[BW]+I.regs.w[IY]+(signed short)E16; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_202(void) { FETCHWORD(E16); EO=I.regs.w[BP]+I.regs.w[IX]+(signed short)E16; EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_203(void) { FETCHWORD(E16); EO=I.regs.w[BP]+I.regs.w[IY]+(signed short)E16; EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_204(void) { FETCHWORD(E16); EO=I.regs.w[IX]+(signed short)E16; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_205(void) { FETCHWORD(E16); EO=I.regs.w[IY]+(signed short)E16; EA=DefaultBase(DS)+EO; return EA; }
ITCM_CODE static unsigned EA_206(void) { FETCHWORD(E16); EO=I.regs.w[BP]+(signed short)E16; EA=DefaultBase(SS)+EO; return EA; }
ITCM_CODE static unsigned EA_207(void) { FETCHWORD(E16); EO=I.regs.w[BW]+(signed short)E16; EA=DefaultBase(DS)+EO; return EA; }

static unsigned (* __attribute__((section(".dtcm"))) GetEA[192])(void) = {
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,
	EA_000, EA_001, EA_002, EA_003, EA_004, EA_005, EA_006, EA_007,

	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,
	EA_100, EA_101, EA_102, EA_103, EA_104, EA_105, EA_106, EA_107,

	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207,
	EA_200, EA_201, EA_202, EA_203, EA_204, EA_205, EA_206, EA_207
};
