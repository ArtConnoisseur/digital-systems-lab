from src.assembler.assembler import Mnemonics, Assembler, RAM

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

# Colours 
# Background colours (dark) — format: GG BBB RRR
# CSS -> R=css_r//32, B=css_b//32, G=css_g//64
bg_base = ram.here()
bg_val_00 = ram.var(0x00, "bg_val_00: black        #000000 (G=0,B=0,R=0)")
bg_val_01 = ram.var(0x04, "bg_val_01: dark red     #800000 (G=0,B=0,R=4)")
bg_val_02 = ram.var(0x80, "bg_val_02: dark green   #008000 (G=2,B=0,R=0)")
bg_val_03 = ram.var(0x20, "bg_val_03: dark blue    #000080 (G=0,B=4,R=0)")
bg_val_04 = ram.var(0x24, "bg_val_04: dark purple  #800080 (G=0,B=4,R=4)")
bg_val_05 = ram.var(0xA0, "bg_val_05: dark teal    #008080 (G=2,B=4,R=0)")
bg_val_06 = ram.var(0x44, "bg_val_06: dark orange  #804000 (G=1,B=0,R=4)")
bg_val_07 = ram.var(0x52, "bg_val_07: dark grey    #404040 (G=1,B=2,R=2)")
bg_val_08 = ram.var(0x03, "bg_val_08: dark maroon  #600000 (G=0,B=0,R=3)")
bg_val_09 = ram.var(0x84, "bg_val_09: dark olive   #808000 (G=2,B=0,R=4)")
bg_val_10 = ram.var(0x18, "bg_val_10: dark navy    #000060 (G=0,B=3,R=0)")
bg_val_11 = ram.var(0x4C, "bg_val_11: dark brown   #804020 (G=1,B=1,R=4)")
bg_val_12 = ram.var(0x22, "bg_val_12: dark indigo  #4B0082 (G=0,B=4,R=2)")
bg_val_13 = ram.var(0x89, "bg_val_13: dark forest  #228B22 (G=2,B=1,R=1)")
bg_val_14 = ram.var(0xA3, "bg_val_14: dark slate   #708090 (G=2,B=4,R=3)")
bg_val_15 = ram.var(0x0C, "bg_val_15: dark crimson #800020 (G=0,B=1,R=4)")

# Foreground colours (light) — format: GG BBB RRR
# CSS -> R=css_r//32, B=css_b//32, G=css_g//64
fg_base = ram.here()
fg_val_00 = ram.var(0xFF, "fg_val_00: white        #FFFFFF (G=3,B=7,R=7)")
fg_val_01 = ram.var(0xC7, "fg_val_01: yellow       #FFFF00 (G=3,B=0,R=7)")
fg_val_02 = ram.var(0xC0, "fg_val_02: light green  #00FF00 (G=3,B=0,R=0)")
fg_val_03 = ram.var(0xF8, "fg_val_03: light cyan   #00FFFF (G=3,B=7,R=0)")
fg_val_04 = ram.var(0xB7, "fg_val_04: light pink   #FFB6C1 (G=2,B=6,R=7)")
fg_val_05 = ram.var(0xF3, "fg_val_05: light aqua   #7FFFD4 (G=3,B=6,R=3)")
fg_val_06 = ram.var(0xEF, "fg_val_06: light peach  #FFDAB9 (G=3,B=5,R=7)")
fg_val_07 = ram.var(0xF6, "fg_val_07: light grey   #C0C0C0 (G=3,B=6,R=6)")
fg_val_08 = ram.var(0x9F, "fg_val_08: light salmon #FA8072 (G=2,B=3,R=7)")
fg_val_09 = ram.var(0xCD, "fg_val_09: lime green   #ADFF2F (G=3,B=1,R=5)")
fg_val_10 = ram.var(0xFC, "fg_val_10: sky blue     #87CEEB (G=3,B=7,R=4)")
fg_val_11 = ram.var(0xA6, "fg_val_11: light tan    #D2B48C (G=2,B=4,R=6)")
fg_val_12 = ram.var(0xFF, "fg_val_12: lavender     #E6E6FA (G=3,B=7,R=7)")
fg_val_13 = ram.var(0xE4, "fg_val_13: mint         #98FF98 (G=3,B=4,R=4)")
fg_val_14 = ram.var(0xFD, "fg_val_14: light blue   #ADD8E6 (G=3,B=7,R=5)")
fg_val_15 = ram.var(0x1F, "fg_val_15: light rose   #FF007F (G=0,B=3,R=7)")


