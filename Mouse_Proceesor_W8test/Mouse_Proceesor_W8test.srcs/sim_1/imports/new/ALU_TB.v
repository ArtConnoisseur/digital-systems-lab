`timescale 1ns / 1ps
// All cases passed

module ALU_tb;

reg CLK;
reg RESET;
reg [7:0] IN_A;
reg [7:0] IN_B;
reg [3:0] ALU_Op_Code;

wire [7:0] OUT_RESULT;

// Instantiate ALU
ALU uut (
    .CLK(CLK),
    .RESET(RESET),
    .IN_A(IN_A),
    .IN_B(IN_B),
    .ALU_Op_Code(ALU_Op_Code),
    .OUT_RESULT(OUT_RESULT)
);

// Clock generation
always #5 CLK = ~CLK;   // 100MHz equivalent (10ns period)

initial begin

    CLK = 0;
    RESET = 1;
    IN_A = 0;
    IN_B = 0;
    ALU_Op_Code = 0;

    #20;
    RESET = 0;

    $display("===== ALU TEST START =====");

    // ------------------------
    // ADD
    // ------------------------
    IN_A = 8'd10;
    IN_B = 8'd5;
    ALU_Op_Code = 4'h0;
    @(posedge CLK);
    @(posedge CLK);
    if (OUT_RESULT !== 8'd15)
        $display("ERROR: ADD failed");
    else
        $display("PASS: ADD");

    // ------------------------
    // SUB
    // ------------------------
    IN_A = 8'd10;
    IN_B = 8'd3;
    ALU_Op_Code = 4'h1;
    @(posedge CLK);
    if (OUT_RESULT !== 8'd7)
        $display("ERROR: SUB failed");
    else
        $display("PASS: SUB");

    // ------------------------
    // MUL (low 8-bit check)
    // ------------------------
    IN_A = 8'd20;
    IN_B = 8'd20;
    ALU_Op_Code = 4'h2;
    @(posedge CLK);
    if (OUT_RESULT !== (20*20 & 8'hFF))
        $display("ERROR: MUL failed");
    else
        $display("PASS: MUL");

    // ------------------------
    // SHIFT LEFT
    // ------------------------
    IN_A = 8'b00000011;
    ALU_Op_Code = 4'h3;
    @(posedge CLK);
    if (OUT_RESULT !== 8'b00000110)
        $display("ERROR: SHL failed");
    else
        $display("PASS: SHL");

    // ------------------------
    // SHIFT RIGHT
    // ------------------------
    IN_A = 8'b00000100;
    ALU_Op_Code = 4'h4;
    @(posedge CLK);
    if (OUT_RESULT !== 8'b00000010)
        $display("ERROR: SHR failed");
    else
        $display("PASS: SHR");

    // ------------------------
    // A == B
    // ------------------------
    IN_A = 8'd5;
    IN_B = 8'd5;
    ALU_Op_Code = 4'h9;
    @(posedge CLK);
    if (OUT_RESULT !== 8'h01)
        $display("ERROR: EQUAL failed");
    else
        $display("PASS: EQUAL");

    // ------------------------
    // A > B
    // ------------------------
    IN_A = 8'd8;
    IN_B = 8'd3;
    ALU_Op_Code = 4'hA;
    @(posedge CLK);
    if (OUT_RESULT !== 8'h01)
        $display("ERROR: GREATER failed");
    else
        $display("PASS: GREATER");

    // ------------------------
    // A < B
    // ------------------------
    IN_A = 8'd2;
    IN_B = 8'd5;
    ALU_Op_Code = 4'hB;
    @(posedge CLK);
    if (OUT_RESULT !== 8'h01)
        $display("ERROR: LESS failed");
    else
        $display("PASS: LESS");

    $display("===== ALU TEST END =====");

    $stop;
end

endmodule