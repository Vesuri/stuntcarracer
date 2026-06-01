#!/usr/bin/env python3
"""Re-encode modified PNGs into self-describing image files for the WHDLoad
slave to load as alternative graphics.

16-colour format (flag bit 6 = 0):

    offset 0   1 byte    flag      $80 = RLE, $00 = raw word-interleaved
    offset 1   1 byte    padding
    offset 2   32 bytes  palette   16 big-endian $0RGB words
    offset 34  variable  data      RLE (decompressRLEImage) or 32000 bytes raw

32-colour format (flag bit 6 = 1, i.e. $C0 = RLE):

    offset 0   1 byte    flag      $C0 (RLE + 32-colour)
    offset 1   1 byte    padding
    offset 2   32 bytes  palette   colours  0-15 ($0RGB words)
    offset 34  32 bytes  palette   colours 16-31 ($0RGB words)
    offset 66  variable  4-plane RLE data   (decompressRLEImage, planes 0-3)
    after      variable  1-plane RLE data   (decompressRLEBitplane, plane 4)

The game detects 32-colour by testing bit 6 of the flag byte.  The data
pointer written to replacementImagePtrs is block+$42 for 32-colour so that
palette-low starts at ptr-$40 and palette-high at ptr-$20 (matching the
ptr-$20 convention the display sites use to locate the palette).
"""

import argparse
import struct
import sys
import zlib
from pathlib import Path

WIDTH = 320
HEIGHT = 200
ROW_BYTES = WIDTH // 8                       # 40
BITPLANE_BYTES = ROW_BYTES * HEIGHT           # 8000
NUM_BITPLANES = 4
IMAGE_BYTES = NUM_BITPLANES * BITPLANE_BYTES  # 32000

MAX_COLORS_16 = 16
MAX_COLORS_32 = 32

IMAGE_NAMES = [
    'imageMainGameBackground',
    'imageMenuScreen',
    'imageTrackPreviewBackground',
    'imageStandingsBackground',
    'imagePlayers',
    'imageWreck',
    'imageWon',
    'imageLost',
    'imagePromotion',
]

# imageMenuScreen must be raw (flag=$00) because the menu cursor renderer
# blits sub-regions directly from the raw word-interleaved image data in
# memory. RLE-compressed replacements cannot be used for this purpose.
ALWAYS_RAW = frozenset({'imageMenuScreen', 'imagePlayers'})


# ---------------------------------------------------------------------------
# Minimal PNG reader (indexed-color, 1/2/4/8 bit depth)
# ---------------------------------------------------------------------------

def _unfilter(filter_type, line, prev, bpp):
    n = len(line)
    if filter_type == 0:
        return bytes(line)
    out = bytearray(n)
    for i in range(n):
        a = out[i - bpp] if i >= bpp else 0
        b = prev[i] if prev else 0
        c = prev[i - bpp] if (prev and i >= bpp) else 0
        x = line[i]
        if filter_type == 1:
            out[i] = (x + a) & 0xFF
        elif filter_type == 2:
            out[i] = (x + b) & 0xFF
        elif filter_type == 3:
            out[i] = (x + ((a + b) >> 1)) & 0xFF
        elif filter_type == 4:
            p = a + b - c
            pa = abs(p - a); pb = abs(p - b); pc = abs(p - c)
            pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            out[i] = (x + pr) & 0xFF
        else:
            raise ValueError(f"unknown PNG filter type {filter_type}")
    return bytes(out)


