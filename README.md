# Stunt Car Racer

A disassembly of the 1989 Amiga game **Stunt Car Racer** (Geoff Crammond / MicroStyle), converted from the original 10 FPS to 50/60 FPS, along with a WHDLoad slave.

## Files

- `StuntCarRacer.s` — Motorola 68000 assembly source for the game, targeting the Amiga OCS/ECS chipset.
- `StuntCarRacerSlave.s` — WHDLoad slave for loading and running the game.

## How the source was produced

The code was initially disassembled from the game binary using **ReSource**. Labels have been renamed manually as the code was analysed. Modifications to the original behaviour are marked with comments such as `; added`, `; removed`, `; originally` and `; fixed`.
