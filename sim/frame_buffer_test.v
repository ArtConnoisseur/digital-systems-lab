`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.02.2026 16:57:17
// Design Name: 
// Module Name: frame_buffer_test
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

module frame_buffer_tb(
        // This is a test bench for the FrameBuffer module 
        // for the Digital Systems Laboratory Lab
        
        // No ports needed for test bench 
    );

    // Initialisation 
    
    // Inputs
    reg reset;       // Global Reset 
    
    // Port A 
    reg a_clk;       // 100MHz clock input
    reg a_we;        // Write Enable 
    reg [7:0] a_x;   // X pixel (0 to 159)
    reg [6:0] a_y;   // Y Pixel (0 to 119)
    reg a_data_in;   // Data to write
    wire a_data_out; // Data read back from Port A
    
    // Port B 
    reg b_clk;       // 25MHz VGA Clock 
    reg [7:0] b_x;   // X pixel (0 to 159)
    reg [6:0] b_y;   // Y pixel (0 to 119)
    wire b_data_out; // Data read out to VGA
    
    // Simulation Variables
    integer error_count; // To track when parts of the dut fail
    integer x_iter;      // Loop iterator for X
    integer y_iter;      // Loop iterator for Y
    reg expected_val;    // For verifying data
    
    // Design under test instance 
    FrameBuffer dut (
        .RESET(reset),
        
        .A_CLK(a_clk),
        .A_WE(a_we), 
        .AX(a_x),
        .AY(a_y),
        .A_DATA_IN(a_data_in), 
        .A_DATA_OUT(a_data_out),
        
        .B_CLK(b_clk), 
        .BX(b_x),
        .BY(b_y),
        .B_DATA(b_data_out) 
    ); 
    
    // Clock Generation
    
    // Generate 100MHz Port A Clock (10ns Period)
    initial begin 
        a_clk = 0; 
        forever #5 a_clk = ~a_clk;
    end 
    
    // Generate 25MHz Port B Clock (40ns Period)
    initial begin 
        b_clk = 0; 
        forever #20 b_clk = ~b_clk; 
    end
    
    // Task to write a single pixel via Port A
    task write_pixel_A;
        input [7:0] t_x;
        input [6:0] t_y;
        input t_val;
        
        begin
            @(posedge a_clk); // Sync with clock
            a_x = t_x;
            a_y = t_y;
            a_data_in = t_val;
            
            // Writing data 
            a_we = 1;
            @(posedge a_clk); // Hold for one cycle to write
            a_we = 0;         // Turn off write enable
        end
        
    endtask

    // Simulation code 
    
    initial begin 
        // Initialising inputs 
        $display("---------------------------------------------------");
        $display("Starting Simulation: FrameBuffer (160x120 Resolution)");
        $display("---------------------------------------------------");
        
        reset = 1;
        a_we = 0;
        a_x = 0; a_y = 0; a_data_in = 0;
        b_x = 0; b_y = 0;
        error_count = 0;
    
        // Hold reset for a bit
        #100;
        reset = 0;
        #20;

        // ---------------------------------------------------------------------
        // Test Case 1: Port A Write/Read Consistency
        // Goal: Write to (X=1, Y=0) and read it back immediately on Port A.
        // Address Calc: 0 * 160 + 1 = 1.
        // ---------------------------------------------------------------------
        
        $display("[Time %0t] Running Test Case 1: Port A Self-Consistency...", $time);
        
        // Write '1' to (1, 0)
        write_pixel_A(8'd1, 7'd0, 1'b1);
        
        // Wait 2 cycles to read 
        @(posedge a_clk); 
        @(posedge a_clk); 
        
        if (a_data_out !== 1'b1) begin
            $display("    FAILED: Port A Readback mismatch at (1,0). Expected 1, Got %b", a_data_out);
            error_count = error_count + 1;
        end else begin
            $display("    PASSED: Port A Readback correct.");
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Port B Dual-Port Retrieval
        // Goal: Write to Address 0x00FF (255) via Port A, read via Port B.
        // Mapping: 255 = (1 * 160) + 95. So Coordinates are X=95, Y=1.
        // ---------------------------------------------------------------------
        
        $display("[Time %0t] Running Test Case 2: Port B Dual-Port Retrieval...", $time);
        
        // Write '0' via Port A to X=95, Y=1
        write_pixel_A(8'd95, 7'd1, 1'b0);
        
        // Set up Port B to read that exact spot
        @(posedge b_clk);
        b_x = 8'd95;
        b_y = 7'd1;
        
        // Wait 2 cycles to read 
        @(posedge b_clk); 
        @(posedge b_clk); 

        // Verify
        if (b_data_out !== 1'b0) begin
            $display("    FAILED: Port B Readback mismatch at (95,1). Expected 0, Got %b", b_data_out);
            error_count = error_count + 1;
        end else begin
            $display("    PASSED: Port B Readback correct.");
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Full Resolution Verification (160x120)
        // Goal: Write a unique pattern to every pixel and verify readback.
        // Pattern: (x + y) % 2 (Creates a checkerboard)
        // ---------------------------------------------------------------------
        
        $display("[Time %0t] Running Test Case 3: Full 160x120 Grid Verification...", $time);
        $display("    Phase 1: Writing Checkerboard Pattern...");

        // Loop Y from 0 to 119
        for (y_iter = 0; y_iter < 120; y_iter = y_iter + 1) begin
            // Loop X from 0 to 159
            for (x_iter = 0; x_iter < 160; x_iter = x_iter + 1) begin
                
                // Calculate pattern: 1 if (x+y) is odd, 0 if even
                a_x = x_iter;
                a_y = y_iter;
                a_data_in = (x_iter + y_iter) % 2; 
                
                // Manual write pulse
                @(posedge a_clk);
                a_we = 1;
                @(posedge a_clk);
                a_we = 0;
            end
        end

        $display("    Phase 2: Verifying Pattern via Port B...");
        
        // Read back loop
        for (y_iter = 0; y_iter < 120; y_iter = y_iter + 1) begin
            for (x_iter = 0; x_iter < 160; x_iter = x_iter + 1) begin
                
                // Set Read Address
                @(posedge b_clk);
                b_x = x_iter;
                b_y = y_iter;
                
                // Wait for BRAM Read Latency
                @(posedge b_clk); 
                
                // Check Data
                expected_val = (x_iter + y_iter) % 2;
                
                if (b_data_out !== expected_val) begin
                    $display("    FAILED at (X:%d Y:%d). Expected %b, Got %b", 
                             x_iter, y_iter, expected_val, b_data_out);
                    error_count = error_count + 1;
                    
                    // Safety break if too many errors
                    if (error_count > 10) begin
                        $display("    ABORTING: Too many errors detected.");
                        y_iter = 120; // Condition to break outer loop
                        x_iter = 160; // Condition to break inner loop
                    end
                end
            end
        end

        // Simulation stats
        $display("---------------------------------------------------");
        if (error_count == 0) begin
            $display("ALL TEST CASES PASSED: All 19,200 pixels verified successfully.");
        end else begin
            $display("SIMULATION FAILED: Found %d errors.", error_count);
        end
        $display("---------------------------------------------------");
        
        // Stop the simulation
        #100;
        $finish;
    end
    
endmodule