`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.03.2026 14:26:09
// Design Name:
// Module Name: ROM
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/*
This file contains the ROM module interfacing with the processor's bus,
providing 256 x 8-bit addressable memory locations.

Unlike the RAM, this is read-only with no write enable or tri-state logic —
it simply outputs the contents of the addressed location on every rising
clock edge.

The program is pre-loaded at simulation start from
"Complete_ROM_demo.mem" via $readmemh.

Parameters:
- RAMAddrWidth: Address width, determines memory size 2^8 = 256 bytes (default: 8)
*/

module ROM(
    // Standard signals
    input               CLK,
    // BUS signals
    output reg  [7:0]   DATA,
    input       [7:0]   ADDR
);

    parameter RAMAddrWidth = 8;

    // Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];

    // Load program
    initial $readmemh("Complete_ROM_demo.mem", ROM);

    // Single port ram
    always@(posedge CLK)
        DATA <= ROM[ADDR];

endmodule
