#!/usr/bin/env python3
"""Scale a high-resolution artwork down to 320x200 and quantize it to 32 Amiga
colours, with two constraints the game imposes:

  * indices 0-15 are PINNED to a fixed palette (an image's original palette, so
    everything the game draws by index keeps its intended colour),
  * inside one or more PROTECTED RECTANGLES only indices 0-15 may be used,
    because the game draws over those areas in 4 bitplanes and cannot control
    the 5th plane there.

Indices 16-31 are chosen freely, optimized for the pixels that are allowed to
use them (i.e. everything outside the protected rectangles).  The Amiga's
reproducible colour space is 16x16x16 = 4096 colours (512 with --9bit), so
instead of a k-means with a lossy snap afterwards the tool searches that whole
space directly: each free slot goes to the ladder colour that reduces the total
weighted error the most, given the pinned palette and the slots picked so far.

The output is an 8-bit indexed PNG ready for `build_images.py --32`.

Track preview example (the protected rectangle is the 3-D viewport, applied
automatically for this image name):

  python3 tools/quantize_artwork.py --image imageTrackPreviewBackground \\
      images/enhanced/imageTrackPreviewBackground_chatgpt.png \\
      images/enhanced/imageTrackPreviewBackground_32c.png
  python3 tools/build_images.py --32 \\
      'imageTrackPreviewBackground=images/enhanced/imageTrackPreviewBackground_32c.png'

See enhanced-graphics.md for each screen's protected regions and reserved
palette slots.
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_images import WIDTH, HEIGHT                              # noqa: E402
from remap_to_original_palette import (                             # noqa: E402
    BIN_DEFAULT,
    ORIGINAL_PALETTE_OFFSETS,
    expand,
    lvl_to_rgb8,
    q,
    read_original_palette,
    write_png_indexed8,
)

# Regions the game draws into with 4 bitplanes only, so the 5th plane must stay
# clear there and the artwork must keep to indices 0-15.  (x, y, w, h).
#   imageTrackPreviewBackground: the 3-D track-preview viewport.  Origin is
#   viewportTopAddress = renderFrameBuffer+$284 -> x 32, y 16; the renderer
#   clips to X 0..255 / Y 0..127 (drawClippedLine, renderTrackNear), and
#   clearPlane5Rect (StuntCarRacer.s:2498) blanks plane 4 there at screen entry.
PROTECTED_RECTS = {
    'imageTrackPreviewBackground': [(32, 16, 256, 128)],
}

# Perceptual weights for the squared-error metric (ITU-R BT.601 luma).
CHANNEL_WEIGHTS = np.array([0.299, 0.587, 0.114], dtype=np.float64)

RESAMPLE = {
    'lanczos': Image.LANCZOS,
    'bicubic': Image.BICUBIC,
    'bilinear': Image.BILINEAR,
    'box': Image.BOX,
}


def snap_to_ladder(rgb, bits12=True):
    """Snap 8-bit RGB to the reproducible Amiga levels per channel.

    12-bit: 16 levels, the multiples of 17.  9-bit: the original eight-value
    ladder that copyPaletteToCopperlist expands to.
    """
    arr = np.atleast_2d(np.asarray(rgb, dtype=np.float64))
    out = np.empty_like(arr)
    for i in range(arr.shape[0]):
        for c in range(3):
            v = int(round(min(255, max(0, arr[i, c]))))
            if bits12:
                out[i, c] = min(15, max(0, (v + 8) // 17)) * 17
            else:
                e = expand(q(v))
                out[i, c] = (e << 4) | e
    return out


def weighted_sqdist(pixels, palette):
    """(N,3) x (K,3) -> (N,K) weighted squared distances."""
    diff = pixels[:, None, :] - palette[None, :, :]
    return np.einsum('nkc,c->nk', diff * diff, CHANNEL_WEIGHTS)


def nearest(pixels, palette, chunk=8192):
    """Index of the nearest palette entry for each pixel, plus its distance."""
    idx = np.empty(len(pixels), dtype=np.int32)
    dist = np.empty(len(pixels), dtype=np.float64)
    for start in range(0, len(pixels), chunk):
        block = pixels[start:start + chunk]
        d = weighted_sqdist(block, palette)
        idx[start:start + chunk] = np.argmin(d, axis=1)
        dist[start:start + chunk] = np.min(d, axis=1)
    return idx, dist


def ladder_colors(bits12=True):
    """Every colour the Amiga palette can reproduce, as 8-bit RGB.

    12-bit (the hardware's real COLORxx width): 16 levels per channel, the
    multiples of 17, giving 4096 colours.  9-bit (the original Atari-ST-derived
    data format): 8 levels per channel, 512 colours.
    """
    if bits12:
        levels = [n * 17 for n in range(16)]
    else:
        levels = [((expand(n) << 4) | expand(n)) for n in range(8)]
    return np.array([(r, g, b) for r in levels for g in levels for b in levels],
                    dtype=np.float64)


def _sqdist_block(block, cand_w, cand_sq):
    """Weighted squared distance for one pixel block against all candidates.

    Expanded as |p|^2 - 2 p.q + |q|^2 so the inner term is a single GEMM; the
    naive (N,K,3) broadcast needs 3x the memory and is far slower once K is
    4096 rather than 512.  The constant |p|^2 is dropped -- it is the same for
    every candidate, and both callers only compare across candidates.
    """
    return cand_sq[None, :] - 2.0 * (block @ cand_w.T)


def choose_high_colors(pixels, low, count, verbose=True, bits12=True):
    """Greedily fill `count` free slots from the reproducible colour space.

    Each round picks the candidate with the largest total error reduction over
    `pixels` -- i.e. sum over pixels of max(0, current_error - error_with_c).
    Pixels the pinned palette already serves well contribute nothing, so the
    free slots go where the fixed 16 fall short.  Stops early if no remaining
    candidate improves anything.
    """
    if count <= 0 or len(pixels) == 0:
        return np.zeros((0, 3), dtype=np.float64)

    candidates = ladder_colors(bits12)
    have = {tuple(int(v) for v in c) for c in low}
    keep = np.array([tuple(int(v) for v in c) not in have for c in candidates])
    candidates = candidates[keep]

    # Precomputing the full (pixels x candidates) distance matrix would need
    # ~1 GB at 4096 candidates, so recompute it in blocks each round instead.
    w = CHANNEL_WEIGHTS
    cand_w = candidates * w
    cand_sq = (candidates * candidates * w).sum(axis=1)
    pix_sq = (pixels * pixels * w).sum(axis=1)
    BLOCK = 8192

    _, err = nearest(pixels, low)
    if verbose:
        print(f'  pinned 0-15 alone: error {err.mean():8.1f}')
    chosen = []
    alive = np.ones(len(candidates), dtype=bool)
    for _ in range(count):
        gains = np.zeros(len(candidates), dtype=np.float64)
        for start in range(0, len(pixels), BLOCK):
            block = pixels[start:start + BLOCK]
            d = _sqdist_block(block, cand_w, cand_sq) + pix_sq[start:start + BLOCK, None]
            np.add(gains, np.maximum(0.0, err[start:start + BLOCK, None] - d).sum(axis=0),
                   out=gains)
        gains[~alive] = -np.inf
        best = int(np.argmax(gains))
        if gains[best] <= 0:
            break
        chosen.append(candidates[best])
        alive[best] = False
        # Fold the winner into the running error.
        one = candidates[best:best + 1]
        for start in range(0, len(pixels), BLOCK):
            block = pixels[start:start + BLOCK]
            d = weighted_sqdist(block, one)[:, 0]
            np.minimum(err[start:start + BLOCK], d, out=err[start:start + BLOCK])
        if verbose:
            r, g, b = (int(v) for v in candidates[best])
            print(f'  slot {16 + len(chosen) - 1:2d}: #{r:02x}{g:02x}{b:02x}'
                  f'  error now {err.mean():8.1f}')
    return np.array(chosen, dtype=np.float64) if chosen else np.zeros((0, 3))


def assign_plain(pixels, palette, allowed_mask):
    """Nearest-colour assignment, per-pixel restricted by `allowed_mask`."""
    out = np.empty(len(pixels), dtype=np.uint8)
    for allowed in (False, True):
        sel = allowed_mask == allowed
        if not sel.any():
            continue
        sub = palette if allowed else palette[:16]
        idx, _ = nearest(pixels[sel], sub)
        out[sel] = idx.astype(np.uint8)
    return out


def assign_dithered(pixels, palette, allowed_mask, width, height):
    """Floyd-Steinberg error diffusion honouring the per-pixel palette limit."""
    work = pixels.reshape(height, width, 3).astype(np.float64).copy()
    allowed = allowed_mask.reshape(height, width)
    out = np.zeros((height, width), dtype=np.uint8)
    w = CHANNEL_WEIGHTS
    for y in range(height):
        for x in range(width):
            old = work[y, x]
            sub = palette if allowed[y, x] else palette[:16]
            d = ((sub - old) ** 2 * w).sum(axis=1)
            k = int(np.argmin(d))
            out[y, x] = k
            err = old - sub[k]
            if x + 1 < width:
                work[y, x + 1] += err * (7 / 16)
            if y + 1 < height:
                if x:
                    work[y + 1, x - 1] += err * (3 / 16)
                work[y + 1, x] += err * (5 / 16)
                if x + 1 < width:
                    work[y + 1, x + 1] += err * (1 / 16)
    return out.reshape(-1)


def parse_rect(text):
    parts = [int(v) for v in text.replace(' ', '').split(',')]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError('rect must be X,Y,W,H')
    return tuple(parts)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('src')
    ap.add_argument('dst')
    low = ap.add_mutually_exclusive_group(required=True)
    low.add_argument('--image', choices=sorted(ORIGINAL_PALETTE_OFFSETS),
                     help="pin indices 0-15 to this image's original palette")
    low.add_argument('--low-reference', metavar='PNG',
                     help="pin indices 0-15 to the first 16 PLTE entries of PNG")
    ap.add_argument('--binary', default=BIN_DEFAULT,
                    help=f'decrypted game binary (default {BIN_DEFAULT})')
    ap.add_argument('--protect-rect', type=parse_rect, action='append',
                    metavar='X,Y,W,H',
                    help='region restricted to indices 0-15 (repeatable); '
                         'overrides the built-in default for --image')
    ap.add_argument('--no-protect', action='store_true',
                    help='ignore the built-in protected rectangle')
    ap.add_argument('--high-colors', type=int, default=16,
                    help='how many of slots 16-31 to fill (default 16)')
    ap.add_argument('--dither', choices=('none', 'fs'), default='none',
                    help='none (default, flat/RLE-friendly) or Floyd-Steinberg')
    ap.add_argument('--resample', choices=sorted(RESAMPLE), default='lanczos')
    ap.add_argument('--9bit', dest='ninebit', action='store_true',
                    help="Restrict the high slots to the original 512-colour "
                         "Atari-ST space instead of the Amiga's native 4096. "
                         "Match this to build_images.py --9bit.")
    ap.add_argument('--quiet', action='store_true',
                    help='do not list each chosen high colour')
    args = ap.parse_args()

    bits12 = not args.ninebit
    if args.high_colors < 0 or args.high_colors > 16:
        ap.error('--high-colors must be 0..16')

    # --- pinned low palette -------------------------------------------------
    if args.image:
        words = read_original_palette(args.binary,
                                     ORIGINAL_PALETTE_OFFSETS[args.image])
        low_rgb = [lvl_to_rgb8(w) for w in words]
        low_src = f'{args.binary} @ ${ORIGINAL_PALETTE_OFFSETS[args.image]:x}'
    else:
        ref = Image.open(args.low_reference)
        if ref.mode != 'P':
            ap.error(f'{args.low_reference}: not an indexed PNG')
        flat = ref.getpalette()[:48]
        low_rgb = [tuple(flat[i * 3:i * 3 + 3]) for i in range(16)]
        low_src = args.low_reference
    low = np.array(low_rgb, dtype=np.float64)
    off_ladder = [i for i, c in enumerate(low)
                  if tuple(int(v) for v in snap_to_ladder([c], bits12)[0]) !=
                  tuple(int(v) for v in c)]
    if off_ladder:
        print(f'  note: pinned palette entries {off_ladder} are not on the '
              f'Amiga level ladder; build_images.py will quantize them',
              file=sys.stderr)

    # --- protected rectangles ----------------------------------------------
    if args.protect_rect:
        rects = args.protect_rect
    elif args.no_protect:
        rects = []
    else:
        rects = PROTECTED_RECTS.get(args.image, [])

    # --- scale down --------------------------------------------------------
    src = Image.open(args.src).convert('RGB')
    src_aspect = src.width / src.height
    if abs(src_aspect - WIDTH / HEIGHT) > 0.02:
        print(f'  note: source aspect {src_aspect:.3f} differs from '
              f'{WIDTH / HEIGHT:.3f}; the image will be stretched',
              file=sys.stderr)
    scaled = src.resize((WIDTH, HEIGHT), RESAMPLE[args.resample])
    pixels = np.asarray(scaled, dtype=np.float64).reshape(-1, 3)

    allowed = np.ones(WIDTH * HEIGHT, dtype=bool)
    grid = allowed.reshape(HEIGHT, WIDTH)
    for (x, y, w, h) in rects:
        grid[y:y + h, x:x + w] = False

    print(f'source        : {args.src} ({src.width}x{src.height})')
    print(f'scaled to     : {WIDTH}x{HEIGHT} ({args.resample})')
    print(f'pinned  0-15  : {low_src}')
    for (x, y, w, h) in rects:
        print(f'protected rect: x {x}-{x + w - 1}, y {y}-{y + h - 1} '
              f'({w}x{h}) -> indices 0-15 only')
    free = int(allowed.sum())
    print(f'pixels able to use 16-31: {free} of {WIDTH * HEIGHT} '
          f'({100.0 * free / (WIDTH * HEIGHT):.1f}%)')

    # --- choose the free half of the palette -------------------------------
    high = choose_high_colors(pixels[allowed], low, args.high_colors,
                              verbose=not args.quiet, bits12=bits12)
    palette = np.vstack([low, high]) if len(high) else low
    print(f'high colours chosen: {len(high)}')

    # --- assign indices -----------------------------------------------------
    if args.dither == 'fs':
        idx = assign_dithered(pixels, palette, allowed, WIDTH, HEIGHT)
    else:
        idx = assign_plain(pixels, palette, allowed)

    # --- report + verify ----------------------------------------------------
    err = ((pixels - palette[idx]) ** 2 * CHANNEL_WEIGHTS).sum(axis=1)
    inside = ~allowed
    print(f'mean weighted error: overall {err.mean():8.1f}'
          + (f' | inside rect {err[inside].mean():8.1f}' if inside.any() else '')
          + (f' | outside {err[allowed].mean():8.1f}' if allowed.any() else ''))
    used = sorted(set(int(v) for v in idx))
    print(f'indices used  : {len(used)} ({used[0]}..{used[-1]})')
    if inside.any():
        bad = int((idx[inside] >= 16).sum())
        print(f'indices >=16 inside protected rects: {bad}')
        if bad:
            raise SystemExit('BUG: protected rectangle uses high indices')

    out_pal = [tuple(int(v) for v in c) for c in palette]
    while len(out_pal) < 32:
        out_pal.append((0, 0, 0))
    write_png_indexed8(args.dst, idx.tolist(), out_pal)
    print(f'wrote         : {args.dst} (32 PLTE entries)')


if __name__ == '__main__':
    main()
