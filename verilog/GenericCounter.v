`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 09:37:52
// Design Name:
// Module Name: GenericCounter
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
This is a fundamental parameterized counter module used as a building block
throughout the Digital Systems Laboratory Lab projects.

It provides a synchronous counting mechanism that can be customized for various
timing and address generation tasks. The module counts from a defined initial
value up to a maximum value, at which point it resets and generates a trigger
pulse.

Functionality:

- Parameterized bit-width to optimize hardware resource usage.
- User-defined maximum value and initial starting value.
- Synchronous reset and enable controls for precise timing.
- Active-high trigger output (TRIG_OUT) for cascading multiple counters.

This module is instantiated and utilized by:

- VGADisplayController (for X and Y address generation)
- VGASignalOut (for horizontal and vertical sync timing)
- PatternStateMachine (indirectly through coordinate tracking)

Detailed logic for the increment and wrap-around behavior is documented
in the comments within the always block.
*/

module GenericCounter(
    input CLK,          // 100MHz Input Clock
    input RESET,        // Counter restarts when this is high
    input ENABLE,       // Counter runs only when this is high
    output TRIG_OUT,    // Trigger set to high when the counter is at maximum value
    output [COUNTER_WIDTH - 1:0] COUNT // Counter value output
);
    // Parameters for the counter

    parameter COUNTER_WIDTH = 4; // Width of counter register
    parameter COUNTER_MAX = 9;   // Maximum value of the counter
    parameter INITIAL_VALUE = 0; // What value does the counter start at

    // Register for the counter

    reg [COUNTER_WIDTH - 1:0] count_value; // The actual count register


    // Counter logic
    always@(posedge CLK) begin
        // When reset is high
        if(RESET)
            // set the counter value to the initial value
            count_value <= INITIAL_VALUE;
        // When reset is not high
        else begin
            // And when the counter is enabled
            if (ENABLE) begin
                // Increment counter value till it reaches the maximum
                // value, then restart the counter
                if(count_value == COUNTER_MAX) begin
                    // Restart at maximum value
                    count_value <= INITIAL_VALUE;
                end else begin
                    // Increment count value
                    count_value <= count_value +1;
                end
            end
        end
    end

    assign TRIG_OUT = (count_value == COUNTER_MAX) && ENABLE; // Trigger when counter reachs
                                                              // maximum value
    assign COUNT = count_value;                               // Connect counter to output port

endmodule
