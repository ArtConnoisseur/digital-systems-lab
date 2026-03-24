module IRTransmitterSM(
    //Standard Signals
    input       RESET,
    input       CLK,
    // Bus Interface Signals
    input [3:0] COMMAND,
    input       SEND_PACKET,
    // IF LED signal
    output      IR_LED
);

    // 38KHz carrier generator (Yellow-coded car)
    // CLK = 10ns, Gen: 1 / 38k = 26.31us
    // 100MHz / 38KHz = 2632 cycles per period
    // Toggle every 1316 cycles -> half-period counter
    parameter HALF_PERIOD = 1389;

    reg [11:0] PulseCounter;
    reg Carrier;

    always @(posedge CLK) begin
        if (RESET) begin
            PulseCounter <= 0;
            Carrier      <= 0;
        end else if (PulseCounter == HALF_PERIOD - 1) begin
            PulseCounter <= 0;
            Carrier      <= ~Carrier;
        end else begin
            PulseCounter <= PulseCounter + 1;
        end
    end

    // Packet state machine
    // Packet structure (pulse counts at 38KHz):
    //   Start(88) Gap(40) CarSelect(22) Gap(40)
    //   Right(44/22) Gap(40) Left(44/22) Gap(40)
    //   Backward(44/22) Gap(40) Forward(44/22)
    //
    // COMMAND[0] = Right
    // COMMAND[1] = Left
    // COMMAND[2] = Backward
    // COMMAND[3] = Forward

    // States
    localparam IDLE        = 4'd0;
    localparam START       = 4'd1;
    localparam GAP_CS      = 4'd2;
    localparam CAR_SELECT  = 4'd3;
    localparam GAP_R       = 4'd4;
    localparam RIGHT       = 4'd5;
    localparam GAP_L       = 4'd6;
    localparam LEFT        = 4'd7;
    localparam GAP_B       = 4'd8;
    localparam BACKWARD    = 4'd9;
    localparam GAP_F       = 4'd10;
    localparam FORWARD     = 4'd11;

    reg [3:0]  State;
    reg [9:0]  PulseCount;     // Counts carrier periods within each burst/gap
    reg        BurstEnable;    // High during burst states, low during gaps
    reg        CarrierEdgePrev;

    // Detect rising edge of carrier to count full carrier periods
    wire CarrierEdge = Carrier & ~CarrierEdgePrev;

    always @(posedge CLK) begin
        if (RESET)
            CarrierEdgePrev <= 0;
        else
            CarrierEdgePrev <= Carrier;
    end

    // Target pulse count for the current state
    reg [9:0] TargetCount;
    always @(*) begin
        case (State)
            START:      TargetCount = 191;
            GAP_CS:     TargetCount = 25;
            CAR_SELECT: TargetCount = 47;
            GAP_R:      TargetCount = 25;
            RIGHT:      TargetCount = COMMAND[0] ? 47 : 22;
            GAP_L:      TargetCount = 25;
            LEFT:       TargetCount = COMMAND[1] ? 47 : 22;
            GAP_B:      TargetCount = 25;
            BACKWARD:   TargetCount = COMMAND[2] ? 47 : 22;
            GAP_F:      TargetCount = 25;
            FORWARD:    TargetCount = COMMAND[3] ? 47 : 22;
            default:    TargetCount = 0;
        endcase
    end

    always @(posedge CLK) begin
        if (RESET) begin
            State       <= IDLE;
            PulseCount  <= 0;
            BurstEnable <= 0;
        end else begin
            case (State)
                IDLE: begin
                    BurstEnable <= 0;
                    if (SEND_PACKET) begin
                        State       <= START;
                        PulseCount  <= 0;
                        BurstEnable <= 1;
                    end
                end

                default: begin
                    if (CarrierEdge) begin
                        if (PulseCount == TargetCount - 1) begin
                            // Current state finished, advance to next
                            PulseCount <= 0;
                            case (State)
                                START:      begin State <= GAP_CS;     BurstEnable <= 0; end
                                GAP_CS:     begin State <= CAR_SELECT; BurstEnable <= 1; end
                                CAR_SELECT: begin State <= GAP_R;      BurstEnable <= 0; end
                                GAP_R:      begin State <= RIGHT;      BurstEnable <= 1; end
                                RIGHT:      begin State <= GAP_L;      BurstEnable <= 0; end
                                GAP_L:      begin State <= LEFT;       BurstEnable <= 1; end
                                LEFT:       begin State <= GAP_B;      BurstEnable <= 0; end
                                GAP_B:      begin State <= BACKWARD;   BurstEnable <= 1; end
                                BACKWARD:   begin State <= GAP_F;      BurstEnable <= 0; end
                                GAP_F:      begin State <= FORWARD;    BurstEnable <= 1; end
                                FORWARD:    begin State <= IDLE;       BurstEnable <= 0; end
                                default:    begin State <= IDLE;       BurstEnable <= 0; end
                            endcase
                        end else begin
                            PulseCount <= PulseCount + 1;
                        end
                    end
                end
            endcase
        end
    end

    // =========================================================
    // Output: IR_LED = carrier AND burst enable
    // During burst states the LED pulses at 38KHz;
    // during gaps and idle it stays off.
    // =========================================================
    assign IR_LED = Carrier & BurstEnable;

endmodule
