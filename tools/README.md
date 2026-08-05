# tools/

Helper scripts for working with the game's image assets. Run from the project
root; Python 3 only, no external dependencies.

## Workflow

1. `extract_images.py` decodes the original game's image assets into 16-color
   indexed PNGs that you can edit in any image editor.
2. Edit the PNGs in `images/` (preserve the palette and stay at 320×200).
3. `build_images.py` re-encodes the PNGs into per-image data files that the
   WHDLoad slave can load as alternative graphics — the original
   `scr.exe.decrypted` is never modified.

## extract_images.py

```
python3 tools/extract_images.py [--input-dir old/old] \
                                [--decrypted old/old/scr.exe.decrypted] \
                                [--output-dir images]
```

Outputs nine 320×200, 4-bit indexed PNGs to `images/`:

| File | Source format in game data |
|---|---|
| `imageMainGameBackground.png`     | RLE-compressed planar bitplanes (palette at `$11a84` in the exe) |
| `imageMenuScreen.png`             | Raw word-interleaved bitplanes (palette at `$15532`) |
| `imageTrackPreviewBackground.png` | RLE-compressed planar bitplanes (palette at `$1d274`) |
| `imageStandingsBackground.png`    | RLE-compressed planar bitplanes (palette at `$224d0`) |
| `imagePlayers.png`                | Raw word-interleaved bitplanes (palette at `$27376`) |
| `imageWreck.png`                  | Self-contained: flag + palette + RLE data |
| `imageWon.png`                    | Self-contained: flag + palette + RLE data |
| `imageLost.png`                   | Self-contained: flag + palette + RLE data |
| `imagePromotion.png`              | Self-contained: flag + palette + RLE data |

The script reproduces two pieces of the game's runtime behaviour:

- **RLE decoding** mirrors `decompressRLEImage` at `StuntCarRacer.s:2758`.
- **Palette brightness expansion** mirrors `copyPaletteToCopperlist` at
  `StuntCarRacer.s:760`. The on-disk palette uses values `0..7` per channel;
  the game shifts left by 1 and ORs in the LSB of every non-zero nibble before
  writing to the COLOR registers, so `$0777` becomes `$0FFF` (white) and
  `$0444` becomes `$0999`. The PNG palette stores the expanded 8-bit values
  (`$00, $33, $55, $77, $99, $BB, $DD, $FF`).

### `imageMenuScreen` is special

The on-disk `imageMenuScreen` file is shorter than the 32000 bytes the game
actually reads — the game reads past the labeled end of the image into the
adjacent `alternateFontBitmapData` region. The extractor therefore pulls the
full 32000 bytes straight from `scr.exe.decrypted`. The lower portion of the
PNG shows the alternate font bitmap; in-game the menu UI is drawn over it.
Changing the lower portion of the PNG will change the alternate font.

## build_images.py

```
python3 tools/build_images.py [--input-dir images] [--output-dir gfx] [--raw] [image-names...]
```

Re-encodes the PNGs in `images/` into per-image data files in `gfx/`. Each
file is self-describing:

| Offset | Size | Meaning |
|---|---|---|
| 0  | 1   | flag — `$80` = RLE, `$00` = raw word-interleaved |
| 1  | 1   | padding |
| 2  | 32  | palette (16 big-endian `$0RGB` words; levels `0..7` per channel) |
| 34 | var | image data |

This is the same layout `displayResultScreen` at `StuntCarRacer.s:2710`
already consumes for `imageWreck`/`Won`/`Lost`/`Promotion`, so the slave can
share one load+decode routine for every replacement:

```assembly
; A0 = loaded file pointer
LEA     2(A0),A1               ; A1 -> embedded palette
JSR     copyPalette            ; copy palette
LEA     34(A0),A0              ; A0 -> image data
TST.B   -34(A0)                ; check flag at offset 0
BPL     .copyRawImage          ; non-negative -> raw interleaved
JSR     decompressRLEImage     ; negative   -> RLE
```

Defaults to RLE-compressed output (flag `$80`). Pass `--raw` to emit
uncompressed word-interleaved bitplanes instead (fixed 32034-byte payload;
slightly faster to load but ~30–50% larger on disk).

### Palette quantization

PNG palette colors are quantized to the eight Amiga levels per channel
(`$00 $33 $55 $77 $99 $BB $DD $FF`). The first out-of-quantization color
prints a one-time note; further mismatches are suppressed. If you stay on
those eight values per channel, no quantization happens.

### Image constraints

- 320×200, indexed-color PNG (color type 3), bit depth 1/2/4/8.
- At most 16 distinct color indices in use.
- Non-interlaced.

## 32-colour images (5 bitplanes)

All nine images can be supplied as 32-colour, 5-bitplane images, and the game
runs every screen in 5 bitplanes whenever enhanced graphics are active.  Build
with the `--32` flag:

```
python3 tools/build_images.py --32 \
    'imageMainGameBackground=images/enhanced/imageMainGameBackground_remapped.png'
python3 tools/build_images.py --32 \
    'imagePlayers=images/enhanced/imagePlayers_remapped.png'
python3 tools/build_images.py --32 \
    'imageMenuScreen=images/enhanced/imageMenuScreen_remapped.png'
```

`--raw` is not needed for `imageMenuScreen`/`imagePlayers`: they are in
`ALWAYS_RAW`, so `--32` already emits the raw form their renderers require.

