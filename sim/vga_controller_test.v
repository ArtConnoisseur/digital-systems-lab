`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08.02.2026 21:49:37
// Design Name:
// Module Name: vga_controller_test
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


module vga_display_controller_tb(
        // This is a test bench for the VGADisplayController module
        // for the Digital Systems Laboratory Lab

        // No ports needed for test bench
    );

    // Initialisation

    // Parameters for this specific test
    parameter INPUT_PERIOD = 10;   // 100MHz Input Clock
    parameter TEST_COL_FREQ = 20;  // Override 1s delay to 20 cycles for simulation efficiency

    // Variables for the DUT
    reg clk;
    reg reset;
    reg [7:0] fg_in, bg_in;
    wire [7:0] fg_out, bg_out;
    wire [7:0] x;
    wire [6:0] y;

    integer error_count = 0;

    // Instantiate the DUT
    VGADisplayController #(
        .COL_CHANGE_FREQ(TEST_COL_FREQ) // Overriding parameter for fast simulation
    ) dut (
        .CLK(clk),
        .RESET(reset),
        .FG_IN(fg_in),
        .BG_IN(bg_in),
        .FG_OUT(fg_out),
        .BG_OUT(bg_out),
        .X(x),
        .Y(y)
    );

    // Clock Generation (100MHz Input)
    initial begin
        clk = 0;
        forever #(INPUT_PERIOD/2) clk = ~clk;
    end

    // Test Script
    initial begin
        // Initialize
        reset = 1;
        fg_in = 8'hAA; // 10101010
        bg_in = 8'h0F; // 00001111

        #100 reset = 0; // Release reset

        // ---------------------------------------------------------------------
        // Test Case 1: Pixel Address Counter (X and Y)
        // Goal: Verify X wraps at 159 and increments Y
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Verifying Address Wrapping", $time);

        // Wait for X to finish its first row (160 cycles)
        repeat(160) @(posedge clk);
        #1; // Offset to observe update

        if (x === 8'd0 && y === 7'd1)
            $display("      PASSED: X wrapped to 0 and Y incremented to 1.");
        else begin
            $display("      FAILED: Address error. X:%d Y:%d", x, y);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Colour Complement Logic
        // Goal: Verify output colors invert after TEST_COL_FREQ cycles
        // ---------------------------------------------------------------------
        reset = 1;
        #20;
        reset = 0;

        $display("[Time %0t] Case 2: Verifying Colour Toggling", $time);

        // Wait for the color change trigger to fire
        repeat(TEST_COL_FREQ) @(posedge clk);
        #1;

        // Inverted AA should be 55, Inverted 0F should be F0
        if (fg_out === 8'h55 && bg_out === 8'hF0)
            $display("      PASSED: Colours successfully complemented.");
        else begin
            $display("      FAILED: Colour logic error. FG_OUT:%h and BG_OUT:%h", fg_out, bg_out);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Reset Behaviour
        // Goal: Ensure colour returns to original state on Reset
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Verifying Reset State", $time);

        reset = 1;
        #20;

        if (fg_out === fg_in)
            $display("      PASSED: Reset restored original colours.");
        else begin
            $display("      FAILED: Reset did not clear complement flag.");
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: Display Controller verified successfully.");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");

        // End simulation
        $finish;
    end
endmodule
