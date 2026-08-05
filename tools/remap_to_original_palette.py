#!/usr/bin/env python3
"""Reorder a replacement PNG's palette so indices 0-15 hold the ORIGINAL game
palette for that image (in the original order), with the image's extra colours
moved into the high slots (16-31).

Appearance is preserved per-pixel: every pixel keeps its colour, only palette
positions change. If the image has more extra colours than there are free high
slots, the least-used extras are merged into their nearest surviving colour
(reported explicitly).

Optionally reserves the car-sprite colour slots (17,18,19,21,22,23) with
--reserve-sprites — required for a 32-colour imageMainGameBackground, where the
image palette drives the sprite colour registers. Not needed for imagePlayers
(no hardware sprites on the results screen). See enhanced-graphics.md.

The output is an 8-bit indexed PNG whose PLTE holds exactly as many entries as
the target palette uses (32 by default), so the file matches its content.

Examples:
  python3 tools/remap_to_original_palette.py --image imagePlayers \\
      images/enhanced/imagePlayers_final_32c.png \\
      images/enhanced/imagePlayers_remapped.png

  python3 tools/remap_to_original_palette.py --image imageMainGameBackground \\
      --reserve-sprites in.png out.png

  # pin all 32 slots to another image's palette (imageMenuScreen must match
  # imagePlayers, because portraits are blitted onto menu-based screens)
  python3 tools/remap_to_original_palette.py \\
      --reference-png images/enhanced/imagePlayers_remapped.png \\
      images/enhanced/imageMenuScreen_chatgpt.png \\
      images/enhanced/imageMenuScreen_remapped.png

See tools/README.md for which remap each image needs.
"""

import argparse
import collections
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_images import _read_indexed_png_raw, WIDTH, HEIGHT  # noqa: E402

BIN_DEFAULT = 'data/scr.exe.decrypted'

# File offsets of the original 16-colour palettes inside scr.exe.decrypted
# (mirrors the *Palette EQUs in StuntCarRacer.s).
ORIGINAL_PALETTE_OFFSETS = {
    'imageMainGameBackground':     0x11a84,
    'imageMenuScreen':             0x15532,
    'imageTrackPreviewBackground': 0x1d274,
    'imageStandingsBackground':    0x224d0,
    'imagePlayers':                0x27376,
}

# Car sprite colours as STORED LEVELS (expanded to $000/$fff/$c88-ish in-game).
SPRITE_SLOTS = {17: 0x000, 18: 0x777, 19: 0x644, 21: 0x000, 22: 0x777, 23: 0x644}

NUM_SLOTS = 32


