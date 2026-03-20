from src.assembler.assembler import Mnemonics, Assembler, Instruction, RAM

# ── Setup ─────────────────────────────────────────────────────────────────────
ram = RAM()
M   = Mnemonics()
asm = Assembler("final_demo", ram)
A, B = Assembler.A, Assembler.B

# ── RAM Variables ─────────────────────────────────────────────────────────────
const_0    = ram.var(0x00, "const_0")
const_1    = ram.var(0x01, "const_1")
prev_x     = ram.var(0x00, "prev_x")
prev_y     = ram.var(0x00, "prev_y")
pixel_data = ram.var(0x00, "pixel_data: pixel value underneath cursor")

# ── ROM: start in IDLE ────────────────────────────────────────────────────────
asm.goto_idle("Start in IDLE mode")

# ── Mouse ISR ─────────────────────────────────────────────────────────────────
mouse_isr = asm.here()
asm.section_comment("Mouse ISR")

# X_ADDR/Y_ADDR in peripheral already point to previous cursor position
# Restore pixel underneath old cursor
asm.load(A, prev_x)
asm.store(A, M.vga_x)
asm.load(A, prev_y)
asm.store(A, M.vga_y)
asm.load(A, const_0)
asm.load(A, pixel_data,   "Load cached pixel")
asm.store(A, M.vga_pixel, "Restore at old X,Y - A_WE fires for 1 cycle")

# Move to new mouse position
asm.load(A, M.mouse_x,    "Load new MouseX")
asm.store(A, M.vga_x,     "Update X_ADDR in peripheral")
asm.store(A, prev_x)
asm.load(A, M.mouse_y,    "Load new MouseY")
asm.store(A, M.vga_y,     "Update Y_ADDR in peripheral")
asm.store(A, prev_y)

# Cache pixel underneath new cursor position
# Enough cycles have passed for A_DATA_OUT to settle
asm.load(A, M.vga_pixel,  "Read pixel at new X,Y")
asm.store(A, pixel_data,  "Cache it in RAM")

# Draw cursor
asm.load(A, const_1,      "Load 1")
asm.store(A, M.vga_pixel, "Draw cursor")

asm.goto_idle("End Mouse ISR")

# ── Timer ISR (stub) ──────────────────────────────────────────────────────────
timer_isr = asm.here()
asm.section_comment("Timer ISR")
asm.goto_idle("Nothing to do")

# ── Vector Table ──────────────────────────────────────────────────────────────
asm.pad_to(0xFE, "Pad to Vector Table")
asm.db(timer_isr, "0xFE: Timer ISR address")
asm.db(mouse_isr, "0xFF: Mouse ISR address")

asm.create_file("4.0")