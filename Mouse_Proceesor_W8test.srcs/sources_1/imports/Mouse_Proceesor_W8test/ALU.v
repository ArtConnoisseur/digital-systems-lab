`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ALU (Arithmetic Logic Unit)
//
// Description:
//   8-bit ALU supporting arithmetic, shift, and comparison operations.
//   The operation is selected by a 4-bit opcode (ALU_Op_Code), which
//   corresponds to the upper nibble [7:4] of the processor instruction byte.
//
//   The ALU is synchronous (registered output) - the result is available
//   one clock cycle after the inputs and opcode are presented.
//
// Opcode Table:
//   0x0 : ADD          OUT = A + B
//   0x1 : SUBTRACT     OUT = A - B
//   0x2 : MULTIPLY     OUT = A * B  (lower 8 bits only)
//   0x3 : SHIFT LEFT   OUT = A << 1
//   0x4 : SHIFT RIGHT  OUT = A >> 1
//   0x5 : INCREMENT A  OUT = A + 1
//   0x6 : INCREMENT B  OUT = B + 1
//   0x7 : DECREMENT A  OUT = A - 1
//   0x8 : DECREMENT B  OUT = B - 1
//   0x9 : EQUAL        OUT = (A == B) ? 1 : 0
//   0xA : GREATER THAN OUT = (A > B)  ? 1 : 0
//   0xB : LESS THAN    OUT = (A < B)  ? 1 : 0
//   default: pass-through A
//
// Note: Comparison results (0x9-0xB) return 8'h01 for TRUE and 8'h00 for
//       FALSE, which the processor uses for conditional branching.
//
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    // Standard signals
    input           CLK,            // System clock
    input           RESET,          // Synchronous reset (clears output to 0)
    // I/O
    input   [7:0]   IN_A,          // Operand A (from processor RegA)
    input   [7:0]   IN_B,          // Operand B (from processor RegB)
    input   [3:0]   ALU_Op_Code,   // Operation selector (from instruction upper nibble)
    output  [7:0]   OUT_RESULT     // Registered result output
);

    reg [7:0] Out;

    // Registered ALU computation - result available on next clock edge
    always@(posedge CLK) begin
        if(RESET)
            Out <= 0;
        else begin
            case (ALU_Op_Code)
            //----------------------------------------------------------
            // Arithmetic Operations
            //----------------------------------------------------------
            4'h0: Out <= IN_A + IN_B;       // ADD:       A + B
            4'h1: Out <= IN_A - IN_B;       // SUBTRACT:  A - B
            4'h2: Out <= IN_A * IN_B;       // MULTIPLY:  A * B (8-bit result)
            4'h3: Out <= IN_A << 1;         // SHIFT LEFT:  A << 1
            4'h4: Out <= IN_A >> 1;         // SHIFT RIGHT: A >> 1
            4'h5: Out <= IN_A + 1'b1;       // INCREMENT A: A + 1
            4'h6: Out <= IN_B + 1'b1;       // INCREMENT B: B + 1
            4'h7: Out <= IN_A - 1'b1;       // DECREMENT A: A - 1
            4'h8: Out <= IN_B - 1'b1;       // DECREMENT B: B - 1
            //----------------------------------------------------------
            // Comparison Operations (used for conditional branching)
            // Return 8'h01 (true) or 8'h00 (false)
            //----------------------------------------------------------
            4'h9: Out <= (IN_A == IN_B) ? 8'h01 : 8'h00;   // EQUAL
            4'hA: Out <= (IN_A > IN_B)  ? 8'h01 : 8'h00;   // GREATER THAN
            4'hB: Out <= (IN_A < IN_B)  ? 8'h01 : 8'h00;   // LESS THAN
            //----------------------------------------------------------
            default: Out <= IN_A;           // Pass-through A
            endcase
        end
    end

    assign OUT_RESULT = Out;

endmodule
