`timescale 1ns / 1ps
// ============================================================
// Module Name: MouseTransceiver
//
// Description:
//   Complete PS/2 mouse interface module that integrates:
//
//     - MouseTransmitter : Sends host-to-device commands (RESET 0xFF, ENABLE 0xF4)
//     - MouseReceiver    : Receives device-to-host data bytes
//     - MouseMasterSM    : High-level protocol control FSM
//
// Functionality:
//   - Manages bidirectional open-collector PS/2 clock and data lines
//   - Performs PS/2 clock filtering (8-sample debounce) for noise rejection
//   - Outputs raw movement data (MouseStatus, MouseDX, MouseDY)
//   - Computes absolute position (MouseX, MouseY) with clamping to screen bounds
//
// Absolute Position Calculation:
//   - Raw DX/DY deltas are sign-extended to 9 bits (two's complement)
//   - Sensitivity is reduced by arithmetic right shift (>>>3)
//   - Result is clamped to [0, MouseLimitX] and [0, MouseLimitY]
//   - Initial position is set to screen centre (80, 60)
//
// PS/2 Clock Filtering:
//   An 8-bit shift register samples the raw PS/2 clock line.
//   ClkMouseStable transitions high only after 8 consecutive '1' samples
//   and low only after 8 consecutive '0' samples, preventing glitches
//   from reaching the transmitter and receiver modules.
// ============================================================
module MouseTransceiver(
    input RESET,                    // Reset
    input CLK,                      // System clock

    inout CLK_MOUSE,                // PS/2 clock line
    inout DATA_MOUSE,               // PS/2 data line

    // Required demo outputs
    output reg [7:0] MouseStatus,   // Status Byte
    output reg [7:0] MouseDX,       // X Direction Byte
    output reg [7:0] MouseDY,       // Y Direction Byte

    // Optional (bonus / internal use)
    output reg [7:0] MouseX,
    output reg [7:0] MouseY
);

    // Tri-state PS/2 interface
    // PS/2 uses open-collector signalling: lines are pulled high by external
    // resistors. To drive low, the FPGA enables the output (pulling to 0).
    // To release, the FPGA tri-states the output (line floats high).
    wire ClkMouseOutEn;     // When 1, pull CLK_MOUSE low
    wire DataMouseOut;      // Data value to drive
    wire DataMouseOutEn;    // When 1, drive DATA_MOUSE with DataMouseOut

    assign CLK_MOUSE  = ClkMouseOutEn  ? 1'b0 : 1'bz;     // Pull low or release
    assign DATA_MOUSE = DataMouseOutEn ? DataMouseOut : 1'bz;

    wire ClkMouseIn  = CLK_MOUSE;   // Read-back of PS/2 clock
    wire DataMouseIn = DATA_MOUSE;  // Read-back of PS/2 data

    // Clock filter make sure that it is stable before transmitter
    // or receiver modules
    reg [7:0] MouseClkFilter;
    reg ClkMouseStable;

    always @(posedge CLK) begin
        if (RESET) begin
            MouseClkFilter <= 0;
            ClkMouseStable <= 0;
        end else begin
            MouseClkFilter <= {MouseClkFilter[6:0], ClkMouseIn};
            if (MouseClkFilter == 8'hFF)
                ClkMouseStable <= 1;
            else if (MouseClkFilter == 8'h00)
                ClkMouseStable <= 0;
        end
    end

    // Transmitter
    wire SendByte;
    wire ByteSent;
    wire [7:0] ByteToSend;

    MouseTransmitter TX (
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE_IN(ClkMouseStable),
        .CLK_MOUSE_OUT_EN(ClkMouseOutEn),
        .DATA_MOUSE_IN(DataMouseIn),
        .DATA_MOUSE_OUT(DataMouseOut),
        .DATA_MOUSE_OUT_EN(DataMouseOutEn),
        .SEND_BYTE(SendByte),
        .BYTE_TO_SEND(ByteToSend),
        .BYTE_SENT(ByteSent)
    );

    // Receiver
    wire ReadEnable;
    wire [7:0] ByteRead;
    wire [1:0] ByteError;
    wire ByteReady;

    MouseReceiver RX (
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE_IN(ClkMouseStable),
        .DATA_MOUSE_IN(DataMouseIn),
        .READ_ENABLE(ReadEnable),
        .BYTE_READ(ByteRead),
        .BYTE_ERROR_CODE(ByteError),
        .BYTE_READY(ByteReady)
    );

    // Master State Machine
    wire [7:0] StatusRaw, DxRaw, DyRaw;
    wire SendInterrupt;

    MouseMasterSM MSM (
        .CLK(CLK),
        .RESET(RESET),
        .SEND_BYTE(SendByte),
        .BYTE_TO_SEND(ByteToSend),
        .BYTE_SENT(ByteSent),
        .READ_ENABLE(ReadEnable),
        .BYTE_READ(ByteRead),
        .BYTE_ERROR_CODE(ByteError),
        .BYTE_READY(ByteReady),
        .MOUSE_STATUS(StatusRaw),
        .MOUSE_DX(DxRaw),
        .MOUSE_DY(DyRaw),
        .SEND_INTERRUPT(SendInterrupt)
    );

// Absolute position calculation (MouseX / MouseY)

// Screen limits (example VGA 160x120)
parameter [7:0] MouseLimitX = 8'd159;
parameter [7:0] MouseLimitY = 8'd119;

// Construct signed deltas from raw Direction Bytes
// Direction Bytes are already two's complement encoded,
// so we can directly interpret them as signed values.
wire signed [8:0] Dx_signed = $signed({DxRaw[7], DxRaw});
wire signed [8:0] Dy_signed = $signed({DyRaw[7], DyRaw});

// Compute next position in signed domain (sensitivity reduced by >>3)
wire signed [9:0] next_x = $signed({1'b0, MouseX}) + (Dx_signed >>> 3);
wire signed [9:0] next_y = $signed({1'b0, MouseY}) + (Dy_signed >>> 3);

always @(posedge CLK) begin
    if (RESET) begin
        // Reset outputs
        MouseStatus <= 8'h00;
        MouseDX     <= 8'h00;
        MouseDY     <= 8'h00;

        // Initialise absolute position to screen centre
        MouseX      <= 8'd80;
        MouseY      <= 8'd60;
    end
    else if (SendInterrupt) begin
        // Update raw register values (assessment requirement)
        MouseStatus <= StatusRaw;
        MouseDX     <= DxRaw;
        MouseDY     <= DyRaw;

        // Update absolute X coordinate with clamp
        if (next_x < 0)
            MouseX <= 0;
        else if (next_x > MouseLimitX)
            MouseX <= MouseLimitX;
        else
            MouseX <= next_x[7:0];

        // Update absolute Y coordinate with clamp
        if (next_y < 0)
            MouseY <= 0;
        else if (next_y > MouseLimitY)
            MouseY <= MouseLimitY;
        else
            MouseY <= next_y[7:0];
    end
end

endmodule