def q(b):                      # 8-bit channel -> Amiga stored level 0..7
    return min(7, max(0, (b + 18) // 36))


def expand(n):                 # stored level 0..7 -> Amiga nibble
    return 0 if n == 0 else (n << 1) | 1


def lvl_to_rgb8(word):         # stored $0RGB word -> canonical 8-bit RGB
    out = []
    for shift in (8, 4, 0):
        e = expand((word >> shift) & 0xF)
        out.append((e << 4) | e)
    return tuple(out)


def rgb8_to_lvl(r, g, b):
    return (q(r) << 8) | (q(g) << 4) | q(b)


def read_original_palette(binary, offset):
    data = Path(binary).read_bytes()
    return [(data[offset + i * 2] << 8) | data[offset + i * 2 + 1] for i in range(16)]


def write_png_indexed8(path, pixels, palette):
    """Write an 8-bit indexed PNG with exactly len(palette) PLTE entries."""
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 3, 0, 0, 0)
    plte = b"".join(struct.pack("BBB", *c) for c in palette)
    raw = bytearray()
    for y in range(HEIGHT):
        raw.append(0)                                    # filter: None
        raw.extend(pixels[y * WIDTH:(y + 1) * WIDTH])
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"PLTE", plte))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--image', choices=sorted(ORIGINAL_PALETTE_OFFSETS),
                    help='which original palette to align to')
    ap.add_argument('--reference-png',
                    help='instead of an original palette, pin ALL 32 slots to this '
                         'PNG\'s palette. Needed when two images are shown with one '
                         'palette - e.g. imageMenuScreen must match imagePlayers, '
                         'because portraits are blitted from imagePlayers onto '
                         'menu-based screens. No slot is left free, so every colour '
                         'not in the reference is mapped to its nearest neighbour.')
    ap.add_argument('--binary', default=BIN_DEFAULT)
    ap.add_argument('--reserve-sprites', action='store_true',
                    help='also pin slots 17,18,19,21,22,23 to the car sprite colours')
    ap.add_argument('--high-reference',
                    help='pin slots 16-31 to another PNG\'s slots 16-31, while slots '
                         '0-15 stay pinned to this image\'s OWN original palette '
                         '(via --image, including its own index-0 background - it is '
                         'not forced to match the reference). Use this instead of '
                         '--reference-png when two images share portrait/extra colours '
                         'but have independent backgrounds - e.g. imageMenuScreen\'s '
                         'slots 16-31 must match imagePlayers\' so blitted portraits '
                         'render correctly, but the menu keeps its own index 0-15. '
                         'Requires --image; incompatible with --reference-png.')
    args = ap.parse_args()

    if bool(args.image) == bool(args.reference_png):
        print('error: give exactly one of --image or --reference-png', file=sys.stderr)
        return 1

    if args.high_reference and not args.image:
        print('error: --high-reference requires --image', file=sys.stderr)
        return 1

    if args.reference_png:
        _, ref = _read_indexed_png_raw(Path(args.reference_png))
        ref = list(ref) + [(0, 0, 0)] * (NUM_SLOTS - len(ref))
        orig = [rgb8_to_lvl(*ref[i]) for i in range(NUM_SLOTS)]
    else:
        orig = read_original_palette(args.binary, ORIGINAL_PALETTE_OFFSETS[args.image])

    high_ref_lvl = None
    if args.high_reference:
        _, href = _read_indexed_png_raw(Path(args.high_reference))
        href = list(href) + [(0, 0, 0)] * (NUM_SLOTS - len(href))
        high_ref_lvl = [rgb8_to_lvl(*href[i]) for i in range(len(orig), NUM_SLOTS)]

    # lowest index wins when the original palette repeats a colour
    orig_pos = {}
    for i, L in enumerate(orig):
        orig_pos.setdefault(L, i)

    pixels, src_pal = _read_indexed_png_raw(Path(args.src))
    if max(pixels) >= NUM_SLOTS:
        print(f'error: {args.src} uses pixel index {max(pixels)} '
              f'(>= {NUM_SLOTS} colours)', file=sys.stderr)
        return 1
    src_pal = list(src_pal) + [(0, 0, 0)] * (NUM_SLOTS - len(src_pal))
    idx_lvl = [rgb8_to_lvl(*src_pal[i]) for i in range(NUM_SLOTS)]

    idx_hist = collections.Counter(pixels)
    lvl_hist = collections.Counter()
    for i, L in enumerate(idx_lvl):
        lvl_hist[L] += idx_hist.get(i, 0)
    used = {L for L, c in lvl_hist.items() if c > 0}

    reserved = dict(SPRITE_SLOTS) if args.reserve_sprites else {}
    free_slots = ([] if high_ref_lvl is not None else
                  [i for i in range(len(orig), NUM_SLOTS) if i not in reserved])

    matched = sorted(used & set(orig), key=lambda L: orig_pos[L])
    extras = sorted((L for L in used if L not in orig_pos), key=lambda L: -lvl_hist[L])

    label = args.image or f'reference {Path(args.reference_png).name}'
    print(f'{label}: {len(used)} distinct colours used '
          f'({len(matched)} match the original palette, {len(extras)} extra)')
    print(f'pinned palette has {len(set(orig))} distinct entries; '
          f'{len(set(orig)) - len(matched)} unused by this image')
    if high_ref_lvl is not None:
        print(f'slots {len(orig)}-{NUM_SLOTS - 1} pinned to '
              f'{Path(args.high_reference).name}\'s high slots')
    else:
        print(f'free high slots: {len(free_slots)}'
              + (f' (sprite slots {sorted(reserved)} reserved)' if reserved else ''))

    kept, merged = extras[:len(free_slots)], extras[len(free_slots):]

    # ---- build target palette ----
    tgt = [0x000] * NUM_SLOTS
    for i, L in enumerate(orig):
        tgt[i] = L
    for slot, L in reserved.items():
        tgt[slot] = L
    if high_ref_lvl is not None:
        for slot, L in zip(range(len(orig), NUM_SLOTS), high_ref_lvl):
            tgt[slot] = L
    extra_slot = {}
    for slot, L in zip(free_slots, kept):
        tgt[slot] = L
        extra_slot[L] = slot

    # distinct target colour -> representative index (originals win)
    tgt_index = {}
    for i in range(NUM_SLOTS - 1, -1, -1):
        tgt_index[tgt[i]] = i
    for i in range(len(orig) - 1, -1, -1):
        tgt_index[tgt[i]] = i

    def nearest(L):
        target = lvl_to_rgb8(L)
        return min(tgt_index.items(),
                   key=lambda kv: sum((a - b) ** 2 for a, b in
                                      zip(lvl_to_rgb8(kv[0]), target)))[1]

    new_index = {}
    for L in used:
        if L in orig_pos:
            new_index[L] = orig_pos[L]
        elif L in extra_slot:
            new_index[L] = extra_slot[L]
        else:
            new_index[L] = nearest(L)

    if merged:
        print(f'MAPPED {len(merged)} colour(s) to their nearest pinned neighbour:')
        for L in merged:
            d = new_index[L]
            print(f'  ${L:03x} ({lvl_hist[L]} px) -> slot {d} (${tgt[d]:03x})')
    else:
        print('no merging needed - every colour kept exactly')

    # ---- remap pixels ----
    old_to_new = {i: new_index[idx_lvl[i]] for i in idx_hist}
    new_px = bytes(old_to_new[p] for p in pixels)

    Path(args.dst).parent.mkdir(parents=True, exist_ok=True)
    write_png_indexed8(args.dst, new_px, [lvl_to_rgb8(L) for L in tgt])
    print(f'wrote {args.dst}')

    # ---- verify by re-reading the file we just wrote ----
    chk_px, chk_pal = _read_indexed_png_raw(Path(args.dst))
    ok = all(rgb8_to_lvl(*chk_pal[i]) == orig[i] for i in range(len(orig)))
    print(f'verify PLTE entries: {len(chk_pal)}')
    print(f'verify indices 0-{len(orig)-1} == pinned palette: {ok}')
    if reserved:
        print('verify sprite slots: ' + ', '.join(
            f'{s}=${rgb8_to_lvl(*chk_pal[s]):03x}' for s in sorted(reserved)))
    if high_ref_lvl is not None:
        hok = all(rgb8_to_lvl(*chk_pal[len(orig) + i]) == L
                  for i, L in enumerate(high_ref_lvl))
        print(f'verify indices {len(orig)}-{NUM_SLOTS-1} == '
              f'{Path(args.high_reference).name}\'s high slots: {hok}')
    ch = collections.Counter(chk_px)
    lo = sum(c for i, c in ch.items() if i < 16)
    hi = sum(c for i, c in ch.items() if i >= 16)
    print(f'pixels using indices 0-15: {lo}')
    print(f'pixels using indices 16-31: {hi} '
          f'({100*hi/(lo+hi):.1f}% - need the 5th bitplane to display)')

    # per-pixel appearance check against the quantized source
    changed = sum(1 for s, d in zip(pixels, chk_px)
                  if lvl_to_rgb8(idx_lvl[s]) != lvl_to_rgb8(rgb8_to_lvl(*chk_pal[d])))
    print(f'pixels whose colour changed (vs quantized source): {changed}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
