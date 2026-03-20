from src.assembler.assembler import Mnemonics, Assembler, Instruction, RAM

# ── Setup ─────────────────────────────────────────────────────────────────────
ram = RAM()
M   = Mnemonics()
asm = Assembler("final_demo", ram)
A, B = Assembler.A, Assembler.B

# ── RAM Variables ─────────────────────────────────────────────────────────────
const_0    = ram.var(0x00, "const_0")
const_1    = ram.var(0x01, "const_1")
pixel_data = ram.var(0x00, "pixel_data: Previous Pixel Data Cache")

# ── ROM: start in IDLE ────────────────────────────────────────────────────────
asm.goto_idle("Start in IDLE mode")

# ── Mouse ISR ─────────────────────────────────────────────────────────────────
mouse_isr = asm.here()
asm.section_comment("Mouse ISR")

# Restore old pixel underneath previous cursor position
asm.load(A, pixel_data,  "Load cached pixel value")
asm.store(A, M.vga_pixel, "Restore pixel at old X,Y")

# Move cursor to new mouse position
asm.load(A, M.mouse_x,   "Load MouseX from peripheral")
asm.store(A, M.vga_x,    "Set VGA X address")
asm.load(A, M.mouse_y,   "Load MouseY from peripheral")
asm.store(A, M.vga_y,    "Set VGA Y address")

# Cache pixel value underneath new cursor position
asm.load(A, M.vga_pixel,  "Read pixel at new X,Y")
asm.store(A, pixel_data,  "Cache it in RAM")

# Draw cursor
asm.load(A, const_1,      "Load 1")
asm.store(A, M.vga_pixel, "Draw cursor pixel")

asm.goto_idle("End of Mouse ISR")

# ── Timer ISR (stub) ──────────────────────────────────────────────────────────
timer_isr = asm.here()
asm.section_comment("Timer ISR")
asm.goto_idle("Nothing to do")

# ── Vector Table ──────────────────────────────────────────────────────────────
asm.pad_to(0xFE, "Pad to Vector Table")
asm.db(timer_isr, "0xFE: Timer ISR address")
asm.db(mouse_isr, "0xFF: Mouse ISR address")

asm.create_file("3.0")