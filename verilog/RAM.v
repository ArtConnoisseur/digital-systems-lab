`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.03.2026 14:26:09
// Design Name:
// Module Name: RAM
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
This file contains the RAM module interfacing with the processor's bus,
mapped to the lower half of the address space (BUS_ADDR[7] = 0), giving
128 x 8-bit addressable memory locations.

On a write (BUS_WE = 1), data from the bus is stored to the addressed
location. On a read (BUS_WE = 0), the module drives the bus with the
contents of the addressed location via a tri-state output buffer.

Memory contents are pre-loaded at simulation start from
"Complete_RAM_demo.mem" via $readmemh.

Parameters:
- RAMBaseAddr:  Base address of RAM in the system address space (default: 0)
- RAMAddrWidth: Address width, determines memory size 2^7 = 128 bytes (default: 7)
*/

module RAM(
    // Standard Signals
    input       CLK,
    // BUS Signals
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input       BUS_WE
);

    parameter RAMBaseAddr   = 0;
    parameter RAMAddrWidth  = 7; // 128 x 8-bits memory

    // Tristate
    wire    [7:0]   BufferedBusData;
    reg     [7:0]   Out;
    reg             RAMBusWE;

    //Only place data on the bus if the processor is NOT writing, and it is addressing this memory assign
    assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;
    assign BufferedBusData = BUS_DATA;

    //Memory
    reg [7:0] Mem [2**RAMAddrWidth-1:0];

    // Initialise the memory for data preloading, initialising variables, and declaring constants
    initial
        $readmemh("Complete_RAM_demo.mem", Mem);

    // Single port ram
    always@(posedge CLK) begin
        // The brute force adressing here has been replaced
        if(!BUS_ADDR[7]) begin
            if(BUS_WE) begin
                Mem[BUS_ADDR[6:0]] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1;
        end else
            RAMBusWE <= 1'b0;
        Out <= Mem[BUS_ADDR[6:0]];
    end

endmodule
