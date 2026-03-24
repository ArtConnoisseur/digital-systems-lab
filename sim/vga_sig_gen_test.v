`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07.02.2026 16:57:17
// Design Name:
// Module Name: vga_sig_gen_test
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

module vga_sig_gen_test(
        // This is a test bench for the VGASigOut module
        // for the Digital Systems Laboratory Lab

        // No ports needed for test bench
    );

    // Declaring variables needed to connect to the design instance

    // Declaring variables needed to connect to the VGASignalOut instance

    parameter H_SYNC_PULSE = 10'd96;
    parameter H_BACK_PORCH = 10'd144;
    parameter H_DISPLAY    = 10'd784;
    parameter H_TOTAL      = 10'd800;

    parameter V_SYNC_PULSE = 10'd2;
    parameter V_BACK_PORCH = 10'd35;
    parameter V_DISPLAY    = 10'd515;
    parameter V_TOTAL      = 10'd525;

    reg clk;            // 25 MHz Clock
    reg reset;          // Reset signal
    reg [7:0] fg;       // Foreground color input
    reg [7:0] bg;       // Background color input

    // Frame buffer interface
    wire [7:0] x;       // X coordinate output to buffer
    wire [6:0] y;       // Y coordinate output to buffer
    reg vga_data;       // Data input coming from buffer

    // VGA Port outputs
    wire hs;            // Horizontal Sync
    wire vs;            // Vertical Sync
    wire [7:0] colour_out; // Final pixel color output

    // Simulation Variables
    integer error_count = 0; // To track when parts of the dut fail

    // Design under test instance
    VGASignalOut dut (
        .CLK(clk),
        .RESET(reset),
        .FG(fg),
        .BG(bg),

        .X(x),
        .Y(y),
        .VGA_DATA(vga_data),

        .HS(hs),
        .VS(vs),
        .COLOUR_OUT(colour_out)
    );

    // Clock Generation - 25MHz

    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end

    // Simulation code

    initial begin
        // Initialising inputs
        reset = 1;
        fg = 0; bg = 0;
        vga_data = 0;

        // Hold reset
        #100;
        reset = 0;

        // ---------------------------------------------------------------------
        // Test Case 1: Testing HS and VS
        // Goal: Once reset is off HS and VS should start automatically so we
        // just check at the appropriate times the signals are the right value
        // ---------------------------------------------------------------------

        $display("[Time %0t] Running Test Case 1: Testing HS and VS...", $time);

        // Check if HS and VS are 0 at the start

        if(hs == 0) begin
            $display("      PASSED: HS is zero at start");
        end else begin
            $display("      FAILED: HS is NOT zero at the start. Failed!");
        end

        if (vs == 1'b0) begin
            $display("      PASSED: VS is zero at start");
        end else begin
            $display("      FAILED: VS is NOT zero at the start. Failed!");
            error_count = error_count + 1;
        end

        // Wait 100 clock cycles
        repeat(H_SYNC_PULSE + 4) @(posedge clk);

        // After these many clock cycles, HS should be 1. Let's assert this
        if(hs == 1) begin
            $display("      SUCCESS: HS is one after 100 clock cycles.");
        end else begin
            $display("      FAILED: HS is not one after 100 clock cycles.");
            error_count = error_count + 1;
        end

        // Wait 1600 clock cycles
        repeat(H_TOTAL * 2 + 5) @(posedge clk);

        // After these many clock cycles, the horizontal counter should've triggered
        // the vertical counter, VS to 1 because vertical count is 2

        if(vs == 1) begin
            $display("      SUCCESS: VS is one after 1605 clock cycles.");
        end else begin
            $display("      FAILED: VS is not one after 1605 clock cycles.");
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Address Scaling (4x4 Rule)
        // Goal: Verify X = (CurrentPixel - BackPorch) / 4
        // ---------------------------------------------------------------------
        $display("[Time %0t] Running Test Case 2: Address Scaling...", $time);

        // 1. We need to get the counter into the active region.
        // Let's reset the system to start fresh at the beginning of a line.
        reset = 1; #40; reset = 0;

        // 2. Move to Pixel 148 (144 BackPorch + 4 pixels into display)
        repeat(H_BACK_PORCH + 4 + 1) @(posedge clk);
        #1; // Offset to see logic update

        // Calculation: (148 - 144) / 4 = 1.
        // We expect X to be 1.
        if (x === 8'd1) begin
            $display("      SUCCESS: X is scaled to 1 at pixel 148.");
        end else begin
            $display("      FAILED: X is %d, expected 1. Scaling logic error!", x);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Color Blanking
        // Goal: Ensure COLOUR_OUT is 0 during Front Porch/Sync Pulse
        // ---------------------------------------------------------------------
        $display("[Time %0t] Running Test Case 3: Color Blanking...", $time);

        // Drive VGA_DATA to 1 (as normally this would show a color)
        vga_data = 1'b1;
        fg = 8'hFF; // Set to a definite colour

        // Move to HorizontalCount = 790.
        // 790 is in the Front Porch/Blanking)
        reset = 1; #40; reset = 0; // Restart line
        repeat(790) @(posedge clk);
        #1;

        // Even though VGA_DATA is 1 and FG is FF, the output MUST be 0
        if (colour_out === 8'h00) begin
            $display("      SUCCESS: Output is blacked out during Front Porch.");
        end else begin
            $display("      FAILED: COLOUR_OUT is %h during blanking. Safety hazard!", colour_out);
            error_count = error_count + 1;
        end

        // Simulation stats
        $display("-------------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: VGA Works correctly within the correct parameter limits");
        end else begin
            $display("SIMULATION FAILED: Found %d errors", error_count);
        end
        $display("-------------------------------------------------------");

        // End simulation
        $finish;
    end

endmodule
