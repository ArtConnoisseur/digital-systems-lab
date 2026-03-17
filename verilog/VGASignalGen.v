`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 10:12:49
// Design Name:
// Module Name: VGASignalOut
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
This module serves as the primary VGA Signal Generator for the VGA Interface
project in the Digital Systems Laboratory Lab.

It is responsible for generating the precise timing required by the VGA standard
to drive a display. This includes the generation of Horizontal (HS) and Vertical
(VS) synchronization pulses, as well as the calculation of pixel addresses (X, Y)
used to fetch data from the frame buffer or pattern generators.

Functionality:

- Sync Generation: Utilizes a 25MHz clock to manage standard 640x480 @ 60Hz
  timing, using cumulative parameters for easier logic comparison.
- Coordinate Scaling: Implements a 4x4 downsampling rule via bit-shifting
  (division by 4), converting the raw 640x480 scan space into a 160x120
  addressable grid for the Frame Buffer.
- Color Blanking: Ensures that the COLOUR_OUT signal is strictly driven to
  8'h00 during the non-display periods (Sync Pulse, Front Porch, and Back Porch)
  to maintain monitor synchronization and black-level calibration.

Instantiated Modules:

- GenericCounter (horizontal_counter): Tracks pixel progress across a line (0-799).
- GenericCounter (vertical_counter): Tracks line progress across a frame (0-520).

This module is effectively the interface between the project and the actual
VGA module.
*/

module VGASignalOut(
        // Essential Ports
        input CLK,          // 25 MHz Clock genereated using the
                            // MMCM in the Vivado Clocking Wizard
        input RESET,        // Reset pin
        input [7:0] FG,     // Foreground Colour value
        input [7:0] BG,     // Background Colour value

        // Frame buffer
        output reg [7:0] X, // Pixel Address for the X-Axis
        output reg [6:0] Y, // Pixel Address for the Y-Axis
        input VGA_DATA,     // VGA Data input for displaying correct colour
                            // i.e. FG or BG to the screen

        // VGA Port
        output reg HS,      // Horizontal Sync Signal
        output reg VS,      // Vertical Sync Sugnal
        output reg [7:0] COLOUR_OUT // Output Colour
    );


    // Parameters for timing the Horitzontal and Vertical sync signals of the
    // VGA.

    // Note: These values are cumulative so that the conditions are easier to
    // understand/code. This why they differ from what is given in the Basys 3
    // manual. Also why X is HS - BACK_PORCH alone.


    parameter V_SYNC_PULSE = 10'd2;    // Initial pulse till when VS has to be off
    parameter V_BACK_PORCH = 10'd31;   // Count till back porch ends
    parameter V_DISPLAY = 10'd511;     // Count till display period ends
    parameter V_TOTAL = 10'd521;       // Total vertical count value

    parameter H_SYNC_PULSE = 10'd96;   // Initial pulse till when HS has to be off
    parameter H_BACK_PORCH = 10'd144;  // Count till back porch ends
    parameter H_DISPLAY = 10'd784;     // Count till display period ends
    parameter H_TOTAL = 10'd800;       // Total horizontal count value

    // When looking online the specifications for VGA follow these parameters:
    // This is based on a 25.175Hz clock

//    parameter V_SYNC_PULSE = 10'd2;    // Initial pulse till when VS has to be off
//    parameter V_BACK_PORCH = 10'd35;   // Count till back porch ends
//    parameter V_DISPLAY = 10'd515;     // Count till display period ends
//    parameter V_TOTAL = 10'd525;       // Total vertical count value

    // The modules works with the above, but the implementation will follow the
    // Basys 3 specifications anyways (it is closer to 60Hz when calculated by hand)


    // The below code block shows the logic for generatting the count for
    // HS and VS. This is how I initially implemented it as there was an issue
    // with my counter module (fixed later) and I have kept it here for safety
    // and logical reference


//     reg [9:0] VerticalCount;
//     reg [9:0] HorizontalCount;

//     initial begin
//         VerticalCount = 0;
//         HorizontalCount = 0;
//     end

//     always @(posedge CLK) begin
//         if (HorizontalCount < H_TOTAL - 1) begin
//             HorizontalCount <= HorizontalCount + 1;
//         end else begin
//             HorizontalCount <= 0;
//             if (VerticalCount < V_TOTAL - 1)
//                 VerticalCount <= VerticalCount + 1;
//             else
//                 VerticalCount <= 0;
//         end
//     end

    // HS and VS counter implemented using generic counter module implemented
    // from the Year 3 DSL course

    wire [9:0] VerticalCount;
    wire [9:0] HorizontalCount;

    wire HorizontalTriggerOut;

    // Horizontal count is initiated first
    GenericCounter # (
        .COUNTER_WIDTH(10),
        .COUNTER_MAX(H_TOTAL - 1)
    ) horizontal_counter (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(1),
        .TRIG_OUT(HorizontalTriggerOut),
        .COUNT(HorizontalCount)
    );

    // Vertical count is initiated every time horizontal
    // count completes one cycle to it's maximum value
    GenericCounter # (
        .COUNTER_WIDTH(10),
        .COUNTER_MAX(V_TOTAL - 1)
    ) vertical_counter (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(HorizontalTriggerOut), // Triggered by Horizontal Counter
        .TRIG_OUT(),
        .COUNT(VerticalCount)
    );

    // VGA Signal Logic

    // Compute active region of VGA timing
    wire h_active = (HorizontalCount > H_BACK_PORCH) && (HorizontalCount < H_DISPLAY);
    wire v_active = (VerticalCount > V_BACK_PORCH) && (VerticalCount < V_DISPLAY);
    wire active = h_active && v_active;

    // Synchronous block to send out the correct signals
    always@(posedge CLK) begin
        if (RESET) begin
            // Switch off HS and VS for the initial sync pulse
            HS <= 1'b1;
            VS <= 1'b1;
            X <= 0;
            Y <= 0;
            COLOUR_OUT <= 0;
        end else begin
            HS <= ~(HorizontalCount < H_SYNC_PULSE);
            VS <= ~(VerticalCount < V_SYNC_PULSE);

            // Calculate X-Axis pixel address as Current Count - Back Porch value
            // Downsize the resolution to meet specification
            // Assign calculated value to X
            X <= h_active ? HorizontalCount[9:2] - 8'd36 : 8'd0; // Right Shift (division by 4)
                                                                   // Effectively reduced resolution

            // Calculate Y Axis pixel address as Current Count - Back Porch value
            // Downsize the resolution to meet specification
            // Assign calculated value to Y
            Y <= v_active ? (VerticalCount - V_BACK_PORCH) >> 2 : 7'd0; // Right Shift (division by 4)
                                                                          // Effectively reduced resolution

            // Map input VGA data bit to Foreground or Background colour; here BG is
            // when the pixel is zero and FG is when the pixel is one.
            // When not in the display period, the colour should be set to zero.
            COLOUR_OUT <= active ? (VGA_DATA ? FG : BG) : 8'h00;
        end
    end

endmodule
