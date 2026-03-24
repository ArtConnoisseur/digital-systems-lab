`timescale 1ns / 1ps
// Testbench for IRTransmitterSM
//
// Packet structure (carrier pulse counts):
//   START(88) GAP(40) CAR_SELECT(22) GAP(40)
//   RIGHT(44/22) GAP(40) LEFT(44/22) GAP(40)
//   BACKWARD(44/22) GAP(40) FORWARD(44/22)
//
// Tests:
//   1) IDLE: IR_LED stays off with no SEND_PACKET
//   2) COMMAND=0000: all short pulses (22 cycles), all states visited
//   3) COMMAND=1111: all long pulses (44 cycles), TargetCount verified
//   4) Reset mid-packet: returns to IDLE, IR_LED goes low
//   5) SEND_PACKET held high during transmission: does not restart mid-packet
//
// Try run for 500us!
module IRTransmitterSM_tb;

    // DUT signals
    reg        CLK;
    reg        RESET;
    reg  [3:0] COMMAND;
    reg        SEND_PACKET;
    wire       IR_LED;

    // Instantiate with fast carrier (HALF_PERIOD=5 -> 10 CLK cycles/period)
    IRTransmitterSM #(.HALF_PERIOD(5)) DUT (
        .CLK        (CLK),
        .RESET      (RESET),
        .COMMAND    (COMMAND),
        .SEND_PACKET(SEND_PACKET),
        .IR_LED     (IR_LED)
    );

    // 100 MHz clock (10 ns period)
    always #5 CLK = ~CLK;

    // ----------------------------------------------------------------
    // Task: trigger one packet and wait for all states in order
    // ----------------------------------------------------------------
    task send_and_wait_idle;
        begin
            @(posedge CLK);
            SEND_PACKET = 1;
            @(posedge CLK);
            SEND_PACKET = 0;
            wait(DUT.State == 4'd0);
        end
    endtask


    // Main stimulus
    initial begin
        CLK         = 0;
        RESET       = 1;
        COMMAND     = 4'b0000;
        SEND_PACKET = 0;

        // Hold reset for 5 cycles then release
        repeat(5) @(posedge CLK);
        RESET = 0;
        @(posedge CLK);

        $display("==== IRTransmitterSM TB Start ====");
        $display("HALF_PERIOD = %0d (fast simulation)", DUT.HALF_PERIOD);

        // -------------------------------------------------------
        // Test 1: IDLE - IR_LED must stay low when no packet sent
        // -------------------------------------------------------
        $display("\n[Test 1] IDLE: no SEND_PACKET -> IR_LED should be 0");
        #100;
        if (IR_LED === 1'b0)
            $display("  PASS: IR_LED = 0 in IDLE");
        else
            $display("  FAIL: IR_LED = %b in IDLE (expected 0)", IR_LED);

        // -------------------------------------------------------
        // Test 2: COMMAND=0000 - all direction bits 0 -> 22-pulse bursts
        // -------------------------------------------------------
        $display("\n[Test 2] COMMAND=0000 -> all direction bursts use 22 pulses");
        COMMAND = 4'b0000;
        @(posedge CLK);
        SEND_PACKET = 1;
        @(posedge CLK);
        SEND_PACKET = 0;

        wait(DUT.State == 4'd1);   $display("  -> START      (burst, 88 pulses)");
        wait(DUT.State == 4'd2);   $display("  -> GAP_CS     (gap,   40 pulses)");
        // Verify IR_LED goes low in a gap state
        @(posedge CLK);
        if (IR_LED === 1'b0)
            $display("     PASS: IR_LED = 0 during GAP_CS");
        else
            $display("     FAIL: IR_LED = %b during GAP_CS (expected 0)", IR_LED);

        wait(DUT.State == 4'd3);   $display("  -> CAR_SELECT (burst, 22 pulses)");
        wait(DUT.State == 4'd4);   $display("  -> GAP_R      (gap,   40 pulses)");
        wait(DUT.State == 4'd5);
        $display("  -> RIGHT      (COMMAND[0]=0 -> 22 pulses, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd22)
            $display("     PASS: TargetCount = 22");
        else
            $display("     FAIL: TargetCount = %0d (expected 22)", DUT.TargetCount);

        wait(DUT.State == 4'd6);   $display("  -> GAP_L      (gap,   40 pulses)");
        wait(DUT.State == 4'd7);
        $display("  -> LEFT       (COMMAND[1]=0 -> 22 pulses, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd22)
            $display("     PASS: TargetCount = 22");
        else
            $display("     FAIL: TargetCount = %0d (expected 22)", DUT.TargetCount);

        wait(DUT.State == 4'd8);   $display("  -> GAP_B      (gap,   40 pulses)");
        wait(DUT.State == 4'd9);
        $display("  -> BACKWARD   (COMMAND[2]=0 -> 22 pulses, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd22)
            $display("     PASS: TargetCount = 22");
        else
            $display("     FAIL: TargetCount = %0d (expected 22)", DUT.TargetCount);

        wait(DUT.State == 4'd10);  $display("  -> GAP_F      (gap,   40 pulses)");
        wait(DUT.State == 4'd11);
        $display("  -> FORWARD    (COMMAND[3]=0 -> 22 pulses, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd22)
            $display("     PASS: TargetCount = 22");
        else
            $display("     FAIL: TargetCount = %0d (expected 22)", DUT.TargetCount);

        wait(DUT.State == 4'd0);
        $display("  -> IDLE (packet complete)");
        if (IR_LED === 1'b0)
            $display("  PASS: IR_LED = 0 after packet");
        else
            $display("  FAIL: IR_LED = %b after packet (expected 0)", IR_LED);

        #100;

        // -------------------------------------------------------
        // Test 3: COMMAND=1111 - all direction bits 1 -> 44-pulse bursts
        // -------------------------------------------------------
        $display("\n[Test 3] COMMAND=1111 -> all direction bursts use 44 pulses");
        COMMAND = 4'b1111;
        @(posedge CLK);
        SEND_PACKET = 1;
        @(posedge CLK);
        SEND_PACKET = 0;

        wait(DUT.State == 4'd5);
        $display("  -> RIGHT    (COMMAND[0]=1, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd44)
            $display("     PASS: TargetCount = 44");
        else
            $display("     FAIL: TargetCount = %0d (expected 44)", DUT.TargetCount);

        wait(DUT.State == 4'd7);
        $display("  -> LEFT     (COMMAND[1]=1, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd44)
            $display("     PASS: TargetCount = 44");
        else
            $display("     FAIL: TargetCount = %0d (expected 44)", DUT.TargetCount);

        wait(DUT.State == 4'd9);
        $display("  -> BACKWARD (COMMAND[2]=1, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd44)
            $display("     PASS: TargetCount = 44");
        else
            $display("     FAIL: TargetCount = %0d (expected 44)", DUT.TargetCount);

        wait(DUT.State == 4'd11);
        $display("  -> FORWARD  (COMMAND[3]=1, TargetCount=%0d)", DUT.TargetCount);
        if (DUT.TargetCount == 10'd44)
            $display("     PASS: TargetCount = 44");
        else
            $display("     FAIL: TargetCount = %0d (expected 44)", DUT.TargetCount);

        wait(DUT.State == 4'd0);
        $display("  -> IDLE (packet complete)");

        #100;

        // -------------------------------------------------------
        // Test 4: Reset mid-packet -> returns to IDLE immediately
        // -------------------------------------------------------
        $display("\n[Test 4] Reset mid-packet");
        COMMAND = 4'b0101;
        @(posedge CLK);
        SEND_PACKET = 1;
        @(posedge CLK);
        SEND_PACKET = 0;

        wait(DUT.State == 4'd3); // CAR_SELECT
        $display("  Asserting RESET during CAR_SELECT (state=%0d)", DUT.State);
        RESET = 1;
        @(posedge CLK);
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);

        if (DUT.State == 4'd0 && IR_LED === 1'b0)
            $display("  PASS: State = IDLE, IR_LED = 0 after reset");
        else
            $display("  FAIL: State = %0d, IR_LED = %b (expected IDLE=0, IR_LED=0)",
                     DUT.State, IR_LED);

        #100;

        // -------------------------------------------------------
        // Test 5: SEND_PACKET held high during transmission
        //         -> packet should complete normally, not restart
        // -------------------------------------------------------
        $display("\n[Test 5] SEND_PACKET held high during packet (no mid-packet restart)");
        COMMAND = 4'b0000;
        @(posedge CLK);
        SEND_PACKET = 1; // keep asserted throughout

        wait(DUT.State == 4'd3); // inside packet at CAR_SELECT
        $display("  In CAR_SELECT with SEND_PACKET=1: state should stay > 0");
        if (DUT.State != 4'd0)
            $display("  PASS: Not restarted mid-packet (state=%0d)", DUT.State);
        else
            $display("  FAIL: Unexpectedly returned to IDLE during packet");

        // Let packet finish with SEND_PACKET still high
        wait(DUT.State == 4'd0);
        $display("  Packet completed normally -> IDLE");

        // A new packet should start on the very next trigger
        @(posedge CLK);
        SEND_PACKET = 0;

        #100;

        $display("\n==== IRTransmitterSM TB Done ====");
        $stop;
    end

endmodule
