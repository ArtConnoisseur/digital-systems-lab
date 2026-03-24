from __future__ import annotations
from dataclasses import dataclass, field
import os

# ── RAM ───────────────────────────────────────────────────────────────────────

@dataclass
class RAMVariable:
    byte : int = 0x00
    addr : int = 0x00
    name : str = ""

class RAM:
    """Keeps track of 'variables' defined as a part of a given assembly program"""
    def __init__(self):
        self.curr_address   : int               = 0x00
        self.variables      : list[RAMVariable] = []

    def var(self, byte: int, name: str) -> int:
        new_var : RAMVariable = RAMVariable(
            byte = byte,
            addr = self.curr_address,
            name = name
        )
        self.variables.append(new_var)
        self.curr_address += 1

        return new_var.addr
    
    def here(self):
        return self.curr_address

    def create_file(self, path: str):
        with open(path, "w+") as f:
            for var in self.variables:
                line = f"{var.byte:02X} // [{var.addr:02X}] {var.name}"
                f.write(line + "\n")


# ── Peripheral / memory map constants ─────────────────────────────────────────

@dataclass
class Mnemonics:
    # Peripheral base addresses (from Table 1)
    switch_base:   int = 0x80 
    ir_base:       int = 0x90
    mouse_base:    int = 0xA0
    vga_base:      int = 0xB0
    leds_base:     int = 0xC0
    sevenseg_base: int = 0xD0
    timer_base:    int = 0xF0

    # Switch Registers
    switch_status_car_en:   int = 0x80
    switch_status_sens:     int = 0x81 
    switch_status_fg:       int = 0x82 
    switch_status_bg:       int = 0x83 

    # IR Peripheral 
    ir_command:     int = 0x90
    ir_enable:      int = 0x91 

    # Mouse registers
    mouse_status:      int = 0xA0
    mouse_x:           int = 0xA1
    mouse_y:           int = 0xA2
    mouse_dx:          int = 0xA3 
    mouse_dy:          int = 0xA4
    mouse_sensitivity: int = 0xA5 

    # VGA registers  (write Y<<1|pixel to B0 to trigger framebuffer write)
    vga_pixel:     int = 0xB0
    vga_x:         int = 0xB1
    vga_y:         int = 0xB2
    vga_fg:        int = 0xB3
    vga_bg:        int = 0xB4

    # Timer registers
    timer_value:   int = 0xF0
    timer_rate:    int = 0xF1
    timer_reset:   int = 0xF2
    timer_enable:  int = 0xF3

    # Interrupt vectors (addresses *of* the handler address, stored in ROM)
    mouse_vector:  int = 0xFF
    timer_vector:  int = 0xFE


# ── Single instruction / comment container ─────────────────────────────────────

@dataclass
class Instruction:
    """Holds one logical instruction as a list of raw bytes plus an optional comment."""
    bytes:   list[int] = field(default_factory=list)
    comment: str       = ""

    @property
    def size(self) -> int:
        return len(self.bytes)


# ── Assembler ──────────────────────────────────────────────────────────────────

