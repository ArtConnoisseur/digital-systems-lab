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
const_40   = ram.var(0x28, "const_40:  Y threshold Backward  (MouseY < 40)")
const_53   = ram.var(0x35, "const_53:  X threshold Left      (MouseX < 53)")
const_79   = ram.var(0x4F, "const_79:  Y threshold Forward   (MouseY > 79)")
const_106  = ram.var(0x6A, "const_106: X threshold Right     (MouseX > 106)")
dir_fwd    = ram.var(0x00, "dir_fwd:   1 if MouseY > 79")
dir_bwd    = ram.var(0x00, "dir_bwd:   1 if MouseY < 40")
dir_left   = ram.var(0x00, "dir_left:  1 if MouseX < 53")
dir_rgt    = ram.var(0x00, "dir_rgt:   1 if MouseX > 106")
ir_cmd     = ram.var(0x00, "ir_cmd:    Accumulated IR command byte")

# 7-seg display codes: digit1=upper nibble, digit0=lower nibble
# 0xA=r  0xB=b  0xC=C  0xD=L  0xE=blank  0xF=F
disp_c     = ram.var(0xEC, "disp_c:  7-seg code for Centre    (_C)")
disp_f     = ram.var(0xEF, "disp_f:  7-seg code for Forward   (_F)")
disp_b     = ram.var(0xEB, "disp_b:  7-seg code for Backward  (_b)")
disp_r     = ram.var(0xEA, "disp_r:  7-seg code for Right     (_r)")
disp_l     = ram.var(0xED, "disp_l:  7-seg code for Left      (_L)")
disp_fr    = ram.var(0xFA, "disp_fr: 7-seg code for Fwd+Right (Fr)")
disp_fl    = ram.var(0xFD, "disp_fl: 7-seg code for Fwd+Left  (FL)")
disp_br    = ram.var(0xBA, "disp_br: 7-seg code for Bwd+Right (br)")
disp_bl    = ram.var(0xBD, "disp_bl: 7-seg code for Bwd+Left  (bL)")

# ── ROM: start in IDLE ────────────────────────────────────────────────────────
asm.goto_idle("Start in IDLE mode")

# ── Mouse ISR ─────────────────────────────────────────────────────────────────
mouse_isr = asm.here()
asm.section_comment("Mouse ISR")

asm.load(A, pixel_data,   "Load cached pixel value")
asm.store(A, M.vga_pixel, "Restore pixel at old X,Y")

asm.load(A, M.mouse_x,   "Load MouseX from peripheral")
asm.store(A, M.vga_x,    "Set VGA X address")
asm.load(A, M.mouse_y,   "Load MouseY from peripheral")
asm.store(A, M.vga_y,    "Set VGA Y address")

asm.load(A, M.vga_pixel,  "Read pixel at new X,Y")
asm.store(A, pixel_data,  "Cache it in RAM")

asm.load(A, const_1,      "Load 1")
asm.store(A, M.vga_pixel, "Draw cursor pixel")

asm.goto_idle("End of Mouse ISR")

# ── Timer ISR ─────────────────────────────────────────────────────────────────
timer_isr = asm.here()
asm.section_comment("Timer ISR")

# Step 1: Compute direction flags from mouse position
asm.load(A, M.mouse_y,  "Load MouseY")
asm.load(B, const_40,   "Load 40")
asm.lt(A,               "A = (MouseY < 40)")
asm.store(A, dir_fwd,   "Store DirForward (Y small = Forward)")

asm.load(A, M.mouse_y,  "Load MouseY")
asm.load(B, const_79,   "Load 79")
asm.gt(A,               "A = (MouseY > 79)")
asm.store(A, dir_bwd,   "Store DirBackward (Y large = Backward)")

asm.load(A, M.mouse_x,  "Load MouseX")
asm.load(B, const_53,   "Load 53")
asm.lt(A,               "A = (MouseX < 53)")
asm.store(A, dir_left,  "Store DirLeft")

asm.load(A, M.mouse_x,  "Load MouseX")
asm.load(B, const_106,  "Load 106")
asm.gt(A,               "A = (MouseX > 106)")
asm.store(A, dir_rgt,   "Store DirRight")

# Step 2: Build IR command = {Forward(b3), Backward(b2), Left(b1), Right(b0)}
asm.load(A, dir_rgt,    "Load DirRight (bit 0)")
asm.store(A, ir_cmd,    "ir_cmd = DirRight")

asm.load(A, dir_left,   "Load DirLeft")
asm.shift_left(         "A <<= 1  (bit 1)")
asm.load(B, ir_cmd,     "Load ir_cmd")
asm.add(A,              "A |= DirLeft<<1")
asm.store(A, ir_cmd,    "Save ir_cmd")

