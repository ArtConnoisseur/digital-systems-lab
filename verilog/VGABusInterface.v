`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.03.2026 23:03:43
// Design Name:
// Module Name: VGABusInterface
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
This module implements the bus interface for the VGA subsystem.
 
BUS Address Map:
    - 0xB0 : X address      (R/W) - 8-bit horizontal coordinate
    - 0xB1 : Y address      (R/W) - 7-bit vertical coordinate (bits [6:0])
    - 0xB2 : Pixel data     (R/W) - write triggers frame buffer write at (X,Y);
                                    read returns current pixel value at (X,Y)
    - 0xB3 : Foreground     (R/W) - 8-bit foreground colour
    - 0xB4 : Background     (R/W) - 8-bit background colour
*/

module VGABusInterface(
    // Essential ports
    input           CLK,        // 100 MHz clock
    input           RESET,      // Reset signal
    // Bus signals
    input  [7:0]    BUS_ADDR,   // Bus Address Line
    inout  [7:0]    BUS_DATA,   // Data on the actual bus
                                // this is a inout port which
                                // means that it is a tristate
                                // element
    input           BUS_WE,     // When the bus wishes to
                                // write to peripheral memory
    // VGA Signals
    output [11:0]   COLOUR_OUT, // Output colour from the VGA
                                // Port
    output          HS,         // Horizontal Sync signal
    output          VS          // Vertical Sync Signal
);
 
    // Frame buffer control
    reg [7:0] X_ADDR;
    reg [6:0] Y_ADDR;
    reg       A_DATA_IN;
    reg       A_WE;
    wire      A_DATA_OUT;
 
    // Colour
    reg [7:0] FG;
    reg [7:0] BG;
 
    // VGA wires
    wire        CLK25;
    wire        VGA_DATA;
    wire [7:0]  X_OUT;
    wire [6:0]  Y_OUT;
    wire [7:0]  COLOUR_OUT_8;
    reg  [7:0]  CURSOR_X;
    reg  [6:0]  CURSOR_Y;

    // In the sequential bus decode always block, add:
    

    // Pass to VGASignalOut as new ports
    .CURSOR_X(CURSOR_X),
    .CURSOR_Y(CURSOR_Y),
 

    // All registers are clocked to avoid combinatorial latch inference.
    // A_WE is pulsed for exactly one cycle when a pixel write is requested.
    always @(posedge CLK) begin
        if (RESET) begin
            X_ADDR    <= 8'h00;
            Y_ADDR    <= 7'h00;
            A_DATA_IN <= 1'b0;
            A_WE      <= 1'b0;
            FG        <= 8'hFF;
            BG        <= 8'h00;
        end else begin
            // Default: deassert write enable each cycle
            A_WE <= 1'b0;
 
            if (BUS_WE) begin
                case (BUS_ADDR)
                    8'hB0: X_ADDR    <= BUS_DATA;
                    8'hB1: Y_ADDR    <= BUS_DATA[6:0];
                    8'hB2: begin
                        A_DATA_IN <= BUS_DATA[0];
                        A_WE      <= 1'b1;
                    end
                    8'hB3: FG <= BUS_DATA;
                    8'hB4: BG <= BUS_DATA;
                    8'hB5: CURSOR_X <= BUS_DATA;
                    8'hB6: CURSOR_Y <= BUS_DATA[6:0];
                    default: ;
                endcase
            end
        end
    end
 
    // Now this uses the clock generated using the MMCM which is much safer
    // and can be passed directly into the clock ports of the VGA and adjacent
    // submodules that need it.
    VGA_CLK_GENERATOR_WIZ vga_clk_gen_inst (
        .CLK_IN(CLK),
        .CLK25(CLK25),
        .reset(RESET),
        .locked()
    );
 
    // This is the frame buffer instance that takes in X and Y values and the
    // input data at port A, writes it to the frame memory and then send it to the VGA
    // from port B maintaining sync between both clocks.
    FrameBuffer fram_buf_inst (
        .RESET(RESET),
        .A_CLK(CLK),
        .A_WE(A_WE),
        .AX(X_ADDR),
        .AY(Y_ADDR),
        .A_DATA_IN(A_DATA_IN),
        .A_DATA_OUT(A_DATA_OUT),
        .B_CLK(CLK25),
        .B_DATA(VGA_DATA),
        .BX(X_OUT),
        .BY(Y_OUT)
    );
 
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
    // needed for the VGA and the 8 bit colour representation specified for
    // the design of this project.
    ColourLogic colour_logic_inst (
        .COLOUR_IN_8(COLOUR_OUT_8),
        .COLOUR_OUT_12(COLOUR_OUT)
    );

    // Each readable register is gated on !BUS_WE and the relevant address.
    // Only one branch will be active at a time; all others drive 8'hZZ.
    assign BUS_DATA = (!BUS_WE && BUS_ADDR == 8'hB0) ? X_ADDR                 :
                      (!BUS_WE && BUS_ADDR == 8'hB1) ? {1'b0, Y_ADDR}         :
                      (!BUS_WE && BUS_ADDR == 8'hB2) ? {7'b0, A_DATA_OUT}     :
                      (!BUS_WE && BUS_ADDR == 8'hB3) ? FG                     :
                      (!BUS_WE && BUS_ADDR == 8'hB4) ? BG                     :
                      8'hZZ;
 
endmodule
