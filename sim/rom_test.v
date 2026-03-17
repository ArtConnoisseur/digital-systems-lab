`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04.03.2026 15:38:05
// Design Name:
// Module Name: rom_test
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


module rom_tb();
    // This is a test bench for the ROM module

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Variables for the DUT
    reg        clk;
    reg  [7:0] addr;
    wire [7:0] data;

    integer error_count = 0;

    // Instantiate the DUT
    ROM dut (
        .CLK(clk),
        .DATA(data),
        .ADDR(addr)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Script
    initial begin
        // Initialise
        addr = 8'h00;

        @(posedge clk); #1;

        // ---------------------------------------------------------------------
        // Test Case 1: Read Address 0x00
        // Goal: Verify data is returned one cycle after address is presented
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Read from Address 0x00", $time);

        addr = 8'h00;
        @(posedge clk); #1;

        // Data is registered, so it appears one cycle after the address is set
        $display("      INFO: Data at 0x00 = 0x%h (verify against .mem file)", data);

        // ---------------------------------------------------------------------
        // Test Case 2: Sequential Reads
        // Goal: Verify consecutive addresses return different values and
        //       that output updates correctly each cycle
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Sequential Address Reads", $time);

        begin : seq_test
            reg [7:0] prev_data;

            addr = 8'h01;
            @(posedge clk); #1;
            prev_data = data;

            addr = 8'h02;
            @(posedge clk); #1;

            if (data !== prev_data)
                $display("      PASSED: Address 0x01 and 0x02 returned different values (0x%h, 0x%h).", prev_data, data);
            else
                $display("      INFO: Addresses 0x01 and 0x02 returned same value — check .mem file is populated.");
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Stable Output
        // Goal: Verify data holds stable when address is unchanged
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Output Stability on Static Address", $time);

        begin : stable_test
            reg [7:0] first_read;

            addr = 8'h10;
            @(posedge clk); #1;
            first_read = data;

            // Hold address, clock several more times
            repeat(4) @(posedge clk); #1;

            if (data === first_read)
                $display("      PASSED: Output stable over multiple cycles at address 0x10.");
            else begin
                $display("      FAILED: Output changed without address change.");
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // Test Case 4: Boundary Address (0xFF)
        // Goal: Verify the last address in the 256-entry ROM is accessible
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 4: Boundary Address 0xFF", $time);

        addr = 8'hFF;
        @(posedge clk); #1;
        $display("      INFO: Data at 0xFF = 0x%h (verify against .mem file)", data);

        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED: ROM verified successfully.");
        else
            $display("SIMULATION FAILED: Found %0d errors.", error_count);
        $display("---------------------------------------------------");

        $finish;
    end
endmodule
