`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.03.2026 14:26:09
// Design Name:
// Module Name: Timer
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
This file contains the Timer module interfacing with the processor's bus,
mapped to four addresses from the base address of F0 to F3:

- BaseAddr + 0 -> Read current timer value (in ms)
- BaseAddr + 1 -> Set interrupt interval (default: 100ms)
- BaseAddr + 2 -> Reset the timer, restarting the count from zero
- BaseAddr + 3 -> Enable/disable interrupts

The timer works by down-counting from 50MHz to 1KHz, giving a 1ms
resolution. It raises an interrupt on the bus each time the configurable
interval elapses, and waits for an acknowledgement before lowering it.
The interval and enable state can both be reconfigured at runtime by
the processor.

Parameters:
- TimerBaseAddr:          Base address of the timer in the memory map (default: 0xF0)
- InitialInterruptRate:   Interval between interrupts in ms (default: 100)
- InitialInterruptEnable: Whether interrupts are enabled on startup (default: 1)
*/

module Timer(
    //standard signals
    input       CLK,
    input       RESET,
    //BUS signals
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input       BUS_WE,
    output      BUS_INTERRUPT_RAISE,
    input       BUS_INTERRUPT_ACK
);
    parameter [7:0] TimerBaseAddr = 8'hF0; // Timer Base Address in the Memory Map
    parameter InitialIterruptRate = 100;   // Default interrupt rate leading to 1 interrupt every 100 ms
    parameter InitialIterruptEnable = 1'b1;  // By default the Interrupt is Enabled


    // Interrupt Rate Configuration - The Rate is initialised to 100 by the parameter above, but can
    // also be set by the processor by writing to mem address BaseAddr + 1;
    reg [7:0] InterruptRate;
    always@(posedge CLK) begin
        if(RESET)
            InterruptRate <= InitialIterruptRate;
        else
            // Change: changed & to && — logical AND operator for conditions
            if((BUS_ADDR == TimerBaseAddr + 8'h01) && BUS_WE)
                InterruptRate <= BUS_DATA;
    end

    // Interrupt Enable Configuration - If this is not set to 1, no interrupts will be
    // created.
    reg InterruptEnable;
    always@(posedge CLK) begin
        if(RESET)
            InterruptEnable <= InitialIterruptEnable;
        else
            // Change: changed & to && — logical AND operator for conditions
            if((BUS_ADDR == TimerBaseAddr + 8'h03) && BUS_WE)
                InterruptEnable <= BUS_DATA[0];
    end

    // Something was wrong here, causing the delay to be half as fast.
    // Change: Corrected from 49999 to 99999. The BASYS 3 board runs at 100MHz,
    // not 50MHz. To generate a 1ms (1KHz) tick we need to count 100,000
    // cycles (0 to 99999), not 50,000. The original value caused interrupts
    // to fire at double the configured rate.
    reg [31:0] DownCounter;
    always@(posedge CLK) begin
        if(RESET)
            DownCounter <= 0;
        else begin
            if(DownCounter == 32'd99999)
                DownCounter <= 0;
            else
                DownCounter <= DownCounter + 1'b1;
        end
    end

    // Timer counter
    reg [31:0] Timer;
    always@(posedge CLK) begin
        // Change: Separated the timer reset from the main RESET condition.
        // Previously, (BUS_ADDR == TimerBaseAddr + 8'h02) was OR'd directly
        // into the reset condition, meaning a read OR write to BaseAddr+2
        // would reset the timer. Now it correctly only resets on an explicit
        // write (BUS_WE high) to BaseAddr+2, matching the register map spec.
        if(RESET)
            Timer <= 0;
        else if(BUS_WE && (BUS_ADDR == TimerBaseAddr + 8'h02))
            // BaseAddr + 2 -> Resets the timer, restart counting from zero
            Timer <= 0;
        else if(DownCounter == 0)
            Timer <= Timer + 1'b1;
    end

    // Interrupt generation
    reg TargetReached;
    reg [31:0] LastTime;

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

    // Broadcast the Interrupt
    reg Interrupt;

    always@(posedge CLK) begin
        if(RESET)
            Interrupt <= 1'b0;
        else if(TargetReached)
            Interrupt <= 1'b1;
        else if(BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
    end
    assign BUS_INTERRUPT_RAISE = Interrupt;

    // Tristate output for interrupt timer output value.
    reg TransmitTimerValue;

    always@(posedge CLK) begin
        if(RESET)
            TransmitTimerValue <= 1'b0;
        else
            TransmitTimerValue <= (BUS_ADDR == TimerBaseAddr) && !BUS_WE;
    end

    // Handle tristate bus
    assign BUS_DATA = (TransmitTimerValue) ? Timer[7:0] : 8'hZZ;

endmodule
