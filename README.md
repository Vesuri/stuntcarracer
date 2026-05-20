# Stunt Car Racer (Framerate Unleashed)

A modification of the 1989 Amiga game **Stunt Car Racer** (Geoff Crammond / MicroStyle) that unlocks the framerate to 50 FPS without changing the original speed or physics. Intended for Amigas with a fast CPU and fast memory — it will not improve performance on a stock Amiga 500.

The modification is distributed as a WHDLoad slave. A Stunt Car Racer WHDLoad installation (original PAL disk-based version) is required: replace the original `StuntCarRacer.slave` with the one built from this source, then run WHDLoad as usual.

The tooltype `C2=1` enables **The New Tracks** option, which plays the game using the track layouts from the TNT hack by AmiGer/CARE. Save and lap time data for the TNT tracks are stored separately in `StuntCarRacerTNT.save` and `StuntCarRacerTNT.times`.

Status: work in progress / beta. Known limitations:

- Only PAL is currently supported.
- Computer link using a serial cable does not work as expected.
- The original code has not been optimized in any way — there is probably room for improvement.

## Files

- `StuntCarRacer.s` — Source code for the game with enhancements.
- `StuntCarRacerSlave.s` — WHDLoad slave for loading and running the game.
- `StuntCarRacer.readme` — Amiga-style readme distributed alongside the slave binary.

## About the source

The code was initially disassembled from the game binary using **ReSource**. Labels have been renamed manually as the code was analysed. Modifications to the original behaviour are marked with comments such as `; added`, `; removed`, `; originally` and `; fixed`.

## Credits

Written by Vesuri / dA JoRMaS — <vesuri@jormas.com>.

The WHDLoad slave is partially based on the work by Codetapper/Action! & StingRay.

Original game (1989): Geoff Crammond / MicroStyle.
