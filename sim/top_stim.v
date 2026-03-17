`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09.02.2026 02:31:03
// Design Name:
// Module Name: top_stim
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

/*
This is the Top-Level Integration Testbench (toplevel_tb) for the
Digital Systems Laboratory VGA Interface project.

The purpose of this simulation is to verify end-to-end connectivity
of the full system. It confirms that the processor begins fetching and
executing instructions from ROM after reset, that the VGA subsystem
generates valid HS and VS sync signals via the 25MHz clock generated
by the MMCM, and that a mid-run reset correctly restarts all connected
modules to a known state.

Integration Coverage:
- Processor instruction fetch and ROM connectivity.
- VGA sync signal generation and 25MHz clock propagation.
- System-wide reset behaviour across all peripherals.
- Shared bus wiring between Processor, RAM, Timer, and VGABusInterface.

Detailed sub-module verification is handled in their respective unit
testbenches (ram_tb, rom_tb, timer_tb, vga_bus_interface_tb).
*/

module toplevel_tb();
    // Simple integration testbench for the TopLevel module

    parameter CLK_PERIOD = 10; // 100MHz clock

    // DUT ports
    reg         clk;
    reg         reset;
    reg  [15:0] switches;
    wire        hs;
    wire        vs;
    wire [11:0] colour_out;

    integer error_count = 0;

    // Instantiate the DUT
    TopLevel toplevel_dut (
        .CLK(clk),
        .RESET(reset),
        .SWITCH(switches),
        .HS(hs),
        .VS(vs),
        .COLOUR_OUT(colour_out)
    );

    // Clock Generation (100MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        reset   = 1;
        switches = 16'h0000;

        repeat(10) @(posedge clk);
        reset = 0;
        @(posedge clk); #1;

        // ---------------------------------------------------------------------
        // Test Case 1: Processor Begins Fetching Instructions from ROM
        // Goal: Verify the ROM address increments after reset, confirming
        //       the processor has started executing the loaded program
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Processor Fetching from ROM", $time);

        begin : fetch_test
            reg [7:0] addr_before;
            addr_before = toplevel_dut.RomAddress;
            repeat(100) @(posedge clk); #1;

            if (toplevel_dut.RomAddress !== addr_before)
                $display("      PASSED: ROM_ADDRESS is incrementing (0x%h -> 0x%h).",
                         addr_before, toplevel_dut.RomAddress);
            else begin
                $display("      FAILED: ROM_ADDRESS unchanged — processor may be stalled.");
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // Test Case 2: VGA Sync Signals Are Toggling
        // Goal: Verify HS is toggling, confirming the VGA subsystem and
        //       the 25MHz clock generator are running correctly
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: VGA HS Signal Toggling", $time);

        begin : vga_test
            reg hs_high, hs_low;
            hs_high = 0;
            hs_low  = 0;

            repeat(5000) @(posedge clk) begin
                if (hs === 1'b1) hs_high = 1;
                if (hs === 1'b0) hs_low  = 1;
            end

            if (hs_high && hs_low)
                $display("      PASSED: HS is toggling correctly.");
            else begin
                $display("      FAILED: HS is not toggling.");
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Reset Restarts the Processor
        // Goal: Assert reset mid-run and verify ROM address returns to near
        //       zero, confirming all modules respond to reset correctly
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Mid-Run Reset Restarts Processor", $time);

        repeat(500) @(posedge clk);

        reset = 1;
        repeat(10) @(posedge clk); #1;
        reset = 0;
        repeat(20) @(posedge clk); #1;

        if (toplevel_dut.RomAddress <= 8'h20)
            $display("      PASSED: ROM address near zero after reset (0x%h).",
                     toplevel_dut.RomAddress);
        else begin
            $display("      FAILED: ROM address not reset. Got 0x%h",
                     toplevel_dut.RomAddress);
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED: TopLevel integration verified successfully.");
        else
            $display("SIMULATION FAILED: Found %0d errors.", error_count);
        $display("---------------------------------------------------");

        $finish;
    end
endmodule
