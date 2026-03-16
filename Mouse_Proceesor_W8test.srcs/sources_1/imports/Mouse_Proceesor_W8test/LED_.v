`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: LED_Peripheral
//
// Description:
//   Simple write-only 8-bit LED output peripheral.
//   When the processor writes to address 0xC0, the data byte is latched
//   and driven directly to the 8 onboard LEDs.
//
//   In this Week 8 demo, the processor writes the mouse status byte
//   to the LEDs. The status byte bit mapping is defined by PS/2 protocol:
//
//   Bit | LED | Meaning
//   ----+-----+----------------------------------
//    7  | LD7 | Y overflow
//    6  | LD6 | X overflow
//    5  | LD5 | Y sign bit (1 = negative movement)
//    4  | LD4 | X sign bit (1 = negative movement)
//    3  | LD3 | Always 1 (alignment bit)
//    2  | LD2 | Middle button  (1 = pressed)
//    1  | LD1 | Right button   (1 = pressed)
//    0  | LD0 | Left button    (1 = pressed)
//
//   Since this is a write-only peripheral, it never drives the data bus
//   (always outputs 8'hZZ).
//
// Bus Address: 0xC0 (single register, write-only)
//
//////////////////////////////////////////////////////////////////////////////////

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