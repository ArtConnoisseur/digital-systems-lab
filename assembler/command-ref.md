To make your `.mem` file easier to write, I have decoded the bit patterns from the PDF into **Hexadecimal Opcodes**.

In this architecture, instructions are often split into a **High Nibble** (first hex digit) and a **Low Nibble** (second hex digit).

### 1. Memory & Flow Control (2-Byte Instructions)
*These require a second byte immediately following the opcode to specify the `ADDR` (00-FF).*

| Mnemonic | Hex Opcode | Byte 2 | Description |
| :--- | :--- | :--- | :--- |
| **A <- [Mem]** | `00` | `ADDR` | Load value at address into Register A |
| **B <- [Mem]** | `01` | `ADDR` | Load value at address into Register B |
| **[Mem] <- A** | `02` | `ADDR` | Store Register A into address |
| **[Mem] <- B** | `03` | `ADDR` | Store Register B into address |
| **BREQ ADDR** | `96` | `ADDR` | Branch to ADDR if A == B |
| **BGTQ ADDR** | `A6` | `ADDR` | Branch to ADDR if A > B |
| **BLTQ ADDR** | `B6` | `ADDR` | Branch to ADDR if A < B |
| **GOTO ADDR** | `07` | `ADDR` | Unconditional jump to ADDR |
| **CALL ADDR** | `09` | `ADDR` | Call function at ADDR (saves context) |

---

### 2. ALU Operations (1-Byte Instructions)
For ALU operations, the **Low Nibble** determines which register stores the result.
*   If Low Nibble is `4`: Result goes to **Register A**.
*   If Low Nibble is `5`: Result goes to **Register B**.

The **High Nibble** is the math operation code:

| Math Operation | Code | **Result in A** | **Result in B** |
| :--- | :---: | :---: | :---: |
| **Add** (A+B) | `0` | `04` | `05` |
| **Subtract** (A-B) | `1` | `14` | `15` |
| **Multiply** (A*B) | `2` | `24` | `25` |
| **Shift Left** (A<<1) | `3` | `34` | `35` |
| **Shift Right** (A>>1) | `4` | `44` | `45` |
| **Increment A** (A+1) | `5` | **`54`** | `55` |
| **Increment B** (B+1) | `6` | `64` | `65` |
| **Decrement A** (A-1) | `7` | `74` | `75` |
| **Decrement B** (B-1) | `8` | `84` | `85` |
| **Compare ==** (1 if true) | `9` | `94` | `95` |
| **Compare >** (1 if true) | `A` | `A4` | `A5` |
| **Compare <** (1 if true) | `B` | `B4` | `B5` |

---

### 3. Special & Pointer Operations (1-Byte Instructions)

| Mnemonic | Hex Opcode | Description |
| :--- | :--- | :--- |
| **GOTO_IDLE** | `08` | Stop and wait for an interrupt |
| **RETURN** | `0A` | Return from function call |
| **Dereference A** | `0B` | `A <- [A]` (Use value in A as an address to load from) |
| **Dereference B** | `0C` | `B <- [B]` (Use value in B as an address to load from) |

---

### Example: Writing your Infinite Loop
If you want to increment X (Register A) and loop back until it hits 160:

```text
// Assuming: 
// Address 0x10 holds the constant 160
// Address 0x05 is the start of your loop

@05 54      // Opcode 54: Increment Register A (X-coord)
@06 01 10   // Opcode 01: Load Register B with value from [0x10] (the limit 160)
@08 B6 05   // Opcode B6: If A < B (X < 160), Jump back to @05
```

### Pro-Tip for your `.mem` file:
The `@XX` is just a pointer. You don't have to write every single address. You can do this:
```text
@00 04 // Logic starts at 00
@01 02 B0 // Store X to VGA
@03 54 // Inc X
@04 07 01 // Jump back to 01
```
This keeps your file clean and prevents "timing issues" caused by large gaps of `08` (Idle) instructions.
