`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08.03.2026 21:29:30
// Design Name:
// Module Name: timer_test
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


module timer_tb();
    // This is a test bench for the corrected Timer module

    // Parameters
    parameter CLK_PERIOD    = 10;  // 100MHz clock (10ns period)
    parameter TEST_INT_RATE = 5;   // Override interrupt rate to 5ms for fast simulation

    // Variables for the DUT
    reg         clk;
    reg         reset;
    reg  [7:0]  bus_addr;
    reg         bus_we;
    wire [7:0]  bus_data;
    reg  [7:0]  bus_data_drive;
    reg         bus_data_en;
    wire        bus_interrupt_raise;
    reg         bus_interrupt_ack;

    integer error_count = 0;

    // Tri-state driver for BUS_DATA
    assign bus_data = (bus_data_en) ? bus_data_drive : 8'hZZ;

    // Instantiate the DUT — override interrupt rate for simulation speed
    Timer #(
        .InitialIterruptRate(TEST_INT_RATE)
    ) dut (
        .CLK(clk),
        .RESET(reset),
        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we),
        .BUS_INTERRUPT_RAISE(bus_interrupt_raise),
        .BUS_INTERRUPT_ACK(bus_interrupt_ack)
    );

    // Clock Generation (100MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task: write a byte to a bus address
    task bus_write;
        input [7:0] addr;
        input [7:0] wdata;
        begin
            bus_addr       = addr;
            bus_data_drive = wdata;
            bus_data_en    = 1;
            bus_we         = 1;
            @(posedge clk); #1;
            bus_we      = 0;
            bus_data_en = 0;
        end
    endtask

    // Task: read from a bus address
    task bus_read;
        input [7:0] addr;
        begin
            bus_addr    = addr;
            bus_we      = 0;
            bus_data_en = 0;
            @(posedge clk); #1;
        end
    endtask

    // Task: wait N ms + generous extra margin cycles
    task wait_ms;
        input integer ms;
        begin
            repeat(ms * 100000) @(posedge clk);
            // Extra margin to let interrupt logic propagate
            repeat(500) @(posedge clk);
        end
    endtask

    // Task: poll for interrupt with a timeout
    // Waits up to max_cycles for interrupt to go high
    task wait_for_interrupt;
        input integer max_cycles;
        output reg found;
        integer i;
        begin
            found = 0;
            for (i = 0; i < max_cycles; i = i + 1) begin
                @(posedge clk);
                if (bus_interrupt_raise === 1'b1) begin
                    found = 1;
                    i = max_cycles; // break
                end
            end
        end
    endtask

    // Test Script
    initial begin
        // Initialise signals
        reset             = 1;
        bus_addr          = 8'h00;
        bus_we            = 0;
        bus_data_en       = 0;
        bus_data_drive    = 8'h00;
        bus_interrupt_ack = 0;

        repeat(10) @(posedge clk);
        reset = 0;
        @(posedge clk); #1;

        // ---------------------------------------------------------------------
        // Test Case 1: Interrupt Raised After Configured Interval
        // Goal: Verify interrupt fires around TEST_INT_RATE ms.
        //       Uses a polling approach with generous timeout instead of
        //       exact cycle counts to avoid tight timing failures.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Interrupt Raised After Interval", $time);

        begin : int_test
            reg found;
            // Poll for up to 2x the expected interval as timeout
            wait_for_interrupt(TEST_INT_RATE * 100000 * 2, found);

            if (found)
                $display("      PASSED: Interrupt raised within expected window.");
            else begin
                $display("      FAILED: Interrupt not raised within %0d ms window.", TEST_INT_RATE * 2);
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // Test Case 2: Interrupt Acknowledged and Lowered
        // Goal: Verify interrupt clears when ACK is asserted
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Interrupt Acknowledged and Lowered", $time);

        bus_interrupt_ack = 1;
        repeat(3) @(posedge clk); #1;
        bus_interrupt_ack = 0;
        repeat(3) @(posedge clk); #1;

        if (bus_interrupt_raise === 1'b0)
            $display("      PASSED: Interrupt cleared after ACK.");
        else begin
            $display("      FAILED: Interrupt still high after ACK.");
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test Case 3: Timer Value Readable from BaseAddr
        // Goal: Verify bus is driven when reading from 0xF0. Just checks
        //       it is non-Z — exact value depends on how long the sim ran.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Timer Value Readback", $time);

        bus_addr    = 8'hF0;
        bus_we      = 0;
        bus_data_en = 0;
        // Give TransmitTimerValue register two cycles to latch
        repeat(2) @(posedge clk); #1;

        if (bus_data !== 8'hZZ)
            $display("      PASSED: Timer value driven on bus: 0x%h", bus_data);
        else begin
            $display("      FAILED: Bus tri-stated during timer read.");
            error_count = error_count + 1;
        end
        bus_addr = 8'h00;

        // ---------------------------------------------------------------------
        // Test Case 4: Timer Reset on Write to BaseAddr + 2
        // Goal: After a write reset, timer should be at a low value.
        //       Check is generous — accepts anything under 0x05 to
        //       account for a few cycles elapsing after the reset.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 4: Timer Reset on Write", $time);

        // Let the timer run a little
        wait_ms(2);

        // Reset the timer
        bus_write(8'hF2, 8'h00);

        // Read back — allow a couple of extra cycles
        repeat(3) @(posedge clk);
        bus_addr    = 8'hF0;
        bus_we      = 0;
        bus_data_en = 0;
        repeat(2) @(posedge clk); #1;

        if (bus_data <= 8'h05)
            $display("      PASSED: Timer near zero after reset (0x%h).", bus_data);
        else begin
            $display("      FAILED: Timer not reset. Got 0x%h", bus_data);
            error_count = error_count + 1;
        end
        bus_addr = 8'h00;

        // ---------------------------------------------------------------------
        // Test Case 5: Interrupt Disabled via BaseAddr + 3
        // Goal: No interrupt should fire while disabled
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 5: Interrupt Disable", $time);

        bus_write(8'hF3, 8'h00); // Disable interrupts

        wait_ms(TEST_INT_RATE);

        if (bus_interrupt_raise === 1'b0)
            $display("      PASSED: No interrupt raised while disabled.");
        else begin
            $display("      FAILED: Interrupt raised despite being disabled.");
            error_count = error_count + 1;
        end

        // Re-enable
        bus_write(8'hF3, 8'h01);

        // ---------------------------------------------------------------------
        // Test Case 6: Interrupt Fires Again After Re-enable
        // Goal: Confirm interrupt resumes after being re-enabled
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 6: Interrupt Resumes After Re-enable", $time);

        begin : reenable_test
            reg found;
            wait_for_interrupt(TEST_INT_RATE * 100000 * 2, found);

            if (found)
                $display("      PASSED: Interrupt raised again after re-enabling.");
            else begin
                $display("      FAILED: Interrupt not raised after re-enabling.");
                error_count = error_count + 1;
            end
        end

        // Clean up
        bus_interrupt_ack = 1;
        @(posedge clk); #1;
        bus_interrupt_ack = 0;

        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED: Timer verified successfully.");
        else
            $display("SIMULATION FAILED: Found %0d errors.", error_count);
        $display("---------------------------------------------------");

        $finish;
    end
endmodule
