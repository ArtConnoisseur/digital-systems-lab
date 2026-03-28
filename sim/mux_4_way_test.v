`timescale 1ns / 1ps

module MUX_4way_tb;

    // -----------------------------------------------------------------------
    // Two DUT instances to cover the WIDTH parameter:
    //   dut5  — default WIDTH=5  (used for all functional tests)
    //   dut8  — WIDTH=8          (used for TC4 width check)
    // -----------------------------------------------------------------------
    localparam W5 = 5;
    localparam W8 = 8;

    // -- DUT5 ports ----------------------------------------------------------
    reg  [1:0]    ctrl5;
    reg  [W5-1:0] in0_5, in1_5, in2_5, in3_5;
    wire [W5-1:0] out5;

    MUX_4way #(.WIDTH(W5)) dut5 (
        .CONTROL (ctrl5),
        .IN0     (in0_5), .IN1 (in1_5),
        .IN2     (in2_5), .IN3 (in3_5),
        .OUT     (out5)
    );

    // -- DUT8 ports ----------------------------------------------------------
    reg  [1:0]    ctrl8;
    reg  [W8-1:0] in0_8, in1_8, in2_8, in3_8;
    wire [W8-1:0] out8;

    MUX_4way #(.WIDTH(W8)) dut8 (
        .CONTROL (ctrl8),
        .IN0     (in0_8), .IN1 (in1_8),
        .IN2     (in2_8), .IN3 (in3_8),
        .OUT     (out8)
    );

    // -----------------------------------------------------------------------
    // Simulation variables
    // -----------------------------------------------------------------------
    integer error_count;

    // -----------------------------------------------------------------------
    // Task: apply inputs to dut5, wait for propagation, check output.
    //   t_ctrl    — CONTROL value to apply
    //   t_expect  — expected OUT value
    //   t_label   — description string printed in pass/fail message
    // -----------------------------------------------------------------------
    task check5;
        input [1:0]    t_ctrl;
        input [W5-1:0] t_expect;
        input [63:0]   t_label;   // up to 8-char ASCII label packed into 64 bits
        begin
            ctrl5 = t_ctrl;
            #10;  // Allow combinational logic to settle
            if (out5 !== t_expect) begin
                $display("  FAILED [%s]: CONTROL=%b — Expected %b, Got %b",
                         t_label, t_ctrl, t_expect, out5);
                error_count = error_count + 1;
            end else
                $display("  PASSED [%s]: CONTROL=%b — OUT=%b correct.",
                         t_label, t_ctrl, out5);
        end
    endtask

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    initial begin
        $display("---------------------------------------------------");
        $display("Starting Simulation: MUX_4way (WIDTH=5 / WIDTH=8)");
        $display("---------------------------------------------------");

        error_count = 0;

        // Initialise all dut5 inputs to known values
        ctrl5 = 2'b00;
        in0_5 = 5'b00000; in1_5 = 5'b00000;
        in2_5 = 5'b00000; in3_5 = 5'b00000;

        // Initialise dut8
        ctrl8 = 2'b00;
        in0_8 = 8'h00; in1_8 = 8'h00;
        in2_8 = 8'h00; in3_8 = 8'h00;
        #10;

        // ===================================================================
        // Test Case 1 — All Four Control Values Select the Correct Input
        //
        // Each input is given a unique value so a wrong selection is
        // immediately distinguishable from a correct one.
        //   IN0 = 5'b00001 (1)
        //   IN1 = 5'b00010 (2)
        //   IN2 = 5'b00100 (4)
        //   IN3 = 5'b01000 (8)
        // ===================================================================
        $display("[Time %0t] TC1: Control Word Selection...", $time);

        in0_5 = 5'd1; in1_5 = 5'd2; in2_5 = 5'd4; in3_5 = 5'd8;

        check5(2'b00, 5'd1, "SEL_IN0");
        check5(2'b01, 5'd2, "SEL_IN1");
        check5(2'b10, 5'd4, "SEL_IN2");
        check5(2'b11, 5'd8, "SEL_IN3");

        // ===================================================================
        // Test Case 2 — Selected Input Change Propagates to Output
        //
        // While CONTROL is held at each value, change the currently-selected
        // input and verify that OUT tracks it immediately.
        // ===================================================================
        $display("[Time %0t] TC2: Dynamic Input Change Propagation...", $time);

        // CONTROL = 00 → monitor IN0
        ctrl5 = 2'b00;
        in0_5 = 5'b10101; #10;
        if (out5 !== 5'b10101) begin
            $display("  FAILED TC2/IN0 (a): Expected 10101, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN0 (a): OUT tracks IN0 change to 10101.");

        in0_5 = 5'b01010; #10;
        if (out5 !== 5'b01010) begin
            $display("  FAILED TC2/IN0 (b): Expected 01010, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN0 (b): OUT tracks IN0 change to 01010.");

        // CONTROL = 01 → monitor IN1
        ctrl5 = 2'b01;
        in1_5 = 5'b11001; #10;
        if (out5 !== 5'b11001) begin
            $display("  FAILED TC2/IN1 (a): Expected 11001, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN1 (a): OUT tracks IN1 change to 11001.");

        in1_5 = 5'b00110; #10;
        if (out5 !== 5'b00110) begin
            $display("  FAILED TC2/IN1 (b): Expected 00110, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN1 (b): OUT tracks IN1 change to 00110.");

        // CONTROL = 10 → monitor IN2
        ctrl5 = 2'b10;
        in2_5 = 5'b11111; #10;
        if (out5 !== 5'b11111) begin
            $display("  FAILED TC2/IN2 (a): Expected 11111, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN2 (a): OUT tracks IN2 change to 11111.");

        in2_5 = 5'b00001; #10;
        if (out5 !== 5'b00001) begin
            $display("  FAILED TC2/IN2 (b): Expected 00001, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN2 (b): OUT tracks IN2 change to 00001.");

        // CONTROL = 11 → monitor IN3
        ctrl5 = 2'b11;
        in3_5 = 5'b10000; #10;
        if (out5 !== 5'b10000) begin
            $display("  FAILED TC2/IN3 (a): Expected 10000, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN3 (a): OUT tracks IN3 change to 10000.");

        in3_5 = 5'b01111; #10;
        if (out5 !== 5'b01111) begin
            $display("  FAILED TC2/IN3 (b): Expected 01111, Got %b", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC2/IN3 (b): OUT tracks IN3 change to 01111.");

        // ===================================================================
        // Test Case 3 — Unselected Inputs Do Not Affect Output
        //
        // Hold CONTROL fixed, set the selected input to a stable value,
        // then toggle every *other* input through all-ones and all-zeros.
        // OUT must not change.
        // ===================================================================
        $display("[Time %0t] TC3: Unselected Input Isolation...", $time);

        // CONTROL = 00 → OUT should only follow IN0
        ctrl5 = 2'b00;
        in0_5 = 5'b10101;
        in1_5 = 5'b00000; in2_5 = 5'b00000; in3_5 = 5'b00000; #10;

        in1_5 = 5'b11111; #10;
        if (out5 !== 5'b10101) begin
            $display("  FAILED TC3/IN0: IN1 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN0 (a): IN1 toggle does not affect OUT.");

        in2_5 = 5'b11111; #10;
        if (out5 !== 5'b10101) begin
            $display("  FAILED TC3/IN0: IN2 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN0 (b): IN2 toggle does not affect OUT.");

        in3_5 = 5'b11111; #10;
        if (out5 !== 5'b10101) begin
            $display("  FAILED TC3/IN0: IN3 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN0 (c): IN3 toggle does not affect OUT.");

        // CONTROL = 11 → OUT should only follow IN3
        ctrl5  = 2'b11;
        in3_5  = 5'b01010;
        in0_5  = 5'b00000; in1_5 = 5'b00000; in2_5 = 5'b00000; #10;

        in0_5 = 5'b11111; #10;
        if (out5 !== 5'b01010) begin
            $display("  FAILED TC3/IN3: IN0 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN3 (a): IN0 toggle does not affect OUT.");

        in1_5 = 5'b11111; #10;
        if (out5 !== 5'b01010) begin
            $display("  FAILED TC3/IN3: IN1 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN3 (b): IN1 toggle does not affect OUT.");

        in2_5 = 5'b11111; #10;
        if (out5 !== 5'b01010) begin
            $display("  FAILED TC3/IN3: IN2 change corrupted OUT (got %b).", out5);
            error_count = error_count + 1;
        end else $display("  PASSED TC3/IN3 (c): IN2 toggle does not affect OUT.");

        // ===================================================================
        // Test Case 4 — WIDTH Parameter Correctness (WIDTH = 8)
        //
        // Verifies that the full 8-bit bus is routed correctly for each
        // control word, exercising the MSB that would be cut off at WIDTH=5.
        // ===================================================================
        $display("[Time %0t] TC4: WIDTH=8 Parameter Check...", $time);

        in0_8 = 8'hA0; in1_8 = 8'hB1; in2_8 = 8'hC2; in3_8 = 8'hD3;

        ctrl8 = 2'b00; #10;
        if (out8 !== 8'hA0) begin
            $display("  FAILED TC4/00: Expected A0, Got %h", out8);
            error_count = error_count + 1;
        end else $display("  PASSED TC4/00: OUT=A0 correct (WIDTH=8).");

        ctrl8 = 2'b01; #10;
        if (out8 !== 8'hB1) begin
            $display("  FAILED TC4/01: Expected B1, Got %h", out8);
            error_count = error_count + 1;
        end else $display("  PASSED TC4/01: OUT=B1 correct (WIDTH=8).");

        ctrl8 = 2'b10; #10;
        if (out8 !== 8'hC2) begin
            $display("  FAILED TC4/10: Expected C2, Got %h", out8);
            error_count = error_count + 1;
        end else $display("  PASSED TC4/10: OUT=C2 correct (WIDTH=8).");

        ctrl8 = 2'b11; #10;
        if (out8 !== 8'hD3) begin
            $display("  FAILED TC4/11: Expected D3, Got %h", out8);
            error_count = error_count + 1;
        end else $display("  PASSED TC4/11: OUT=D3 correct (WIDTH=8).");

        // ===================================================================
        // Summary
        // ===================================================================
        $display("---------------------------------------------------");
        if (error_count == 0)
            $display("ALL TEST CASES PASSED.");
        else
            $display("SIMULATION FAILED: %0d error(s) found.", error_count);
        $display("---------------------------------------------------");

        #10;
        $finish;
    end

endmodule