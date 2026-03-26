import numpy as np
from math import ceil

# ── Letter bitmaps (7 rows × 5 cols) ─────────────────────────────────────────

F = np.array([
    [1,1,1,1,1],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,1,1,1,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
])

L = np.array([
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,1,1,1,1],
])

B = np.array([
    [1,1,1,1,0],
    [1,0,0,0,1],
    [1,0,0,0,1],
    [1,1,1,1,0],
    [1,0,0,0,1],
    [1,0,0,0,1],
    [1,1,1,1,0],
])

R = np.array([
    [1,1,1,1,0],
    [1,0,0,0,1],
    [1,0,0,0,1],
    [1,1,1,1,0],
    [1,0,1,0,0],
    [1,0,0,1,0],
    [1,0,0,0,1],
])

C = np.array([
    [0,1,1,1,0],
    [1,0,0,0,1],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,0],
    [1,0,0,0,1],
    [0,1,1,1,0],
])

# ── Helpers ───────────────────────────────────────────────────────────────────

def make_two_letter(left, right):
    """Combine two 7×5 letter bitmaps into a 7×11 block (with 1-col gap)."""
    gap = np.zeros((7, 1), dtype=int)
    return np.concatenate([left, gap, right], axis=1)

def place(matrix, glyph, cy, cx):
    """Place a glyph centred at row cy, col cx."""
    h, w = glyph.shape
    r0 = cy - h // 2
    c0 = cx - w // 2
    matrix[r0:r0+h, c0:c0+w] = glyph

# ── Build matrix ──────────────────────────────────────────────────────────────

matrix = np.zeros((120, 160), dtype=int)

# Dividing lines
matrix[:, ceil(160/3) - 1]   = 1   # col 53
matrix[:, ceil(2*160/3) - 1] = 1   # col 106
matrix[ceil(120/3) - 1, :]   = 1   # row 39
matrix[ceil(2*120/3) - 1, :] = 1   # row 79

# Zone centres
col_centres = [26, 79, 133]   # left, centre, right
row_centres = [19, 59, 99]    # top, mid, bot

# Labels: None means empty
labels = [
    [make_two_letter(F, L),  F,  make_two_letter(F, R)],
    [L,                      C,                    R],
    [make_two_letter(B, L),  B,  make_two_letter(B, R)],
]

for ri, cy in enumerate(row_centres):
    for ci, cx in enumerate(col_centres):
        glyph = labels[ri][ci]
        if glyph is not None:
            place(matrix, glyph, cy, cx)

# ── Write .mem file ───────────────────────────────────────────────────────────

with open("ascii.txt", "w") as f:
    for row in matrix:
        f.write("".join(str(int(v)) for v in row) + "\n")

with open("frame_init.mem", "w") as f:
    for row in matrix:
        for val in row:
            f.write(str(int(val)) + "\n")
