`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07.02.2026 20:38:21
// Design Name:
// Module Name: VGADisplayController
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
This module acts as the central display controller within the VGA Interface
system for the Digital Systems Laboratory Lab.

It is responsible for two primary tasks: managing the change of
colour every second and stimulating the frame buffer with every combination of
(x, y) coordinates to show the functionality of the week 5 submission
implemented on the actual screen.

Instantiated Modules:

- GenericCounter (one_second_counter): Generates a 1Hz trigger for color logic.
- GenericCounter (X_counter_inst): Tracks horizontal pixel position (0-159).
- GenericCounter (Y_counter_inst): Tracks vertical line position (0-119).

This module basically provides stimulation for the 'test' functionality
required to be implemented in the submission in week 5.
*/

module VGADisplayController(
        // Universal ports
        input CLK,              // 100MHz clock
        input RESET,            // Reset signal

        // Ports for colour control
        input [7:0] FG_IN,      // Foreground colour input
        input [7:0] BG_IN,      // Background colour input
        output [7:0] FG_OUT,    // Foreground colour output
        output [7:0] BG_OUT,    // Background colour output

        // Ports for pixel address control
        output [7:0] X,         // Generated X Axis pixel address out
        output [6:0] Y          // Generated Y Axis pixel address out
    );

    // Parameters

    parameter COL_CHANGE_FREQ = 100000000; // Number of clock cycles to delay
                                           // 10e6 should delay 100MHz by one
    parameter X_RES = 160;                 // Resolution of pixels across X-Axis
    parameter Y_RES = 120;                 // Resolution of pixels across Y-Axis

    // Colour logic

    // The idea is that colour is to be complemented every one second
    // which should meet functionality requirements ensuring that the colour
    // change taking palce every second is always distinguisable to the
    // naked eye.

    // Let's create a one second delay

    wire one_second_trigger;

    // This counter counts up to one second
    GenericCounter #(
        .COUNTER_WIDTH(27),
        .COUNTER_MAX(COL_CHANGE_FREQ - 1)
    ) one_second_counter (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(1),
        .TRIG_OUT(one_second_trigger),
        .COUNT()
    );

    // Complement bit flag
    reg complement = 0;

    // Now the above counter can be used to change the colour every second

    always @(posedge CLK) begin
        // When reset is active, set complement bit flag
        // to zero
        if (RESET) begin
            complement <= 0;
        // Toggle current colour with its complement
        // every second
        end else if (one_second_trigger) begin
            complement <= ~complement;
        end
    end

    // Complement input colour according to the complement flag
    // and connect to output colour
    assign FG_OUT = FG_IN ^ {8{complement}};
    assign BG_OUT = BG_IN ^ {8{complement}};

    // Pixel address generation logic

    // The idea here is to generate every combination of coordinated
    // X, Y in the

    // Wire to enable Y pixels after the first row
    // of X pixels have been counted fully
    wire x_trig;

    // X pixel counter
    GenericCounter  #(
        .COUNTER_WIDTH(8),
        .COUNTER_MAX(X_RES - 1)
    ) X_counter_inst (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(1),
        .TRIG_OUT(x_trig),
        .COUNT(X)
    );

    // Y pixel counter
    GenericCounter #(
        .COUNTER_WIDTH(7),
        .COUNTER_MAX(Y_RES - 1)
    ) Y_counter_inst (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(x_trig), // Enable only when X Pixels are done counting for
                         // for one frame.
        .TRIG_OUT(),
        .COUNT(Y)
    );

endmodule
