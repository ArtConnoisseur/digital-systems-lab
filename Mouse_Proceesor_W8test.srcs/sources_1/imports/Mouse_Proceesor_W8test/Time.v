`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Timer
//
// Description:
//   Programmable timer peripheral with interrupt generation.
//   Generates periodic interrupts at a configurable rate (default 100 ms).
//
//   The timer derives a 1 ms tick from the 100 MHz system clock using a
//   prescaler (divide by 50,000). A free-running millisecond counter is
//   compared against a configurable interval to generate interrupts.
//
// Register Map (Base Address: 0xF0):
//   0xF0 (R)  : Current timer value (lower 8 bits of ms counter)
//   0xF1 (W)  : Interrupt rate register (interval in ms, default = 100)
//   0xF2 (W)  : Timer reset (writing to this address resets the counter)
//   0xF3 (W)  : Interrupt enable register (bit 0: 1=enabled, 0=disabled)
//
// Interrupt Behaviour:
//   When (LastTime + InterruptRate == Timer) and interrupts are enabled,
//   the module raises BUS_INTERRUPT_RAISE. The interrupt stays asserted
//   until the processor acknowledges it via BUS_INTERRUPT_ACK.
//
//////////////////////////////////////////////////////////////////////////////////


module Timer(
    //standard signals
    input       CLK,                    // System clock (100 MHz)
    input       RESET,                  // Synchronous reset
    //BUS signals
    inout [7:0] BUS_DATA,              // Tri-state data bus
    input [7:0] BUS_ADDR,             // Address bus
    input       BUS_WE,               // Write enable
    output      BUS_INTERRUPT_RAISE,   // Interrupt request to processor
    input       BUS_INTERRUPT_ACK      // Interrupt acknowledge from processor
);
    
    parameter [7:0] TimerBaseAddr = 8'hF0; // Timer Base Address in the Memory Map
    parameter InitialIterruptRate = 100;   // Default interrupt rate leading to 1 interrupt every 100 ms
    parameter InitialIterruptEnable = 1'b1;  // By default the Interrupt is Enabled
    
    //////////////////////
    // BaseAddr + 0 -> reports current timer value
    // BaseAddr + 1 -> Address of a timer interrupt interval register, 100 ms by default
    // BaseAddr + 2 -> Resets the timer, restart counting from zero
    // BaseAddr + 3 -> Address of an interrupt Enable register, allows the microprocessor to disable
    // the timer
    //
    // This module will raise an interrupt flag when the designated time is up. It will
    // automatically set the time of the next interrupt to the time of the last interrupt plus
    // a configurable value (in milliseconds).
    // Interrupt Rate Configuration - The Rate is initialised to 100 by the parameter above, but can
    // also be set by the processor by writing to mem address BaseAddr + 1;
    
    reg [7:0] InterruptRate;
    
    always@(posedge CLK) begin
        if(RESET)
            InterruptRate <= InitialIterruptRate;
        else
            if((BUS_ADDR == TimerBaseAddr + 8'h01) && BUS_WE)
                InterruptRate <= BUS_DATA;
    end

    //Interrupt Enable Configuration - If this is not set to 1, no interrupts will be
    //created.
    reg InterruptEnable;
    
    always@(posedge CLK) begin
        if(RESET)
            InterruptEnable <= InitialIterruptEnable;
        else
            if((BUS_ADDR == TimerBaseAddr + 8'h03) && BUS_WE)
                InterruptEnable <= BUS_DATA[0];
    end
    
    // Prescaler: divides 100 MHz clock down to 1 KHz (1 ms period)
    // Counts from 0 to 49,999 (50,000 cycles = 1 ms at 100 MHz)
    reg [31:0] DownCounter;
    
    always@(posedge CLK) begin
        if(RESET)
            DownCounter <= 0;
        else begin
            if(DownCounter == 32'd49999)
                DownCounter <= 0;
            else
                DownCounter <= DownCounter + 1'b1;
        end
    end

    // Free-running millisecond counter
    // Increments by 1 every time the prescaler wraps around (every 1 ms).
    // Can be reset by writing to BaseAddr + 2.
    reg [31:0] Timer;
    
    always@(posedge CLK) begin
        if(RESET | (BUS_ADDR == TimerBaseAddr + 8'h02))
            Timer <= 0;
        else begin
            if((DownCounter == 0))
                Timer <= Timer + 1'b1;
            else
                Timer <= Timer;
        end
    end

    // Interrupt generation logic
    // Compares current Timer value against (LastTime + InterruptRate).
    // When they match and interrupts are enabled, TargetReached pulses high.
    reg TargetReached;
    reg [31:0] LastTime;    // Records the Timer value when last interrupt was generated

    always@(posedge CLK) begin
        if(RESET) begin
            TargetReached <= 1'b0;
            LastTime <= 0;
        end else if((LastTime + InterruptRate) == Timer) begin
            if(InterruptEnable)
                TargetReached <= 1'b1;
            LastTime <= Timer;
        end else
            TargetReached <= 1'b0;
    end
    
    reg Interrupt;

    // Interrupt latch: holds interrupt high until acknowledged by processor
    always@(posedge CLK) begin
        if(RESET)
            Interrupt <= 1'b0;
        else if(TargetReached)
            Interrupt <= 1'b1;
        else if(BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
    end

    assign BUS_INTERRUPT_RAISE = Interrupt;
    
    // Tri-state bus interface: drives Timer[7:0] onto BUS_DATA when
    // processor reads from BaseAddr (0xF0)
    reg TransmitTimerValue;
    
    always@(posedge CLK) begin
        if(BUS_ADDR == TimerBaseAddr)
            TransmitTimerValue <= 1'b1;
        else
            TransmitTimerValue <= 1'b0;
    end

    assign BUS_DATA = (TransmitTimerValue) ? Timer[7:0] : 8'hZZ;

endmodule

