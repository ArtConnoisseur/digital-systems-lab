`timescale  1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.03.2026 23:03:43
// Design Name:
// Module Name: SwitchPeripheral
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
* This module implements the switch peripheral for all additional features 
* 
* The idea is that when there is a single switch that switch
*/

module SwitchPeripheral (
    // Essential ports 
    input CLK, // 100MHz Clock 
    input RESET, // Reset 

    // Switch config 
    input [15:0] SWITCH,

    // Bus Interface 
    input BUS_WE, 
    inout [7:0] BUS_DATA, 
    input [7:0] BUS_ADDR
); 

    // Parameters 
    localparam SWITCH_BASE = 8'h80;
    localparam SWITCH_STATUS_LO = SWITCH_BASE + 0;
    localparam SWITCH_STATUS_HI = SWITCH_BASE + 1;

    // Local registers 
    reg bus_re; 
    reg [7:0] temp_bus_data;

    // Handle reading by bus 
    always @(posedge CLK) begin
        if (RESET) begin
            bus_re <= 0; 
            temp_bus_data <= 0; 
        end else begin
            // READ ONLY!!
            if (!BUS_WE && BUS_ADDR[7:4] == 4'h8) begin
                bus_re <= 1; 

                case (BUS_ADDR)
                    SWITCH_STATUS_HI : temp_bus_data <= SWITCH[15:8]; 
                    SWITCH_STATUS_LO : temp_bus_data <= SWITCH[7:0];
                endcase
            end else begin
                bus_re <= 0; 
            end
        end
    end

    // Handle tristate output 
    assign BUS_DATA = bus_re ? temp_bus_data : 8'hZZ;

endmodule