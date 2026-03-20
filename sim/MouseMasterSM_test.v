`timescale 1ns / 1ps
// Testbench for MouseMasterSM
//
// Verifies the full initialisation sequence and continuous
// 3-byte packet reception:
//   1) Power-up delay
//   2) Send RESET (0xFF) -> ACK (0xFA) -> Self-test (0xAA) -> ID (0x00)
//   3) Send ENABLE (0xF4) -> ACK (0xFA)
//   4) Receive 3-byte movement packets (Status, DX, DY)
//   5) SEND_INTERRUPT pulse per packet
//   6) Restart from state 0 on unexpected reply
//
// Try run for 30us!

module MouseMasterSM_tb;

    // System
    reg CLK;
    reg RESET;

    // Transmitter interface
    wire       SEND_BYTE;
    wire [7:0] BYTE_TO_SEND;
    reg        BYTE_SENT;

    // Receiver interface
    wire       READ_ENABLE;
    reg  [7:0] BYTE_READ;
    reg  [1:0] BYTE_ERROR_CODE;
    reg        BYTE_READY;

    // Mouse data outputs
    wire [7:0] MOUSE_STATUS;
    wire [7:0] MOUSE_DX;
    wire [7:0] MOUSE_DY;
    wire       SEND_INTERRUPT;
    wire [3:0] CURR_STATE;

    // DUT
    MouseMasterSM DUT (
        .CLK(CLK),
        .RESET(RESET),
        .SEND_BYTE(SEND_BYTE),
        .BYTE_TO_SEND(BYTE_TO_SEND),
        .BYTE_SENT(BYTE_SENT),
        .READ_ENABLE(READ_ENABLE),
        .BYTE_READ(BYTE_READ),
        .BYTE_ERROR_CODE(BYTE_ERROR_CODE),
        .BYTE_READY(BYTE_READY),
        .MOUSE_STATUS(MOUSE_STATUS),
        .MOUSE_DX(MOUSE_DX),
        .MOUSE_DY(MOUSE_DY),
        .SEND_INTERRUPT(SEND_INTERRUPT),
        .CURR_STATE(CURR_STATE)
    );

    // 100 MHz clock
    always #5 CLK = ~CLK;

    // ============================================================
    // Task: simulate transmitter completing a send
    // ============================================================
    task wait_for_send_and_ack;
        begin
            // Wait for MSM to assert SEND_BYTE
            wait(SEND_BYTE == 1'b1);
            #20;
            $display("  MSM sending: 0x%h", BYTE_TO_SEND);
            // Simulate transmitter finishing
            #200;
            BYTE_SENT = 1;
            #10;
            BYTE_SENT = 0;
        end
    endtask

    // ============================================================
    // Task: simulate receiver delivering a byte
    // ============================================================
    task deliver_byte;
        input [7:0] data;
        begin
            // Wait until MSM is ready to read
            wait(READ_ENABLE == 1'b1);
            #200;
            BYTE_READ = data;
            BYTE_ERROR_CODE = 2'b00;
            BYTE_READY = 1;
            #10;
            BYTE_READY = 0;
        end
    endtask

    // ============================================================
    // Task: deliver a 3-byte mouse packet
    // ============================================================
    task deliver_packet;
        input [7:0] status;
        input [7:0] dx;
        input [7:0] dy;
        begin
            deliver_byte(status);
            #100;
            deliver_byte(dx);
            #100;
            deliver_byte(dy);
            #100;
        end
    endtask

    // ============================================================
    // Test
    // ============================================================
    initial begin
        CLK = 0;
        RESET = 1;
        BYTE_SENT = 0;
        BYTE_READ = 0;
        BYTE_ERROR_CODE = 0;
        BYTE_READY = 0;

        #100;
        RESET = 0;

        $display("==== MouseMasterSM TB Start ====");

        // --------------------------------------------------------
        // Phase 1: Power-up delay (State 0)
        // Skip most of the 1,000,000 cycle delay by forcing counter
        // --------------------------------------------------------
        $display("Phase 1: Power-up delay (skipping)...");
        #200;
        force DUT.Curr_Counter = 24'd999_990;
        #10;
        release DUT.Curr_Counter;
        wait(CURR_STATE == 4'h1);
        $display("  Power-up complete, entering State 1");

        // --------------------------------------------------------
        // Phase 2: Send RESET (0xFF)
        // --------------------------------------------------------
        $display("Phase 2: RESET command");
        wait_for_send_and_ack();
        $display("  RESET sent, waiting for ACK...");

        // --------------------------------------------------------
        // Phase 3: Receive ACK (0xFA) -> Self-test (0xAA) -> ID (0x00)
        // --------------------------------------------------------
        $display("Phase 3: Init sequence");
        deliver_byte(8'hFA);  // ACK
        $display("  ACK received, state=%h", CURR_STATE);
        #100;
        deliver_byte(8'hAA);  // Self-test pass
        $display("  Self-test pass, state=%h", CURR_STATE);
        #100;
        deliver_byte(8'h00);  // Mouse ID
        $display("  Mouse ID received, state=%h", CURR_STATE);

        // --------------------------------------------------------
        // Phase 4: Send ENABLE REPORTING (0xF4)
        // --------------------------------------------------------
        $display("Phase 4: ENABLE REPORTING");
        wait_for_send_and_ack();
        $display("  ENABLE sent, waiting for ACK...");

        deliver_byte(8'hFA);  // ACK
        $display("  ACK received, state=%h", CURR_STATE);

        // --------------------------------------------------------
        // Phase 5: Receive movement packets
        // --------------------------------------------------------
        $display("Phase 5: Movement packets");

        // Packet 1: Move right +10, up +5
        $display("  Packet 1: status=08, dx=0A, dy=05");
        deliver_packet(8'h08, 8'h0A, 8'h05);
        #20;
        $display("    STATUS=0x%h DX=0x%h DY=0x%h INT=%b",
                 MOUSE_STATUS, MOUSE_DX, MOUSE_DY, SEND_INTERRUPT);

        if (MOUSE_STATUS == 8'h08 && MOUSE_DX == 8'h0A && MOUSE_DY == 8'h05)
            $display("    PASS: Packet 1 correct");
        else
            $display("    FAIL: Packet 1 mismatch");

        #200;

        // Packet 2: Move left -3 (FD), down -7 (F9), left button pressed
        $display("  Packet 2: status=19, dx=FD, dy=F9");
        deliver_packet(8'h19, 8'hFD, 8'hF9);
        #20;
        $display("    STATUS=0x%h DX=0x%h DY=0x%h INT=%b",
                 MOUSE_STATUS, MOUSE_DX, MOUSE_DY, SEND_INTERRUPT);

        if (MOUSE_STATUS == 8'h19 && MOUSE_DX == 8'hFD && MOUSE_DY == 8'hF9)
            $display("    PASS: Packet 2 correct");
        else
            $display("    FAIL: Packet 2 mismatch");

        #200;

        // Packet 3: No movement, right button pressed
        $display("  Packet 3: status=0A, dx=00, dy=00");
        deliver_packet(8'h0A, 8'h00, 8'h00);
        #20;
        $display("    STATUS=0x%h DX=0x%h DY=0x%h",
                 MOUSE_STATUS, MOUSE_DX, MOUSE_DY);

        if (MOUSE_STATUS == 8'h0A && MOUSE_DX == 8'h00 && MOUSE_DY == 8'h00)
            $display("    PASS: Packet 3 correct");
        else
            $display("    FAIL: Packet 3 mismatch");

        // --------------------------------------------------------
        // Phase 6: Error recovery - bad ACK during init
        // --------------------------------------------------------
        $display("Phase 6: Error recovery test");
        RESET = 1;
        #50;
        RESET = 0;

        // Skip power-up delay again
        #200;
        force DUT.Curr_Counter = 24'd999_990;
        #10;
        release DUT.Curr_Counter;
        wait(CURR_STATE == 4'h1);
        wait_for_send_and_ack();

        // Send wrong ACK (0xEE instead of 0xFA)
        deliver_byte(8'hEE);
        #200;
        $display("  After bad ACK, state=%h (expected 0 = restart)", CURR_STATE);

        if (CURR_STATE == 4'h0)
            $display("  PASS: MSM restarted on bad ACK");
        else
            $display("  FAIL: MSM did not restart");

        #500;
        $display("==== MouseMasterSM TB Done ====");
        $stop;
    end

endmodule
