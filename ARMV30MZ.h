//
//  ARMV30MZ.h
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2023 Fredrik Ahlström. All rights reserved.
//

#ifndef ARMV30MZ_HEADER
#define ARMV30MZ_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	u32 v30Regs[8];
	u32 v30SRegs[4];
	u32 v30PrefixBase;
	u32 v30Flags;
	u32 v30PC;
	u32 v30Cycles;
	u8 v30IrqPin;
	u8 v30IF;
	u8 v30Empty;
	u8 v30NmiPending;
	u16 v30ParityVal;
	u8 v30NmiPin;
	u8 v30DF;
	u8 v30MulOverflow;
	u8 dummy0[3];

	u32 v30LastBank;
	void *v30IrqVectorFunc;

	u32 v30MemTbl[16];

	u32 v30Opz[256];
	u8 v30PZST[256];
	void *EATable[256];
	u32 v30ModRm[256];
	u8 v30SegTbl[256];
} ARMV30Core;

extern ARMV30Core V30OpTable;

/**
 * Reset the cpu core.
 * @param  *cpu: The ARMV30Core cpu to reset.
 * @param  type: ASWAN = 0, SPHINX(2) != 0.
 */
void V30Reset(ARMV30Core *cpu, int type);

/**
 * Saves the state of the cpu to the destination.
 * @param  *destination: Where to save the state.
 * @param  *cpu: The ARMV30Core cpu to save.
 * @return The size of the state.
 */
int V30SaveState(void *destination, const ARMV30Core *cpu);

/**
 * Loads the state of the cpu from the source.
 * @param  *cpu: The ARMV30Core cpu to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int V30LoadState(ARMV30Core *cpu, const void *source);

/**
 * Gets the state size of an ARMV30Core state.
 * @return The size of the state.
 */
int V30GetStateSize(void);

/**
 * Redirect/patch an opcode to a new function.
 * @param  opcode: Which opcode to redirect.
 * @param  *function: Pointer to new function .
 */
void V30RedirectOpcode(int opcode, void *function);

void V30SetIRQPin(bool set);
void V30SetNMIPin(bool set);
void V30RestoreAndRunXCycles(int cycles);
void V30RunXCycles(int cycles);
void V30CheckIRQs(void);

#ifdef __cplusplus
}
#endif

#endif // ARMV30MZ_HEADER
