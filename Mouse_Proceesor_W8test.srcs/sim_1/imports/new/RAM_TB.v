`timescale 1ns/1ps

// RAM_TB
// Reads all 128 addresses and verifies they are initialised to 0x00.
// No error during testing. It is OK.

module RAM_TB;

reg CLK;
reg BUS_WE;
reg [7:0] BUS_ADDR;
wire [7:0] BUS_DATA;

// TB never writes, so BUS_DATA is always high-Z from TB side
assign BUS_DATA = 8'hZZ;

// Instantiate RAM
RAM uut (
    .CLK(CLK),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE)
);

// 100 MHz clock
initial begin
    CLK = 0;
    forever #5 CLK = ~CLK;
end

integer i;
integer errors;

initial begin
    BUS_WE = 0;       // Read mode
    BUS_ADDR = 0;
    errors = 0;
    @(posedge CLK);

    $display("==== RAM INIT VERIFY: all 128 bytes should be 0x00 ====");

    for (i = 0; i < 128; i = i + 1) begin
        BUS_ADDR = i;
        @(posedge CLK);    // Present address
        @(posedge CLK);    // Wait for synchronous read

        if (BUS_DATA !== 8'h00) begin
            $display("ERROR: ADDR=%02h  DATA=%02h (expected 00)", BUS_ADDR, BUS_DATA);
            errors = errors + 1;
        end
    end

    if (errors == 0)
        $display("PASS: All 128 bytes are 0x00");
    else
        $display("FAIL: %0d errors found", errors);

    $display("==== DONE ====");
    $stop;
end

endmodule
