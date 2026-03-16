`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: SystemTop
//
// Description:
//   Top-level module of the Mouse Processor system. This module acts as a
//   structural wrapper that instantiates and interconnects all subsystems
//   to form a complete microprocessor-based SoC on an FPGA (Basys3 board).
//
//   For the Week 8 assessment, this system re-implements the Week 5 mouse
//   demo, but now under full processor control rather than using dedicated
//   hardware. The demonstration behaviour is:
//
//     - 7-Segment Display (4 digits, right to left):
//         Digits 0-1 (rightmost two): Absolute Y coordinate in hex
//           (VGA range 0-119, displayed as 00-77)
//         Digits 2-3 (leftmost two):  Absolute X coordinate in hex
//           (VGA range 0-159, displayed as 00-9F)
//
//     - LEDs (8 LEDs):
//         Display the mouse status byte (PS/2 status byte bit mapping):
//           LED[7] = Y overflow
//           LED[6] = X overflow
//           LED[5] = Y sign bit  (1 = negative movement)
//           LED[4] = X sign bit  (1 = negative movement)
//           LED[3] = Always 1    
//           LED[2] = Always 0  
//           LED[1] = Right button   (1 = pressed)
//           LED[0] = Left button    (1 = pressed)
//
// Architecture:
//   Shared 8-bit tri-state data bus (BUS_DATA / BUS_ADDR / BUS_WE).
//   Processor is bus master; peripherals are slaves (drive 8'hZZ when inactive).
//   ROM has a dedicated bus to the processor for independent instruction fetch.
//
// Memory Map:
//   0x00-0x7F  RAM (R/W)        0xA0-0xA4  Mouse (R)
//   0xC0       LEDs (W)         0xD0-0xD1  7-Seg (W)
//   0xF0-0xF3  Timer (R/W)      0xFE-0xFF  ROM interrupt vectors
//
// Interrupts:
//   IRQ[0] Mouse (highest) triggered on movement
//   IRQ[1] Timer (lower) triggered every InterruptRate ms
//
//////////////////////////////////////////////////////////////////////////////////

module SystemTop(
    input CLK,                      // System clock (100 MHz on Basys3)
    input RESET,                    // Reset botton

    // PS/2 mouse interface
    // Open-collector bidirectional lines with external pull-up resistors.
    inout CLK_MOUSE,                // PS/2 clock line (bidirectional)
    inout DATA_MOUSE,               // PS/2 data line (bidirectional)

    // 7-segment display output
    output [7:0] HEX_OUT,           // 
    output [3:0] SEG_SELECT_OUT,    // 

    // LED output
    output [7:0] LED                // 8-bit LED
);

// System Bus
// Shared tri-state bus connecting processor to all
// peripherals. Only one device may drive BUS_DATA at
// a time; all others must output high-impedance (8'hZZ).
wire [7:0] BUS_DATA;       // 8-bit tri-state data bus
wire [7:0] BUS_ADDR;       // 8-bit address bus (driven by processor)
wire BUS_WE;               // Bus write enable (1 = write, 0 = read)

// Interrupt Lines
// Two interrupt channels: one for mouse, one for timer.
wire [1:0] BUS_INTERRUPTS_RAISE;   // Interrupt request from peripherals
wire [1:0] BUS_INTERRUPTS_ACK;     // Interrupt acknowledge from processor

// ROM Interface
// Dedicated point-to-point connection between processor
// and ROM (not on the shared bus).
wire [7:0] ROM_ADDRESS;    // Program counter address to ROM
wire [7:0] ROM_DATA;       // Instruction data from ROM

// LED Peripheral (Address: 0xC0, write-only)
// Directly drives the 8 onboard LEDs.
LED_Peripheral led(
    .CLK(CLK),
    .RESET(RESET),

    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),

    .LED(LED)
);

// 7-Segment Display Peripheral (Address: 0xD0-0xD1, write-only)
// Drives a 4-digit multiplexed 7-segment display.
SevenSeg_Peripheral sevenseg(
    .CLK(CLK),
    .RESET(RESET),

    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),

    .HEX_OUT(HEX_OUT),
    .SEG_SELECT_OUT(SEG_SELECT_OUT)
);

// Instantiate Processor
Processor cpu(
    .CLK(CLK),
    .RESET(RESET),

    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),

    .ROM_ADDRESS(ROM_ADDRESS),
    .ROM_DATA(ROM_DATA),

    .BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
    .BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
);

// ROM (Program Memory)
ROM rom(
    .CLK(CLK),
    .ADDR(ROM_ADDRESS),
    .DATA(ROM_DATA)
);

// RAM (Data Memory)
RAM ram(
    .CLK(CLK),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE)
);

// Mouse Peripheral
Mouse_Peripheral mouse(
    .RESET(RESET),
    .CLK(CLK),

    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),

    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[0]),
    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[0]),

    .CLK_MOUSE(CLK_MOUSE),
    .DATA_MOUSE(DATA_MOUSE)
);

// Timer Peripheral
Timer timer(
    .CLK(CLK),
    .RESET(RESET),

    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),

    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[1]),
    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[1])
);

endmodule