# ARMV30MZ V0.8.3
NEC V30MZ emulator for ARM 32.

All opcodes should behave pretty much like the real deal in a WonderSwan.
All flags should be emulated correctly except when a division exception occurs,
then the Zero flag is not updated as it is on HW.
Timing should be pretty close to HW as well, it doesn't handle extra cycles on branches to odd addresses.

This is a version with insecure handling of PC.
This version requires asm hooks for memory reading.
