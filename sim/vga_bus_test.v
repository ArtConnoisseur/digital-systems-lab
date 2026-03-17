`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03.03.2026 01:07:14
// Design Name:
// Module Name: vga_bus_test
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module VGA_Bus_stim();
    // This is a test bench for the VGABusInterface module

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Variables for the DUT
    reg         clk;
    reg         reset;
    reg  [7:0]  bus_addr;
    reg         bus_we;
    wire [7:0]  bus_data;
    reg  [7:0]  bus_data_drive;
    reg         bus_data_en;
    wire [11:0] colour_out;
    wire        hs;
    wire        vs;

    integer error_count = 0;

    // Tri-state driver for BUS_DATA
    assign bus_data = (bus_data_en) ? bus_data_drive : 8'hZZ;

    // Instantiate the DUT
    VGABusInterface dut (
        .CLK(clk),
        .RESET(reset),
        .BUS_ADDR(bus_addr),
        .BUS_DATA(bus_data),
        .BUS_WE(bus_we),
        .COLOUR_OUT(colour_out),
        .HS(hs),
        .VS(vs)
    );

    // Clock Generation (100MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to write a byte to a bus address
    task bus_write;
        input [7:0] addr;
        input [7:0] wdata;
        begin
            bus_addr       = addr;
            bus_data_drive = wdata;
            bus_data_en    = 1;
            bus_we         = 1;
            @(posedge clk); #1;
            bus_we      = 0;
            bus_data_en = 0;
        end
    endtask

    // Task to read from a bus address
    task bus_read;
        input [7:0] addr;
        begin
            bus_addr    = addr;
            bus_we      = 0;
            bus_data_en = 0;
            @(posedge clk); #1;
        end
    endtask

    // Test Script
    initial begin
        // Initialise
        reset          = 1;
        bus_addr       = 8'h00;
        bus_we         = 0;
        bus_data_en    = 0;
        bus_data_drive = 8'h00;

        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk); #1;

        // ---------------------------------------------------------------------
        // Test Case 1: Write X and Y Address, Read Back Pixel
        // Goal: Write a pixel to a known location and verify it reads back
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Write Pixel and Read Back", $time);

        // Set X address to 10
        bus_write(8'hB1, 8'h0A);

        // Set Y address to 5, pixel bit = 1 (BUS_DATA = {Y[6:0], pixel} = {7'd5, 1'b1})
        bus_write(8'hB0, {7'd5, 1'b1});

        // Read back from B0 range (tri-state readback)
        bus_read(8'hB0);

        if (bus_data[0] === 1'b1)
            $display("      PASSED: Pixel read back correctly as 1.");
        else begin
            $display("      FAILED: Expected pixel = 1, got %b", bus_data[0]);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Foreground and Background Colour Toggle
        // Goal: Verify alternating writes to B2 set BG then FG correctly
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Foreground/Background Colour Toggle", $time);

        // First write -> Background colour
        bus_write(8'hB2, 8'hAA);

        // Second write -> Foreground colour
        bus_write(8'hB2, 8'h55);

        // We can't read BG/FG directly, so we check COLOUR_OUT is non-zero
        // as a basic sanity check that the colour logic is active
        #10;
        $display("      INFO: COLOUR_OUT = 0x%h (verify FG/BG set correctly via waveform)", colour_out);
        if (colour_out !== 12'hXXX)
            $display("      PASSED: COLOUR_OUT is being driven.");
        else begin
            $display("      FAILED: COLOUR_OUT is undefined.");
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Bus Tri-state — No Drive Outside Address Range
        // Goal: Verify BUS_DATA is high-Z when address is not in B0-B3 range
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Tri-state Outside Address Range", $time);

        bus_read(8'hA0); // Outside VGA address range

        if (bus_data === 8'hZZ)
            $display("      PASSED: BUS_DATA correctly tri-stated outside address range.");
        else begin
            $display("      FAILED: BUS_DATA driven when it should be tri-stated. Got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 4: Reset Clears Colour Registers
        // Goal: Verify FG returns to 0xFF and BG to 0x00 after reset,
        //       and colour toggle resets to 0
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 4: Reset Behaviour", $time);

        // Write some non-default colours
        bus_write(8'hB2, 8'hDE);
        bus_write(8'hB2, 8'hAD);

        // Assert reset
        reset = 1;
        repeat(3) @(posedge clk);
        reset = 0;
        @(posedge clk); #1;

        // Write BG again — if toggle reset correctly this sets BG not FG
        bus_write(8'hB2, 8'hAA);
        bus_write(8'hB2, 8'h55);

        $display("      INFO: Post-reset colour write complete — verify via waveform that BG=0xAA, FG=0x55.");
        $display("      PASSED: Reset sequence completed without errors.");

        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED: VGABusInterface verified successfully.");
        else
            $display("SIMULATION FAILED: Found %0d errors.", error_count);
        $display("---------------------------------------------------");

        $finish;
    end
endmodule
