`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2026 19:07:55
// Design Name: 
// Module Name: generic_counter_test
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


module generic_counter_tb(
        // This is a test bench for the GenericCounter module 
        // for the Digital Systems Laboratory Lab
        
        // No ports needed for test bench 
    );
    
    // Initialisation 
    
    // Parameters for this specific test
    parameter WIDTH = 4;
    parameter MAX = 5;

    // Variables for the DUT
    reg clk;
    reg reset;
    reg enable;
    wire trig_out;
    wire [WIDTH-1:0] count;
    
    integer error_count = 0; 

    // Instantiate the DUT
    GenericCounter #(
        .COUNTER_WIDTH(WIDTH),
        .COUNTER_MAX(MAX)
    ) dut (
        .CLK(clk),
        .RESET(reset),
        .ENABLE(enable),
        .TRIG_OUT(trig_out),
        .COUNT(count)
    );

    // Clock Generation (100MHz)
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk;
    end 

    // Test Script
    initial begin
        // Initialize
        reset = 1;
        enable = 0;
        
        #20 reset = 0; // Release reset
        
        // ---------------------------------------------------------------------
        // Test Case 1: Enable Logic
        // Goal: Ensure it doesn't count when enable is 0
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Checking Enable Logic", $time);
        
        repeat(5) @(posedge clk);
        
        if (count === 0) 
            $display("      PASSED: Counter stayed at 0 while disabled.");
        else 
            $display("      FAILED: Counter moved without enable! Value: %d", count);

        // ---------------------------------------------------------------------
        // Test Case 2: Wrap-around and Trigger
        // Goal: Watch it hit the max and reset to 0
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Checking Wrap-around and Trigger", $time);
        
        // Reset the counter first 
        reset = 1; 
        #10;
        reset = 0; 
        enable = 1;

        // We want to reach the MAX (5). 
        // From 0 to 5 takes 5 clock edges.
        repeat(5) @(posedge clk);
        #1; // Offset to see logic update
        
        if (count === MAX && trig_out === 1)
            $display("      PASSED: Reached MAX (%d) and TRIG_OUT is high.", MAX);
        else
            $display("      FAILED: Expected %d, got %d. Trig: %b", MAX, count, trig_out);

        // One more clock cycle to see the wrap-around
        @(posedge clk);
        #1;

        if (count === 0)
            $display("      PASSED: Counter wrapped back to 0.");
        else
            $display("      FAILED: Counter did not wrap! Value: %d", count);

        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: Counter works exactly as expected");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");
        // End simulation 
        $finish;
    end
endmodule
