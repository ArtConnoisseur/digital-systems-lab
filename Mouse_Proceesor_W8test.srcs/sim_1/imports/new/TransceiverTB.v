`timescale 1ns / 1ps
// ============================================================
// Simple Testbench for MouseTransceiver
//
// Purpose:
//   - Verify that Status/DX/DY update correctly
//   - Verify absolute MouseX/MouseY integration
//
// NOTE:
//   This is NOT a full PS/2 serial protocol simulation.
//   We directly force the MasterSM outputs and pulse SendInterrupt.
//   All submodules already verified in week 5.
// ============================================================

module tb_MouseTransceiver_simple;

    // DUT Inputs
    reg CLK;
    reg RESET;

    // PS/2 bidirectional wires (idle pulled high)
    wire CLK_MOUSE;
    wire DATA_MOUSE;

    // Pull-ups simulate PS/2 open-collector idle state
    pullup(CLK_MOUSE);
    pullup(DATA_MOUSE);

    // DUT Outputs
    wire [7:0] MouseStatus;
    wire [7:0] MouseDX;
    wire [7:0] MouseDY;
    wire [7:0] MouseX;
    wire [7:0] MouseY;

    // Instantiate DUT
    MouseTransceiver DUT (
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE(CLK_MOUSE),
        .DATA_MOUSE(DATA_MOUSE),

        .MouseStatus(MouseStatus),
        .MouseDX(MouseDX),
        .MouseDY(MouseDY),

        .MouseX(MouseX),
        .MouseY(MouseY)
    );

    // Clock generation: 100 MHz
    always #5 CLK = ~CLK;

    // ============================================================
    // Task: simulate one mouse packet arrival
    // ============================================================
    task send_packet;
        input [7:0] status;
        input [7:0] dx;
        input [7:0] dy;
        begin
            force DUT.StatusRaw = status;
            force DUT.DxRaw     = dx;
            force DUT.DyRaw     = dy;

            // Pulse interrupt (packet complete)
            force DUT.SendInterrupt = 1;
            #20;
            release DUT.SendInterrupt;

            // Release forced data
            release DUT.StatusRaw;
            release DUT.DxRaw;
            release DUT.DyRaw;

            #50;
        end
    endtask

    // ============================================================
    // Test sequence
    // ============================================================
    initial begin
        // Init
        CLK   = 0;
        RESET = 1;

        // Hold reset
        #50;
        RESET = 0;

        $display("==== MouseTransceiver TB Start ====");

        // --------------------------------------------------------
        // Test 1: Move right +5
        // --------------------------------------------------------
        send_packet(8'b00001000, 8'h05, 8'h00);

        $display("Test1: DX=%h DY=%h  X=%d Y=%d",
                 MouseDX, MouseDY, MouseX, MouseY);

        // --------------------------------------------------------
        // Test 2: Move left -3 (FD)
        // --------------------------------------------------------
        send_packet(8'b00011000, 8'hFD, 8'h00);

        $display("Test2: DX=%h DY=%h  X=%d Y=%d",
                 MouseDX, MouseDY, MouseX, MouseY);

        // --------------------------------------------------------
        // Test 3: Move down -9 (F7)
        // --------------------------------------------------------
        send_packet(8'b00101000, 8'h00, 8'hF7);

        $display("Test3: DX=%h DY=%h  X=%d Y=%d",
                 MouseDX, MouseDY, MouseX, MouseY);

        // Finish
        #200;
        $display("==== Simulation Finished ====");
        $stop;
    end

endmodule
