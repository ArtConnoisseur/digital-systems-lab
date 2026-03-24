`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.03.2026 11:05:07
// Design Name:
// Module Name: MousePeripheral
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
Module Name: Mouse_Peripheral
Description:
Bus-attached PS/2 mouse peripheral. This module wraps the MouseTransceiver
core and exposes mouse data through the system's shared tri-state bus.

Register Map (Base Address: 0xA0, read-only):
   0xA0 (R) : MouseStatus  - PS/2 status byte (button states, sign bits, overflow)
   0xA1 (R) : MouseX       - Absolute X position (0 - 159, clamped)
   0xA2 (R) : MouseY       - Absolute Y position (0 - 119, clamped)
   0xA3 (R) : MouseDX      - Raw X movement delta (two's complement)
   0xA4 (R) : MouseDY      - Raw Y movement delta (two's complement)

Interrupt Behaviour:
An interrupt is raised whenever mouse movement is detected (DX or DY != 0).
The interrupt remains asserted until acknowledged by the processor.
*/

module Mouse_Peripheral(
    input RESET,                        // Synchronous reset
    input CLK,                          // System clock

    // ===== BUS Interface =====
    inout [7:0] BUS_DATA,              // Tri-state data bus
    input [7:0] BUS_ADDR,             // Address bus
    input BUS_WE,                     // Write enable (this peripheral is read-only)

    // ===== Interrupt =====
    output reg BUS_INTERRUPT_RAISE,    // Interrupt request to processor
    input BUS_INTERRUPT_ACK,           // Interrupt acknowledge from processor

    // ===== PS/2 lines =====
    inout CLK_MOUSE,                   // PS/2 clock (bidirectional, active low)
    inout DATA_MOUSE                   // PS/2 data (bidirectional, active low)
);

parameter MouseBaseAddr = 8'hA0;       // Base address in the memory map

// Mouse data signals from the transceiver core
wire [7:0] MouseStatus;    // Status byte from PS/2 packet
wire [7:0] MouseDX;        // Raw X delta
wire [7:0] MouseDY;        // Raw Y delta
wire [7:0] MouseX;         // Calculated absolute X position
wire [7:0] MouseY;         // Calculated absolute Y position

// Tri-state bus control
reg [7:0] Out;              // Data to drive onto the bus
reg MouseBusWE;             // Bus write enable (active when processor reads from this peripheral)
assign BUS_DATA = MouseBusWE ? Out : 8'hZZ;

// Instantiate the PS/2 mouse transceiver core
MouseTransceiver mouse_core(
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

// Bus read logic: drive the appropriate register onto BUS_DATA
// when the processor reads from an address in range [0xA0, 0xA4]
always @(posedge CLK) begin
    MouseBusWE <= 1'b0;        // Default: do not drive the bus

    // Address decoding: respond only to reads within our address range
    if (BUS_ADDR >= MouseBaseAddr &&
        BUS_ADDR <= MouseBaseAddr + 8'h04 &&
        !BUS_WE) begin

	case (BUS_ADDR)
    	8'hA0: Out <= MouseStatus;  // Status byte
    	8'hA1: Out <= MouseX;       // Absolute X position
    	8'hA2: Out <= MouseY;       // Absolute Y position
    	8'hA3: Out <= MouseDX;      // Raw X delta
    	8'hA4: Out <= MouseDY;      // Raw Y delta
	endcase

        MouseBusWE <= 1'b1;        // Enable bus driver for read
    end
end

// Interrupt generation: raise interrupt when mouse movement is detected
// (either DX or DY is non-zero). Cleared when processor acknowledges.
reg [7:0] prev_x, prev_y;

always @(posedge CLK) begin
    prev_x <= MouseX;
    prev_y <= MouseY;

    if (RESET)
        BUS_INTERRUPT_RAISE <= 1'b0;
    else if (BUS_INTERRUPT_ACK)
        BUS_INTERRUPT_RAISE <= 1'b0;
    else if (MouseX != prev_x || MouseY != prev_y)
        BUS_INTERRUPT_RAISE <= 1'b1;
end

endmodule
