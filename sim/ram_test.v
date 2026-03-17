`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08.03.2026 21:07:33
// Design Name:
// Module Name: ram_test
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


module ram_tb();
    // This is a test bench for the RAM module

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Variables for the DUT
    reg         clk;
    reg  [7:0]  bus_addr;
    reg         bus_we;
    wire [7:0]  bus_data;
    reg  [7:0]  bus_data_drive;
    reg         bus_data_en;

    integer error_count = 0;

    // Tri-state driver for BUS_DATA
    assign bus_data = (bus_data_en) ? bus_data_drive : 8'hZZ;

    // Instantiate the DUT
    RAM dut (
        .CLK(clk),
        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Script
    initial begin
        // Initialise
        bus_we       = 0;
        bus_addr     = 8'h00;
        bus_data_en  = 0;
        bus_data_drive = 8'h00;

        @(posedge clk); #1;

        // ---------------------------------------------------------------------
        // Test Case 1: Write then Read Back
        // Goal: Verify a written value can be read back from the same address
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Write then Read Back", $time);

        bus_addr       = 8'h05;  
        bus_data_drive = 8'hA5;
        bus_data_en    = 1;
        bus_we         = 1;
        @(posedge clk); #1;

        // Switch to read
        bus_we      = 0;
        bus_data_en = 0;

        if (bus_data === 8'hA5)
            $display("      PASSED: Read back correct value 0xA5.");
        else begin
            $display("      FAILED: Expected 0xA5, got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Address Boundary — Upper Half Ignored (BUS_ADDR[7] = 1)
        // Goal: Verify RAM does not respond to addresses outside its range
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Upper Address Range Ignored", $time);

        bus_addr       = 8'h85;   // BUS_ADDR[7] = 1, outside RAM range
        bus_data_drive = 8'hFF;
        bus_data_en    = 1;
        bus_we         = 1;
        @(posedge clk); #1;

        bus_we      = 0;
        bus_data_en = 0;
        bus_addr    = 8'h85;
        @(posedge clk); #1;

        if (bus_data === 8'hZZ)
            $display("      PASSED: RAM correctly tristated for out-of-range address.");
        else begin
            $display("      FAILED: RAM drove bus for out-of-range address. Got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Multiple Sequential Writes and Reads
        // Goal: Verify different addresses are independently addressable
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Sequential Multi-Address Write/Read", $time);

        // Write 0x11 to address 0x01
        bus_addr = 8'h01; bus_data_drive = 8'h11; bus_data_en = 1; bus_we = 1;
        @(posedge clk); #1;

        // Write 0x22 to address 0x02
        bus_addr = 8'h02; bus_data_drive = 8'h22;
        @(posedge clk); #1;

        // Write 0x33 to address 0x03
        bus_addr = 8'h03; bus_data_drive = 8'h33;
        @(posedge clk); #1;

        // Read back address 0x01
        bus_we = 0; bus_data_en = 0; bus_addr = 8'h01;
        @(posedge clk); #1;
        if (bus_data === 8'h11)
            $display("      PASSED: Address 0x01 correct.");
        else begin
            $display("      FAILED: Address 0x01. Expected 0x11, got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        // Read back address 0x02
        bus_addr = 8'h02;
        @(posedge clk); #1;
        if (bus_data === 8'h22)
            $display("      PASSED: Address 0x02 correct.");
        else begin
            $display("      FAILED: Address 0x02. Expected 0x22, got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        // Read back address 0x03
        bus_addr = 8'h03;
        @(posedge clk); #1;
        if (bus_data === 8'h33)
            $display("      PASSED: Address 0x03 correct.");
        else begin
            $display("      FAILED: Address 0x03. Expected 0x33, got 0x%h", bus_data);
            error_count = error_count + 1;
        end

        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED: RAM verified successfully.");
        else
            $display("SIMULATION FAILED: Found %0d errors.", error_count);
        $display("---------------------------------------------------");

        $finish;
    end
endmodule
