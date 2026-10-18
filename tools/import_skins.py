"""Imports Pac-Man skins drawn in Aseprite into the game.

Usage:  python3 tools/import_skins.py ~/Documents/Sprites

Each .ase file is one 128x256 image: a 4x8 grid of 32x32 cells.
  rows 0-3 = facing right, left, up, down; column 0 = mouth half open, column 1 = wide open
  column 2, row 0 = mouth closed
  column 3 = the death animation, top to bottom (empty cells at the end are ignored)

For every skin this writes, into entities/pacman/skins/:
  <id>.png          the in-game sheet: 16x16 cells in the same layout as entities/pacman/pacman.png,
                    the body scaled to BODY_SIZE pixels
                    (0 lives icon | 1 closed | 2,3 right | 4,5 left | 6,7 up | 8,9 down | 10.. death)
  <id>_preview.png  full size 32x32 frames for the character select screen (closed, half, wide; facing right)

Only the Python standard library is needed (no Aseprite, no Pillow).
"""
import os
import struct
import sys
import zlib

# .ase file name -> skin id used by the game (see entities/pacman/pacman_skins.gd)
SKINS = {
    'yippie': 'stylish',
    'pumpkin': 'hallopac',
    'shark': 'sharkpac',
    'spiderman_pacman': 'spideypac',
}
# Fixes for cells that are in the wrong place in a source file: {file name: [(cell, cell), ...]}
# swaps the two cells. spiderman_pacman.ase has its wide-open up/down frames swapped; delete the
# entry once the art itself is fixed.
SWAPPED_CELLS = {
    'spiderman_pacman': [((1, 2), (1, 3))],
}
# In-game size (pixels) of a skin's body: its closed + moving frames are scaled to fit this square,
# centred where the classic Pac-Man sits. The classic one is 13px, but outlined art looks smaller
# against the black maze, so custom skins get a little more.
BODY_SIZE = 15
GAME_CELL = 16
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'entities', 'pacman', 'skins')
CELL = 32


class Image:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = bytearray(w * h * 4)

    def get(self, x, y):
        i = (y * self.w + x) * 4
        return self.px[i:i + 4]

    def set(self, x, y, rgba):
        i = (y * self.w + x) * 4
        self.px[i:i + 4] = bytes(rgba)

    def cell(self, col, row, size=CELL):
        out = Image(size, size)
        for y in range(size):
            for x in range(size):
                out.set(x, y, self.get(col * size + x, row * size + y))
        return out

    def is_empty(self):
        return not any(self.px[3::4])

    def paste(self, img, x0, y0):
        for y in range(img.h):
            for x in range(img.w):
                self.set(x0 + x, y0 + y, img.get(x, y))

    def save(self, path):
        raw = b''.join(b'\x00' + bytes(self.px[y * self.w * 4:(y + 1) * self.w * 4]) for y in range(self.h))

        def chunk(tag, data):
            return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
        with open(path, 'wb') as f:
            f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', self.w, self.h, 8, 6, 0, 0, 0))
                    + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def read_ase(path):
    """Reads a single-frame RGBA .ase file (all visible layers flattened, compressed cels)."""
    d = open(path, 'rb').read()
    _, magic, frames, w, h, depth = struct.unpack('<IHHHHH', d[:14])
    if magic != 0xA5E0 or depth != 32:
        raise ValueError(f'{path}: not a 32-bit RGBA Aseprite file')
    img = Image(w, h)
    off = 128
    _, _, old_chunks, _ = struct.unpack('<IHHH', d[off:off + 10])
    chunks = struct.unpack('<I', d[off + 12:off + 16])[0] or old_chunks
    off += 16
    for _ in range(chunks):
        size, kind = struct.unpack('<IH', d[off:off + 6])
        if kind == 0x2005:  # cel
            _, x, y, _, cel_type = struct.unpack('<HhhBH', d[off + 6:off + 15])
            if cel_type == 2:  # compressed image
                cw, ch = struct.unpack('<HH', d[off + 22:off + 26])
                px = zlib.decompress(d[off + 26:off + size])
                for row in range(ch):
                    for col in range(cw):
                        i = (row * cw + col) * 4
                        if px[i + 3] and 0 <= x + col < w and 0 <= y + row < h:
                            img.set(x + col, y + row, px[i:i + 4])
        off += size
    return img


