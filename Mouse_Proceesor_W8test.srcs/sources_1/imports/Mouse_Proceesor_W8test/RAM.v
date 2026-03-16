`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: RAM (Random Access Memory)
//
// Description:
//   128 x 8-bit synchronous RAM connected to the shared system bus.
//   Occupies the address range 0x00 - 0x7F (selected when BUS_ADDR[7] = 0).
//
//   Bus Protocol:
//     - Write (BUS_WE = 1): data from BUS_DATA is stored into memory
//     - Read  (BUS_WE = 0): memory content is driven onto BUS_DATA
//     - When not addressed, the output is high impedance (8'hZZ)
//
//   Initial contents are loaded from "Complete_Demo_RAM.txt" via $readmemh.
//   This can be used to preload variables and constants.
//
//////////////////////////////////////////////////////////////////////////////////
module RAM(
	//standard signals
	input CLK,                      // System clock
	//BUS signals
	inout [7:0] BUS_DATA,          // Tri-state data bus
	input [7:0] BUS_ADDR,          // Address bus
	input BUS_WE                   // Write enable (1 = write, 0 = read)
);

	parameter RAMBaseAddr = 0;
	parameter RAMAddrWidth = 7;     // 2^7 = 128 bytes

	// Tri-state bus interface
	wire [7:0] BufferedBusData;     // Captures BUS_DATA for write operations
	reg [7:0] Out;                  // Read data output register
	reg RAMBusWE;                   // Drives BUS_DATA when reading

	// Drive the bus only during a read from this RAM
	assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;
	assign BufferedBusData = BUS_DATA;

	// 128 x 8-bit memory array
	reg [7:0] Mem [2**RAMAddrWidth-1:0];

	// Preload memory contents from hex file
	initial $readmemh("Complete_Demo_RAM.txt", Mem);

	// Synchronous read/write logic
	always @(posedge CLK) begin
    	RAMBusWE <= 1'b0;           // Default: do not drive the bus

    	// RAM is selected when address MSB is 0 (range 0x00-0x7F)
    	if (!BUS_ADDR[7]) begin
        	if (BUS_WE) begin
            	// Write: store incoming bus data into memory
            	Mem[BUS_ADDR[6:0]] <= BufferedBusData;
        	end
        	else begin
            	// Read: latch memory content and enable bus driver
            	Out <= Mem[BUS_ADDR[6:0]];
            	RAMBusWE <= 1'b1;
        	end
    	end
	end
endmodule




