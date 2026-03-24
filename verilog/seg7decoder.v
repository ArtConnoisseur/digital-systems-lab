
////////////////////////////////////////////////////////////////////////////////
// Module Name: seg7decoder
//
// Description:
//   Combinational decoder for a 4-digit common-anode 7-segment display.
//   Converts a 4-bit binary/hex input (0x0 - 0xF) into the corresponding
//   7-segment cathode pattern, and generates the digit anode select signal.
//
// Interface:
//   SEG_SELECT_IN [1:0] : Selects which of the 4 digits is active (0-3)
//   BIN_IN [3:0]        : 4-bit hex value to display (0x0 - 0xF)
//   DOT_IN              : Decimal point control (1 = on, active low output)
//   SEG_SELECT_OUT [3:0]: Digit anode select (active low, one-hot encoding)
//                           2'b00 -> 4'b1110 (rightmost digit)
//                           2'b11 -> 4'b0111 (leftmost digit)
//   HEX_OUT [7:0]       : Segment cathode outputs (active low)
////////////////////////////////////////////////////////////////////////////////
module seg7decoder(
		input		[1:0]	SEG_SELECT_IN,      // Digit select (0 = rightmost)
		input		[3:0]	BIN_IN,             // 4-bit hex input value
		input				DOT_IN,             // Decimal point (1 = on)
		output	reg	[3:0]	SEG_SELECT_OUT,     // Digit anode select (active low)
		output	reg	[7:0]	HEX_OUT             // Segment cathodes [7]=dp, [6:0]=a-g
	);

	// Hex-to-7-segment lookup table (active low: 0 = segment ON)
	always@(BIN_IN) begin
		case(BIN_IN)
			4'b0000:	HEX_OUT[6:0] <= 7'b1000000; // 0
			4'b0001:	HEX_OUT[6:0] <= 7'b1111001; // 1
			4'b0010:	HEX_OUT[6:0] <= 7'b0100100; // 2
			4'b0011:	HEX_OUT[6:0] <= 7'b0110000; // 3

			4'b0100:	HEX_OUT[6:0] <= 7'b0011001; // 4
			4'b0101:	HEX_OUT[6:0] <= 7'b0010010; // 5
			4'b0110:	HEX_OUT[6:0] <= 7'b0000010; // 6
			4'b0111:	HEX_OUT[6:0] <= 7'b1111000; // 7

			4'b1000:	HEX_OUT[6:0] <= 7'b0000000; // 8
			4'b1001:	HEX_OUT[6:0] <= 7'b0011000; // 9
			4'b1010:	HEX_OUT[6:0] <= 7'b0001000; // A  (a+b+c+e+f+g ON)
			4'b1011:	HEX_OUT[6:0] <= 7'b0000000; // B  (all segments ON, same as 8)

			4'b1100:	HEX_OUT[6:0] <= 7'b1000110; // C
			4'b1101:	HEX_OUT[6:0] <= 7'b1000111; // L  (f+e+d ON)
			4'b1110:	HEX_OUT[6:0] <= 7'b1111111; // blank (all OFF)
			4'b1111:	HEX_OUT[6:0] <= 7'b0001110; // F

			default:	HEX_OUT[6:0] <= 7'b1111111; // All segments off
		endcase
	end

	// Decimal point: active low (DOT_IN=1 -> HEX_OUT[7]=0 -> DP on)
	always@(DOT_IN) begin
		HEX_OUT[7] <= ~DOT_IN;
	end

	// Anode select: active low one-hot encoding
	always@(SEG_SELECT_IN) begin
		case(SEG_SELECT_IN)
			2'b00:		SEG_SELECT_OUT <= 4'b1110; // Digit 0 (rightmost)
			2'b01:		SEG_SELECT_OUT <= 4'b1101; // Digit 1
			2'b10:		SEG_SELECT_OUT <= 4'b1011; // Digit 2
			2'b11:		SEG_SELECT_OUT <= 4'b0111; // Digit 3 (leftmost)
			default:	SEG_SELECT_OUT <= 4'b1111; // All digits off
		endcase
	end

endmodule