asm.load(A, dir_bwd,    "Load DirBackward")
asm.shift_left(         "A <<= 1")
asm.shift_left(         "A <<= 1  (bit 2)")
asm.load(B, ir_cmd,     "Load ir_cmd")
asm.add(A,              "A |= DirBackward<<2")
asm.store(A, ir_cmd,    "Save ir_cmd")

asm.load(A, dir_fwd,    "Load DirForward")
asm.shift_left(         "A <<= 1")
asm.shift_left(         "A <<= 1")
asm.shift_left(         "A <<= 1  (bit 3)")
asm.load(B, ir_cmd,     "Load ir_cmd")
asm.add(A,              "A |= DirForward<<3")
asm.store(A, M.ir_base, "Write IR command to peripheral 0x90")

# Step 3: Region detection -> write display code to 7-seg (0xD0)
# digit1=upper nibble, digit0=lower nibble; 0xA=r 0xB=b 0xC=C 0xD=L 0xE=blank 0xF=F
asm.load(A, dir_fwd,    "Check DirForward")
asm.load(B, const_1,    "Load 1")
b_is_fwd  = asm.reserve_branch("breq", "if Fwd goto IS_FORWARD")

asm.load(A, dir_bwd,    "Check DirBackward")
asm.load(B, const_1,    "Load 1")
b_is_bwd  = asm.reserve_branch("breq", "if Bwd goto IS_BACKWARD")

# Centre row: check horizontal
asm.load(A, dir_rgt,    "Check DirRight")
asm.load(B, const_1,    "Load 1")
b_ctr_rgt = asm.reserve_branch("breq", "Centre+Right -> _r")

asm.load(A, dir_left,   "Check DirLeft")
asm.load(B, const_1,    "Load 1")
b_ctr_lft = asm.reserve_branch("breq", "Centre+Left  -> _L")

# Centre: _C
asm.load(A, disp_c,           "Load display code 0xEC (_C)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# IS_FORWARD
asm.patch(b_is_fwd, asm.here())
asm.section_comment("IS_FORWARD")
asm.load(A, dir_left,   "Check DirLeft")
asm.load(B, const_1,    "Load 1")
b_fwd_lft = asm.reserve_branch("breq", "Fwd+Left  -> FL")

asm.load(A, dir_rgt,    "Check DirRight")
asm.load(B, const_1,    "Load 1")
b_fwd_rgt = asm.reserve_branch("breq", "Fwd+Right -> Fr")

# Forward only: _F
asm.load(A, disp_f,           "Load display code 0xEF (_F)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# IS_BACKWARD
asm.patch(b_is_bwd, asm.here())
asm.section_comment("IS_BACKWARD")
asm.load(A, dir_left,   "Check DirLeft")
asm.load(B, const_1,    "Load 1")
b_bwd_lft = asm.reserve_branch("breq", "Bwd+Left  -> bL")

asm.load(A, dir_rgt,    "Check DirRight")
asm.load(B, const_1,    "Load 1")
b_bwd_rgt = asm.reserve_branch("breq", "Bwd+Right -> br")

# Backward only: _b
asm.load(A, disp_b,           "Load display code 0xEB (_b)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Centre + Right: _r
asm.patch(b_ctr_rgt, asm.here())
asm.section_comment("CENTRE_RIGHT")
asm.load(A, disp_r,           "Load display code 0xEA (_r)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Centre + Left: _L
asm.patch(b_ctr_lft, asm.here())
asm.section_comment("CENTRE_LEFT")
asm.load(A, disp_l,           "Load display code 0xED (_L)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Forward + Left: FL
asm.patch(b_fwd_lft, asm.here())
asm.section_comment("FWD_LEFT")
asm.load(A, disp_fl,          "Load display code 0xFD (FL)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Forward + Right: Fr
asm.patch(b_fwd_rgt, asm.here())
asm.section_comment("FWD_RIGHT")
asm.load(A, disp_fr,          "Load display code 0xFA (Fr)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Backward + Left: bL
asm.patch(b_bwd_lft, asm.here())
asm.section_comment("BWD_LEFT")
asm.load(A, disp_bl,          "Load display code 0xBD (bL)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# Backward + Right: br
asm.patch(b_bwd_rgt, asm.here())
asm.section_comment("BWD_RIGHT")
asm.load(A, disp_br,          "Load display code 0xBA (br)")
asm.store(A, M.sevenseg_base, "Write to 7-seg 0xD0")
asm.goto_idle("End Timer ISR")

# ── Vector Table ──────────────────────────────────────────────────────────────
asm.pad_to(0xFE, "Pad to Vector Table")
asm.db(timer_isr, "0xFE: Timer ISR address")
asm.db(mouse_isr, "0xFF: Mouse ISR address")

asm.create_file("5.0")
