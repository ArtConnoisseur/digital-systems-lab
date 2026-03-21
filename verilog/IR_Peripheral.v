`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: IR_Peripheral
//
// Description:
//   Bus-attached wrapper around IRTransmitterSM.
//   The processor writes a command byte to 0x90 to trigger IR transmission.
//
//   Register Map (Base Address: 0x90):
//     0x90 (W) : command [3:0]
//                  bit0 = Right
//                  bit1 = Left
//                  bit2 = Backward
//                  bit3 = Forward
//
//   SEND_PACKET is asserted whenever the stored command is non-zero.
//   Write 0x00 to stop transmitting.
//////////////////////////////////////////////////////////////////////////////////

module IR_Peripheral(
    input           CLK,
    input           RESET,

    // BUS Interface
    inout  [7:0]    BUS_DATA,
    input  [7:0]    BUS_ADDR,
    input           BUS_WE,

    // IR output
    output          IR_LED
);

parameter BaseAddr = 8'h90;

// Write-only: never drive the bus
assign BUS_DATA = 8'hZZ;

// Latched command register
reg [3:0] command;

always @(posedge CLK) begin
    if (RESET)
        command <= 4'b0000;
    else if (BUS_WE && BUS_ADDR == BaseAddr)
        command <= BUS_DATA[3:0];
end

// Instantiate IR state machine
IRTransmitterSM ir_sm (
    .RESET      (RESET),
    .CLK        (CLK),
    .COMMAND    (command),
    .SEND_PACKET(|command),
    .IR_LED     (IR_LED)
);

endmodule
