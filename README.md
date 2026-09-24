# Stunt Car Racer / Stunt Track Racer (Framerate Unleashed)

A modification of the 1989 Amiga game **Stunt Car Racer** (Geoff Crammond / MicroStyle) that unlocks the framerate to 50/60 FPS without changing the original speed or physics. Intended for Amigas with a fast CPU and fast memory — it will not improve performance on a stock Amiga 500.

## PAL version — Stunt Car Racer

The modification is distributed as a WHDLoad slave. The installer (`Install`) can create a full installation from the original PAL floppy disk or the Quartex cracked ADF image, or upgrade an existing Stunt Car Racer WHDLoad installation by replacing `StuntCarRacer.slave` in place. Unrecognised disk images produce a clean WHDLoad error instead of crashing.

The tooltype `C2=1` enables **The New Tracks** option, which plays the game using the track layouts from the TNT hack by AmiGer/CARE. Save and lap time data for the TNT tracks are stored separately in `StuntCarRacerTNT.save` and `StuntCarRacerTNT.times`.

## NTSC version — Stunt Track Racer

A separate NTSC build (`StuntTrackRacer.slave`) targets 60 FPS on NTSC hardware. It requires a Stunt Car Racer WHDLoad installation using the **original PAL disk** — the slave loads and patches the PAL binary at runtime, replacing the title logo with the North American *Stunt Track Racer* branding.

The `C2=1` tooltype works the same way as in the PAL version.

## Building on the host

`make -j2` cross-compiles both the game executables and the PAL/NTSC WHDLoad
slaves using native vasm. No Amiga assembler or emulator is required to build.
Outputs are `build/StuntCarRacer.slave` and `build/StuntTrackRacer.slave`.

The defaults match the local Vette toolchain:

- `VASM=$HOME/.local/vasmm68k_mot` (tested with vasm 1.9).
- `WHDLOAD=$HOME/.local/share/amiga/WHDLoad` (SDK containing `Include/`).
- `NDK=$HOME/.local/opt/m68k-amiga-elf/sys-include` (Amiga assembly includes).
- Python 3 generates the WDate-compatible version date. Set `SOURCE_DATE_EPOCH`
  for reproducible builds; dates use UTC.

Override these paths as make variables, for example `make VASM=/path/to/vasmm68k_mot`.
The checked-in `gfx/` assets are embedded directly; original game disks are only
needed for running/testing, not for building. Both variants are rebuilt on each
invocation to avoid stale SDK, assembler-option or embedded-asset changes.

`make dist` (or `./create_release.sh`) rebuilds both slaves and prepares the
installer in `dist/StuntCarRacerUnleashed/`, downloading the upstream installers
with `curl` and extracting them with `lha`. It replaces the existing `dist/`
directory. This produces an installation folder, not a compressed archive.
`make clean` removes host build outputs and test fixtures.

The original basm build remains available on Amiga as `make -f makefile.amiga`.
Existing root-level Amiga binaries are not used by the host release build.

The embedded game requires `-kick1hunks`: vasm's default compact HUNK_DREL32
relocations are rejected by WHDLoad's `resload_Relocate`. The slave itself uses
`-pic -x` to reject accidental absolute references. The three indexed jumps use
an explicit zero PC displacement, preserving their jump-table instruction bytes.

## Testing the host-built slaves

Build first, then boot an isolated FS-UAE fixture with local, legally obtained
Kickstart, Workbench and game-disk files:

```sh
python3 tools/test_whdload.py \
  --disk /path/to/PAL/Disk.1 \
  --workbench /path/to/Workbench.adf \
  --kickstart /path/to/kick31.rom
```

Use `--ntsc` for Stunt Track Racer (still with the PAL game disk), `--custom2`
for TNT, `--custom3` for enhanced graphics, and `--no-preload` for live disk reads.
`--emulator` and `--whdload` override their local toolchain defaults. A Quartex
Disk.1 can also be supplied. Each run copies its inputs, saves WHDLoad logs and
memory dumps under `build/whdload-test-*`, and terminates only its own emulator.
The test fails on emulator exit, host timeout, missing dumps or a WHDLoad error;
a passing timed run is a startup smoke test, not a full gameplay regression.

Host validation used FS-UAE A1200/68020 with WHDLoad 19.2: PAL original and
Quartex disks, NTSC, TNT/enhanced graphics, and PRELOAD disabled. Timed runs
completed without reported exceptions and the menu screens were decoded from
the actual chip-memory dumps for visual inspection. The complete `make dist`
workflow was also run and its packaged slaves matched the build outputs.

## Known limitations

- Computer link play via serial cable is not supported.
- The original code has not been optimized in any way — there is probably room for improvement.

## Files

- `StuntCarRacer.s` — Source code for the game with enhancements (PAL and NTSC, selected at build time with `-dNTSC=1`).
- `StuntCarRacerSlave.s` — WHDLoad slave for loading and running the game (`StuntCarRacer.slave` for PAL, `StuntTrackRacer.slave` for NTSC).
- `Install` — Amiga Installer script for creating or upgrading a WHDLoad installation.
- `ReadMe` — Readme distributed in the release archive, in WHDLoad template format.
- `create_release.sh` — Builds the release installation folder. Run via `make dist`.

## About the source

The code was initially disassembled from the game binary using **ReSource**. Labels have been renamed manually as the code was analysed. Modifications to the original behaviour are marked with comments such as `; added`, `; removed`, `; originally` and `; fixed`.

## Credits

Written by Vesuri / dA JoRMaS — <vesuri@jormas.com>.

The WHDLoad slave is partially based on the work by Codetapper/Action! & StingRay.

Original game (1989): Geoff Crammond / MicroStyle.
