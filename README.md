# Stunt Car Racer / Stunt Track Racer (Framerate Unleashed)

A modification of the 1989 Amiga game **Stunt Car Racer** (Geoff Crammond / MicroStyle) that unlocks the framerate to 50/60 FPS without changing the original speed or physics. Intended for Amigas with a fast CPU and fast memory — it will not improve performance on a stock Amiga 500.

## PAL version — Stunt Car Racer

The modification is distributed as a WHDLoad slave. The installer (`Install`) can create a full installation from the original PAL floppy disk, or upgrade an existing Stunt Car Racer WHDLoad installation by replacing `StuntCarRacer.slave` in place.

The tooltype `C2=1` enables **The New Tracks** option, which plays the game using the track layouts from the TNT hack by AmiGer/CARE. Save and lap time data for the TNT tracks are stored separately in `StuntCarRacerTNT.save` and `StuntCarRacerTNT.times`.

## NTSC version — Stunt Track Racer

A separate NTSC build (`StuntTrackRacer.slave`) targets 60 FPS on NTSC hardware. It requires a Stunt Car Racer WHDLoad installation using the **original PAL disk** — the slave loads and patches the PAL binary at runtime, replacing the title logo with the North American *Stunt Track Racer* branding.

The `C2=1` tooltype works the same way as in the PAL version.

## Status

Work in progress / beta. Known limitations:

- Computer link using a serial cable does not work as expected.
- The original code has not been optimized in any way — there is probably room for improvement.

## Files

- `StuntCarRacer.s` — Source code for the game with enhancements (PAL and NTSC, selected at build time with `-dNTSC=1`).
- `StuntCarRacerSlave.s` — WHDLoad slave for loading and running the game (`StuntCarRacer.slave` for PAL, `StuntTrackRacer.slave` for NTSC).
- `Install` — Amiga Installer script for creating or upgrading a WHDLoad installation.
- `ReadMe` — Readme distributed in the release archive, in WHDLoad template format.
- `create_release.sh` — Builds the release archive (`StuntCarRacerUnleashed.tar`). Run via `make dist`.

## About the source

The code was initially disassembled from the game binary using **ReSource**. Labels have been renamed manually as the code was analysed. Modifications to the original behaviour are marked with comments such as `; added`, `; removed`, `; originally` and `; fixed`.

## Credits

Written by Vesuri / dA JoRMaS — <vesuri@jormas.com>.

The WHDLoad slave is partially based on the work by Codetapper/Action! & StingRay.

Original game (1989): Geoff Crammond / MicroStyle.
