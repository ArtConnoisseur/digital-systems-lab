`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 20.03.2026 12:40:46
// Design Name:
// Module Name: IR_Peripheral
// Project Name:
// Target Devices:
// Tool Versions:
// Description: See below.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/* 
Module Name: IR_Peripheral
Description:
Bus-attached wrapper around IRTransmitterSM.
The processor writes a command byte to 0x90 to trigger IR transmission.

Register Map (Base Address: 0x90):
0x90 (W) : command [3:0]
    bit0 = Right
    bit1 = Left
    bit2 = Backward
    bit3 = Forward

A 10 Hz counter fires SEND_PACKET once per 100 ms while the stored
command is non-zero.  Write 0x00 to stop transmitting.
*/

module IR_Peripheral(
    input        CLK,
    input        RESET,
    // BUS Interface
    inout  [7:0] BUS_DATA,
    input  [7:0] BUS_ADDR,
    input        BUS_WE,
    // IR output
    output       IR_LED
);

    // Parameters
    parameter BaseAddr = 8'h90;
    localparam COMMAND = BaseAddr + 0;  
    localparam ENABLE  = BaseAddr + 1; 

    // Write-only: never drive the bus
    assign BUS_DATA = 8'hZZ;

    // Latched command register
    reg [3:0] command;
    reg enable; 

    always @(posedge CLK) begin
        if (RESET) begin 
            command <= 4'b0000;
            enable  <= 1; 
        end 
        else if (BUS_WE && BUS_ADDR[7:4] == 9) begin
            case (BUS_ADDR)
                COMMAND : command  <= BUS_DATA[3:0]; 
                ENABLE  : enable   <= BUS_DATA[0];
                default : ;
            endcase
        end
    end

    // 10 Hz tick: 100 MHz / 10 = 10_000_000 cycles
    wire send_tick;
    GenericCounter #(
        .COUNTER_WIDTH(24),       // 2^24 = 16M > 10M
        .COUNTER_MAX  (9_999_999),
        .INITIAL_VALUE(0)
    ) u_10Hz (
        .CLK     (CLK),
        .RESET   (RESET),
        .ENABLE  (enable),
        .TRIG_OUT(send_tick),
        .COUNT   ()
    );

    // Instantiate IR state machine
    IRTransmitterSM ir_sm (
        .RESET      (RESET),
        .CLK        (CLK),
        .COMMAND    (command),
        .SEND_PACKET(send_tick & |command),
        .IR_LED     (IR_LED)
    );

endmodule