# Cursor Colours (light) — format: GG BBB RRR
# CSS -> R=css_r//32, B=css_b//32, G=css_g//64
cur_col_base = ram.here()
cur_col_00 = ram.var(0xFF, "")
cur_col_01 = ram.var(0x90, "")
cur_col_02 = ram.var(0x52, "")
cur_col_03 = ram.var(0x1F, "")

# Pointers to the fg and bg base values
bg_base_ref = ram.var(bg_base, "BG Base Reference Address")
fg_base_ref = ram.var(fg_base, "FG Base Reference Address")
cur_col_base_ref = ram.var(cur_col_base, "Cursor Colour Base Reference Address")

# ── ROM: start in IDLE ────────────────────────────────────────────────────────
asm.goto_idle("Start in IDLE mode")

# ── Mouse ISR ─────────────────────────────────────────────────────────────────
mouse_isr = asm.here()
asm.section_comment("Mouse ISR")

# asm.load(A, pixel_data,   "Load cached pixel value")
# asm.store(A, M.vga_pixel, "Restore pixel at old X,Y")

# asm.load(A, M.mouse_x,   "Load MouseX from peripheral")
# asm.store(A, M.vga_x,    "Set VGA X address")
# asm.load(A, M.mouse_y,   "Load MouseY from peripheral")
# asm.store(A, M.vga_y,    "Set VGA Y address")

# asm.load(A, M.vga_pixel,  "Read pixel at new X,Y")
# asm.store(A, pixel_data,  "Cache it in RAM")

# asm.load(A, const_1,      "Load 1")
# asm.store(A, M.vga_pixel, "Draw cursor pixel")

asm.load(A, M.mouse_x)
asm.store(A, M.vga_cur_x)

asm.load(A, M.mouse_y)
asm.store(A, M.vga_cur_y)

asm.goto_idle("End of Mouse ISR")

# ── Timer ISR ─────────────────────────────────────────────────────────────────
timer_isr = asm.here()
asm.section_comment("Timer ISR")

asm.load(A, M.switch_status_car_en, "Load Enable status")
asm.store(A, M.ir_enable, "Store enable value in IR")
asm.load(A, M.switch_status_sens)
asm.store(A, M.mouse_sensitivity)
asm.load(A, M.switch_status_car_sel, "Load car select switch value")
asm.store(A, M.ir_car_sel, "Store car select to IR Peripheral")

asm.load(A, M.switch_status_fg, "Get the FG switch value. This is the offset from base ref")
asm.load(B, fg_base_ref, "Get the FG base reference in B")
asm.add(A, "Increment A by base ref to give A = offset + base_ref")
asm.deref(A, "Derefernce A for the right value")
asm.store(A, M.vga_fg, "Store colour in VGA FG register")

asm.load(A, M.switch_status_bg, "Repeat for BG")
asm.load(B, bg_base_ref, "Get the BG base reference in B")
asm.add(A, "Increment A by base ref to give A = offset + base_ref")
asm.deref(A, "Derefernce A for the right value")
asm.store(A, M.vga_bg, "Store colour in VGA BG register")

asm.load(A, M.switch_cur_col_sel)
asm.load(B, cur_col_base_ref)
asm.add(A)
asm.deref(A)
asm.store(A, M.vga_cur_color)

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

# Switch peripheral handler 
asm.load(A, M.switch_status_car_en, "Load mouse enable status")
asm.store(A, M.ir_enable, "Set Enable to the IR Peripheral")

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