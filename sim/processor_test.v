`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04.03.2026 14:57:10
// Design Name:
// Module Name: processor_test
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


module ProcessorTB();

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    reg         CLK;
    reg         RESET;
    wire [7:0]  BUS_DATA;
    wire [7:0]  BUS_ADDR;
    wire        BUS_WE;
    wire [7:0]  ROM_ADDRESS;
    wire [7:0]  ROM_DATA;
    reg  [1:0]  BUS_INTERRUPTS_RAISE;
    wire [1:0]  BUS_INTERRUPTS_ACK;

    integer error_count = 0;

    // -------------------------------------------------------------------------
    // DUT Instances
    // -------------------------------------------------------------------------
    RAM uut1 (
        .CLK      (CLK),
        .BUS_DATA (BUS_DATA),
        .BUS_ADDR (BUS_ADDR),
        .BUS_WE   (BUS_WE)
    );

    ROM uut2 (
        .CLK  (CLK),
        .DATA (ROM_DATA),
        .ADDR (ROM_ADDRESS)
    );

    Processor uut3 (
        .CLK                  (CLK),
        .RESET                (RESET),
        .BUS_DATA             (BUS_DATA),
        .BUS_ADDR             (BUS_ADDR),
        .BUS_WE               (BUS_WE),
        .ROM_ADDRESS          (ROM_ADDRESS),
        .ROM_DATA             (ROM_DATA),
        .BUS_INTERRUPTS_RAISE (BUS_INTERRUPTS_RAISE),
        .BUS_INTERRUPTS_ACK   (BUS_INTERRUPTS_ACK)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // -------------------------------------------------------------------------
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // -------------------------------------------------------------------------
    // Task: wait_for_idle
    // Blocks until CurrState == IDLE (0xF0) or timeout expires.
    // timeout is in clock cycles.
    // -------------------------------------------------------------------------
    task wait_for_idle;
        input integer timeout;
        integer i;
        begin
            i = 0;
            while (uut3.CurrState !== 8'hF0 && i < timeout) begin
                @(posedge CLK);
                i = i + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Simulation Script
    // -------------------------------------------------------------------------
    initial begin
        RESET                = 1'b0;
        BUS_INTERRUPTS_RAISE = 2'b00;

        // ---------------------------------------------------------------------
        // Pre-load RAM constants via hierarchical reference.
        //
        // The ROM program reads all its constants and working variables from RAM,
        // so these must be valid before execution starts.  In synthesis this is
        // handled by Complete_Demo_RAM.txt.
        //
        // X_limit and Y_limit are reduced to 4 (from 160/120) so the VGA fill
        // loop completes in ~1500 cycles rather than ~500,000, making interrupt
        // tests reachable within simulation time.
        // ---------------------------------------------------------------------
        @(posedge CLK); // one cycle before reset so writes settle
        uut1.Mem[8'h00] = 8'h00; // X counter (init to 0)
        uut1.Mem[8'h01] = 8'h00; // Y counter (init to 0)
        uut1.Mem[8'h02] = 8'h00; // pixel scratch
        uut1.Mem[8'h03] = 8'h00; // x_even
        uut1.Mem[8'h04] = 8'h00; // y_even
        uut1.Mem[8'h05] = 8'h00; // const 0
        uut1.Mem[8'h06] = 8'h01; // const 1
        uut1.Mem[8'h07] = 8'h04; // X_limit = 4  (reduced from 160 for simulation)
        uut1.Mem[8'h08] = 8'h04; // Y_limit = 4  (reduced from 120 for simulation)
        uut1.Mem[8'h09] = 8'h00; // Y<<1 scratch
        uut1.Mem[8'h0A] = 8'h00; // timer_count
        uut1.Mem[8'h0B] = 8'h0A; // timer_limit = 10
        uut1.Mem[8'h0C] = 8'hFF; // colour: White
        uut1.Mem[8'h0D] = 8'h0F; // colour: Teal
        uut1.Mem[8'h0E] = 8'h15; // colour: Red
        uut1.Mem[8'h0F] = 8'h00; // colour: Black
        uut1.Mem[8'h10] = 8'h00; // colour toggle flag

        // ---------------------------------------------------------------------
        // Test 1: Reset Behaviour
        //
        // After reset the processor latches:
        //   CurrState        = 8'h00  (CHOOSE_OPP - NOT IDLE)
        //   CurrProgCounter  = 8'h00
        //   CurrRegA/B       = 8'h00
        // Execution begins immediately from ROM[0x00].
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 1: Verifying Reset Behaviour", $time);

        RESET = 1'b1;
        @(posedge CLK);
        RESET = 1'b0;
        @(posedge CLK);

        if (uut3.CurrState       === 8'h00 &&
            uut3.CurrRegA        === 8'h00 &&
            uut3.CurrRegB        === 8'h00 &&
            uut3.CurrProgCounter === 8'h00)
            $display("      PASSED: Reset correct. State=CHOOSE_OPP(0x00), PC=0x00, RegA=0x00, RegB=0x00");
        else begin
            $display("      FAILED: State=0x%h, PC=0x%h, RegA=0x%h, RegB=0x%h",
                uut3.CurrState, uut3.CurrProgCounter, uut3.CurrRegA, uut3.CurrRegB);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 2: Processor Begins Execution Immediately on Reset
        //
        // Unlike a typical processor that boots to an idle/halt state, this
        // processor resets into CHOOSE_OPP (0x00) and immediately begins
        // executing the init code at ROM address 0x00.  IDLE (0xF0) is only
        // reached when a GOTO_IDLE instruction is executed (at 0x69 after the
        // VGA fill completes, or via interrupt handlers).
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 2: Verifying Processor Begins Execution on Reset (Not IDLE)", $time);

        RESET = 1'b1;
        @(posedge CLK);
        RESET = 1'b0;
        repeat(5) @(posedge CLK);

        if (uut3.CurrState !== 8'hF0)
            $display("      PASSED: Processor is executing (State=0x%h). Correctly not in IDLE at startup.",
                uut3.CurrState);
        else begin
            $display("      FAILED: Processor is in IDLE at startup - ROM init code should be executing.");
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 3: Processor Reaches IDLE After VGA Fill Completes
        //
        // With X_limit=4 and Y_limit=4 the fill loop runs 16 iterations and
        // hits GOTO_IDLE at 0x69 within ~1500 cycles.  We allow 3000 cycles.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 3: Verifying Processor Reaches IDLE After VGA Fill", $time);

        // Fresh reset so we start the fill from scratch
        RESET = 1'b1;
        @(posedge CLK);
        RESET = 1'b0;

        wait_for_idle(3000);

        if (uut3.CurrState === 8'hF0)
            $display("      PASSED: Processor reached IDLE after VGA fill. PC=0x%h", uut3.CurrProgCounter);
        else begin
            $display("      FAILED: Processor did not reach IDLE within 3000 cycles. State=0x%h, PC=0x%h",
                uut3.CurrState, uut3.CurrProgCounter);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 4: Interrupt 0 (Mouse) - Accepted from IDLE
        //
        // Mouse interrupt vector: ROM[0xFF] = 0x69.
        // When accepted from IDLE:
        //   - NextProgCounter set to 0xFF
        //   - State transitions through GET_THREAD_START_ADDR pipeline
        //   - PC then loaded with ROM[0xFF] = 0x69
        //   - ROM[0x69] = 0x08 (GOTO_IDLE), so processor returns to IDLE quickly
        //
        // We check that one cycle after the interrupt the PC has moved to 0xFF
        // (confirming the interrupt was accepted and the vector fetch began).
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 4: Verifying Interrupt 0 (Mouse) Accepted from IDLE", $time);

        // Processor should already be in IDLE from Test 3; guard anyway
        if (uut3.CurrState !== 8'hF0) wait_for_idle(100);

        BUS_INTERRUPTS_RAISE = 2'b01;
        @(posedge CLK); // IDLE processes interrupt: NextPC=0xFF, NextState=GET_THREAD_0
        BUS_INTERRUPTS_RAISE = 2'b00;
        @(posedge CLK); // CurrState=GET_THREAD_0(0xF1), CurrPC=0xFF  <-- check here

        if (uut3.CurrState !== 8'hF0 && uut3.CurrProgCounter === 8'hFF)
            $display("      PASSED: Interrupt 0 accepted. State=0x%h, PC=0xFF (fetching vector).",
                uut3.CurrState);
        else begin
            $display("      FAILED: Interrupt 0 not handled. State=0x%h, PC=0x%h",
                uut3.CurrState, uut3.CurrProgCounter);
            error_count = error_count + 1;
        end

        // Mouse handler is GOTO_IDLE (ROM[0x69]=0x08) so processor returns to IDLE
        repeat(15) @(posedge CLK);
        if (uut3.CurrState === 8'hF0)
            $display("      PASSED: Processor returned to IDLE after mouse handler (GOTO_IDLE at 0x69).");
        else begin
            $display("      FAILED: Processor did not return to IDLE. State=0x%h", uut3.CurrState);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 5: Interrupt 1 (Timer) - Accepted from IDLE
        //
        // Timer vector: ROM[0xFE] = 0x70 (start of timer handler).
        // Timer handler increments timer_count, checks against limit, then idles.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 5: Verifying Interrupt 1 (Timer) Accepted from IDLE", $time);

        if (uut3.CurrState !== 8'hF0) wait_for_idle(100);

        BUS_INTERRUPTS_RAISE = 2'b10;
        @(posedge CLK); // IDLE processes: NextPC=0xFE, NextState=GET_THREAD_0
        BUS_INTERRUPTS_RAISE = 2'b00;
        @(posedge CLK); // CurrPC=0xFE, CurrState=GET_THREAD_0  <-- check here

        if (uut3.CurrState !== 8'hF0 && uut3.CurrProgCounter === 8'hFE)
            $display("      PASSED: Interrupt 1 accepted. State=0x%h, PC=0xFE (fetching timer vector).",
                uut3.CurrState);
        else begin
            $display("      FAILED: Interrupt 1 not handled. State=0x%h, PC=0x%h",
                uut3.CurrState, uut3.CurrProgCounter);
            error_count = error_count + 1;
        end

        // Timer handler is short - wait for it to finish and return to IDLE
        wait_for_idle(200);
        if (uut3.CurrState === 8'hF0)
            $display("      PASSED: Processor returned to IDLE after timer handler.");
        else begin
            $display("      FAILED: Timer handler did not complete. State=0x%h, PC=0x%h",
                uut3.CurrState, uut3.CurrProgCounter);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 6: Interrupt Priority - Both Raised Simultaneously
        //
        // Interrupt 0 (mouse) is checked first in the IDLE case statement, so
        // it takes priority.  PC should be set to 0xFF (mouse vector), not 0xFE.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 6: Verifying Interrupt Priority (Both Raised)", $time);

        if (uut3.CurrState !== 8'hF0) wait_for_idle(100);

        BUS_INTERRUPTS_RAISE = 2'b11; // Both raised simultaneously
        @(posedge CLK);
        BUS_INTERRUPTS_RAISE = 2'b00;
        @(posedge CLK);

        if (uut3.CurrProgCounter === 8'hFF)
            $display("      PASSED: Interrupt 0 took priority. PC=0xFF (mouse vector).");
        else begin
            $display("      FAILED: Wrong interrupt prioritised. PC=0x%h (expected 0xFF).",
                uut3.CurrProgCounter);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Test 7: BUS_WE and Tristate Behaviour
        //
        // BUS_WE should only be asserted during WRITE_TO_MEM_0.
        // In all other states NextBusDataOutWE defaults to 0.
        // Verified here by checking the processor is not writing while in a
        // non-write state shortly after reset.
        // ---------------------------------------------------------------------
        $display("[Time %0t] Case 7: Verifying BUS_WE Tristate Behaviour", $time);

        RESET = 1'b1;
        @(posedge CLK);
        RESET = 1'b0;
        @(posedge CLK); // CurrState = CHOOSE_OPP, reading opcode - not writing

        if (uut3.CurrBusDataOutWE === 1'b0)
            $display("      PASSED: BUS_WE deasserted in non-write state (State=0x%h).", uut3.CurrState);
        else begin
            $display("      FAILED: BUS_WE unexpectedly asserted. State=0x%h", uut3.CurrState);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        $display("-------------------------------------------------------");
        if (error_count == 0)
            $display("PROCESSOR TESTBENCH PASSED: All %0d tests verified.", 7);
        else
            $display("PROCESSOR TESTBENCH FAILED: %0d error(s) found.", error_count);
        $display("-------------------------------------------------------");

        $finish;
    end

endmodule
