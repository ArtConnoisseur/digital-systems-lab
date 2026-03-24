`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 10:25:39
// Design Name:
// Module Name: ClockDivider
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
This module has been deprecated and is only included for reference.
*/

module ClockDivider (
    input CLK_IN,      // High-speed input clock (e.g., 100MHz)
    output reg CLK_OUT // Divided output clock
);

    // The DIVISOR determines how many input pulses to count before toggling.
    // Note: The resulting frequency will be: CLK_IN / (2 * DIVISOR)
    parameter DIVISOR = 2;

    // 32-bit register to hold the current count
    reg [31:0] counter;

    // Sequential logic triggered on every rising edge of the input clock
    always @(posedge CLK_IN) begin
        // Check if we have reached the target count
        // We use (DIVISOR - 1) because the counter starts at 0
        if (counter >= (DIVISOR - 1)) begin
            CLK_OUT <= ~CLK_OUT; // Invert the output clock signal (Toggle)
            counter <= 0;        // Reset the counter to start over
        end else begin
            // If the target is not reached, increment the counter
            counter <= counter + 1;
        end
    end

    // Initial block for simulation and FPGA power-on state
    // This ensures the counter doesn't start at an 'X' (Unknown) value
    initial begin
        counter = 0;
        CLK_OUT = 0;
    end

endmodule
