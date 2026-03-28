`timescale 1ns / 1ps

module IRTransmitterSM_tb;

    // -----------------------------------------------------------------------
    // Blue-car parameters
    // CLK is assumed to be 50 MHz (20 ns period) so that:
    //   carrier frequency = 50e6 / (2 × 657) ≈ 38 kHz
    // -----------------------------------------------------------------------
    localparam integer HALF_P     = 657;  // Carrier half-period (CLK cycles)
    localparam integer START_C    = 88;   // START burst length  (carrier periods)
    localparam integer GAP_C      = 40;   // Every inter-burst gap
    localparam integer CAR_SEL_C  = 22;   // CAR_SELECT burst
    localparam integer DIR_ASS_C  = 22;   // Direction burst when COMMAND bit = 1
    localparam integer DIR_DEAS_C = 11;   // Direction burst when COMMAND bit = 0
    localparam integer CLK_HALF   = 10;   // 50 MHz → 10 ns half-period

    // -----------------------------------------------------------------------
    // DUT I/O
    // -----------------------------------------------------------------------
    reg        RESET;
    reg        CLK;
    reg  [3:0] COMMAND;
    reg        SEND_PACKET;
    wire       IR_LED;

    // -----------------------------------------------------------------------
    // Simulation variables
    // -----------------------------------------------------------------------
    integer error_count;
    reg     saw_high;   // Output latch for sample_ir task

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    IRTransmitterSM dut (
        .RESET          (RESET),
        .CLK            (CLK),
        .COMMAND        (COMMAND),
        .SEND_PACKET    (SEND_PACKET),
        .IR_LED         (IR_LED),
        .HALF_PERIOD_IN (HALF_P[10:0]),
        .START_COUNT    (START_C[7:0]),
        .GAP_COUNT      (GAP_C[7:0]),
        .CAR_SEL_COUNT  (CAR_SEL_C[7:0]),
        .DIR_ASSERT     (DIR_ASS_C[7:0]),
        .DIR_DEASSERT   (DIR_DEAS_C[7:0])
    );

    // -----------------------------------------------------------------------
    // Clock generation — 50 MHz
    // -----------------------------------------------------------------------
    initial begin
        CLK = 1'b0;
        forever #CLK_HALF CLK = ~CLK;
    end

    // -----------------------------------------------------------------------
    // Task: advance exactly n carrier periods (n × 2 × HALF_P CLK ticks)
    // -----------------------------------------------------------------------
    task wait_cp;
        input integer n;
        integer total;
        begin
            total = n * 2 * HALF_P;
            repeat(total) @(posedge CLK);
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: pulse SEND_PACKET high for exactly one CLK cycle
    // -----------------------------------------------------------------------
    task trigger_send;
        begin
            @(posedge CLK); SEND_PACKET = 1'b1;
            @(posedge CLK); SEND_PACKET = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: sample IR_LED over 2 carrier periods (4 × HALF_P CLK ticks).
    //       Sets the module-level 'saw_high' flag if IR_LED was ever 1.
    //       During a burst state, IR_LED toggles at 38 kHz — any posedge
    //       confirms the carrier is running. During a gap it stays at 0.
    // -----------------------------------------------------------------------
    task sample_ir;
        integer i;
        begin
            saw_high = 1'b0;
            for (i = 0; i < 4 * HALF_P; i = i + 1) begin
                @(posedge CLK);
                if (IR_LED === 1'b1) saw_high = 1'b1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: assert RESET and wait for signals to settle
    // -----------------------------------------------------------------------
    task do_reset;
        begin
            RESET       = 1'b1;
            SEND_PACKET = 1'b0;
            repeat(10) @(posedge CLK);
            RESET = 1'b0;
            repeat(5)  @(posedge CLK);
        end
    endtask

    // -----------------------------------------------------------------------
    // Simulation stimulus
    // -----------------------------------------------------------------------
    initial begin
        $display("---------------------------------------------------");
        $display("Starting Simulation: IRTransmitterSM (Blue Car)");
        $display("---------------------------------------------------");

        // Initialise
        RESET = 1'b1; SEND_PACKET = 1'b0; COMMAND = 4'b0000;
        error_count = 0;
        repeat(10) @(posedge CLK);
        RESET = 1'b0;
        repeat(5)  @(posedge CLK);

        // ===================================================================
        // Test Case 1 — SEND_PACKET Trigger
        //
        // a) IR_LED must be 0 in IDLE before any trigger.
        // b) IR_LED must become active (carrier toggling) shortly after
        //    SEND_PACKET is asserted.
        // c) IR_LED must return to 0 once the full packet has completed
        //    and the FSM has returned to IDLE.
        // ===================================================================
        $display("[Time %0t] TC1: SEND_PACKET Trigger...", $time);

        // 1a — quiescent IDLE
        if (IR_LED !== 1'b0) begin
            $display("  FAILED TC1a: IR_LED=%b in IDLE (expected 0).", IR_LED);
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1a: IR_LED is 0 in IDLE before trigger.");

        // Trigger a full packet
        COMMAND = 4'b1111;
        trigger_send;

        // 1b — burst should be active within 2 carrier periods
        wait_cp(2);
        sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC1b: IR_LED did not activate after SEND_PACKET.");
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1b: IR_LED active (burst running) in START state.");

        // 1c — wait out the full packet (worst-case 398 CPs) plus margin,
        //      then confirm IR_LED has returned to 0 in IDLE.
        //      4 CPs were already consumed above (wait_cp(2) + 2 in sample_ir).
        wait_cp(398);
        wait_cp(5);
        if (IR_LED !== 1'b0) begin
            $display("  FAILED TC1c: IR_LED=%b after packet (expected 0 / IDLE).", IR_LED);
            error_count = error_count + 1;
        end else
            $display("  PASSED TC1c: IR_LED returns to 0 after full packet.");

        // ===================================================================
        // Test Case 2 — Full Burst / Gap Sequence  (COMMAND = 4'b1111)
        //
        // Start a fresh packet and sample IR_LED in the middle of every one
        // of the 11 FSM states. The per-state budget is:
        //   wait_cp(3) [enter state] + sample_ir [2 CP] + wait_cp(N−5) [drain]
        //   = N carrier periods total, keeping the timer locked to state edges.
        //
        // State sequence (all direction bits = 1, so all DIR_ASSERT = 22 CP):
        //   START(88) → GAP_CS(40) → CAR_SELECT(22) →
        //   GAP_R(40)  → RIGHT(22)  → GAP_L(40)  → LEFT(22)  →
        //   GAP_B(40)  → BACKWARD(22) → GAP_F(40) → FORWARD(22) → IDLE
        // ===================================================================
        $display("[Time %0t] TC2: Full Burst/Gap Sequence (COMMAND=1111)...", $time);

        do_reset;
        COMMAND = 4'b1111;
        trigger_send;

        // -- START (88 CP) — expect burst ---------------------------------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/START:      Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/START:      Burst active.");
        wait_cp(START_C - 5);

        // -- GAP_CS (40 CP) — expect inactive -----------------------------
        wait_cp(3); sample_ir;
        if (saw_high) begin
            $display("  FAILED TC2/GAP_CS:     Expected inactive, IR_LED went high.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/GAP_CS:     Gap inactive.");
        wait_cp(GAP_C - 5);

        // -- CAR_SELECT (22 CP) — expect burst ----------------------------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/CAR_SELECT: Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/CAR_SELECT: Burst active.");
        wait_cp(CAR_SEL_C - 5);

        // -- GAP_R (40 CP) — expect inactive ------------------------------
        wait_cp(3); sample_ir;
        if (saw_high) begin
            $display("  FAILED TC2/GAP_R:      Expected inactive, IR_LED went high.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/GAP_R:      Gap inactive.");
        wait_cp(GAP_C - 5);

        // -- RIGHT (22 CP, CMD[0]=1 → DIR_ASSERT) — expect burst ----------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/RIGHT:      Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/RIGHT:      Burst active.");
        wait_cp(DIR_ASS_C - 5);

        // -- GAP_L (40 CP) — expect inactive ------------------------------
        wait_cp(3); sample_ir;
        if (saw_high) begin
            $display("  FAILED TC2/GAP_L:      Expected inactive, IR_LED went high.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/GAP_L:      Gap inactive.");
        wait_cp(GAP_C - 5);

        // -- LEFT (22 CP, CMD[1]=1 → DIR_ASSERT) — expect burst -----------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/LEFT:       Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/LEFT:       Burst active.");
        wait_cp(DIR_ASS_C - 5);

        // -- GAP_B (40 CP) — expect inactive ------------------------------
        wait_cp(3); sample_ir;
        if (saw_high) begin
            $display("  FAILED TC2/GAP_B:      Expected inactive, IR_LED went high.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/GAP_B:      Gap inactive.");
        wait_cp(GAP_C - 5);

        // -- BACKWARD (22 CP, CMD[2]=1 → DIR_ASSERT) — expect burst ------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/BACKWARD:   Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/BACKWARD:   Burst active.");
        wait_cp(DIR_ASS_C - 5);

        // -- GAP_F (40 CP) — expect inactive ------------------------------
        wait_cp(3); sample_ir;
        if (saw_high) begin
            $display("  FAILED TC2/GAP_F:      Expected inactive, IR_LED went high.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/GAP_F:      Gap inactive.");
        wait_cp(GAP_C - 5);

        // -- FORWARD (22 CP, CMD[3]=1 → DIR_ASSERT) — expect burst -------
        wait_cp(3); sample_ir;
        if (!saw_high) begin
            $display("  FAILED TC2/FORWARD:    Expected burst, IR_LED stayed 0.");
            error_count = error_count + 1;
        end else $display("  PASSED TC2/FORWARD:    Burst active.");
        wait_cp(DIR_ASS_C - 5);

        // -- Post-packet IDLE check ---------------------------------------
        wait_cp(5);
        if (IR_LED !== 1'b0) begin
            $display("  FAILED TC2/IDLE: IR_LED=%b after FORWARD (expected 0).", IR_LED);
            error_count = error_count + 1;
        end else
            $display("  PASSED TC2/IDLE: IR_LED returns to 0 after full packet.");

        // ===================================================================
        // Test Case 3 — COMMAND Bit Combinations
        //
        // Tests COMMAND = 0000, 0101, 1010, 1111.
        // For each value three checks are made:
        //   3a — IR_LED activates after SEND_PACKET (burst in START)
        //   3b — IR_LED returns to 0 after the full packet (FSM back to IDLE)
        //   3c — No spurious IR_LED activity without a second SEND_PACKET
        //
        // Upper bound on packet duration:
        //   All-assert  (1111): 88+40+22+40+22+40+22+40+22+40+22 = 398 CP
        //   All-deassert(0000): 88+40+22+40+11+40+11+40+11+40+11 = 354 CP
        //   Safe upper bound: 420 CP (used below for TC3b wait)
        // ===================================================================
        $display("[Time %0t] TC3: COMMAND Bit Combinations...", $time);

        begin : tc3_block
            reg [3:0] cmd;
            integer   ci;

            for (ci = 0; ci < 4; ci = ci + 1) begin

                case (ci)
                    0: cmd = 4'b0000;   // All deasserted  (DIR_DEASSERT = 11 CP each)
                    1: cmd = 4'b0101;   // RIGHT + BACKWARD asserted
                    2: cmd = 4'b1010;   // LEFT  + FORWARD  asserted
                    3: cmd = 4'b1111;   // All asserted    (DIR_ASSERT   = 22 CP each)
                endcase

                do_reset;
                COMMAND = cmd;
                trigger_send;

                // 3a: IR_LED must activate within 2 carrier periods of trigger
                wait_cp(2);
                sample_ir;
                if (!saw_high) begin
                    $display("  FAILED TC3a [CMD=%b]: IR_LED did not activate after trigger.", cmd);
                    error_count = error_count + 1;
                end else
                    $display("  PASSED TC3a [CMD=%b]: IR_LED activates after SEND_PACKET.", cmd);

                // 3b: Wait out the full packet with margin, then verify IDLE.
                //     4 CPs already consumed (wait_cp(2) + 2 in sample_ir).
                //     420 - 4 = 416 remaining to reach the 420 CP mark.
                wait_cp(416);
                wait_cp(5);
                if (IR_LED !== 1'b0) begin
                    $display("  FAILED TC3b [CMD=%b]: IR_LED=%b after packet (expected 0).", cmd, IR_LED);
                    error_count = error_count + 1;
                end else
                    $display("  PASSED TC3b [CMD=%b]: FSM returns to IDLE after packet.", cmd);

                // 3c: With no new SEND_PACKET, IR_LED must stay at 0 for 2 CPs
                sample_ir;
                if (saw_high) begin
                    $display("  FAILED TC3c [CMD=%b]: Spurious IR_LED activity in IDLE.", cmd);
                    error_count = error_count + 1;
                end else
                    $display("  PASSED TC3c [CMD=%b]: No spurious activity in IDLE.", cmd);

            end
        end

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