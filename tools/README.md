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

`imageMainGameBackground` can be supplied as a 32-colour, 5-bitplane image.
Build it with the `--32` flag:

```
python3 tools/build_images.py --32 \
    'imageMainGameBackground=images/wip/imageMainGameBackground_WIP_2.png'
```

The PNG must use at most 32 distinct palette indices.  The output format is:

| Offset | Size | Meaning |
|---|---|---|
| 0  | 1   | flag `$C0` (bit 7 = RLE, bit 6 = 32-colour) |
| 1  | 1   | padding |
| 2  | 32  | palette colours  0–15 (`$0RGB` words, levels `0..7` per channel) |
| 34 | 32  | palette colours 16–31 (same format) |
| 66 | var | 4-plane RLE data (planes 0–3, `decompressRLEImage`) |
| —  | var | 1-plane RLE data (plane 4, `decompressRLEBitplane`) |

### Reserved sprite palette entries

The game hardware sprites use Amiga color registers 16–23.  These are set
once at startup by `loadPaletteColors` from the original game binary and are
**overwritten every frame** by `copyPaletteToCopperlist` when 32-colour mode
is active.  For the car sprites to display correctly, palette indices 16–23
in the replacement image must match the original values:

| Index | Value | Role |
|---|---|---|
| 16 | `$500` | **Transparent** (sprite index 0 = background shows through; value ignored by hardware) |
| 17 | `$f8e` | Sprites 0 & 1 — colour 1 (bright pink/mauve) |
| 18 | `$c00` | Sprites 0 & 1 — colour 2 (dark red) |
| 19 | `$07b` | Sprites 0 & 1 — colour 3 (mid blue) |
| 20 | `$500` | **Transparent** (same as index 16, for sprite group 2/3) |
| 21 | `$01c` | Sprites 2 & 3 — colour 1 (deep blue) |
| 22 | `$000` | Sprites 2 & 3 — colour 2 (black) |
| 23 | `$f82` | Sprites 2 & 3 — colour 3 (orange-yellow) |

Palette indices 24–31 are **not** written by `loadPaletteColors`; they default
to `$000` (black) and are free to use for background detail.  Sprites 4–7
are unused by the car renderer and will appear black regardless.

Values are 12-bit hardware color register values (4 bits per channel, written
directly — no brightness expansion), unlike the 0–7-per-channel values used
for 16-colour palette entries.

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
