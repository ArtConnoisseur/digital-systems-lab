`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// This TB successfully read instruction from Complete_Demo_Rom.txt (ignore xx after 00)
//00     // LOAD  A, [0xA0]  ; A = Mouse Status
//A0
//02     // STORE A, [0xC0]  ; LEDs = Status byte
//C0
//00     // LOAD  A, [0xA1]  ; A = Mouse X
//A1
//02     // STORE A, [0xD0]  ; 7-Seg digits 0-1 = X
//D0
//00     // LOAD  A, [0xA2]  ; A = Mouse Y
//A2
//02     // STORE A, [0xD1]  ; 7-Seg digits 2-3 = Y
//D1
//07     // JUMP  0x00       ; Loop back
//00 
//////////////////////////////////////////////////////////////////////////////////


module ROM_TB;
reg CLK;
reg [7:0] ADDR;
wire [7:0] DATA;

ROM uut (
    .CLK(CLK),
    .ADDR(ADDR),
    .DATA(DATA)
);

// Generate CLK
initial begin
    CLK = 0;
    forever #5 CLK = ~CLK;   // 10ns period
end

integer i;
initial begin
    

    $display("Starting ROM Test...");

    for (i = 0; i < 100; i = i + 1) begin
        ADDR = i;
        @(posedge CLK);  // Wait two CLK period
        @(posedge CLK);  // 
        $display("ADDR=%02h DATA=%02h", ADDR, DATA);
    end

    $display("ROM Test Complete");
    $stop;
end
endmodule
