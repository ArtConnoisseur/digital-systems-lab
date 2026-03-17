`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.01.2026 10:13:19
// Design Name:
// Module Name: VGAInterface - TOP WRAPPER
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
This is the top level module for the VGA Interface part of the project in
the Digital Systems Laboratory Lab.

This takes colour in from the 16 switches on the basys 3 board for the
colour config, instantiates all the modules for the project and provides
the interface to the HS, VS and colour out signals for the VGA.

Modules used:

According to the given specification:

- FrameBuffer
- VGASignalOut

Additional instantiated modules:

- VGA_CLK_GENERATOR_WIZ
- VGADisplayController
- ColourLogic
- PatternStateMachine

Additional modules instantiated elsewhere:

- GenericCounter

Deprecated Modules:

- ClockDivider

Detailed module descriptions are in comments and further information
is included in their respective files.
*/

module VGAInterface(
        // Universal input ports
        input CLK,                  // 100MHz clock
        input RESET,                // Reset Signal
        input [15:0] COLOUR_CONFIG, // Input colour - coming from the 16 switches
                                    // LSBs - Background colour
                                    // MSBs - Foreground colour
        input [3:0] PUSH_BTTN,      // Push button input - used to toggle the state
                                    // of the Pattern State Machine module

        // Universal output ports
        output [11:0] COLOUR_OUT,   // Colour output to the VGA
                                    // This is 12 bit, expanded to by the Colour Logic
                                    // module. The actual designs comply with the
                                    // recommended 8-bit specification
        output HS,                  // Horizontal sync signal for the VGA from the VGA
                                    // Signal generator module
        output VS                   // Horizontal sync signal for the VGA from the VGA
                                    // Signal generator module
    );

    // Wires needed to connect the modules in the top wrapper

    // Wires for the X and Y axis
    // Input here refers to the pixel numbers generated via counter
    // by the VGA controller module.
    // Output is the actual pixel value from the VGA Signal Generator
    // synced with the 25MHz clock.
    wire [7:0] X_IN, X_OUT;
    wire [6:0] Y_IN, Y_OUT;

    // Colour wires
    wire [7:0] FG;  // Foreground colour
    wire [7:0] BG;  // Background colour


    // Wire to connect VGA data between the modules
    wire VGA_DATA;  // Gets the data from port B of the frame buffer
    wire DATA_OUT;  // Output of the frame buffer port A. This would interface
                    // with the MPU in the next iteration of this lab project.
    wire A_DATA_IN; // Input to the frame buffer port A. Essentially what is used to
                    // write to the screen

    wire CLK25;     // Connects 25MHz clock wherever needed (related to VGA Systems)

    // Top Wraper Logic

    // Note that that the 25MHz clock was first created using digital logic
    // in the ClockDivider module. This has since been replaced with the module
    // created using the Vivado clock wizard and Mixed Mode Clock Manager to
    // more realiably/professionally generate the 25MHz clock. That is what the
    // beneath code block is referring to.

   // ClockDivider clock_div_inst (
   //     .CLK_IN(CLK),
   //     .CLK_OUT(CLK25)
   // );


   // Now this uses the clock generated using the MMCM which is much safer
   // and can be passed directly into the clock ports of the VGA and adjacent
   // submodules that need it.
    VGA_CLK_GENERATOR_WIZ vga_clk_gen_inst (
        .CLK_IN(CLK),
        .CLK25(CLK25), // Output 25MHz clock
        .reset(RESET),
        .locked()
    );

    // This module is what drives this display for the week 5 submission.
    // Generates the (x, y) inputs for the frame buffer and complements the
    // colour to change it every one second.
    VGADisplayController vga_controller_inst (
        .CLK(CLK),
        .RESET(RESET),
        .FG_IN(COLOUR_CONFIG[15:8]),
        .BG_IN(COLOUR_CONFIG[7:0]),
        .FG_OUT(FG),
        .BG_OUT(BG),
        .X(X_IN),
        .Y(Y_IN)
    );

    // Connection to the 8 bit colour output from the VGA Signal Generator
    // to the Colour Logic that converts it to the full 12 bit representation
    // for the actual VGA input. This has been explained in the module itself
    // please refer that for more information.
    wire [7:0] COLOUR_OUT_8;

    // This is the main VGA signal generator module. It has the parameters for
    // generating the correct HS and VS signals and sending the correct colour
    // (FG or BG) based on the input data at that point from the frame buffer
    VGASignalOut vga_inst (
        .RESET(RESET),
        .CLK(CLK25),
        .FG(FG),
        .BG(BG),
        .X(X_OUT),
        .Y(Y_OUT),
        .VGA_DATA(VGA_DATA),
        .HS(HS),
        .VS(VS),
        .COLOUR_OUT(COLOUR_OUT_8)
    );

    // This module is the bridge between the 12 bit colour representation
    // nneded for the VGA and the 8 bit colour representation specified for
    // the design of this project.
    ColourLogic colour_logic_inst (
        .COLOUR_IN_8(COLOUR_OUT_8),
        .COLOUR_OUT_12(COLOUR_OUT)
    );

    // This module implements 4 patterns. These patterns are implemented
    // prgrammatically via a state machine. The state and the logic for the
    // pattern implementation is abstracted in this module.
    PatternStateMachine pattern_state_machine_inst (
        .CLK(CLK),
        .RESET(RESET),
        .STATE_CONTROL(PUSH_BTTN[3:0]),
        .X_IN(X_IN),
        .Y_IN(Y_IN),
        .DATA_OUT(A_DATA_IN)
    );

    // This is the frame buffer instance that takes in X and Y values and the
    // input data at port A, writes it to the frame memory and then send it to the VGA
    // from port B maintaining sync between both clocks.
    FrameBuffer fram_buf_inst (
        .RESET(RESET),
        .A_CLK(CLK),
        .A_WE(1),
        .AX(X_IN),
        .AY(Y_IN),
        .A_DATA_IN(A_DATA_IN),
        .A_DATA_OUT(DATA_OUT),
        .B_CLK(CLK25),
        .B_DATA(VGA_DATA),
        .BX(X_OUT),
        .BY(Y_OUT)
    );

endmodule
