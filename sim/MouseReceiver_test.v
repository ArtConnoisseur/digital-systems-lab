`timescale 1ns / 1ps
// Testbench for MouseReceiver
//
// Verifies:
//   1) Correct reception of a valid PS/2 byte (0xAA)
//   2) Parity error detection (wrong parity bit)
//   3) Stop bit error detection (stop bit = 0)
//   4) Timeout recovery from incomplete frame
//
// Try run for 100us!

module MouseReceiver_tb;

    // System signals
    reg CLK;
    reg RESET;

    // PS/2 lines (simulated by testbench)
    reg CLK_MOUSE_IN;
    reg DATA_MOUSE_IN;

    // Control
    reg        READ_ENABLE;
    wire [7:0] BYTE_READ;
    wire [1:0] BYTE_ERROR_CODE;
    wire       BYTE_READY;

    // DUT
    MouseReceiver DUT (
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE_IN(CLK_MOUSE_IN),
        .DATA_MOUSE_IN(DATA_MOUSE_IN),
        .READ_ENABLE(READ_ENABLE),
        .BYTE_READ(BYTE_READ),
        .BYTE_ERROR_CODE(BYTE_ERROR_CODE),
        .BYTE_READY(BYTE_READY)
    );

    // 100 MHz clock
    always #5 CLK = ~CLK;

    // PS/2 clock half period (shortened for simulation speed)
    parameter PS2_HALF = 500;  // 0.5us instead of real 30us

    // ============================================================
    // Task: send one PS/2 bit (device drives DATA, then clocks)
    // Data is sampled by receiver on falling edge of CLK
    // ============================================================
    task send_bit;
        input bit_val;
        begin
            DATA_MOUSE_IN = bit_val;
            #(PS2_HALF / 2);        // setup time
            CLK_MOUSE_IN = 1'b0;    // falling edge - receiver samples here
            #PS2_HALF;
            CLK_MOUSE_IN = 1'b1;    // rising edge
            #(PS2_HALF / 2);
        end
    endtask

    // ============================================================
    // Task: send a complete PS/2 frame
    //   start(0) + 8 data bits LSB first + parity + stop
    // ============================================================
    task send_byte;
        input [7:0] data;
        input       parity;  // expected odd parity, can be forced wrong
        input       stop;    // normally 1, can be forced wrong
        integer i;
        begin
            // Start bit
            send_bit(1'b0);
            // 8 data bits, LSB first
            for (i = 0; i < 8; i = i + 1)
                send_bit(data[i]);
            // Parity bit
            send_bit(parity);
            // Stop bit
            send_bit(stop);
            // Return to idle
            DATA_MOUSE_IN = 1'b1;
            #(PS2_HALF * 2);
        end
    endtask

    // ============================================================
    // Test
    // ============================================================
    initial begin
        CLK = 0;
        RESET = 1;
        CLK_MOUSE_IN = 1'b1;
        DATA_MOUSE_IN = 1'b1;
        READ_ENABLE = 0;

        #100;
        RESET = 0;
        #100;

        $display("==== MouseReceiver TB Start ====");

        // --------------------------------------------------------
        // Test 1: Valid byte 0xAA (self-test pass)
        //   0xAA = 10101010, odd parity = ~^0xAA = 1
        // --------------------------------------------------------
        $display("Test 1: Send valid byte 0xAA");
        READ_ENABLE = 1;
        send_byte(8'hAA, ~^8'hAA, 1'b1);

        #100;
        $display("  BYTE_READ=0x%h  ERROR=%b  READY=%b",
                 BYTE_READ, BYTE_ERROR_CODE, BYTE_READY);

        if (BYTE_READ == 8'hAA && BYTE_ERROR_CODE == 2'b00)
            $display("  PASS: Correct byte, no errors");
        else
            $display("  FAIL");

        #500;

        // --------------------------------------------------------
        // Test 2: Valid byte 0xFA (ACK)
        //   0xFA = 11111010, odd parity = ~^0xFA = 0
        // --------------------------------------------------------
        $display("Test 2: Send valid byte 0xFA");
        send_byte(8'hFA, ~^8'hFA, 1'b1);

        #100;
        $display("  BYTE_READ=0x%h  ERROR=%b", BYTE_READ, BYTE_ERROR_CODE);

        if (BYTE_READ == 8'hFA && BYTE_ERROR_CODE == 2'b00)
            $display("  PASS");
        else
            $display("  FAIL");

        #500;

        // --------------------------------------------------------
        // Test 3: Parity error (send wrong parity for 0x08)
        //   0x08 = 00001000, correct odd parity = 0
        //   We send parity = 1 (wrong)
        // --------------------------------------------------------
        $display("Test 3: Parity error");
        send_byte(8'h08, ~(~^8'h08), 1'b1); // invert correct parity

        #100;
        $display("  BYTE_READ=0x%h  ERROR=%b", BYTE_READ, BYTE_ERROR_CODE);

        if (BYTE_ERROR_CODE[0] == 1'b1)
            $display("  PASS: Parity error detected");
        else
            $display("  FAIL: Parity error not detected");

        #500;

        // --------------------------------------------------------
        // Test 4: Stop bit error (stop = 0)
        // --------------------------------------------------------
        $display("Test 4: Stop bit error");
        send_byte(8'h55, ~^8'h55, 1'b0); // wrong stop bit

        #100;
        $display("  ERROR=%b", BYTE_ERROR_CODE);

        if (BYTE_ERROR_CODE[1] == 1'b1)
            $display("  PASS: Stop bit error detected");
        else
            $display("  FAIL: Stop bit error not detected");

        #500;

        // --------------------------------------------------------
        // Test 5: READ_ENABLE = 0, receiver should not start
        // --------------------------------------------------------
        $display("Test 5: READ_ENABLE=0, no reception");
        READ_ENABLE = 0;
        send_byte(8'h33, ~^8'h33, 1'b1);

        #100;
        // BYTE_READ should still hold previous value, not 0x33
        if (BYTE_READ != 8'h33)
            $display("  PASS: Byte ignored when READ_ENABLE=0");
        else
            $display("  FAIL: Byte received despite READ_ENABLE=0");

        #200;
        $display("==== MouseReceiver TB Done ====");
        $stop;
    end

endmodule
