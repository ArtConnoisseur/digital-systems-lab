`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08.02.2026 19:07:55
// Design Name:
// Module Name: colour_logic_test
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


module colour_logic_tb(
        // This is a test bench for the ColourLogic module
        // for the Digital Systems Laboratory Lab

        // No ports needed for test bench
    );

    // Initialisation

    // Parameters for this specific test
    parameter INPUT_PERIOD = 10;

    // Variables for the DUT
    reg clk;                    // Clock included for template consistency
    reg [7:0] colour_in_8;
    wire [11:0] colour_out_12;

    integer error_count = 0;

    // Instantiate the DUT
    ColourLogic dut (
        .COLOUR_IN_8(colour_in_8),
        .COLOUR_OUT_12(colour_out_12)
    );

    // Clock Generation (Kept for template structure)
    initial begin
        clk = 0;
        forever #(INPUT_PERIOD/2) clk = ~clk;
    end

    // Test Script
    initial begin
        // Initialize
        colour_in_8 = 8'h00;

        #20; // Short delay to start

        // ---------------------------------------------------------------------
        // Test Case 1: Red Channel and Bit Extension
        // Goal: Verify 3-bit Red (111) becomes 4-bit Red (1111)
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Checking Red Bit Extension", $time);

        colour_in_8 = 8'b0000_0111; // Red is max (7)
        #1; // Allow combinational logic to propagate

        // Expected: OUT[3:0] should be 4'hF (1111)
        if (colour_out_12[3:0] === 4'hF)
            $display("      PASSED: Red 3-bit max extended to 4-bit max.");
        else begin
            $display("      FAILED: Red extension error. Got %h", colour_out_12[3:0]);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Green Channel Replication
        // Goal: Verify 2-bit Green (10) replicates to 4-bit (1010)
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Checking Green Replication", $time);

        colour_in_8 = 8'b1000_0000; // Green bits are 10
        #1;

        // Expected: OUT[11:8] should be 4'b1010 (hex A)
        if (colour_out_12[11:8] === 4'hA)
            $display("      PASSED: Green 2-bit pattern successfully replicated.");
        else begin
            $display("      FAILED: Green replication error. Got %h", colour_out_12[11:8]);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Full White Verification
        // Goal: Verify 8-bit White (FF) converts to 12-bit White (FFF)
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Checking Full Scale White", $time);

        colour_in_8 = 8'hFF;
        #1;

        if (colour_out_12 === 12'hFFF)
            $display("      PASSED: 8-bit White converted to 12-bit White correctly.");
        else begin
            $display("      FAILED: Full scale conversion error. Got %h", colour_out_12);
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: Colour Logic verified successfully.");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");

        // End simulation
        $finish;
    end
endmodule
