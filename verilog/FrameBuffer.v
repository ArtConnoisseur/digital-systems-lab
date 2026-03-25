`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 10:19:07
// Design Name:
// Module Name: FrameBuffer
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
This module implements a Dual-Port Frame Buffer for the VGA Interface project
in the Digital Systems Laboratory Lab.

It serves as the system's Video RAM (VRAM), providing a synchronized storage
medium for a 160x120 resolution single-bit pixel map. The buffer is designed
with a dual-port architecture to allow simultaneous access from two different
clock domains: Port A for logic-driven updates (MPU later/Pattern Generator
for week 5) and Port B for real-time VGA display driving.

Functionality:

- Dual-Port Memory: Enables independent Read/Write access on Port A and
  dedicated Read-only access on Port B.
- Address Flattening: Converts 2D spatial coordinates (X, Y) into a linear
  1D memory index using the formula: Index = (Y * Width) + X.
- Multi Clock Implementation: Supports different frequencies for A_CLK and B_CLK,
  allowing the system logic to run at 100MHz while the VGA driver operates
  at the standard 25MHz.

Interface:

- Port A: Used by the processing unit to update specific pixels or read back
  stored data.
- Port B: Used exclusively by the VGASignalOut module to fetch pixel data
  sequentially for display on the monitor.
*/

module FrameBuffer(
        // Universal
        input RESET,    // Reset signal

        // Read/Write - Port A
        input A_CLK,     // Frame Buffer clock
        input A_WE,      // Write Enable
        input [7:0] AX,  // 8 bit X data - input from MPU
        input [6:0] AY,  // 7 bit Y data  - input from MPU
        input A_DATA_IN, // Pixel data in (Either foreground/background)
        output reg A_DATA_OUT,

        // Read only - Port B
        input B_CLK,      // 25 MHz Clock to interface with VGA
        input [7:0] BX,   // 8 bit X data - input from VGA driver
        input [6:0] BY,   // 7 bit Y data  - input from VGA driver
        output reg B_DATA // Pixel data out (Either foreground/background)
    );

    // Defining parameters pertaining to frame data:

    parameter X_RES = 160; // Horizontal Resolution
    parameter Y_RES = 120; // Vertical Resolution

    // Ideally you'd want to implement this with a 2D array in verilog
    // but for some reason vivado is struggling to initialise this
    // which is why this line is here for reference, but is not part of the
    // submitted implementation of the design

    // reg [0:0] frame [0:X_RES][0:Y_RES];

    // Note on addressing of the frame: the data for a given pixel value pair
    // X and Y is calculated as Y rows of X pixes, so Y rows of X_RES pixels
    // and X is the offset in that row that is being adressed.

    parameter FRAME_SIZE = X_RES * Y_RES;
    (* ram_style = "distributed" *) reg [0:0] frame [0 : FRAME_SIZE - 1];

    // The grid to be displayed along with the labels of each grid part
    initial
        $readmemb("Frame_Buffer_Init.mem", frame);

    // Handle reset 
    always @(posedge CLK) begin
        if (RESET)
            $readmemb("Frame_Buffer_Init.mem", frame);
    end
    // The code block below implements the frame buffer logic for port A

    always @(posedge A_CLK) begin
        if (!RESET) begin
            // If writing is enabled, the frame data is updated with
            // the input data
            if (A_WE) begin
                frame[AY * X_RES + AX] <= A_DATA_IN;
            end

            // Current output data for reference at port A
            A_DATA_OUT <= frame[AY * X_RES + AX];
        end
    end

    // The code block below implements the frame buffer logic for port B

    // Note, B_CLK is connected to the 25MHz clock for the VGA
    always @(posedge B_CLK) begin
        if (!RESET) begin
            // Sending data to VGA signal generator
            B_DATA <= frame[BY * X_RES + BX];
        end
    end

endmodule
