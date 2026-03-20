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
This file contains the VGA interface to the processor's bus, decoding
data from the base adress of B0 to high of B3. It decodes bus data and
appropriately sends it to the right modules.

- BaseAddr + 0 (B0) -> Write Y address and pixel data bit to the frame buffer
- BaseAddr + 1 (B1) -> Write X address for the frame buffer
- BaseAddr + 2 (B2) -> Alternately set background and foreground colour (toggles each write)
- BaseAddr + 3 (B3) -> Read back pixel data from the frame buffer (tri-state)

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


Detailed module descriptions are in comments and further information
is included in their respective files.
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
    reg A_DATA_IN;
    reg A_WE;
    wire A_DATA_OUT;

    // Colour
    reg colour_toggle;
    reg [7:0] FG;
    reg [7:0] BG;

    // VGA wires
    wire CLK25;
    wire VGA_DATA;
    wire [7:0] X_OUT;
    wire [6:0] Y_OUT;
    wire [7:0] COLOUR_OUT_8;


    // Combinatorial bus decode for X and Y
    // values
    always @(posedge CLK) begin
        if (RESET) begin
            X_ADDR        <= 8'h00;
            Y_ADDR        <= 7'h00;
            A_WE          <= 1'b0;
            A_DATA_IN     <= 1'b0;
            BG            <= 8'h00;
            FG            <= 8'hFF;
            colour_toggle <= 0;
        end else begin
            A_WE <= 1'b0;  // deassert every cycle
            if (BUS_WE) begin
                case (BUS_ADDR)
                    8'hB0: begin
                        A_DATA_IN <= BUS_DATA[0];
                        A_WE      <= 1'b1;
                    end
                    8'hB1: X_ADDR <= BUS_DATA;
                    8'hB2: Y_ADDR <= BUS_DATA[6:0];
                    8'hB3: begin
                        if (colour_toggle == 0)
                            BG <= BUS_DATA;
                        else
                            FG <= BUS_DATA;
                        colour_toggle <= ~colour_toggle;
                    end
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
    // nneded for the VGA and the 8 bit colour representation specified for
    // the design of this project.
    ColourLogic colour_logic_inst (
        .COLOUR_IN_8(COLOUR_OUT_8),
        .COLOUR_OUT_12(COLOUR_OUT)
    );

    // Bus readback (tristate)
    reg vga_bus_re;
    reg [7:0] vga_bus_out;

    always @(posedge CLK) begin
        if (!BUS_WE && BUS_ADDR == 8'hB0) begin
            vga_bus_re  <= 1'b1;
            vga_bus_out <= {7'b0, A_DATA_OUT};
        end else
            vga_bus_re <= 1'b0;
    end

    assign BUS_DATA = vga_bus_re ? vga_bus_out : 8'hZZ;

endmodule
