`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.03.2026 14:25:52
// Design Name:
// Module Name: LED_Peripheral
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
Description:
Simple write-only 8-bit LED output peripheral.
When the processor writes to address 0xC0, the data byte is latched and driven directly to the 8 onboard LEDs.

Since this is a write-only peripheral, it never drives the data bus (always outputs 8'hZZ).
Bus Address: 0xC0 (single register, write-only)
*/

module LED_Peripheral(
    input CLK,                  // System clock
    input RESET,                // Reset botton

    // ================= BUS =================
    inout [7:0] BUS_DATA,      // Tri-state data bus (never driven by this peripheral)
    input [7:0] BUS_ADDR,      // Address bus
    input BUS_WE,              // Write enable

    // ================= LED OUTPUT =================
    output reg [7:0] LED       // 8-bit LED output to FPGA board
);

parameter BaseAddr = 8'hC0;    // Bus address for LED register

// Write-only peripheral: never drives the data bus
assign BUS_DATA = 8'hZZ;

// Latch bus data into LED register on write to BaseAddr
always @(posedge CLK) begin
    if (RESET)
        LED <= 8'h00;           // All LEDs off on reset
    else if (BUS_WE && BUS_ADDR == BaseAddr)
        LED <= BUS_DATA;        // Update LED output
end

endmodule