`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 20.03.2026 12:32:22
// Design Name:
// Module Name: IRTransmitterSM
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
IRTransmitterSM.v  —  Yellow-coded car IR transmitter state machine

Carrier frequency : 38 kHz
   100 MHz / 38 000 Hz = 2631.6 cycles/period  →  half-period = 1316 cycles

Packet structure (carrier-pulse counts):
   Start(88)  Gap(40)  CarSelect(22)  Gap(40)
   Right(44/22)  Gap(40)  Left(44/22)  Gap(40)
   Backward(44/22)  Gap(40)  Forward(44/22)

COMMAND[0] = Right   COMMAND[1] = Left
COMMAND[2] = Backward  COMMAND[3] = Forward

State machine follows the same Curr/Next two-always-block pattern used in the Processor module.
*/

module IRTransmitterSM(
    input        RESET,
    input        CLK,
    input  [3:0] COMMAND,
    input        SEND_PACKET,
    output       IR_LED
);

    // Carrier generator  (38 kHz, half-period = 1316 cycles)
    localparam HALF_PERIOD = 1388;   // 100 MHz / 38 kHz / 2

    wire CarrierTick;

    GenericCounter #(
        .COUNTER_WIDTH(11),           // 2^11 = 2048 > 1316
        .COUNTER_MAX  (HALF_PERIOD - 1),
        .INITIAL_VALUE(0)
    ) u_CarrierHalfPeriod (
        .CLK     (CLK),
        .RESET   (RESET),
        .ENABLE  (1'b1),
        .TRIG_OUT(CarrierTick),
        .COUNT   ()
    );

    // Toggle carrier on every half-period tick
    reg CurrCarrier;
    always @(posedge CLK) begin
        if (RESET)
            CurrCarrier <= 1'b0;
        else if (CarrierTick)
            CurrCarrier <= ~CurrCarrier;
    end

    // Rising-edge detect on carrier → one CLK-wide pulse per carrier period
    reg CarrierPrev;
    always @(posedge CLK) begin
        if (RESET) CarrierPrev <= 1'b0;
        else       CarrierPrev <= CurrCarrier;
    end

    wire CarrierRise = CurrCarrier & ~CarrierPrev;

    // State encoding
    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam GAP_CS     = 4'd2;
    localparam CAR_SELECT = 4'd3;
    localparam GAP_R      = 4'd4;
    localparam RIGHT      = 4'd5;
    localparam GAP_L      = 4'd6;
    localparam LEFT       = 4'd7;
    localparam GAP_B      = 4'd8;
    localparam BACKWARD   = 4'd9;
    localparam GAP_F      = 4'd10;
    localparam FORWARD    = 4'd11;

    // Curr / Next registers  —  processor-style two-always pattern
    reg [3:0] CurrState,       NextState;
    reg [7:0] CurrPulseCount,  NextPulseCount;
    reg       CurrBurstEnable, NextBurstEnable;

    // --- Sequential block -------------------------------------------
    always @(posedge CLK) begin
        if (RESET) begin
            CurrState       <= IDLE;
            CurrPulseCount  <= 8'h00;
            CurrBurstEnable <= 1'b0;
        end else begin
            CurrState       <= NextState;
            CurrPulseCount  <= NextPulseCount;
            CurrBurstEnable <= NextBurstEnable;
        end
    end

    // --- Target pulse count for current state -----------------------
    // (burst: 88/44/22; gap: 40; car-select: 22)
    reg [7:0] TargetCount;
    always @(*) begin
        case (CurrState)
            START:      TargetCount = 8'd191;
            GAP_CS:     TargetCount = 8'd25;
            CAR_SELECT: TargetCount = 8'd47;
            GAP_R:      TargetCount = 8'd25;
            RIGHT:      TargetCount = COMMAND[0] ? 8'd47 : 8'd22;
            GAP_L:      TargetCount = 8'd25;
            LEFT:       TargetCount = COMMAND[1] ? 8'd47 : 8'd22;
            GAP_B:      TargetCount = 8'd25;
            BACKWARD:   TargetCount = COMMAND[2] ? 8'd47 : 8'd22;
            GAP_F:      TargetCount = 8'd25;
            FORWARD:    TargetCount = COMMAND[3] ? 8'd47 : 8'd22;
            default:    TargetCount = 8'd0;
        endcase
    end

    // Combinatorial 
    always @(*) begin
        // Defaults: hold current values
        NextState       = CurrState;
        NextPulseCount  = CurrPulseCount;
        NextBurstEnable = CurrBurstEnable;

        case (CurrState)

            IDLE: begin
                NextBurstEnable = 1'b0;
                NextPulseCount  = 8'h00;
                if (SEND_PACKET) begin
                    NextState       = START;
                    NextBurstEnable = 1'b1;
                end
            end

            default: begin
                if (CarrierRise) begin
                    if (CurrPulseCount == TargetCount - 1) begin
                        // State complete — advance to next state
                        NextPulseCount = 8'h00;
                        case (CurrState)
                            START:      begin NextState = GAP_CS;     NextBurstEnable = 1'b0; end
                            GAP_CS:     begin NextState = CAR_SELECT; NextBurstEnable = 1'b1; end
                            CAR_SELECT: begin NextState = GAP_R;      NextBurstEnable = 1'b0; end
                            GAP_R:      begin NextState = RIGHT;      NextBurstEnable = 1'b1; end
                            RIGHT:      begin NextState = GAP_L;      NextBurstEnable = 1'b0; end
                            GAP_L:      begin NextState = LEFT;       NextBurstEnable = 1'b1; end
                            LEFT:       begin NextState = GAP_B;      NextBurstEnable = 1'b0; end
                            GAP_B:      begin NextState = BACKWARD;   NextBurstEnable = 1'b1; end
                            BACKWARD:   begin NextState = GAP_F;      NextBurstEnable = 1'b0; end
                            GAP_F:      begin NextState = FORWARD;    NextBurstEnable = 1'b1; end
                            FORWARD:    begin NextState = IDLE;       NextBurstEnable = 1'b0; end
                            default:    begin NextState = IDLE;       NextBurstEnable = 1'b0; end
                        endcase
                    end else begin
                        NextPulseCount = CurrPulseCount + 1'b1;
                    end
                end
            end

        endcase
    end
    =
    // Output: LED pulses at 38 kHz during burst states, off during gaps/idle
    assign IR_LED = CurrCarrier & CurrBurstEnable;

endmodule