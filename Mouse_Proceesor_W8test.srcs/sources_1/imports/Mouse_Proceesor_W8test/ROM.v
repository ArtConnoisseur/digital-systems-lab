`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ROM (Read-Only Memory)
//
// Description:
//   256 x 8-bit synchronous read-only memory for storing the processor's
//   program (instructions and operands). Contents are loaded at synthesis
//   time from the hex file "Complete_Demo_ROM.txt" using $readmemh.
//
//   The ROM is accessed via a dedicated point-to-point interface with the
//   processor (not on the shared tri-state bus), providing single-cycle
//   latency instruction fetch.
//
// Address Layout:
//   0x00 - 0xFD : Program instructions and operands
//   0xFE        : Interrupt vector for IRQ[1] (timer) - stores thread start address
//   0xFF        : Interrupt vector for IRQ[0] (mouse) - stores thread start address
//
//////////////////////////////////////////////////////////////////////////////////

module ROM(
    input CLK,              // System clock
    input [7:0] ADDR,       // 8-bit address input from processor
    output reg [7:0] DATA   // 8-bit registered data output (1-cycle read latency)
);

parameter ROMAddrWidth = 8; // Address width: 2^8 = 256 entries

// 256 x 8-bit memory array
reg [7:0] mem [0:(1<<ROMAddrWidth)-1];

// Load program from hex file at initialisation
initial $readmemh("Complete_Demo_ROM.txt", mem);

    // Synchronous read: data is available one clock cycle after address is presented
    always@(posedge CLK)
        DATA <= mem[ADDR];

endmodule
