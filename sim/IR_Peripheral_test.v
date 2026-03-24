`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for IRTransmitterSM — 8 directions + stop
// Vivado 2022 compatible (plain Verilog)
//////////////////////////////////////////////////////////////////////////////////

module IR_Peripheral_test();

    reg        CLK;
    reg        RESET;
    reg  [3:0] COMMAND;
    reg        SEND_PACKET;
    wire       IR_LED;

    // Instantiate DUT
    IRTransmitterSM uut (
        .CLK        (CLK),
        .RESET      (RESET),
        .COMMAND    (COMMAND),
        .SEND_PACKET(SEND_PACKET),
        .IR_LED     (IR_LED)
    );

    // Access internal signals for waveform viewing
    wire [3:0] State       = uut.CurrState;
    wire [7:0] PulseCount  = uut.CurrPulseCount;
    wire       BurstEnable = uut.CurrBurstEnable;
    wire       Carrier     = uut.CurrCarrier;

    // 100MHz clock
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // ---- IR_LED rising edge detect ----
    reg ir_prev;
    always @(posedge CLK) begin
        if (RESET) ir_prev <= 0;
        else       ir_prev <= IR_LED;
    end
    wire ir_rising = IR_LED & ~ir_prev;

    // ---- Pulse counting per state ----
    reg  [3:0] prev_state;
    integer    pulse_cnt;
    integer    start_pulses, carsel_pulses;
    integer    right_pulses, left_pulses, bwd_pulses, fwd_pulses;

    always @(posedge CLK) begin
        if (RESET) begin
            prev_state <= 0;
            pulse_cnt  <= 0;
        end else begin
            if (ir_rising)
                pulse_cnt <= pulse_cnt + 1;

            if (State != prev_state) begin
                case (prev_state)
                    4'd1:  start_pulses  = pulse_cnt;
                    4'd3:  carsel_pulses = pulse_cnt;
                    4'd5:  right_pulses  = pulse_cnt;
                    4'd7:  left_pulses   = pulse_cnt;
                    4'd9:  bwd_pulses    = pulse_cnt;
                    4'd11: fwd_pulses    = pulse_cnt;
                endcase
                pulse_cnt  <= 0;
                prev_state <= State;
            end
        end
    end

    // ---- Carrier frequency measurement ----
    time t1, t2;
    integer test_num;

    // ---- Send one packet and print results ----
    task send_and_check;
        input [3:0]  cmd;
        input [8*20-1:0] name;   // direction name string
        input integer exp_r, exp_l, exp_b, exp_f;
        begin
            // Reset counters
            start_pulses  = 0; carsel_pulses = 0;
            right_pulses  = 0; left_pulses   = 0;
            bwd_pulses    = 0; fwd_pulses    = 0;

            COMMAND = cmd;
            @(posedge CLK);
            SEND_PACKET = 1;
            @(posedge CLK);
            SEND_PACKET = 0;

            // Wait for packet to complete
            wait (State == 4'd0 && prev_state == 4'd11);
            #1000;

            $display("");
            $display("  Test %0d: %0s  (COMMAND = %b)", test_num, name, cmd);
            $display("    Start:     %3d (exp 191)  CarSel:   %3d (exp  47)",
                     start_pulses, carsel_pulses);
            $display("    Right:     %3d (exp %3d)  Left:     %3d (exp %3d)",
                     right_pulses, exp_r, left_pulses, exp_l);
            $display("    Backward:  %3d (exp %3d)  Forward:  %3d (exp %3d)",
                     bwd_pulses, exp_b, fwd_pulses, exp_f);

            // Check
            if (start_pulses  != 191) $display("    ** FAIL: Start");
            if (carsel_pulses != 47)  $display("    ** FAIL: CarSelect");
            if (right_pulses  != exp_r) $display("    ** FAIL: Right");
            if (left_pulses   != exp_l) $display("    ** FAIL: Left");
            if (bwd_pulses    != exp_b) $display("    ** FAIL: Backward");
            if (fwd_pulses    != exp_f) $display("    ** FAIL: Forward");

            test_num = test_num + 1;
            #50000;
        end
    endtask

    // ---- Main test sequence ----
    initial begin
        RESET       = 1;
        COMMAND     = 4'b0000;
        SEND_PACKET = 0;
        test_num    = 1;
        start_pulses = 0; carsel_pulses = 0;
        right_pulses = 0; left_pulses   = 0;
        bwd_pulses   = 0; fwd_pulses    = 0;

        #200;
        RESET = 0;
        #100;

        $display("");
        $display("========================================================");
        $display(" IRTransmitterSM Testbench — 8 Directions + Stop");
        $display("========================================================");

        // Measure carrier frequency on first packet
        COMMAND = 4'b1000;
        @(posedge CLK);
        SEND_PACKET = 1;
        @(posedge CLK);
        SEND_PACKET = 0;

        @(posedge IR_LED);
        t1 = $time;
        @(negedge IR_LED);
        @(posedge IR_LED);
        t2 = $time;
        $display("");
        $display("  Carrier period = %0d ns", t2 - t1);
        $display("  Carrier freq   = %.0f Hz (expect ~36000)", 1.0e9 / (t2 - t1));

        // Wait for this packet to finish
        wait (State == 4'd0 && prev_state == 4'd11);
        #50000;

        //                cmd       name              R   L   B   F
        // ---- 4 cardinal directions ----
        send_and_check(4'b1000, "Forward          ", 22, 22, 22, 47);
        send_and_check(4'b0100, "Backward         ", 22, 22, 47, 22);
        send_and_check(4'b0010, "Left             ", 22, 47, 22, 22);
        send_and_check(4'b0001, "Right            ", 47, 22, 22, 22);

        // ---- 4 diagonal directions ----
        send_and_check(4'b1001, "Forward + Right  ", 47, 22, 22, 47);
        send_and_check(4'b1010, "Forward + Left   ", 22, 47, 22, 47);
        send_and_check(4'b0101, "Backward + Right ", 47, 22, 47, 22);
        send_and_check(4'b0110, "Backward + Left  ", 22, 47, 47, 22);

        // ---- Stop (no direction) ----
        send_and_check(4'b0000, "Stop             ", 22, 22, 22, 22);

        $display("");
        $display("========================================================");
        $display(" All 9 tests complete");
        $display("========================================================");
        $display("");
        $finish;
    end

endmodule
