`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.03.2026 00:25:12
// Design Name: 
// Module Name: MUX_4way
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
4-way multiplexer used for car color selection.
Has a parameter WIDTH of 5
*/
module MUX_4way #(
        parameter WIDTH = 5
    )(
        input [1:0] CONTROL,
        input [WIDTH-1:0] IN0,
        input [WIDTH-1:0] IN1,
        input [WIDTH-1:0] IN2,
        input [WIDTH-1:0] IN3,
        output reg [WIDTH-1:0] OUT
    );

    always @(CONTROL or IN0 or IN1 or IN2 or IN3) begin
        case (CONTROL)
            2'b00: OUT <= IN0;
            2'b01: OUT <= IN1;
            2'b10: OUT <= IN2;
            2'b11: OUT <= IN3;
            default: OUT <= {WIDTH{1'b0}};
        endcase
    end
    
endmodule
