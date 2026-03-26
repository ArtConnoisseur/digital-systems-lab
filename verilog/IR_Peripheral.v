`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 20.03.2026 12:40:46
// Design Name:
// Module Name: IR_Peripheral
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
Module Name: IR_Peripheral
Description:
Bus-attached wrapper around IRTransmitterSM.
The processor writes a command byte to 0x90 to trigger IR transmission.

Register Map (Base Address: 0x90):
0x90 (W) : command [3:0]
    bit0 = Right
    bit1 = Left
    bit2 = Backward
    bit3 = Forward
0x91 (W) : enable [0]
0x92 (W) : car_sel [1:0]  â€” selects car colour (00=Blue,01=Yellow,10=Green,11=Red)

A 10 Hz counter fires SEND_PACKET once per 100 ms while the stored
command is non-zero.  Write 0x00 to stop transmitting.
*/

module IR_Peripheral(
    input        CLK,
    input        RESET,
    // BUS Interface
    inout  [7:0] BUS_DATA,
    input  [7:0] BUS_ADDR,
    input        BUS_WE,
    // IR output
    output       IR_LED
);

    // Parameters
    parameter BaseAddr  = 8'h90;
    localparam COMMAND  = BaseAddr + 0;
    localparam ENABLE   = BaseAddr + 1;
    localparam CAR_SEL  = BaseAddr + 2;

    // Write-only: never drive the bus
    assign BUS_DATA = 8'hZZ;

    // Latched command register
    reg [3:0] command;
    reg enable;
    reg [1:0] car_sel;

    always @(posedge CLK) begin
        if (RESET) begin
            command <= 4'b0000;
            enable  <= 1;
            car_sel <= 2'b00;
        end
        else if (BUS_WE && BUS_ADDR[7:4] == 9) begin
            case (BUS_ADDR)
                COMMAND : command  <= BUS_DATA[3:0];
                ENABLE  : enable   <= BUS_DATA[0];
                CAR_SEL : car_sel  <= BUS_DATA[1:0];
                default : ;
            endcase
        end
    end

    // 10 Hz tick: 100 MHz / 10 = 10_000_000 cycles
    wire send_tick;
    
    GenericCounter #(
        .COUNTER_WIDTH(24),       // 2^24 = 16M > 10M
        .COUNTER_MAX  (9_999_999),
        .INITIAL_VALUE(0)
    ) u_10Hz (
        .CLK     (CLK),
        .RESET   (RESET),
        .ENABLE  (enable),
        .TRIG_OUT(send_tick),
        .COUNT   ()
    );

    // ---- Car-parameter MUXes ----
    // CONTROL: 00=Blue, 01=Yellow, 10=Green, 11=Red
    wire [10:0] half_period_sel;
    wire  [7:0] start_count_sel;
    wire  [7:0] gap_count_sel;
    wire  [7:0] car_sel_count_sel;
    wire  [7:0] dir_assert_sel;
    wire  [7:0] dir_deassert_sel;

    //                          Blue    Yellow  Green   Red
    MUX_4way #(.WIDTH(11)) mux_half_period (
        .CONTROL(car_sel),
        .IN0(11'd1388), .IN1(11'd1316), .IN2(11'd1333), .IN3(11'd1388),
        .OUT(half_period_sel)
    );

    MUX_4way #(.WIDTH(8)) mux_start (
        .CONTROL(car_sel),
        .IN0(8'd191), .IN1(8'd88), .IN2(8'd88), .IN3(8'd192),
        .OUT(start_count_sel)
    );

    MUX_4way #(.WIDTH(8)) mux_gap (
        .CONTROL(car_sel),
        .IN0(8'd25), .IN1(8'd40), .IN2(8'd40), .IN3(8'd24),
        .OUT(gap_count_sel)
    );

    MUX_4way #(.WIDTH(8)) mux_car_select (
        .CONTROL(car_sel),
        .IN0(8'd47), .IN1(8'd22), .IN2(8'd44), .IN3(8'd24),
        .OUT(car_sel_count_sel)
    );

    MUX_4way #(.WIDTH(8)) mux_dir_assert (
        .CONTROL(car_sel),
        .IN0(8'd47), .IN1(8'd44), .IN2(8'd44), .IN3(8'd48),
        .OUT(dir_assert_sel)
    );

    MUX_4way #(.WIDTH(8)) mux_dir_deassert (
        .CONTROL(car_sel),
        .IN0(8'd22), .IN1(8'd22), .IN2(8'd22), .IN3(8'd24),
        .OUT(dir_deassert_sel)
    );

    // Instantiate IR state machine
    IRTransmitterSM ir_sm (
        .RESET          (RESET),
        .CLK            (CLK),
        .COMMAND        (command),
        .SEND_PACKET    (send_tick & |command),
        .IR_LED         (IR_LED),
        .HALF_PERIOD_IN (half_period_sel),
        .START_COUNT    (start_count_sel),
        .GAP_COUNT      (gap_count_sel),
        .CAR_SEL_COUNT  (car_sel_count_sel),
        .DIR_ASSERT     (dir_assert_sel),
        .DIR_DEASSERT   (dir_deassert_sel)
    );

endmodule