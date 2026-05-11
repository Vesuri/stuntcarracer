# Stunt Car Racer

A modification of the 1989 Amiga game **Stunt Car Racer** (Geoff Crammond / MicroStyle) that unlocks the framerate to 50/60 FPS without changing the original speed or physics. Intended for Amigas with a fast CPU and fast memory — it will not improve performance on a stock Amiga 500.

The modification is distributed as a WHDLoad slave. A Stunt Car Racer WHDLoad installation (disk-based version, not "The New Tracks") is required: replace the original `StuntCarRacer.slave` with the one built from this source, then run WHDLoad as usual.

Status: work in progress / beta. Known limitations:

- Only one game version is currently supported.
- Only PAL is currently supported.
- The original code has not been optimized in any way — there is probably room for improvement.

## Files

- `StuntCarRacer.s` — Motorola 68000 assembly source for the game, targeting the Amiga OCS/ECS chipset.
- `StuntCarRacerSlave.s` — WHDLoad slave for loading and running the game.
- `StuntCarRacer.readme` — Amiga-style readme distributed alongside the slave binary.

## About the source

The code was initially disassembled from the game binary using **ReSource**. Labels have been renamed manually as the code was analysed. Modifications to the original behaviour are marked with comments such as `; added`, `; removed`, `; originally` and `; fixed`.

## Author

Written by Vesuri / dA JoRMaS — <vesuri@jormas.com>.