class Assembler:
    # Register identifiers used throughout the API
    A: int = 0
    B: int = 1

    def __init__(self,
        name: str,
        ram: RAM
    ):
        # Mix of Instruction objects and plain strings (section comments)
        self.instructions: list[Instruction | str] = []
        self.name = name
        self.ram = ram
        self.version = 1.0

    # ── Address tracking ──────────────────────────────────────────────────────

    def here(self) -> int:
        """Return the current byte address (sum of all emitted instruction sizes)."""
        return sum(i.size for i in self.instructions if isinstance(i, Instruction))
    
    def reserve_branch(self, kind: str, comment: str = "") -> int:
        """Emit a branch with placeholder 0x00, return its index for later patching."""
        op = {"breq": 0x96, "bgtq": 0xA6, "bltq": 0xB6, "goto": 0x07}[kind]
        idx = len(self.instructions)
        self.instructions.append(Instruction(bytes=[op, 0x00], comment=comment))
        return idx

    def patch(self, idx: int, addr: int):
        """Patch the address byte of a previously reserved branch."""
        self.instructions[idx].bytes[1] = addr

    # ── Output ────────────────────────────────────────────────────────────────

    def create_file(self, version: str):
        """
        Serialise all instructions to a hex text file compatible with
        Verilog's $readmemh directive and matching the sample format:

            00  // [0x00] A <- [0x05] (const 0)
            05
        """
        lines: list[str] = []
        addr = 0

        for item in self.instructions:
            if isinstance(item, str):
                # Bare section comment – emit as-is on its own line
                lines.append(item)
                continue

            for i, byte in enumerate(item.bytes):
                if i == 0 and item.comment:
                    lines.append(f"{byte:02X}  // [0x{addr:02X}] {item.comment}")
                else:
                    lines.append(f"{byte:02X}")
                addr += 1

        file_string = "\n".join(lines)

        os.makedirs("output", exist_ok=True)

        ram_path = f"output/{self.name}/v{version}/{self.name}_RAM_Demo.txt"
        os.makedirs(os.path.dirname(ram_path), exist_ok=True)
        self.ram.create_file(ram_path)

        rom_path = f"output/{self.name}/v{version}/{self.name}_ROM_Demo.txt"
        os.makedirs(os.path.dirname(rom_path), exist_ok=True)
        with open(rom_path, "w") as f:
            f.write(file_string)

        print(f"Written to \n{rom_path}\n{ram_path}")

    # ── Comments ──────────────────────────────────────────────────────────────

    def section_comment(self, comment: str):
        """Emit a section-divider comment  //  ==== LABEL (0xAB) ===="""
        self.instructions.append(f"\n// ==== {comment} (0x{self.here():02X}) ====")

    def inline_comment(self, comment: str):
        """Emit a standalone comment line (no instruction bytes)."""
        self.instructions.append(f"// {comment}")

    # ── Memory operations ─────────────────────────────────────────────────────

    def load(self, reg: int, memloc: int, comment: str = ""):
        """A <- [memloc]  or  B <- [memloc]"""
        opcode = 0x00 if reg == self.A else 0x01
        reg_name = "A" if reg == self.A else "B"
        self.instructions.append(Instruction(
            bytes=[opcode, memloc],
            comment=comment or f"{reg_name} <- [0x{memloc:02X}]",
        ))

    def store(self, reg: int, memloc: int, comment: str = ""):
        """[memloc] <- A  or  [memloc] <- B"""
        opcode = 0x02 if reg == self.A else 0x03
        reg_name = "A" if reg == self.A else "B"
        self.instructions.append(Instruction(
            bytes=[opcode, memloc],
            comment=comment or f"[0x{memloc:02X}] <- {reg_name}",
        ))

    # ── ALU operations ────────────────────────────────────────────────────────
    # Instruction encoding:  byte = (ALU_op_code << 4) | dest_nibble
    # dest_nibble: 0x4 -> save in A,  0x5 -> save in B

    def _alu(self, op: int, dest: int, comment: str = ""):
        dest_nibble = 0x04 if dest == self.A else 0x05
        opcode = (op << 4) | dest_nibble
        self.instructions.append(Instruction(bytes=[opcode], comment=comment))

    def add(self, dest: int = 0, comment: str = ""):
        """dest = A + B"""
        reg = "A" if dest == self.A else "B"
        self._alu(0x0, dest, comment or f"{reg} = A + B")

    def sub(self, dest: int = 0, comment: str = ""):
        """dest = A - B"""
        reg = "A" if dest == self.A else "B"
        self._alu(0x1, dest, comment or f"{reg} = A - B")

    def mul(self, dest: int = 0, comment: str = ""):
        """dest = A * B"""
        reg = "A" if dest == self.A else "B"
        self._alu(0x2, dest, comment or f"{reg} = A * B")

    def shift_left(self, comment: str = ""):
        """A = A << 1  (only A is defined for shifts in the ISA)"""
        self._alu(0x3, self.A, comment or "A = A << 1")

    def shift_right(self, comment: str = ""):
        """A = A >> 1"""
        self._alu(0x4, self.A, comment or "A = A >> 1")

    def inc(self, reg: int, comment: str = ""):
        """reg = reg + 1"""
        # ALU op 5 = inc A,  op 6 = inc B;  result always saved back into same reg
        op = 0x5 if reg == self.A else 0x6
        reg_name = "A" if reg == self.A else "B"
        self._alu(op, reg, comment or f"{reg_name} += 1")

    def dec(self, reg: int, comment: str = ""):
        """reg = reg - 1"""
        op = 0x7 if reg == self.A else 0x8
        reg_name = "A" if reg == self.A else "B"
        self._alu(op, reg, comment or f"{reg_name} -= 1")

    def eq(self, dest: int = 0, comment: str = ""):
        """dest = 1 if A == B else 0"""
        reg = "A" if dest == self.A else "B"
        self._alu(0x9, dest, comment or f"{reg} = (A == B)")

    def gt(self, dest: int = 0, comment: str = ""):
        """dest = 1 if A > B else 0"""
        reg = "A" if dest == self.A else "B"
        self._alu(0xA, dest, comment or f"{reg} = (A > B)")

    def lt(self, dest: int = 0, comment: str = ""):
        """dest = 1 if A < B else 0"""
        reg = "A" if dest == self.A else "B"
        self._alu(0xB, dest, comment or f"{reg} = (A < B)")

    # ── Branch / jump operations ──────────────────────────────────────────────
    # Upper nibble encodes condition,  lower nibble = 0x6 for all branches.
    # GOTO uses lower nibble 0x7.

    def breq(self, addr: int, comment: str = ""):
        """Branch to addr if A == B  (opcode 0x96)"""
        self.instructions.append(Instruction(
            bytes=[0x96, addr],
            comment=comment or f"if A == B goto 0x{addr:02X}",
        ))

    def bgtq(self, addr: int, comment: str = ""):
        """Branch to addr if A > B  (opcode 0xA6)"""
        self.instructions.append(Instruction(
            bytes=[0xA6, addr],
            comment=comment or f"if A > B goto 0x{addr:02X}",
        ))

    def bltq(self, addr: int, comment: str = ""):
        """Branch to addr if A < B  (opcode 0xB6)"""
        self.instructions.append(Instruction(
            bytes=[0xB6, addr],
            comment=comment or f"if A < B goto 0x{addr:02X}",
        ))

    def goto(self, addr: int, comment: str = ""):
        """Unconditional jump  (opcode 0x07)"""
        self.instructions.append(Instruction(
            bytes=[0x07, addr],
            comment=comment or f"goto 0x{addr:02X}",
        ))

    def goto_idle(self, comment: str = ""):
        """Suspend execution and wait for the next interrupt  (opcode 0x08)"""
        self.instructions.append(Instruction(
            bytes=[0x08],
            comment=comment or "goto idle",
        ))

    # ── Function call / return ────────────────────────────────────────────────

    def call(self, addr: int, comment: str = ""):
        """Save return address and jump to addr  (opcode 0x09)"""
        self.instructions.append(Instruction(
            bytes=[0x09, addr],
            comment=comment or f"call 0x{addr:02X}",
        ))

    def ret(self, comment: str = ""):
        """Return from function call  (opcode 0x0A)"""
        self.instructions.append(Instruction(
            bytes=[0x0A],
            comment=comment or "return",
        ))

    # ── Dereference ───────────────────────────────────────────────────────────

    def deref(self, reg: int, comment: str = ""):
        """A <- [A]  or  B <- [B]  (opcodes 0x0B / 0x0C)"""
        opcode = 0x0B if reg == self.A else 0x0C
        reg_name = "A" if reg == self.A else "B"
        self.instructions.append(Instruction(
            bytes=[opcode],
            comment=comment or f"{reg_name} <- [{reg_name}]",
        ))

    # ── Utility ───────────────────────────────────────────────────────────────

    def db(self, value: int, comment: str = ""):
        """Place a raw byte (e.g. for interrupt vector table entries)."""
        self.instructions.append(Instruction(
            bytes=[value & 0xFF],
            comment=comment or f"db 0x{value:02X}",
        ))

    def pad_for(self, lines: int, comment: str = ""):
        """
        Fill with GOTO_IDLE bytes for as many lines as given
        """

        current = self.here() 
        remaining_lines = 255 - current 

        if remaining_lines < lines:
            raise ValueError(
                f"pad(Cannot add {lines} of code as only {remaining_lines} of space left)"
            )
        
        self.section_comment(f"Pad for {lines}. Comment: {comment}")
        
        self.instructions.append(Instruction(
            bytes=[0x08] * lines,
            comment="",   # individual pad bytes get no inline comment
        ))

    def pad_to(self, addr: int, comment: str = ""):
        """
        Fill with GOTO_IDLE bytes (0x08) until the address counter reaches addr.
        Raises ValueError if addr is already behind the current position.
        """
        current = self.here()
        if addr < current:
            raise ValueError(
                f"pad_to(0x{addr:02X}): already at 0x{current:02X}"
            )
        count = addr - current
        if count == 0:
            return
        self.section_comment(f"Pad 0x{current:02X} to 0x{addr - 1:02X}. Comment: {comment}")
        self.instructions.append(Instruction(
            bytes=[0x08] * count,
            comment="",   # individual pad bytes get no inline comment
        ))
