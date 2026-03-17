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
    
    // =========================================================
    // Parameters – YELLOW car (38 kHz carrier)
    // =========================================================
    parameter StartBurstSize    = 88;
    parameter CarSelectBurstSize = 22;
    parameter GapSize           = 40;
    parameter AssertBurstSize   = 44;
    parameter DeAssertBurstSize = 22;

    // =========================================================
    // Carrier Generator – 38 kHz from 100 MHz clock
    //   Half-period = 100_000_000 / (2 * 38_000) = 1316 cycles
    //   CarrierSignal toggles every 1316 cycles → 38.002 kHz
    // =========================================================
    parameter HALF_PERIOD = 11'd1316;

    reg [10:0] PulseCounter;   // 11 bits: covers 0–1315 (max 2047)
    reg        CarrierSignal;  // 38 kHz square wave

    always @(posedge CLK) begin
        if (RESET) begin
            PulseCounter  <= 0;
            CarrierSignal <= 0;
        end else begin
            if (PulseCounter == HALF_PERIOD - 1) begin
                PulseCounter  <= 0;
                CarrierSignal <= ~CarrierSignal;
            end else begin
                PulseCounter <= PulseCounter + 1'b1;
            end
        end
    end

    // BurstTick: one clock-wide pulse once per full carrier cycle
    // Fires at the falling edge of CarrierSignal (when it is about to go low)
    // so the state machine counts completed carrier pulses.
    wire BurstTick = (PulseCounter == HALF_PERIOD - 1) && (CarrierSignal == 1'b1);

    /*
    Simple state machine to generate the states of the packet i.e. Start, Gaps, Right Assert or De-Assert, Left
    Assert or De-Assert, Backward Assert or De-Assert, and Forward Assert or De-Assert
    */

    
    // Sequential
        always @(posedge CLK) begin
            if (RESET) begin
                Curr_State <= 4'h0;
                Curr_Counter <= 0;
            end else begin
                Curr_State <= Next_State;
                Curr_Counter <= Next_Counter;
            end
        end
        
        // Combinational FSM
    
        // FSM States:

    
        always @* begin
            Next_State = Curr_State;
            Next_Counter = Curr_Counter;
    
            case (Curr_State)  
            
                // Power-up delay to allow mouse to initialise
                4'h0: begin
                    
                end
                
    

    // Finally, tie the pulse generator with the packet state to generate IR_LED
    
    /*
    ....................
    FILL IN THIS AREA
    ...................
    */

endmodule