def _read_indexed_png_raw(path):
    """Read a 320x200 indexed-color PNG. Returns (pixels, palette) where pixels
    is bytes of length 320*200 with raw palette indices and palette is a list of
    (r,g,b) tuples (0..255)."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG file")

    width = height = depth = ctype = None
    palette = None
    idat_parts = []
    pos = 8
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        chunk_data = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if tag == b"IHDR":
            width, height, depth, ctype, _c, _f, interlace = struct.unpack(
                ">IIBBBBB", chunk_data)
            if interlace:
                raise ValueError(f"{path}: interlaced PNGs are not supported")
        elif tag == b"PLTE":
            palette = [(chunk_data[i], chunk_data[i + 1], chunk_data[i + 2])
                       for i in range(0, len(chunk_data), 3)]
        elif tag == b"IDAT":
            idat_parts.append(chunk_data)
        elif tag == b"IEND":
            break

    if (width, height) != (WIDTH, HEIGHT):
        raise ValueError(f"{path}: expected {WIDTH}x{HEIGHT}, got {width}x{height}")
    if ctype != 3:
        raise ValueError(f"{path}: expected indexed-color PNG (color_type 3), got {ctype}")
    if depth not in (1, 2, 4, 8):
        raise ValueError(f"{path}: unsupported bit depth {depth}")
    if palette is None:
        raise ValueError(f"{path}: missing PLTE chunk")
    raw = zlib.decompress(b"".join(idat_parts))
    bytes_per_scanline = (width * depth + 7) // 8
    prev = b""
    pixels = bytearray()
    p = 0
    for _y in range(height):
        ftype = raw[p]; p += 1
        line = raw[p:p + bytes_per_scanline]; p += bytes_per_scanline
        unfiltered = _unfilter(ftype, line, prev, 1)
        prev = unfiltered
        if depth == 8:
            pixels.extend(unfiltered)
        else:
            mask = (1 << depth) - 1
            ppb = 8 // depth
            row = bytearray()
            for byte in unfiltered:
                for sub in range(ppb):
                    shift = 8 - depth * (sub + 1)
                    row.append((byte >> shift) & mask)
            pixels.extend(row[:width])
    if len(pixels) != width * height:
        raise ValueError(f"{path}: pixel count mismatch ({len(pixels)} vs {width*height})")
    return bytes(pixels), palette


def read_indexed_png(path, *, max_colors=MAX_COLORS_16):
    """Read a 320x200 indexed PNG, enforcing a colour-count limit.
    Returns (pixels, palette) with the palette padded to max_colors entries."""
    pixels, palette = _read_indexed_png_raw(path)
    if any(p >= max_colors for p in pixels):
        raise ValueError(
            f"{path}: pixel index >= {max_colors} "
            f"(image uses more than {max_colors} colours)"
        )
    while len(palette) < max_colors:
        palette.append((0, 0, 0))
    return bytes(pixels), palette


# ---------------------------------------------------------------------------
# Palette: 8-bit RGB -> 4-bit Amiga ($0RGB before copyPaletteToCopperlist)
# ---------------------------------------------------------------------------

_EXPANDED_LEVELS = (0x00, 0x33, 0x55, 0x77, 0x99, 0xBB, 0xDD, 0xFF)


def _quantize_channel(byte):
    return min(7, max(0, (byte + 18) // 36))


def rgb_palette_to_amiga(palette, *, warn_label=None):
    """Convert 16 (r,g,b) tuples to 32 bytes of $0RGB palette words."""
    out = bytearray(32)
    warned = False
    for i, (r, g, b) in enumerate(palette[:16]):
        rn = _quantize_channel(r); gn = _quantize_channel(g); bn = _quantize_channel(b)
        if warn_label and not warned:
            expected = (_EXPANDED_LEVELS[rn], _EXPANDED_LEVELS[gn], _EXPANDED_LEVELS[bn])
            if (r, g, b) != expected:
                print(f"  note: {warn_label} color {i} #{r:02x}{g:02x}{b:02x} "
                      f"quantized to #{expected[0]:02x}{expected[1]:02x}{expected[2]:02x} "
                      f"(further mismatches suppressed)", file=sys.stderr)
                warned = True
        word = (rn << 8) | (gn << 4) | bn
        out[i * 2] = (word >> 8) & 0xFF
        out[i * 2 + 1] = word & 0xFF
    return bytes(out)


# ---------------------------------------------------------------------------
# Bitplane packing
# ---------------------------------------------------------------------------

def indexed_to_planar(pixels, num_planes=NUM_BITPLANES):
    """One byte per pixel -> num_planes contiguous bitplanes of 8000 bytes each."""
    out = bytearray(BITPLANE_BYTES * num_planes)
    for y in range(HEIGHT):
        row_off = y * ROW_BYTES
        in_off = y * WIDTH
        for byte_idx in range(ROW_BYTES):
            planes = [0] * num_planes
            base = in_off + byte_idx * 8
            for bit in range(8):
                pixel = pixels[base + bit]
                m = 0x80 >> bit
                for p in range(num_planes):
                    if pixel & (1 << p):
                        planes[p] |= m
            for p in range(num_planes):
                out[p * BITPLANE_BYTES + row_off + byte_idx] = planes[p]
    return bytes(out)


def planar_to_interleaved(planar):
    """4-bitplane planar -> word-interleaved (bp0, bp1, bp2, bp3 per word group)."""
    out = bytearray(IMAGE_BYTES)
    words_per_plane = BITPLANE_BYTES // 2
    dst = 0
    for i in range(words_per_plane):
        src = i * 2
        for bp in range(NUM_BITPLANES):
            out[dst]     = planar[bp * BITPLANE_BYTES + src]
            out[dst + 1] = planar[bp * BITPLANE_BYTES + src + 1]
            dst += 2
    return bytes(out)


# ---------------------------------------------------------------------------
# RLE encoder (inverse of decompressRLEImage in StuntCarRacer.s:2758)
# ---------------------------------------------------------------------------

def encode_rle_segment(segment):
    """Encode a 40-byte row-of-one-bitplane into RLE packets.

    Packet formats (must match decompressRLEImage):
      ctrl 0x00..0x7F : (ctrl+1) literal bytes follow
      ctrl 0x80       : no-op
      ctrl 0x81..0xFF : run of ((256 - ctrl) + 1) copies of the next byte
    Max literal run = 128 bytes, max RLE run = 128 bytes."""
    out = bytearray()
    n = len(segment)
    i = 0
    while i < n:
        run = 1
        while run < 128 and i + run < n and segment[i + run] == segment[i]:
            run += 1
        if run >= 3:
            out.append((257 - run) & 0xFF)
            out.append(segment[i])
            i += run
            continue
        start = i
        while i < n and (i - start) < 128:
            if i != start and i + 3 <= n and segment[i] == segment[i + 1] == segment[i + 2]:
                break
            i += 1
        lit_len = i - start
        out.append(lit_len - 1)
        out.extend(segment[start:i])
    return bytes(out)


def encode_rle(planar, num_planes=NUM_BITPLANES):
    """Encode planar image data in row-major, bitplane-inner order."""
    out = bytearray()
    for row in range(HEIGHT):
        for bp in range(num_planes):
            seg_start = bp * BITPLANE_BYTES + row * ROW_BYTES
            out.extend(encode_rle_segment(planar[seg_start:seg_start + ROW_BYTES]))
    return bytes(out)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def build_one(image_path, name, *, raw):
    """Build a 16-colour self-describing image block."""
    pixels, palette = read_indexed_png(image_path, max_colors=MAX_COLORS_16)
    pal_bytes = rgb_palette_to_amiga(palette[:16], warn_label=image_path.stem)
    planar = indexed_to_planar(pixels, num_planes=4)
    use_raw = raw or (name in ALWAYS_RAW)
    if use_raw:
        flag = 0x00
        data = planar_to_interleaved(planar)
    else:
        flag = 0x80
        data = encode_rle(planar, num_planes=4)
    return bytes([flag, 0]) + pal_bytes + data


def build_one_32(image_path):
    """Build a 32-colour self-describing image block (flag=$C0, RLE only).

    Block layout (total header = $42 bytes):
      [0]     flag $C0  (bit7=RLE, bit6=32-colour)
      [1]     pad  $00
      [2..33] palette colours  0-15 (16 words)
      [34..65] palette colours 16-31 (16 words)
      [66..]  4-plane RLE data  (decompressRLEImage, planes 0-3)
              1-plane RLE data  (decompressRLEBitplane, plane 4)

    The slave writes block+$42 as the data pointer so that:
      ptr - $40 = colours 0-15 palette start
      ptr - $20 = colours 16-31 palette start
    """
    pixels, palette = read_indexed_png(image_path, max_colors=MAX_COLORS_32)
    pal_low  = rgb_palette_to_amiga(palette[:16],    warn_label=image_path.stem)
    pal_high = rgb_palette_to_amiga(palette[16:32])
    planar5  = indexed_to_planar(pixels, num_planes=5)
    rle_4    = encode_rle(planar5, num_planes=4)     # planes 0-3
    plane4   = planar5[4 * BITPLANE_BYTES:]          # plane 4 data (8000 bytes)
    rle_5    = encode_rle(plane4, num_planes=1)      # plane 4 only
    return bytes([0xC0, 0]) + pal_low + pal_high + rle_4 + rle_5


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--input-dir", default="images",
                    help="Directory with the modified PNG files (default: images)")
    ap.add_argument("--output-dir", default="gfx",
                    help="Directory to write the per-image data files (default: gfx)")
    ap.add_argument("--raw", action="store_true",
                    help="Emit raw word-interleaved bitplanes (flag=$00) instead "
                         "of RLE-compressed data. Fixed 32034-byte payload. "
                         "imageMenuScreen is always built raw regardless of this flag.")
    ap.add_argument("--32", dest="colors32", action="store_true",
                    help="Build a 32-colour (5-bitplane) image block (flag=$C0). "
                         "The source PNG must use at most 32 distinct palette indices. "
                         "Only valid with a single name=path argument.")
    ap.add_argument("images", nargs="*",
                    help="Image names to build, or name=path pairs to specify an "
                         "explicit source PNG (e.g. "
                         "imageMainGameBackground=images/wip/imageMainGameBackground_WIP_mockup.png). "
                         "Default: every image whose PNG exists in --input-dir.")
    args = ap.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Parse positional args: plain names vs name=path overrides
    overrides = {}   # name -> explicit Path
    plain_names = []
    for arg in args.images:
        if '=' in arg:
            name, _, path_str = arg.partition('=')
            if name not in IMAGE_NAMES:
                print(f"error: unknown image name '{name}'", file=sys.stderr)
                return 1
            overrides[name] = Path(path_str)
        else:
            plain_names.append(arg)

    selected = set(plain_names) | set(overrides) if (plain_names or overrides) else None
    built = []
    for name in IMAGE_NAMES:
        if selected is not None and name not in selected:
            continue
        if name in overrides:
            png_path = overrides[name]
        else:
            png_path = input_dir / f"{name}.png"
        if not png_path.exists():
            if selected is not None:
                print(f"error: {png_path} not found", file=sys.stderr)
                return 1
            continue
        try:
            if args.colors32:
                payload = build_one_32(png_path)
            else:
                payload = build_one(png_path, name, raw=args.raw)
        except Exception as exc:
            print(f"failed {name}: {exc}", file=sys.stderr)
            return 1
        out_path = output_dir / name
        out_path.write_bytes(payload)
        built.append((name, len(payload)))

    if not built:
        print("nothing built", file=sys.stderr)
        return 1
    if args.colors32:
        fmt = "32-colour RLE"
    elif args.raw:
        fmt = "raw"
    else:
        fmt = "RLE"
    print(f"built {len(built)} image file(s) in {output_dir} "
          f"({fmt}, always-raw: {', '.join(sorted(ALWAYS_RAW))}):")
    for name, size in built:
        print(f"  {name:32}  {size:>6} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
