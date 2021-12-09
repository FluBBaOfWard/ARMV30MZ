
static u32 EA;
static u16 EO;
static u16 E16;

static unsigned EA_000(void) { EO=I.regs.w[BW]+I.regs.w[IX]; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_001(void) { EO=I.regs.w[BW]+I.regs.w[IY]; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_002(void) { EO=I.regs.w[BP]+I.regs.w[IX]; EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_003(void) { EO=I.regs.w[BP]+I.regs.w[IY]; EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_004(void) { EO=I.regs.w[IX]; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_005(void) { EO=I.regs.w[IY]; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_006(void) { EO=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); EO+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_007(void) { EO=I.regs.w[BW]; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }

static unsigned EA_100(void) { EO=(I.regs.w[BW]+I.regs.w[IX]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_101(void) { EO=(I.regs.w[BW]+I.regs.w[IY]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_102(void) { EO=(I.regs.w[BP]+I.regs.w[IX]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_103(void) { EO=(I.regs.w[BP]+I.regs.w[IY]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_104(void) { EO=(I.regs.w[IX]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_105(void) { EO=(I.regs.w[IY]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_106(void) { EO=(I.regs.w[BP]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_107(void) { EO=(I.regs.w[BW]+(signed char)(cpuReadByte((I.sregs[CS]<<4)+I.ip++))); EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }

static unsigned EA_200(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BW]+I.regs.w[IX]+(signed short)E16; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_201(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BW]+I.regs.w[IY]+(signed short)E16; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_202(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BP]+I.regs.w[IX]+(signed short)E16; EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_203(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BP]+I.regs.w[IY]+(signed short)E16; EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_204(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[IX]+(signed short)E16; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_205(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[IY]+(signed short)E16; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }
static unsigned EA_206(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BP]+(signed short)E16; EA=((seg_prefix && (SS==DS || SS==SS)) ? prefix_base : I.sregs[SS] << 4)+EO; return EA; }
static unsigned EA_207(void) { E16=(cpuReadByte((I.sregs[CS]<<4)+I.ip++)); E16+=(cpuReadByte((I.sregs[CS]<<4)+I.ip++))<<8; EO=I.regs.w[BW]+(signed short)E16; EA=((seg_prefix && (DS==DS || DS==SS)) ? prefix_base : I.sregs[DS] << 4)+EO; return EA; }

static unsigned (*GetEA[192])(void) = {
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
