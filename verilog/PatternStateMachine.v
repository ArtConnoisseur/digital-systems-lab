//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 10:13:19
// Design Name:
// Module Name: PatternStateMachine
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
This module implements a Pattern Generator State Machine for the VGA Interface
project in the Digital Systems Laboratory Lab.

It functions as a mathematical 'engine' that determines the pixel data output
(DATA_OUT) based on the current active state and the spatial coordinates
(X_IN, Y_IN). The state is controlled via push buttons, allowing for
real-time switching between different visual patterns on the VGA display.

Pattern Logic:
- State 0: Array of Squares
- State 1: Checkerboard using Gray Code (also called Knitting Pattern)
- State 2: Fractal of triangles
- State 3: Checquered Lines

Control Logic:
- State transitions are synchronous and driven by the 100MHz clock.
- The STATE_CONTROL input uses a one-hot encoding scheme to trigger transitions
  between the four internal pattern states using push buttons.
*/

module PatternStateMachine (
        // Inputs
        input CLK,              // 100MHz System Clock
        input RESET,            // Synchronous Reset
        input [3:0] STATE_CONTROL, // Push buttons to control state (one-hot)
        input [7:0] X_IN,       // Current X pixel coordinate from controller
        input [6:0] Y_IN,       // Current Y pixel coordinate from controller

        // Outputs
        output reg DATA_OUT     // Resulting bit (High/Low) for the current pixel
);
    // Internal state register (holds 4 possible states: 0, 1, 2, 3)
    reg [1:0] PatternState;

    // Initialize state to 0 for simulation and power-on consistency
    initial begin
        PatternState = 0;
    end

    // Combinational Logic: Determines pixel color based on current state and coordinates
    // This block reacts instantly to changes in coordinates or state
    always @(*) begin
        case (PatternState)
            // State 0: Array of Squared
            2'd0: DATA_OUT = ~(X_IN[0] | Y_IN[0]);

            // State 1: Checkerboard (Gray Code | Knit)
            2'd1: DATA_OUT = (X_IN ^ (X_IN >> 1)) ^ (Y_IN ^ (Y_IN >> 1));

            // State 2: Fractal
            2'd2: DATA_OUT = (X_IN & Y_IN) == 0;

            // State 3: Checquered Lines
            2'd3: DATA_OUT = (X_IN ^ Y_IN) & (Y_IN >> 2);

            // Default safety case
            default: DATA_OUT = ~(X_IN[0] | Y_IN[0]);
        endcase
    end

    // Sequential Logic: Handles state transitions on the rising edge of the clock
    always @(posedge CLK) begin
        if (RESET)
            // Return to the first pattern on reset
            PatternState <= 2'd0;
        else begin
            // State switching based on one-hot STATE_CONTROL input
            case (STATE_CONTROL)
                4'b0001: PatternState <= 2'd0; // Trigger State 0
                4'b0010: PatternState <= 2'd1; // Trigger State 1
                4'b0100: PatternState <= 2'd2; // Trigger State 2
                4'b1000: PatternState <= 2'd3; // Trigger State 3
                default: PatternState <= PatternState; // Maintain current state if no input
            endcase
        end
    end

endmodule
