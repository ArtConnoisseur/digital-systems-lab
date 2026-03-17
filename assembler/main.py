from src.assembler import Mnemonics, Assembler, Instruction

if __name__ == "__main__":
    M   = Mnemonics()
    asm = Assembler()
    A, B = Assembler.A, Assembler.B

    # --- INIT (0x00) ---
    asm.section_comment("INIT - load constants, zero state")
    asm.load(A, 0x05, "const 0")
    asm.store(A, M.timer_enable, "disable timer interrupt")
    asm.store(A, 0x00, "X = 0")
    asm.store(A, 0x01, "Y = 0")
    asm.load(A, 0x06, "const 1")
    asm.store(A, 0x03, "x_even = 1")
    asm.store(A, 0x04, "y_even = 1")

    # --- Y_LOOP (record address) ---
    y_loop = asm.here()
    asm.section_comment("Y_LOOP - reset X and x_even each row")
    asm.load(A, 0x05, "const 0")
    asm.store(A, 0x00, "X = 0")
    asm.load(A, 0x06, "const 1")
    asm.store(A, 0x03, "x_even = 1")

    # --- X_LOOP ---
    x_loop = asm.here()
    asm.section_comment("X_LOOP - write pixel")
    asm.load(A, 0x04, "y_even")
    asm.load(B, 0x03, "x_even")
    asm.mul(A, "pixel = y_even * x_even")
    asm.store(A, 0x02, "save pixel")

    # write X to VGA
    asm.load(A, 0x00, "X")
    asm.store(A, M.vga_x, "VGA X")

    # compute Y_write = (Y<<1) | pixel
    asm.load(A, 0x01, "Y")
    asm.shift_left("A = Y << 1")
    asm.store(A, 0x09, "save Y<<1")
    asm.load(A, 0x02, "pixel")
    asm.load(B, 0x09, "Y<<1")
    asm.add(A, "Y_write = (Y<<1) | pixel")
    asm.store(A, M.vga_write, "trigger framebuffer write")

    # increment X and loop
    asm.load(A, 0x00, "X")
    asm.inc(A, "X++")
    asm.store(A, 0x00, "save X")
    asm.load(B, 0x07, "X_limit = 160")

    next_y = asm.here() + 4   # BREQ(2) + GOTO(2) = 4 bytes ahead
    asm.breq(next_y, "if X==160 goto NEXT_Y")
    asm.goto(x_loop, "loop back to X_LOOP")

    # --- NEXT_Y ---
    asm.section_comment("NEXT_Y - increment Y, loop or finish")
    asm.load(A, 0x01, "Y")
    asm.inc(A, "Y++")
    asm.store(A, 0x01, "save Y")
    asm.load(B, 0x08, "Y_limit = 120")

    done = asm.here() + 4
    asm.breq(done, "if Y==120 goto DONE")
    asm.goto(y_loop, "loop back to Y_LOOP")

    # --- DONE ---
    asm.section_comment("DONE - re-enable timer, go idle")
    asm.load(A, 0x06, "const 1")
    asm.store(A, M.timer_enable, "re-enable timer interrupt")
    asm.goto_idle()

    # --- Pad to timer handler at 0x70 ---
    asm.pad_to(0x70)
    asm.section_comment("TIMER_HANDLER")
    asm.load(A, 0x0A, "timer_count")
    asm.inc(A, "count++")
    asm.store(A, 0x0A, "save count")
    asm.load(B, 0x0B, "timer_limit = 10")
    trigger = asm.here() + 4
    asm.breq(trigger, "if count==10 goto TRIGGER")
    asm.goto_idle("count not reached")

    # --- TRIGGER_COLOUR ---
    asm.inline_comment("TRIGGER_COLOUR")
    asm.load(A, 0x05, "const 0")
    asm.store(A, 0x0A, "reset count")
    asm.load(A, 0x10, "colour_toggle")
    asm.load(B, 0x06, "const 1")
    branch2 = asm.here() + 4
    asm.breq(branch2, "if toggle==1 goto branch2")

    # branch 1 (toggle == 0)
    asm.load(A, 0x0C, "White=0xFF")
    asm.store(A, M.vga_config, "BG = White")
    asm.load(A, 0x0D, "Teal=0x0F")
    asm.store(A, M.vga_config, "FG = Teal")
    asm.load(A, 0x06, "const 1")
    asm.store(A, 0x10, "toggle = 1")
    asm.goto_idle()

    # branch 2 (toggle == 1)
    asm.load(A, 0x0E, "Red=0x15")
    asm.store(A, M.vga_config, "BG = Red")
    asm.load(A, 0x0F, "Black=0x00")
    asm.store(A, M.vga_config, "FG = Black")
    asm.load(A, 0x05, "const 0")
    asm.store(A, 0x10, "toggle = 0")
    asm.goto_idle()

    # --- Interrupt vectors ---
    asm.pad_to(0xFE)
    asm.section_comment("Interrupt vectors")
    asm.db(0x70, "timer handler at 0x70")
    asm.db(0x08, "mouse -> GOTO_IDLE")

    asm.create_file("vga_demo", "1.0")
