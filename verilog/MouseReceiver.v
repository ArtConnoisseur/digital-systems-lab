`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01.02.2026 13:01:50
// Design Name:
// Module Name: MouseReceiver
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
Implements device-to-host PS/2 reception.
Data from mouse is sampled on the falling edge of CLK.

Each frame consists of:
   - Start bit (0)
   - 8 data bits (LSB first)
   - Odd parity bit
   - Stop bit (1)

Basic error checking is performed.
The receiver performs basic error checking on:
   - Start bit
   - Odd parity bit
   - Stop bit

When a complete byte is received, BYTE_READY is asserted for one system clock cycle, allowing the master FSM to
latch the received data.

A timeout mechanism is included to recover safely from incomplete or corrupted frames.
*/

module MouseReceiver(
	//Standard Inputs
    input RESET,
    input CLK,						// System clock (100 MHz)
    
    //Mouse IO - CLK
    input CLK_MOUSE_IN,
    //Mouse IO - DATA
    input DATA_MOUSE_IN,

    //Control
    input READ_ENABLE,				// Enables byte reception
    output [7:0] BYTE_READ,			// Received data byte
    output [1:0] BYTE_ERROR_CODE,	// Error flags
    output BYTE_READY				// Asserted when byte is valid
);

	// Delay register used to detect falling edge of PS/2 clock.
	// Falling edge occurs when previous value was '1' and
	// current value is '0'.
    reg ClkMouseInDly;
    always @(posedge CLK)
        ClkMouseInDly <= CLK_MOUSE_IN;

    reg [2:0] Curr_State;
    reg [7:0] ShiftReg;
    reg [3:0] BitCount;
    reg ByteReady;
    reg [1:0] ErrorCode;
    reg [15:0] Timeout;

    always @(posedge CLK) begin
        if (RESET) begin
            Curr_State <= 0;
            ShiftReg <= 0;
            BitCount <= 0;
            ByteReady <= 0;
            ErrorCode <= 0;
            Timeout <= 0;
        end else begin
            ByteReady <= 0;
            Timeout <= Timeout + 1;

            case (Curr_State)
            	// Receiver state machine:
            	// State 0 : Wait for start bit
           	 	// State 1 : Receive 8 data bits (LSB first)
            	// State 2 : Check odd parity bit
            	// State 3 : Check stop bit
            	// State 4 : Byte received successfully
                0: begin
                    BitCount <= 0;
                    Timeout <= 0;
                    ErrorCode <= 2'b00;
                    // Wait for a valid start bit (DATA = 0) on falling edge of CLK.
                    // READ_ENABLE ensures reception only occurs when commanded
                    // by the master state machine.
                    if (READ_ENABLE && ClkMouseInDly && ~CLK_MOUSE_IN && ~DATA_MOUSE_IN)
                        Curr_State <= 1;
                end

                1: begin
                    if (Timeout > 100000)
                    	// Timeout counter prevents the FSM from being stuck
                    	// in case of incomplete or corrupted PS/2 frames.
                    	// Timeout value is approximately 1 ms
                        Curr_State <= 0;
                    else if (ClkMouseInDly && ~CLK_MOUSE_IN) begin	// Sample data bits on each falling edge of the PS/2 clock.
                        ShiftReg <= {DATA_MOUSE_IN, ShiftReg[7:1]};
                        BitCount <= BitCount + 1;
                        Timeout <= 0;
                        if (BitCount == 7)
                            Curr_State <= 2;
                    end
                end

                2: begin
                    if (ClkMouseInDly && ~CLK_MOUSE_IN) begin
                    	// Odd parity check:
                    	// If parity bit does not match expected odd parity,
                    	// set parity error flag.
                        if (DATA_MOUSE_IN != ~^ShiftReg)
                            ErrorCode[0] <= 1;
                        Curr_State <= 3;
                        Timeout <= 0;
                    end
                end

                3: begin
                    if (ClkMouseInDly && ~CLK_MOUSE_IN) begin
                    	// Stop bit must be logic '1'.
                    	// Any other value indicates a framing error.
                        if (~DATA_MOUSE_IN)
                            ErrorCode[1] <= 1;
                        Curr_State <= 4;
                        Timeout <= 0;
                    end
                end

                4: begin
                    ByteReady <= 1;		// BYTE_READY is asserted for one system clock cycle
                    Curr_State <= 0;
                end
            endcase
        end
    end

    assign BYTE_READ = ShiftReg;
    assign BYTE_READY = ByteReady;
    assign BYTE_ERROR_CODE = ErrorCode;

endmodule