def used_rect(img):
    xs = [x for y in range(img.h) for x in range(img.w) if img.get(x, y)[3]]
    ys = [y for y in range(img.h) for x in range(img.w) if img.get(x, y)[3]]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1) if xs else None


def resample(img, origin, scale):
    """Scales a 32px frame down to a 16px game cell. Game pixel (x, y) shows the source area
    starting at origin + (x, y) * scale: the average colour of its solid pixels (weighted by how
    much of each one it covers), or transparent if less than half of the area is solid. Keeps
    pixel-art edges crisp at any scale."""
    out = Image(GAME_CELL, GAME_CELL)
    for ty in range(GAME_CELL):
        for tx in range(GAME_CELL):
            x0, y0 = origin[0] + tx * scale, origin[1] + ty * scale
            x1, y1 = x0 + scale, y0 + scale
            total = solid = 0.0
            rgb = [0.0, 0.0, 0.0]
            for sy in range(int(y0), int(y1) + 1):
                for sx in range(int(x0), int(x1) + 1):
                    w = max(0.0, min(x1, sx + 1) - max(x0, sx)) * max(0.0, min(y1, sy + 1) - max(y0, sy))
                    if w <= 0:
                        continue
                    total += w
                    if 0 <= sx < img.w and 0 <= sy < img.h:
                        p = img.get(sx, sy)
                        if p[3] >= 128:
                            solid += w
                            for c in range(3):
                                rgb[c] += p[c] * w
            if total and solid / total >= 0.5:
                out.set(tx, ty, [round(v / solid) for v in rgb] + [255])
    return out


def import_skin(src, skin_id):
    sheet = read_ase(src)
    for a, b in SWAPPED_CELLS.get(os.path.basename(src)[:-4], []):
        cell_a, cell_b = sheet.cell(*a), sheet.cell(*b)
        sheet.paste(cell_b, a[0] * CELL, a[1] * CELL)
        sheet.paste(cell_a, b[0] * CELL, b[1] * CELL)
    death = []
    for row in range(sheet.h // CELL):
        frame = sheet.cell(3, row)
        if not frame.is_empty():
            death.append(frame)
    # (col, row) of the 32px source cell for each 16px game cell
    layout = [(0, 1), (2, 0), (0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2), (0, 3), (1, 3)]
    # scale so the body (all closed + moving frames together) is BODY_SIZE game pixels, centred on
    # the classic Pac-Man's centre; death frames use the same scale and position
    rects = [used_rect(sheet.cell(col, row)) for col, row in layout]
    left, top = min(r[0] for r in rects), min(r[1] for r in rects)
    right, bottom = max(r[2] for r in rects), max(r[3] for r in rects)
    size = max(right - left, bottom - top)
    scale = size / BODY_SIZE
    centre = ((left + right) / 2, (top + bottom) / 2)
    origin = (centre[0] - 7.5 * scale, centre[1] - 7.5 * scale)
    game = Image((len(layout) + len(death)) * GAME_CELL, GAME_CELL)
    for i, (col, row) in enumerate(layout):
        game.paste(resample(sheet.cell(col, row), origin, scale), i * GAME_CELL, 0)
    for i, frame in enumerate(death):
        game.paste(resample(frame, origin, scale), (len(layout) + i) * GAME_CELL, 0)
    game.save(os.path.join(OUT_DIR, f'{skin_id}.png'))

    preview = Image(3 * CELL, CELL)
    for i, (col, row) in enumerate([(2, 0), (0, 0), (1, 0)]):
        preview.paste(sheet.cell(col, row), i * CELL, 0)
    preview.save(os.path.join(OUT_DIR, f'{skin_id}_preview.png'))
    print(f'{os.path.basename(src)} -> {skin_id}: {len(death)} death frames')


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, skin_id in SKINS.items():
        src = os.path.join(sys.argv[1], name + '.ase')
        if not os.path.exists(src):
            print(f'missing {src}, skipped')
            continue
        import_skin(src, skin_id)


if __name__ == '__main__':
    main()
