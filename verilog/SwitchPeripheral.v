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
    parameter SWITCH_BASE           = 8'h80;
    localparam SWITCH_STATUS_CAR_EN = SWITCH_BASE + 0;
    localparam SWITCH_STATUS_SENS   = SWITCH_BASE + 1;
    localparam SWITCH_STATUS_FG     = SWITCH_BASE + 2; 
    localparam SWITCH_STATUS_BG     = SWITCH_BASE + 3;
    localparam SWITCH_STATUS_CAR_SEL = SWITCH_BASE + 4;

    // Local registers 
    reg bus_re; 
    reg [7:0] temp_bus_data;

    // Handle reading by bus 
    always @(posedge CLK) begin
        if (RESET) begin
            bus_re        <= 0; 
            temp_bus_data <= 0; 
        end else begin
            // READ ONLY!!
            if (!BUS_WE && BUS_ADDR[7:4] == 4'h8) begin
                bus_re <= 1; 
                case (BUS_ADDR)
                    SWITCH_STATUS_CAR_EN    : temp_bus_data <= SWITCH[0];
                    SWITCH_STATUS_SENS      : temp_bus_data <= SWITCH[2:1];
                    SWITCH_STATUS_FG        : temp_bus_data <= SWITCH[6:3];
                    SWITCH_STATUS_BG        : temp_bus_data <= SWITCH[10:7];
                    SWITCH_STATUS_CAR_SEL   : temp_bus_data <= SWITCH[12:11];
                endcase
            end else begin
                bus_re <= 0; 
            end
        end
    end

    // Handle tristate output 
    assign BUS_DATA = bus_re ? temp_bus_data : 8'hZZ;

endmodule