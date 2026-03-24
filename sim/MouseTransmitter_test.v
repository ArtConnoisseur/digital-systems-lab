`timescale 1ns / 1ps
// Testbench for MouseTransmitter
//
// Verifies:
//   1) IDLE: no transmission when SEND_BYTE is low
//   2) Full byte transmission (0xF4 = Enable Reporting)
//      - Host pulls CLK low for >100us
//      - Start bit, 8 data bits LSB first, parity, stop
//   3) Device ACK sequence
//   4) BYTE_SENT asserted after complete transmission
//
// Try run for 100us!

module MouseTransmitter_tb;

    // System signals
    reg CLK;
    reg RESET;

    // Transmitter control
    reg       SEND_BYTE;
    reg [7:0] BYTE_TO_SEND;
    wire      BYTE_SENT;

    // PS/2 lines
    wire CLK_MOUSE_OUT_EN;
    wire DATA_MOUSE_OUT;
    wire DATA_MOUSE_OUT_EN;

    // Simulated PS/2 clock and data (active low, open collector)
    reg  mouse_clk_device;    // Device-driven clock
    reg  mouse_data_device;   // Device-driven data
    wire CLK_MOUSE_IN;
    wire DATA_MOUSE_IN;

    // PS/2 bus: if host pulls low, line is low; else device controls
    assign CLK_MOUSE_IN  = CLK_MOUSE_OUT_EN  ? 1'b0 : mouse_clk_device;
    assign DATA_MOUSE_IN = DATA_MOUSE_OUT_EN ? DATA_MOUSE_OUT : mouse_data_device;

    // DUT
    MouseTransmitter DUT (
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE_IN(CLK_MOUSE_IN),
        .CLK_MOUSE_OUT_EN(CLK_MOUSE_OUT_EN),
        .DATA_MOUSE_IN(DATA_MOUSE_IN),
        .DATA_MOUSE_OUT(DATA_MOUSE_OUT),
        .DATA_MOUSE_OUT_EN(DATA_MOUSE_OUT_EN),
        .SEND_BYTE(SEND_BYTE),
        .BYTE_TO_SEND(BYTE_TO_SEND),
        .BYTE_SENT(BYTE_SENT)
    );

    // 100 MHz clock
    always #5 CLK = ~CLK;

    // PS/2 clock period (shortened for simulation speed)
    parameter PS2_HALF_CLK = 500; // 0.5us instead of real 30us

    // ============================================================
    // Task: generate one falling+rising edge on PS/2 clock
    // (device drives clock after host releases it)
    // ============================================================
    task ps2_clock_cycle;
        begin
            mouse_clk_device = 1'b0;  // falling edge
            #PS2_HALF_CLK;
            mouse_clk_device = 1'b1;  // rising edge
            #PS2_HALF_CLK;
        end
    endtask

    // Captured data bits
    reg [7:0] captured_data;
    reg       captured_parity;
    reg       captured_stop;
    integer   i;

    // ============================================================
    // Test
    // ============================================================
    initial begin
        // Init
        CLK = 0;
        RESET = 1;
        SEND_BYTE = 0;
        BYTE_TO_SEND = 8'h00;
        mouse_clk_device = 1'b1;  // idle high
        mouse_data_device = 1'b1; // idle high

        #100;
        RESET = 0;
        #100;

        $display("==== MouseTransmitter TB Start ====");

        // --------------------------------------------------------
        // Test 1: No transmission in IDLE
        // --------------------------------------------------------
        #500;
        if (BYTE_SENT !== 0)
            $display("FAIL: BYTE_SENT should be 0 in idle");
        else
            $display("PASS: IDLE state correct");

        // --------------------------------------------------------
        // Test 2: Send 0xF4 (Enable Reporting)
        // --------------------------------------------------------
        BYTE_TO_SEND = 8'hF4;
        SEND_BYTE = 1;
        #10;
        SEND_BYTE = 0;

        // Wait for host to pull CLK low (inhibit phase, ~60us)
        $display("Waiting for host CLK inhibit...");
        wait(CLK_MOUSE_OUT_EN == 1'b1);
        $display("  Host pulling CLK low");

        // Wait for host to release CLK and pull DATA low (start bit)
        wait(CLK_MOUSE_OUT_EN == 1'b0);
        $display("  Host released CLK, DATA driven low (start bit)");
        #(PS2_HALF_CLK);

        // Device generates clock: start bit
        // DATA should already be low (start bit = 0)
        ps2_clock_cycle();

        // Clock in 8 data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            // Sample DATA on falling edge (when we set clk low)
            mouse_clk_device = 1'b0;
            #100; // small settle time
            captured_data[i] = DATA_MOUSE_IN;
            #(PS2_HALF_CLK - 100);
            mouse_clk_device = 1'b1;
            #PS2_HALF_CLK;
        end
        $display("  Captured data: 0x%h (expected 0xF4)", captured_data);

        // Parity bit
        mouse_clk_device = 1'b0;
        #100;
        captured_parity = DATA_MOUSE_IN;
        #(PS2_HALF_CLK - 100);
        mouse_clk_device = 1'b1;
        #PS2_HALF_CLK;
        $display("  Parity: %b (expected %b = odd parity of 0xF4)", captured_parity, ~^8'hF4);

        // Stop bit
        mouse_clk_device = 1'b0;
        #100;
        captured_stop = DATA_MOUSE_IN;
        #(PS2_HALF_CLK - 100);
        mouse_clk_device = 1'b1;
        #PS2_HALF_CLK;
        $display("  Stop bit: %b (expected 1)", captured_stop);

        // Wait for host to release DATA
        #(PS2_HALF_CLK);

        // Device ACK: pull DATA low, then CLK low, then release both
        mouse_data_device = 1'b0;
        #(PS2_HALF_CLK);
        mouse_clk_device = 1'b0;
        #(PS2_HALF_CLK);
        mouse_data_device = 1'b1;
        mouse_clk_device = 1'b1;

        // Wait for BYTE_SENT
        #1000;

        if (captured_data == 8'hF4)
            $display("PASS: Data byte correct");
        else
            $display("FAIL: Data byte mismatch");

        if (captured_parity == ~^8'hF4)
            $display("PASS: Parity correct");
        else
            $display("FAIL: Parity mismatch");

        if (captured_stop == 1'b1)
            $display("PASS: Stop bit correct");
        else
            $display("FAIL: Stop bit wrong");

        if (BYTE_SENT)
            $display("PASS: BYTE_SENT asserted");
        else
            $display("FAIL: BYTE_SENT not asserted");

        #500;
        $display("==== MouseTransmitter TB Done ====");
        $stop;
    end

endmodule
