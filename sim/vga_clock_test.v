`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08.02.2026 21:49:37
// Design Name:
// Module Name: vga_clock_test
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


module vga_clk_gen_tb(
        // This is a test bench for the VGA_CLK_GENERATOR_WIZ module
        // for the Digital Systems Laboratory Lab

        // No ports needed for test bench
    );

    // Initialisation

    // Parameters for this specific test
    parameter INPUT_PERIOD = 10; // 100MHz Input Clock

    // Variables for the DUT
    reg clk_in;
    reg reset;
    wire clk25;
    wire locked;

    integer error_count = 0;
    realtime t1, t2; // Used to measure clock period

    // Instantiate the DUT
    VGA_CLK_GENERATOR_WIZ dut (
        .CLK_IN(clk_in),
        .CLK25(clk25),
        .reset(reset),
        .locked(locked)
    );

    // Clock Generation (100MHz Input)
    initial begin
        clk_in = 0;
        forever #(INPUT_PERIOD/2) clk_in = ~clk_in;
    end

    // Test Script
    initial begin
        // Initialize
        reset = 1;

        #100 reset = 0; // Release reset after a short delay

        // ---------------------------------------------------------------------
        // Test Case 1: PLL Lock Phase
        // Goal: Ensure the 'locked' signal eventually goes high
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Waiting for PLL Lock...", $time);

        // Wait for locked signal (or timeout after 1000ns)
        wait(locked || $time > 1000);

        if (locked === 1'b1)
            $display("      PASSED: PLL locked successfully.");
        else begin
            $display("      FAILED: PLL failed to lock within 1000ns.");
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Frequency Verification
        // Goal: Measure the output period to ensure it is 40ns (25MHz)
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Checking CLK25 Frequency", $time);

        // Wait for two consecutive positive edges to measure the period
        @(posedge clk25);
        t1 = $realtime;
        @(posedge clk25);
        t2 = $realtime;

        // For 25MHz, period should be exactly 40ns
        if ((t2 - t1) == 40)
            $display("      PASSED: CLK25 period is %0t ns (25MHz).", t2 - t1);
        else begin
            $display("      FAILED: Expected 40ns period, got %0t ns.", t2 - t1);
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: Clock Generator verified successfully.");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");

        // End simulation
        $finish;
    end
endmodule
