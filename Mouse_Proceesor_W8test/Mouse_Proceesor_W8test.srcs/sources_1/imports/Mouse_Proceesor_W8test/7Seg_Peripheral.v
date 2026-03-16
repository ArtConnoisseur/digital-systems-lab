`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: SevenSeg_Peripheral
//
// Description:
//   Write-only 4-digit 7-segment display peripheral.
//   The processor writes two bytes to control all four digits:
//
//   Register Map (Base Address: 0xD0):
//     0xD0 (W) : digit0 = BUS_DATA[3:0], digit1 = BUS_DATA[7:4]
//     0xD1 (W) : digit2 = BUS_DATA[3:0], digit3 = BUS_DATA[7:4]
//
//   Each digit is a 4-bit BCD/hex value (0x0 - 0xF).
//
//   The display is time-multiplexed: a 16-bit free-running counter
//   selects one of the four digits at a time. At 100 MHz, the upper
//   2 bits cycle through all 4 digits at ~1.5 kHz, fast enough to
//   appear continuous to the human eye.
//
//////////////////////////////////////////////////////////////////////////////////

module SevenSeg_Peripheral(
    input CLK,                      // System clock
    input RESET,                    // Reset botton

    // ================= BUS =================
    inout [7:0] BUS_DATA,          // Tri-state data bus (never driven)
    input [7:0] BUS_ADDR,          // Address bus
    input BUS_WE,                  // Write enable

    // ================= 7SEG OUTPUT =================
    output [7:0] HEX_OUT,          // Segment cathodes (active low)
    output [3:0] SEG_SELECT_OUT    // Digit anode select (active low, one-hot)
);

parameter BaseAddr = 8'hD0;        // Base address for this peripheral

// ================= Digit Registers =================
// Each holds a 4-bit value (0-F) for one display digit
reg [3:0] digit0;  // Rightmost digit
reg [3:0] digit1;  // Second from right
reg [3:0] digit2;  // Second from left
reg [3:0] digit3;  // Leftmost digit

// Write-only peripheral: never drives the data bus
assign BUS_DATA = 8'hZZ;

// ================= BUS Write Logic =================
// Processor writes a byte; lower nibble and upper nibble are split
// into two separate digit registers.
always @(posedge CLK) begin
    if (RESET) begin
        digit0 <= 0;
        digit1 <= 0;
        digit2 <= 0;
        digit3 <= 0;
    end
    else if (BUS_WE) begin
        case (BUS_ADDR)
        	BaseAddr + 0: begin
                digit0 <= BUS_DATA[3:0];    // Lower nibble -> digit0
                digit1 <= BUS_DATA[7:4];    // Upper nibble -> digit1
            end
            BaseAddr + 1: begin
                digit2 <= BUS_DATA[3:0];    // Lower nibble -> digit2
                digit3 <= BUS_DATA[7:4];    // Upper nibble -> digit3
            end
    	endcase
    end
end

// ================= Display Multiplexing =================
// A 16-bit counter's top 2 bits cycle through the 4 digits.
reg [1:0] seg_select;
reg [15:0] refresh_counter;

always @(posedge CLK) begin
    refresh_counter <= refresh_counter + 1;
    seg_select <= refresh_counter[15:14];   // Selects which digit is active
end

// Multiplex: select the digit value based on current segment select
reg [3:0] current_digit;

always @(*) begin
    case(seg_select)
        2'b00: current_digit = digit0;
        2'b01: current_digit = digit1;
        2'b10: current_digit = digit2;
        2'b11: current_digit = digit3;
    endcase
end

// ================= 7-Segment Decoder =================
// Converts 4-bit BCD/hex value into segment drive signals
seg7decoder decoder(
    .SEG_SELECT_IN(seg_select),
    .BIN_IN(current_digit),
    .DOT_IN(1'b0),                  // Decimal point always off
    .SEG_SELECT_OUT(SEG_SELECT_OUT),
    .HEX_OUT(HEX_OUT)
);

endmodule