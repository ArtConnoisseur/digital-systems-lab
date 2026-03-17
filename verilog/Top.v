`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04.03.2026 14:43:09
// Design Name:
// Module Name: Top
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
This file contains the TopLevel module, which connects all subsystems
of the processor design onto a shared 8-bit bus. It instantiates and
wires together the following modules:

- Processor:      Central state machine, fetches and executes instructions
                  from ROM and communicates with peripherals via the bus
- ROM:            Read-only instruction memory, addressed directly by the
                  processor via dedicated lines outside the main bus
- RAM:            Read/write data memory, mapped to the lower half of the
                  address space (BUS_ADDR[7] = 0)
- Timer:          Configurable ms-resolution timer, mapped to 0xF0-0xF3,
                  raises interrupt line 1 at a configurable interval
- VGABusInterface: Drives the VGA display, mapped to 0xB0-0xB3, accepts
                  pixel writes and colour configuration from the processor

All peripherals share BusData, BusAddr, and BusWE. Tri-state logic within
each peripheral ensures only the addressed module drives the data bus at
any given time. Two interrupt lines are routed between the Timer and the
Processor for interrupt-driven operation.
*/

module TopLevel(
        // Essential Ports
        input           CLK,
        input           RESET,

        //  Switches (used later)
        input   [15:0]  SWITCH,

        // VGA Ports
        output          HS,
        output          VS,
        output  [11:0]  COLOUR_OUT
    );

    // Wires and registers to connect various parts of the project
    wire    [7:0]   BusData;
    wire    [7:0]   BusAddr;
    wire            BusWE;
    wire    [7:0]   RomAddress;
    wire    [7:0]   RomData;
    wire    [1:0]   BusInterruptsRaise;
    wire    [1:0]   BusInterruptsAck;

    // Processor developed individually as a part of Week 8 submission
    Processor CPU (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .ROM_ADDRESS(RomAddress),
        .ROM_DATA(RomData),
        .BUS_INTERRUPTS_RAISE(BusInterruptsRaise),
        .BUS_INTERRUPTS_ACK(BusInterruptsAck)
    );

    // Main memory
    ROM rom_inst (
        .CLK(CLK),
        .ADDR(RomAddress),
        .DATA(RomData)
    );

    // Data Memory
    RAM ram_inst (
        .CLK(CLK),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE)
    );

    // Timer module - this has been changed from the recommended file
    // implementation - see /design/week8/README.pdf for more deatils.
    Timer timer_inst (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .BUS_INTERRUPT_RAISE(BusInterruptsRaise[1]),
        .BUS_INTERRUPT_ACK(BusInterruptsAck[1])
    );

    // This is the interface between the Processor BUS and the
    // VGA peripheral
    VGABusInterface vga_inst (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .COLOUR_OUT(COLOUR_OUT),
        .HS(HS),
        .VS(VS)
    );

    // Mouse Peripheral
    Mouse_Peripheral(
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .BUS_INTERRUPT_RAISE(BusInterruptsRaise),
        .BUS_INTERRUPT_ACK(BusInterruptsAck),
        .CLK_MOUSE(CLK_MOUSE),
        .DATA_MOUSE(DATA_MOUSE)
    )

endmodule
