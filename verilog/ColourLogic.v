`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03.02.2026 15:41:33
// Design Name:
// Module Name: ColourLogic
// Project Name: DSL 4
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
This module basically handles the conversation from the
8-bit output of the VGA Signal Generator (complying with the design )
and then gives you a 12 bit version.

8 bit format: RRR BBB GG
12 bit format: RRRR BBBB GGGG

This maintains synchronisation between colour resolution and colour accuracy
by grouping the LSBs of the Blue and Red in the 12 bit based on the LSB of
the Red and Blue of the 8 bit colour. Green just has the two bits repeated
averaging it out.

The need for this module is so that the entire colour spectrum can be represented
using the 8 bit representation of the colour value. This is better than a naive
truncation of bits to represent the colours.
*/

module ColourLogic(
        // 8 - bit colour input
        input [7:0] COLOUR_IN_8,
        // 12 - bit colour output
        output reg [11:0] COLOUR_OUT_12
    );

    // Simple combinational logic to implement the functionality
    // described above.
    always @(*) begin
        // Red
        COLOUR_OUT_12[2:0] = COLOUR_IN_8[2:0];
        COLOUR_OUT_12[3] = COLOUR_IN_8[2];

        // Blue
        COLOUR_OUT_12[6:4] = COLOUR_IN_8[5:3];
        COLOUR_OUT_12[7] = COLOUR_IN_8[5];

        // Green
        COLOUR_OUT_12[11:8] = {COLOUR_IN_8[7:6], COLOUR_IN_8[7:6]};
    end

endmodule
