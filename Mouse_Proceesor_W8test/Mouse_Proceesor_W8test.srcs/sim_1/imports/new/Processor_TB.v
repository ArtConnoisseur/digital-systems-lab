`timescale 1ns/1ps

// Processor_TB
// Tests the processor executing the ROM demo program.
// Test 1: A=zz,it is high impidence without mouse peripharal respond(pass)
// Test 2: PC sequence 00 ¡ú 02 ¡ú 04 ¡ú 06 ¡ú 08 ¡ú 0A ¡ú 0C ¡ú 00(each 2 bits) (pass)

module Processor_TB;

reg CLK;
reg RESET;

// BUS
wire [7:0] BUS_DATA;
wire [7:0] BUS_ADDR;
wire BUS_WE;

// ROM
wire [7:0] ROM_ADDRESS;
wire [7:0] ROM_DATA;

// Interrupt
reg [1:0] BUS_INTERRUPTS_RAISE;
wire [1:0] BUS_INTERRUPTS_ACK;

// Instantiate Processor
Processor uut(
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .ROM_ADDRESS(ROM_ADDRESS),
    .ROM_DATA(ROM_DATA),
    .BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
    .BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
);

// Instantiate ROM
ROM rom_inst(
    .CLK(CLK),
    .ADDR(ROM_ADDRESS),
    .DATA(ROM_DATA)
);

// Instantiate RAM
RAM ram_inst(
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

// Track bus accesses for verification
integer addr_idx;
reg [7:0] expected_addr [0:5];
reg       expected_we   [0:5];
integer match_count;

initial begin
    // Expected address sequence per iteration
    expected_addr[0] = 8'hA0; expected_we[0] = 0; // READ  Mouse Status
    expected_addr[1] = 8'hC0; expected_we[1] = 1; // WRITE LEDs
    expected_addr[2] = 8'hA1; expected_we[2] = 0; // READ  Mouse X
    expected_addr[3] = 8'hD0; expected_we[3] = 1; // WRITE 7-Seg low
    expected_addr[4] = 8'hA2; expected_we[4] = 0; // READ  Mouse Y
    expected_addr[5] = 8'hD1; expected_we[5] = 1; // WRITE 7-Seg high
end

// Reset + Simulation
initial begin
    RESET = 1;
    BUS_INTERRUPTS_RAISE = 2'b01;  // Raise mouse interrupt (IRQ[0])
    addr_idx = 0;
    match_count = 0;

    #20;
    RESET = 0;

    // Run long enough for multiple loop iterations
    #2000;

    $display("=================================================");
    $display("FINAL STATE:");
    $display("  PC   = %h", uut.CurrProgCounter);
    $display("  RegA = %h", uut.CurrRegA);
    $display("  RegB = %h", uut.CurrRegB);
    $display("  Bus accesses matched: %0d", match_count);
    if (match_count >= 6)
        $display("  PASS: At least one full loop completed");
    else
        $display("  FAIL: Expected >= 6 matched accesses");
    $display("=================================================");

    $stop;
end

// Monitor: check bus address sequence
always @(posedge CLK) begin
    if (!RESET && (BUS_ADDR == expected_addr[addr_idx]) && (BUS_WE == expected_we[addr_idx])) begin
        match_count = match_count + 1;
        addr_idx = (addr_idx == 5) ? 0 : addr_idx + 1;
    end
end

// Debug trace
always @(posedge CLK) begin
    $display("Time=%0t | PC=%h | State=%h | A=%h | B=%h | BUS_ADDR=%h | WE=%b",
        $time,
        uut.CurrProgCounter,
        uut.CurrState,
        uut.CurrRegA,
        uut.CurrRegB,
        BUS_ADDR,
        BUS_WE
    );
end

endmodule
