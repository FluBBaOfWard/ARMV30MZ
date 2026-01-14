# ARMV30MZ V0.8.11

NEC V30MZ emulator for ARM32.

## About

All opcodes should behave pretty much like the real deal in a WonderSwan.
All flags should be emulated correctly except when a division exception occurs,
then the Zero flag is not updated as it is on HW.
Timing should be pretty close to HW as well, it doesn't handle extra cycles on branches to odd addresses.
It only handles interrupts during REP instructions for MOVMW/MOVSW & STMW/STOSW, on these instructions LOCK is never accounted for.
It doesn't handle emulation bit/mode in status register, I haven't figured out how to test that.

This is a version with insecure handling of PC.

## Projects that use this cpu core

* <https://github.com/FluBBaOfWard/NitroSwan>
* <https://github.com/FluBBaOfWard/SwanGBA>

## Requirements

This version requires hooks for memory/io handling.

IO Handling:
u8 v30ReadPort(u16 port);
u16 v30ReadPort16(u16 port);
void v30WritePort(u8 value, u16 port);
void v30WritePort16(u16 value, u16 port);

Memory Handling:
u8 cpuReadMem20(u32 addr);
u16 cpuReadMem20W(u32 addr);
void cpuWriteMem20(u32 addr, u8 value);
void cpuWriteMem20W(u32 addr, u16 value);
Address is in the top 20bits.

## Credits

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