The PNG must use at most 32 distinct palette indices.  There are two 32-colour
output formats; both share a `$42`-byte header and are distinguished by bit 7
of the flag byte.

**RLE (flag `$C0`)** — the default:

| Offset | Size | Meaning |
|---|---|---|
| 0  | 1   | flag `$C0` (bit 7 = RLE, bit 6 = 32-colour) |
| 1  | 1   | padding |
| 2  | 32  | palette colours  0–15 (`$0RGB` words, levels `0..7` per channel) |
| 34 | 32  | palette colours 16–31 (same format) |
| 66 | var | 4-plane RLE data (planes 0–3, `decompressRLEImage`) |
| —  | var | 1-plane RLE data (plane 4, `decompressRLEBitplane`) |

**Raw (flag `$40`)** — used automatically for the always-raw images
(`imagePlayers`, `imageMenuScreen`) and with `--32 --raw`.  Their renderers blit
sub-regions straight out of the image data in memory, which rules out RLE:

| Offset | Size | Meaning |
|---|---|---|
| 0  | 1   | flag `$40` (bit 7 = raw, bit 6 = 32-colour) |
| 1  | 1   | padding |
| 2  | 32  | palette colours  0–15 |
| 34 | 32  | palette colours 16–31 |
| 66 | 32000 | word-interleaved planes 0–3 (same layout as the 16-colour raw form) |
| 32066 | 8000 | planar plane 4 (40 bytes/row) |

Fixed total: 40066 bytes.  Planes 0–3 keep the 160-byte interleaved row stride
of the 16-colour form, so existing sub-region source offsets stay valid; a
plane-4 offset is the plane-0–3 offset divided by 4 (`row*160 + word*8` →
`row*40 + word*2`).

Note that palette indices 16–31 (the high half) double as the car sprites'
colour registers in 32-colour mode, so some of them are not free — see
`enhanced-graphics.md` for which entries are reserved and the safe-to-edit
regions of each image.

## remap_to_original_palette.py

```
python3 tools/remap_to_original_palette.py \
    [--image NAME | --reference-png PNG] [--high-reference PNG] \
    [--reserve-sprites] SRC DST
```

Reorders a replacement PNG's palette so the low slots hold a *fixed* palette,
moving the image's own extra colours into the free high slots.  No pixel changes
colour unless a colour has to be merged.  This matters because the game selects
many colours **by index** (text, HUD, track and cursor colours), so those slots
have a fixed meaning and cannot be reassigned freely.

- `--image NAME` pins indices 0–15 to that image's own original palette, read
  from `scr.exe.decrypted` (including its own index-0 background), and leaves
  16–31 free for the artist.
- `--reference-png PNG` pins **all 32** slots to another PNG's palette,
  including index 0.  Only appropriate when two images are meant to show the
  *identical* palette, background included.
- `--high-reference PNG` (combine with `--image NAME`) pins only slots 16–31
  to another PNG's slots 16–31, while 0–15 stay pinned to this image's own
  original palette — so index 0 (the background) is free to differ between
  the two images.  Use this when two images share portrait/extra colours
  but have independent backgrounds — e.g. `imageMenuScreen`'s 16–31 must
  match `imagePlayers`' so portraits blitted from one onto the other render
  correctly, but each screen keeps its own background at index 0.
- `--reserve-sprites` additionally pins 17,18,19,21,22,23 to the car sprite
  colours.  Only `imageMainGameBackground` needs this.

### What each image needs

| Image | Remap | Why |
|---|---|---|
| `imageMainGameBackground` | `--image imageMainGameBackground --reserve-sprites` | HUD colours by index; palette 16–31 drives the car sprite registers |
| `imagePlayers` | `--image imagePlayers` | no sprites on the results screen; 16–31 free for the artist |
| `imageMenuScreen` | `--image imageMenuScreen --high-reference .../imagePlayers_remapped.png` | portraits are blitted from `imagePlayers` onto menu-based screens, so 16–31 must mean the same colour in both; index 0 (background) stays independent |
| `imageTrackPreviewBackground` | `--image imageTrackPreviewBackground` | 3-D preview and text pick colours by index |
| `imageStandingsBackground` | `--image imageStandingsBackground` | records table text picks colours by index |
| `imageWreck`/`Won`/`Lost`/`Promotion` | **none** | nothing is drawn over them and no index is referenced — all 32 free |

Full workflow for the menu screen, which needs both steps:

```
python3 tools/remap_to_original_palette.py \
    --image imageMenuScreen \
    --high-reference images/enhanced/imagePlayers_remapped.png \
    images/enhanced/imageMenuScreen_chatgpt.png \
    images/enhanced/imageMenuScreen_remapped.png
python3 tools/build_images.py --32 \
    'imageMenuScreen=images/enhanced/imageMenuScreen_remapped.png'
```

If `imagePlayers` ever changes, rerun **both** steps for the menu, or the two
palettes drift apart again.

## Round-trip sanity check

```
python3 tools/extract_images.py
python3 tools/build_images.py
python3 tools/extract_images.py --decrypted old/old/scr.exe.decrypted --output-dir /tmp/check
diff -r images /tmp/check          # should be empty
```

For an even tighter check, decode any built file via `extract_images`'s helper
routines and compare PNGs byte-for-byte — the test in the build-tool commit
history does exactly that.
