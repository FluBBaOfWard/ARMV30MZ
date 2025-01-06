# ARMV30MZ V0.8.9

NEC V30MZ emulator for ARM32.

## About

All opcodes should behave pretty much like the real deal in a WonderSwan.
All flags should be emulated correctly except when a division exception occurs,
then the Zero flag is not updated as it is on HW.
Timing should be pretty close to HW as well, it doesn't handle extra cycles on branches to odd addresses.
It only handles interrupts during REP instructions for MOVMW/MOVSW & STMW/STOSW, on these instructions LOCK is never accounted for.
It doesn't handle emulation bit/mode in status register, I haven't figured out how to test that.

This is a version with insecure handling of PC.
This version requires asm hooks for memory/io handling.

## Projects that use this cpu core

* <https://github.com/FluBBaOfWard/NitroSwan>
* <https://github.com/FluBBaOfWard/SwanGBA>

## Credits

Fredrik Ahlström

X/Twitter @TheRealFluBBa

<https://www.github.com/FluBBaOfWard>
