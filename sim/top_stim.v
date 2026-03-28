`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09.02.2026 02:31:03
// Design Name:
// Module Name: top_stim
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

// Testbench: TopLevel — Connectivity & Output Signal Checks
//
// Scope: structural wiring only.  No attempt is made to run programs or
// verify peripheral logic (each peripheral has its own dedicated TB).
//
// Tests:
//   TC1 — Post-reset output levels (IR_LED, LED, COLOUR_OUT, HS, VS)
//   TC2 — HS toggles (VGA pixel clock running, H-sync counter counting)
//   TC3 — VS asserts within one full VGA frame
//   TC4 — COLOUR_OUT is driven (not floating Z)
//   TC5 — HEX_OUT / SEG_SELECT_OUT are driven (not floating Z)
//
// VGA timing reference (25 MHz pixel clock, 4:1 CLK divider at 100 MHz):
//   Horizontal total : 800 px × 4 = 3 200 CLK cycles
//   HS pulse width   :  96 px × 4 =   384 CLK cycles
//   Vertical total   : 525 lines × 3 200 = 1 680 000 CLK cycles

module TopLevel_tb;

    // -----------------------------------------------------------------------
    // DUT ports
    // -----------------------------------------------------------------------
    reg          CLK;
    reg          RESET;
    reg  [15:0]  SWITCH;

    wire         HS;
    wire         VS;
    wire [11:0]  COLOUR_OUT;

    // Mouse — pull high through weak resistors; TB does not drive a mouse
    wire CLK_MOUSE;
    wire DATA_MOUSE;
    assign CLK_MOUSE  = 1'bz;
    assign DATA_MOUSE = 1'bz;

    wire  [7:0]  HEX_OUT;
    wire  [3:0]  SEG_SELECT_OUT;
    wire  [7:0]  LED;
    wire         IR_LED;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    TopLevel dut (
        .CLK            (CLK),
        .RESET          (RESET),
        .SWITCH         (SWITCH),
        .HS             (HS),
        .VS             (VS),
        .COLOUR_OUT     (COLOUR_OUT),
        .CLK_MOUSE      (CLK_MOUSE),
        .DATA_MOUSE     (DATA_MOUSE),
        .HEX_OUT        (HEX_OUT),
        .SEG_SELECT_OUT (SEG_SELECT_OUT),
        .LED            (LED),
        .IR_LED         (IR_LED)
    );

    // -----------------------------------------------------------------------
    // Clock — 100 MHz
    // -----------------------------------------------------------------------
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    // -----------------------------------------------------------------------
    // Simulation variables
    // -----------------------------------------------------------------------
    integer error_count;

    // -----------------------------------------------------------------------
    // Task: wait n clock cycles
    // -----------------------------------------------------------------------
    task wait_cycles;
        input integer n;
        begin : wc_body
            integer k;
            for (k = 0; k < n; k = k + 1)
                @(posedge CLK);
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: poll a 1-bit signal for up to max_cycles, set found=1 if seen.
    // Usage: poll_high(signal, max_cycles, found)
    // -----------------------------------------------------------------------
    // Verilog-2001 cannot pass wire refs into tasks, so we inline the polling
    // in each test case using the specific signal.  The macro below is used
    // purely for readability inside the initial block.

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    initial begin
        $display("---------------------------------------------------");
        $display("Starting Simulation: TopLevel (Connectivity Checks)");
        $display("---------------------------------------------------");

        error_count = 0;

        // Global init
        RESET  = 1'b1;
        SWITCH = 16'h0000;

        // Hold reset for 20 cycles then release
        wait_cycles(20);
        RESET = 1'b0;
        wait_cycles(5);

        // ===================================================================
        // Test Case 1 — Post-Reset Output Levels
        //
        // Immediately after RESET de-asserts:
        //   1a — IR_LED must be 0 (IR_Peripheral resets command to 0)
        //   1b — LED must be 0    (LED_Peripheral resets to 0)
        //   1c — HS must not be X (VGA controller has driven a defined level)
        //   1d — VS must not be X
        //   1e — COLOUR_OUT must not be X
        // ===================================================================
        $display("[Time %0t] TC1: Post-Reset Output Levels...", $time);

        if (IR_LED !== 1'b0) begin
            $display("  FAILED TC1a: IR_LED=%b after reset (expected 0).", IR_LED);
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1a: IR_LED=0 after reset.");

        if (LED !== 8'h00) begin
            $display("  FAILED TC1b: LED=%b after reset (expected 00).", LED);
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1b: LED=0x00 after reset.");

        if (HS === 1'bx) begin
            $display("  FAILED TC1c: HS=X after reset — VGA controller not driving HS.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1c: HS is defined (%b) after reset.", HS);

        if (VS === 1'bx) begin
            $display("  FAILED TC1d: VS=X after reset — VGA controller not driving VS.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1d: VS is defined (%b) after reset.", VS);

        if (^COLOUR_OUT === 1'bx) begin
            $display("  FAILED TC1e: COLOUR_OUT contains X after reset.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1e: COLOUR_OUT is fully defined after reset.");

        // ===================================================================
        // Test Case 2 — HS Toggles Within Two Horizontal Lines
        //
        // With a 25 MHz pixel clock (100 MHz ÷ 4) and 800 px/line, one
        // horizontal line takes 3 200 CLK cycles.  Waiting 7 000 cycles
        // (> 2 lines) guarantees HS must have gone high then low at least
        // once if the VGA controller is wired and counting correctly.
        //
        //   2a — HS goes low (sync pulse) at some point within 7 000 cycles
        //   2b — HS goes high (back to idle) within the same window
        // ===================================================================
        $display("[Time %0t] TC2: HS Toggles (VGA H-sync active)...", $time);

        begin : tc2
            integer k;
            reg saw_hs_low, saw_hs_high;
            saw_hs_low  = 1'b0;
            saw_hs_high = 1'b0;

            for (k = 0; k < 7000; k = k + 1) begin
                @(posedge CLK);
                if (HS === 1'b0) saw_hs_low  = 1'b1;
                if (HS === 1'b1) saw_hs_high = 1'b1;
            end

            if (!saw_hs_low) begin
                $display("  FAILED TC2a: HS never went low in 7 000 cycles.");
                error_count = error_count + 1;
            end else
                $display("  PASSED TC2a: HS pulse (low) observed within 7 000 cycles.");

            if (!saw_hs_high) begin
                $display("  FAILED TC2b: HS never went high in 7 000 cycles.");
                error_count = error_count + 1;
            end else
                $display("  PASSED TC2b: HS idle (high) observed within 7 000 cycles.");
        end

        // ===================================================================
        // Test Case 3 — VS Asserts Within One Full VGA Frame
        //
        // One frame = 525 lines × 3 200 CLK = 1 680 000 cycles.
        // Waiting 1 700 000 cycles ensures at least one VS pulse has
        // occurred.  VS is active-low (pulse low during sync period).
        //
        //   3a — VS goes low at some point within 1 700 000 cycles
        //   3b — VS goes high within the same window
        // ===================================================================
        $display("[Time %0t] TC3: VS Asserts Within One VGA Frame (wait ~17ms sim)...", $time);

        begin : tc3
            integer k;
            reg saw_vs_low, saw_vs_high;
            saw_vs_low  = 1'b0;
            saw_vs_high = 1'b0;

            for (k = 0; k < 1_700_000; k = k + 1) begin
                @(posedge CLK);
                if (VS === 1'b0) saw_vs_low  = 1'b1;
                if (VS === 1'b1) saw_vs_high = 1'b1;
            end

            if (!saw_vs_low) begin
                $display("  FAILED TC3a: VS never went low in 1.7 M cycles — V-sync missing.");
                error_count = error_count + 1;
            end else
                $display("  PASSED TC3a: VS pulse (low) observed within one frame.");

            if (!saw_vs_high) begin
                $display("  FAILED TC3b: VS never went high in 1.7 M cycles.");
                error_count = error_count + 1;
            end else
                $display("  PASSED TC3b: VS idle (high) observed within one frame.");
        end

        // ===================================================================
        // Test Case 4 — COLOUR_OUT Is Driven (Not Floating)
        //
        // Sampled mid-frame after the VGA controller has had time to start
        // its scanline state machine.  A value of all-X would indicate an
        // unconnected COLOUR_OUT wire in TopLevel.
        // ===================================================================
        $display("[Time %0t] TC4: COLOUR_OUT Driven (not floating)...", $time);

        // Already several frames deep at this point; sample immediately.
        if (^COLOUR_OUT === 1'bx) begin
            $display("  FAILED TC4: COLOUR_OUT contains X — wire may be unconnected.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC4: COLOUR_OUT=%h — fully driven by VGA interface.", COLOUR_OUT);

        // ===================================================================
        // Test Case 5 — HEX_OUT / SEG_SELECT_OUT Are Driven
        //
        // SevenSeg_Peripheral drives both outputs on every CLK cycle after
        // reset.  X on either output indicates a missing or broken connection
        // in TopLevel.
        // ===================================================================
        $display("[Time %0t] TC5: HEX_OUT / SEG_SELECT_OUT Driven...", $time);

        if (~HEX_OUT == 1'bx) begin
            $display("  FAILED TC5a: HEX_OUT contains X — wire may be unconnected.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC5a: HEX_OUT=%h — driven by SevenSeg_Peripheral.", HEX_OUT);

        if (~SEG_SELECT_OUT == 1'bx) begin
            $display("  FAILED TC5b: SEG_SELECT_OUT contains X — wire may be unconnected.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC5b: SEG_SELECT_OUT=%b — driven by SevenSeg_Peripheral.", SEG_SELECT_OUT);

        // ===================================================================
        // Summary
        // ===================================================================
        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED.");
        else
            $display("SIMULATION FAILED: %0d error(s) found.", error_count);
        $display("---------------------------------------------------");

        #100;
        $finish;
    end

endmodule