//
//  ARMV30MZ.h
//  V30MZ cpu emulator for arm32.
//
//  Created by Fredrik Ahlström on 2021-10-19.
//  Copyright © 2021-2025 Fredrik Ahlström. All rights reserved.
//

#ifndef ARMV30MZ_HEADER
#define ARMV30MZ_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	u32 regs[8];
	u32 sRegs[4];
	u32 prefixBase;
	u32 flags;
	u8 *pc;
	u32 cycles;
	u8 irqPin;
	u8 iFlag;
	u8 empty;
	u8 nmiPending;
	u16 parityVal;
	u8 nmiPin;
	u8 df;
	u8 mulOverflow;
	u8 dummy0[3];

	u8 *lastBank;
	u8 (*irqVectorFunc)(void);
	void (*v30BusStatusFunc)(u8);
	void (*v30SRegTable[4])(void);

	u8 *memTbl[16];

	void (*opz[256])(void);
	u8 pzst[256];
	void (*EATable[256])(void);
	u32 modRm[256];
	u8 segTbl[256];
	void (*_80Table[1])(void);
	void (*_83Table[1])(void);
	void (*c0Table[1])(void);
	void (*c1Table[1])(void);
	void (*f6Table[1])(void);
	void (*f7Table[1])(void);
	void (*feTable[1])(void);
	void (*ffTable[1])(void);
	void (*xxTable[32*8-8])(void);
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
void V30RedirectOpcode(int opcode, void (*function)(void));

void V30SetIRQPin(bool set);
void V30SetNMIPin(bool set);
void V30RestoreAndRunXCycles(int cycles);
void V30RunXCycles(int cycles);
void V30CheckIRQs(void);

#ifdef __cplusplus
}
#endif

#endif // ARMV30MZ_HEADER
