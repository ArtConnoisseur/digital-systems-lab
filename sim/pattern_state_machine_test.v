`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.02.2026 16:57:17
// Design Name: 
// Module Name: pattern_state_machine_test
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


module pattern_state_machine_tb(
        // This is a test bench for the PatternStateMachine module 
        // for the Digital Systems Laboratory Lab
        
        // No ports needed for test bench 
    );
    
    // Initialisation 
    
    // Parameters (Not strictly required for this DUT, but kept for 
    // code clsrity)
    parameter CLK_PERIOD = 10;

    // Variables for the DUT
    reg clk;
    reg reset;
    reg [3:0] state_control;
    reg [7:0] x_in;
    reg [6:0] y_in;
    wire data_out;
    
    integer error_count = 0; 

    // Instantiate the DUT
    PatternStateMachine dut (
        .CLK(clk),
        .RESET(reset),
        .STATE_CONTROL(state_control),
        .X_IN(x_in),
        .Y_IN(y_in),
        .DATA_OUT(data_out)
    );

    // Clock Generation (100MHz)
    initial begin 
        clk = 0; 
        forever #(CLK_PERIOD/2) clk = ~clk;
    end 

    // Test Script
    initial begin
        // Initialize
        reset = 1;
        state_control = 4'b0000;
        x_in = 8'd0;
        y_in = 7'd0;
        
        #20 reset = 0; // Release reset
        
        // ---------------------------------------------------------------------
        // Test Case 1: State Transition and Basic Logic
        // Goal: Change to State 1 (OR logic) and verify output for X=1, Y=0
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Checking State 1 (OR logic) Transition", $time);
        
        // Request State 1
        state_control = 4'b0010; 
        x_in = 8'd1;
        y_in = 7'd0;
        
        @(posedge clk); // Trigger state change
        #1;             // Allow combinational DATA_OUT to settle
        
        // State 1 logic is (X[0] | Y[0]). With X=1, Y=0, result should be 1.
        if (data_out === 1'b1) 
            $display("      PASSED: State 1 logic correctly output 1 for X=1, Y=0.");
        else begin
            $display("      FAILED: State 1 logic error. Expected 1, got %b", data_out);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Pattern Specific Logic (State 0 - Array of Squares)
        // Goal: Verify NOR-based logic ~(X[0] | Y[0])
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Checking State 0 (Array of Squares) logic", $time);
        
        // 1. Request State 0 
        state_control = 4'b0001;
        
        // 2. Test "ON" condition: X and Y are both even (LSBs are 0)
        // ~(0 | 0) = 1
        x_in = 8'd0; 
        y_in = 7'd0;
        
        @(posedge clk); // Trigger state change
        #1;             // Allow combinational logic to propagate
        
        if (data_out === 1'b1)
            $display("      PASSED: State 0 correctly output 1 for X=0, Y=0 (Even/Even).");
        else begin
            $display("      FAILED: State 0 logic error at X=0, Y=0.");
            error_count = error_count + 1;
        end
        
        // 3. Test "OFF" condition: X is odd (LSB is 1)
        // ~(1 | 0) = 0
        x_in = 8'd1;
        y_in = 7'd0;
        #1;             // Delay to see change 
        
        if (data_out === 1'b0)
            $display("      PASSED: State 0 correctly output 0 for X=1, Y=0 (Odd/Even).");
        else begin
            $display("      FAILED: State 0 logic error at X=1, Y=0.");
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: Pattern logic verified successfully.");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");
        
        // End simulation 
        $finish;
    end
endmodule