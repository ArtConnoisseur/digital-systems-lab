`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 29.01.2026 10:25:22
// Design Name:
// Module Name: MouseMasterSM
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

/* MouseMasterSM
High-level control state machine for PS/2 mouse protocol.

Startup sequence:
   1) Send RESET (0xFF)
   2) Wait for ACK (0xFA)
   3) Wait for self-test pass (0xAA)
   4) Wait for mouse ID
   5) Send ENABLE REPORTING (0xF4)
   6) Receive 3-byte movement packets continuously

Outputs decoded mouse data and interrupt pulse per packet.
*/

module MouseMasterSM(
    input CLK,                  // System clock (100 MHz)
    input RESET,                // Reset Botton

    // Transmitter
    output SEND_BYTE,           // Request a transmission
    output [7:0] BYTE_TO_SEND,  // Holds the command byte
    input BYTE_SENT,            // Asserted by the transmitter when done

    // Receiver
    output READ_ENABLE,         // Allows the receiver to sample incoming data
    input [7:0] BYTE_READ,      // Bytes read
    input [1:0] BYTE_ERROR_CODE,// Error code
    input BYTE_READY,           // Pulses when a full byte has been received

    // Mouse data
    output [7:0] MOUSE_DX,      // Changes of X
    output [7:0] MOUSE_DY,      // Changes of Y
    output [7:0] MOUSE_STATUS,  // States
    output SEND_INTERRUPT,

    output [3:0] CURR_STATE
);

    // State and internal registers
    reg [3:0] Curr_State, Next_State;
    reg [23:0] Curr_Counter, Next_Counter;

    reg Curr_SendByte, Next_SendByte;
    reg [7:0] Curr_ByteToSend, Next_ByteToSend;
    reg Curr_ReadEnable, Next_ReadEnable;

    reg [7:0] Curr_Status, Next_Status;
    reg [7:0] Curr_Dx, Next_Dx;
    reg [7:0] Curr_Dy, Next_Dy;
    reg Curr_SendInterrupt, Next_SendInterrupt;

    // Sequential
    always @(posedge CLK) begin
        if (RESET) begin
            Curr_State <= 4'h0;
            Curr_Counter <= 0;
            Curr_SendByte <= 0;
            Curr_ByteToSend <= 8'h00;
            Curr_ReadEnable <= 0;
            Curr_Status <= 0;
            Curr_Dx <= 0;
            Curr_Dy <= 0;
            Curr_SendInterrupt <= 0;
        end else begin
            Curr_State <= Next_State;
            Curr_Counter <= Next_Counter;
            Curr_SendByte <= Next_SendByte;
            Curr_ByteToSend <= Next_ByteToSend;
            Curr_ReadEnable <= Next_ReadEnable;
            Curr_Status <= Next_Status;
            Curr_Dx <= Next_Dx;
            Curr_Dy <= Next_Dy;
            Curr_SendInterrupt <= Next_SendInterrupt;
        end
    end
    
    // Combinational FSM

    // FSM States:
    // 0 : Power-up delay
    // 1 : Send RESET (0xFF)
    // 2 : Wait for BYTE_SENT
    // 3 : Wait for ACK of RESET (0xFA)
    // 4 : Wait for self-test pass (0xAA)
    // 5 : Wait for mouse ID
    // 6 : Send ENABLE REPORTING (0xF4)
    // 7 : Wait for BYTE_SENT
    // 8 : Wait for ACK of F4 (FA or F4 on Basys3)
    // 9 : Read status byte
    // A : Read DX byte
    // B : Read DY byte
    // C : Generate interrupt and loop back

    always @* begin
        Next_State = Curr_State;
        Next_Counter = Curr_Counter;
        Next_SendByte = 0;
        Next_ByteToSend = Curr_ByteToSend;
        Next_ReadEnable = 0;
        Next_Status = Curr_Status;
        Next_Dx = Curr_Dx;
        Next_Dy = Curr_Dy;
        Next_SendInterrupt = 0;

        case (Curr_State)  
        
            // Power-up delay to allow mouse to initialise
            4'h0: begin
                if (Curr_Counter == 1_000_000) begin
                    Next_State = 4'h1;
                    Next_Counter = 0;
                end else
                    Next_Counter = Curr_Counter + 1;
            end
            
            // Send RESET command (0xFF)
            4'h1: begin
                Next_SendByte = 1;
                Next_ByteToSend = 8'hFF;
                Next_State = 4'h2;
            end
            
            // Wait for transmitter to finish
            4'h2: if (BYTE_SENT) Next_State = 4'h3;

            // Wait for ACK (0xFA) from mouse
            4'h3: begin
                Next_ReadEnable = 1;
                if (BYTE_READY)
                    Next_State = (BYTE_READ == 8'hFA) ? 4'h4 : 4'h0;
            end

            // Wait for self-test pass (0xAA)
            4'h4: begin
                Next_ReadEnable = 1;
                if (BYTE_READY)
                    Next_State = (BYTE_READ == 8'hAA) ? 4'h5 : 4'h0;
            end

            // Wait for mouse ID byte (usually 0x00)
            4'h5: begin
                Next_ReadEnable = 1;
                if (BYTE_READY)
                    Next_State = (BYTE_READ == 8'h00) ? 4'h6 : 4'h0;
            end

            // Send ENABLE REPORTING command (0xF4)
            4'h6: begin
                Next_SendByte = 1;
                Next_ByteToSend = 8'hF4;
                Next_State = 4'h7;
            end

            // Wait for transmitter to finish
            4'h7: if (BYTE_SENT) Next_State = 4'h8;

            // Wait for ACK of F4
            // NOTE:
            // On a standard PS/2 interface, the mouse replies
            // with 0xFA. On the Basys 3 board, due to the
            // USB-to-PS/2 conversion, the reply may be 0xF4
            // and the parity check may fail.
            4'h8: begin
                Next_ReadEnable = 1;
                if (BYTE_READY) begin
                    // Basys3 USB-to-PS/2 converter may return F4 instead of FA
                    // Parity error is ignored in this state
                    if (BYTE_READ == 8'hFA || BYTE_READ == 8'hF4)
                        Next_State = 4'h9;
                    else
                        Next_State = 4'h0;
                end
            end
            
            // Read Status byte
            4'h9: begin
                Next_ReadEnable = 1;
                if (BYTE_READY) begin
                    Next_Status = BYTE_READ;
                    Next_State = 4'hA;
                end
            end

            // Read X movement byte
            4'hA: begin
                Next_ReadEnable = 1;
                if (BYTE_READY) begin
                    Next_Dx = BYTE_READ;
                    Next_State = 4'hB;
                end
            end

            // Read Y movement byte
            4'hB: begin
                Next_ReadEnable = 1;
                if (BYTE_READY) begin
                    Next_Dy = BYTE_READ;
                    Next_State = 4'hC;
                end
            end

            // Packet complete: raise interrupt and loop
            4'hC: begin
                Next_SendInterrupt = 1;
                Next_State = 4'h9;
            end
        endcase
    end

    // Output assignments
    assign SEND_BYTE = Curr_SendByte;
    assign BYTE_TO_SEND = Curr_ByteToSend;
    assign READ_ENABLE = Curr_ReadEnable;
    assign MOUSE_STATUS = Curr_Status;
    assign MOUSE_DX = Curr_Dx;
    assign MOUSE_DY = Curr_Dy;
    assign SEND_INTERRUPT = Curr_SendInterrupt;
    assign CURR_STATE = Curr_State;

endmodule
