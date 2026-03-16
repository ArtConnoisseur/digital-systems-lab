`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Processor
//
// Description:
//   An 8-bit microprocessor implemented as a finite state machine (FSM).
//   The processor fetches instructions from ROM, decodes them, and executes
//   multi-cycle operations through a sequential pipeline of states.
//
// Instruction Format:
//   Each instruction is 1 or 2 bytes in ROM:
//     Byte 0: [7:4] = ALU opcode / sub-type,  [3:0] = instruction opcode
//     Byte 1: operand (memory address or jump target), if required
//
// Instruction Set (opcode = lower nibble [3:0]):
//   0x0 : Load memory -> Reg A          (2 bytes: opcode + address)
//   0x1 : Load memory -> Reg B          (2 bytes: opcode + address)
//   0x2 : Store Reg A -> memory         (2 bytes: opcode + address)
//   0x3 : Store Reg B -> memory         (2 bytes: opcode + address)
//   0x4 : ALU operation, result -> A    (1 byte, ALU op in upper nibble)
//   0x5 : ALU operation, result -> B    (1 byte, ALU op in upper nibble)
//   0x6 : Conditional branch (if ALU)   (2 bytes: opcode + target address)
//   0x7 : Unconditional jump            (2 bytes: opcode + target address)
//   0x8 : Go to IDLE (wait for IRQ)     (1 byte)
//   0x9 : Function call                 (2 bytes: opcode + function address)
//   0xA : Return from function          (1 byte)
//   0xB : Dereference Reg A (A = Mem[A]) (1 byte)
//   0xC : Dereference Reg B (B = Mem[B]) (1 byte)
//
// Interrupt Handling:
//   When idle, the processor polls interrupt lines. On interrupt:
//     - IRQ[0] (mouse): reads thread start address from ROM[0xFF]
//     - IRQ[1] (timer): reads thread start address from ROM[0xFE]
//   The processor then jumps to the corresponding interrupt handler.
//////////////////////////////////////////////////////////////////////////////////

module Processor(
    // Standard Signals
    input           CLK,                    // System clock
    input           RESET,                  // Synchronous reset
    // BUS Signals
    inout   [7:0]   BUS_DATA,              // Tri-state data bus
    output  [7:0]   BUS_ADDR,             // Address bus output
    output          BUS_WE,                // Write enable 
    // ROM signals
    output  [7:0]   ROM_ADDRESS,           // Address sent to program ROM
    input   [7:0]   ROM_DATA,             // Instruction data returned from ROM
    // INTERRUPT signals
    input   [1:0]   BUS_INTERRUPTS_RAISE,  // Interrupt requests from peripherals
    output  [1:0]   BUS_INTERRUPTS_ACK     // Interrupt acknowledge to peripherals
);

    //The main data bus is treated as tristate, so we need a mechanism to handle this.
    wire [7:0] BusDataIn;
    reg [7:0] CurrBusDataOut, NextBusDataOut;
    reg CurrBusDataOutWE, NextBusDataOutWE;

    //Tristate Mechanism
    assign BusDataIn = BUS_DATA;
    assign BUS_DATA = CurrBusDataOutWE ? CurrBusDataOut : 8'hZZ;
    assign BUS_WE = CurrBusDataOutWE;
    
    //Address of the bus
    reg [7:0] CurrBusAddr, NextBusAddr;
    assign BUS_ADDR = CurrBusAddr;
    
    //The processor has two internal registers to hold data between operations, and a third to hold
    //the current program context when using function calls.
    reg [7:0] CurrRegA, NextRegA;
    reg [7:0] CurrRegB, NextRegB;
    reg CurrRegSelect, NextRegSelect;
    reg [7:0] CurrProgContext, NextProgContext;
    
    //Dedicated Interrupt output lines - one for each interrupt line
    reg [1:0] CurrInterruptAck, NextInterruptAck;
    assign BUS_INTERRUPTS_ACK = CurrInterruptAck;
    
    //Instantiate program memory here
    //There is a program counter which points to the current operation. The program counter
    //has an offset that is used to reference information that is part of the current operation
    reg [7:0] CurrProgCounter, NextProgCounter;
    reg [1:0] CurrProgCounterOffset, NextProgCounterOffset;
    wire [7:0] ProgMemoryOut;
    wire [7:0] ActualAddress;
    assign ActualAddress = CurrProgCounter + CurrProgCounterOffset;
    
    // ROM signals
    assign ROM_ADDRESS = ActualAddress;
    assign ProgMemoryOut = ROM_DATA;

    //Instantiate the ALU
    wire [7:0] AluOut;
    ALU ALU0(
        //standard signals
        .CLK(CLK),
        .RESET(RESET),
        //I/O
        .IN_A(CurrRegA),
        .IN_B(CurrRegB),
        .ALU_Op_Code(ProgMemoryOut[7:4]),
        .OUT_RESULT(AluOut)
    );

    //The microprocessor is essentially a state machine, with one sequential pipeline
    //of states for each operation.
    //The current list of operations is:
    // 0: Read from memory to A
    // 1: Read from memory to B
    // 2: Write to memory from A
    // 3: Write to memory from B
    // 4: Do maths with the ALU, and save result in reg A
    // 5: Do maths with the ALU, and save result in reg B
    // 6: if A (== or < or > B) GoTo ADDR
    // 7: Goto ADDR
    // 8: Go to IDLE
    // 9: End thread, goto idle state and wait for interrupt.
    // 10: Function call
    // 11: Return from function call
    // 12: Dereference A
    // 13: Dereference B

    //Program thread selection
    //Waits here until an interrupt wakes up the processor.
    parameter [7:0] IDLE = 8'hF0; 
    parameter GET_THREAD_START_ADDR_0 = 8'hF1; //Wait.
    parameter GET_THREAD_START_ADDR_1 = 8'hF2; //Apply the new address to the program counter.
    parameter GET_THREAD_START_ADDR_2 = 8'hF3; //Wait. Goto ChooseOp.
    
    //Operation selection
    //Depending on the value of ProgMemOut, goto one of the instruction start states.
    parameter CHOOSE_OPP = 8'h00;
    
    //Data Flow
    parameter READ_FROM_MEM_TO_A = 8'h10; //Wait to find what address to read, save reg select.
    parameter READ_FROM_MEM_TO_B = 8'h11; //Wait to find what address to read, save reg select.
    parameter READ_FROM_MEM_0 = 8'h12; //Set BUS_ADDR to designated address.
    parameter READ_FROM_MEM_1 = 8'h13; //wait - Increments program counter by 2. Reset offset.
    parameter READ_FROM_MEM_2 = 8'h14; //Writes memory output to chosen register, end op.
    parameter WRITE_TO_MEM_FROM_A = 8'h20; //Reads Op+1 to find what address to Write to.
    parameter WRITE_TO_MEM_FROM_B = 8'h21; //Reads Op+1 to find what address to Write to.
    parameter WRITE_TO_MEM_0 = 8'h22; //wait - Increments program counter by 2. Reset offset.
    
    //Data Manipulation
    parameter DO_MATHS_OPP_SAVE_IN_A = 8'h30; //The result of maths op. is available, save it to Reg A.
    parameter DO_MATHS_OPP_SAVE_IN_B = 8'h31; //The result of maths op. is available, save it to Reg B.
    parameter DO_MATHS_OPP_0 = 8'h32; //wait for new op address to settle. end op.
    
    // Control Flow Instructions
    // Conditional branch: if ALU result is non-zero, jump to target address
    parameter IF_A_EQUALITY_B_GOTO = 8'h40; // Evaluate condition via ALU output
    parameter IF_0 = 8'h45;                 // Condition true: read jump target from ROM
    parameter IF_1 = 8'h46;                 // Wait state, then proceed to CHOOSE_OPP

    // Unconditional jump: always jump to the target address in ROM
    parameter GOTO                 = 8'h41; // Start unconditional jump sequence
    parameter GOTO_IDLE            = 8'h42; // Jump to IDLE state (wait for next interrupt)
    parameter GOTO_0 			   = 8'h43; // Read jump target from ROM
    parameter GOTO_1 			   = 8'h44; // Wait state, then proceed to CHOOSE_OPP

    // Function call and return (single-level call stack via ProgContext register)
    parameter FUNCTION_START       = 8'h50; // Save return address (PC+2) into ProgContext
    parameter RETURN               = 8'h51; // Restore PC from ProgContext
    parameter FUNCTION_0 = 8'h52;           // Read function entry address from ROM
    parameter FUNCTION_1 = 8'h53;           // Wait state, then proceed to CHOOSE_OPP

    // Dereference: use register value as a memory address, read memory into that register
    // Effectively performs: RegA = Mem[RegA]  or  RegB = Mem[RegB]
    parameter DE_REFERENCE_A       = 8'h60; // Set BUS_ADDR = RegA, read result into RegA
    parameter DE_REFERENCE_B       = 8'h61; // Set BUS_ADDR = RegB, read result into RegB



    //Sequential part of the State Machine.
    reg [7:0] CurrState, NextState;
    always@(posedge CLK) begin
        if(RESET) begin
            CurrState = 8'h00;
            CurrProgCounter = 8'h00;
            CurrProgCounterOffset = 2'h0;
            CurrBusAddr = 8'hFF; //Initial instruction after reset.
            CurrBusDataOut = 8'h00;
            CurrBusDataOutWE = 1'b0;
            CurrRegA = 8'h00;
            CurrRegB = 8'h00;
            CurrRegSelect = 1'b0;
            CurrProgContext = 8'h00;
            CurrInterruptAck = 2'b00;
        end else begin
            CurrState = NextState;
            CurrProgCounter = NextProgCounter;
            CurrProgCounterOffset = NextProgCounterOffset;
            CurrBusAddr = NextBusAddr;
            CurrBusDataOut = NextBusDataOut;
            CurrBusDataOutWE = NextBusDataOutWE;
            CurrRegA = NextRegA;
            CurrRegB = NextRegB;
            CurrRegSelect = NextRegSelect;
            CurrProgContext = NextProgContext;
            CurrInterruptAck = NextInterruptAck;
        end
    end


    // Combinational next-state logic
    // Default assignments below hold current values unless explicitly
    // overridden in a specific state, preventing unintended latches.
    always@* begin
        NextState = CurrState;
        NextProgCounter = CurrProgCounter;
        NextProgCounterOffset = 2'h0;       // Default: no offset (points to opcode byte)
        NextBusAddr = 8'hFF;                // Default: address 0xFF (no peripheral selected)
        NextBusDataOut = CurrBusDataOut;
        NextBusDataOutWE = 1'b0;            // Default: not writing to bus
        NextRegA = CurrRegA;
        NextRegB = CurrRegB;
        NextRegSelect = CurrRegSelect;
        NextProgContext = CurrProgContext;
        NextInterruptAck = 2'b00;           // Default: no interrupt acknowledged
        //Case statement to describe each state
        case (CurrState)
            // IDLE state: processor waits here for an interrupt.
            // IRQ[0] has higher priority than IRQ[1].
            // On interrupt, PC is set to the corresponding vector address in ROM
            // (0xFF for IRQ[0], 0xFE for IRQ[1]), and the content at that ROM
            // location holds the actual thread start address.
            IDLE: begin
                if(BUS_INTERRUPTS_RAISE[0]) begin
                    NextState = GET_THREAD_START_ADDR_0;
                    NextProgCounter = 8'hFF;    // IRQ[0] vector at ROM[0xFF]
                    NextInterruptAck = 2'b01;   // Acknowledge IRQ[0]
                end else if(BUS_INTERRUPTS_RAISE[1]) begin
                    NextState = GET_THREAD_START_ADDR_0;
                    NextProgCounter = 8'hFE;    // IRQ[1] vector at ROM[0xFE]
                    NextInterruptAck = 2'b10;   // Acknowledge IRQ[1]
                end else begin
                    NextState = IDLE;
                    NextProgCounter = 8'hFF;    // Stay idle, no interrupt pending
                    NextInterruptAck = 2'b00;
                end
            end
            
            //Wait state 
            GET_THREAD_START_ADDR_0: begin
                NextState = GET_THREAD_START_ADDR_1;
            end
            
            //Assign the new program counter value
            GET_THREAD_START_ADDR_1: begin
                NextState = GET_THREAD_START_ADDR_2;
                NextProgCounter = ProgMemoryOut;
            end

            //Wait for the new program counter value to settle
            GET_THREAD_START_ADDR_2:
                NextState = CHOOSE_OPP;
            
            // CHOOSE_OPP: Instruction decode stage.
            // The lower nibble [3:0] of the current ROM byte selects the operation.
            // ProgCounterOffset is set to 1 so that the next ROM read will fetch
            // the operand byte (if the instruction uses one).
            CHOOSE_OPP: begin
                case (ProgMemoryOut[3:0])
                    4'h0:       NextState = READ_FROM_MEM_TO_A;     // Load Mem -> A
                    4'h1:       NextState = READ_FROM_MEM_TO_B;     // Load Mem -> B
                    4'h2:       NextState = WRITE_TO_MEM_FROM_A;    // Store A -> Mem
                    4'h3:       NextState = WRITE_TO_MEM_FROM_B;    // Store B -> Mem
                    4'h4:       NextState = DO_MATHS_OPP_SAVE_IN_A; // ALU result -> A
                    4'h5:       NextState = DO_MATHS_OPP_SAVE_IN_B; // ALU result -> B
                    4'h6:       NextState = IF_A_EQUALITY_B_GOTO;   // Conditional branch
                    4'h7:       NextState = GOTO;                   // Unconditional jump
                    4'h8:       NextState = IDLE;                   // Halt (wait for IRQ)
                    4'h9:       NextState = FUNCTION_START;         // Function call
                    4'hA:       NextState = RETURN;                 // Return from function
                    4'hB:       NextState = DE_REFERENCE_A;         // A = Mem[A]
                    4'hC:       NextState = DE_REFERENCE_B;         // B = Mem[B]
                    default:    NextState = CurrState;              // Invalid opcode: stall
                endcase
                NextProgCounterOffset = 2'h1;   // Advance to operand byte for next read
            end

            //READ_FROM_MEM_TO_A : here starts the memory read operational pipeline.
            //Wait state. Reg select is set to 0
            READ_FROM_MEM_TO_A:begin
                NextState = READ_FROM_MEM_0;
                NextRegSelect = 1'b0;
            end

            //READ_FROM_MEM_TO_B : here starts the memory read operational pipeline.
            //Wait state. Reg select is set to 1
            READ_FROM_MEM_TO_B:begin
                NextState = READ_FROM_MEM_0;
                NextRegSelect = 1'b1;
            end

            //The address will be valid during this state, so set the BUS_ADDR to this value.
            READ_FROM_MEM_0: begin
                NextState = READ_FROM_MEM_1;
                NextBusAddr = ProgMemoryOut;
            end

            //Wait state
            //Increment the program counter here. This must be done 2 clock cycles ahead
            READ_FROM_MEM_1: begin
                NextState = READ_FROM_MEM_2;
                NextProgCounter = CurrProgCounter + 2;
            end

            //The data will now have arrived from memory. Write it to the proper register.
            READ_FROM_MEM_2: begin
                NextState = CHOOSE_OPP;
                if(!CurrRegSelect)
                    NextRegA = BusDataIn;
                else
                    NextRegB = BusDataIn;
            end

            //WRITE_TO_MEM_FROM_A : here starts the memory write operational pipeline.
            //Wait state - to find the address of where we are writing
            //Increment the program counter here. This must be done 2 clock cycles ahead
            //so that it presents the right data when required.
            WRITE_TO_MEM_FROM_A:begin
                NextState = WRITE_TO_MEM_0;
                NextRegSelect = 1'b0;
                NextProgCounter = CurrProgCounter + 2;
            end
            
            //WRITE_TO_MEM_FROM_B : here starts the memory write operational pipeline.
            //Wait state - to find the address of where we are writing
            //Increment the program counter here. This must be done 2 clock cycles ahead
            // so that it presents the right data when required.
            WRITE_TO_MEM_FROM_B:begin
                NextState = WRITE_TO_MEM_0;
                NextRegSelect = 1'b1;
                NextProgCounter = CurrProgCounter + 2;
            end

            //The address will be valid during this state, so set the BUS_ADDR to this value,
            //and write the value to the memory location.
            WRITE_TO_MEM_0: begin
                NextState = CHOOSE_OPP;
                NextBusAddr = ProgMemoryOut;
                if(!NextRegSelect)
                    NextBusDataOut = CurrRegA;
                else
                    NextBusDataOut = CurrRegB;
                NextBusDataOutWE = 1'b1;
            end

            //DO_MATHS_OPP_SAVE_IN_A : here starts the DoMaths operational pipeline.
            //Reg A and Reg B must already be set to the desired values. The MSBs of the
            // Operation type determines the maths operation type. At this stage the result is
            // ready to be collected from the ALU.
            DO_MATHS_OPP_SAVE_IN_A: begin
                NextState = DO_MATHS_OPP_0;
                NextRegA = AluOut;
                NextProgCounter = CurrProgCounter + 1;
            end

            //DO_MATHS_OPP_SAVE_IN_B : here starts the DoMaths operational pipeline
            //when the result will go into reg B.
            DO_MATHS_OPP_SAVE_IN_B: begin
                NextState = DO_MATHS_OPP_0;
                NextRegB = AluOut;
                NextProgCounter = CurrProgCounter + 1;
            end

            //Wait state for new prog address to settle.
            DO_MATHS_OPP_0:
                NextState = CHOOSE_OPP;
            
            // Conditional Branch (opcode 0x6):
            // Uses ALU output to decide whether to branch.
            // The upper nibble [7:4] of the instruction byte specifies the ALU
            // comparison operation (e.g. 0x9 = A==B, 0xA = A>B, 0xB = A<B).
            // If AluOut is non-zero (condition TRUE), jump to address in next ROM byte.
            // If AluOut is zero (condition FALSE), skip operand and continue sequentially.
            ///////////////////////////////////////////////////////////////////////////////////////
            IF_A_EQUALITY_B_GOTO: begin
                if (AluOut)
                    NextState = IF_0;           // Condition met: proceed to read jump target
                else begin
                    NextProgCounter = CurrProgCounter + 2;  // Condition not met: skip operand byte
                    NextState = IF_1;
                end
            end
            
            // Read the branch target address from ROM operand byte
            IF_0: begin
                NextState = IF_1;
                NextProgCounter = ProgMemoryOut;    // Set PC to jump target
            end

            // Wait state for new PC to settle, then decode next instruction
            IF_1:
                NextState = CHOOSE_OPP;

            // Unconditional Jump (opcode 0x7):
            // Always jumps to the address specified in the operand byte.
            // Pipeline: GOTO -> GOTO_0 (read target) -> GOTO_1 (settle) -> CHOOSE_OPP
            GOTO:
                NextState = GOTO_0;

            GOTO_0: begin
                NextState = GOTO_1;
                NextProgCounter = ProgMemoryOut;    // Set PC to jump target from ROM
            end

            // Wait state for new PC to settle
            GOTO_1:
                NextState = CHOOSE_OPP;

            // Go to Idle (opcode 0x8):
            // Halts execution and returns to IDLE state, waiting for the next interrupt.
            // PC is incremented so that if the same thread is re-entered, it
            // continues from the instruction after GOTO_IDLE.

            GOTO_IDLE: begin
                NextProgCounter = CurrProgCounter + 1;
                NextState = IDLE;
            end

            // Function Call (opcode 0x9):
            // Saves the return address (PC+2, i.e. instruction after the operand byte)
            // into ProgContext, then jumps to the function entry address from operand.
            // Note: Only supports single-level calls (no nested function support).
            FUNCTION_START: begin
                NextState = FUNCTION_0;
                NextProgContext = CurrProgCounter + 2;  // Save return address
            end

            // Read function entry address from ROM operand byte
            FUNCTION_0: begin
                NextState = FUNCTION_1;
                NextProgCounter = ProgMemoryOut;        // Jump to function entry
            end

            // Wait state for new PC to settle
            FUNCTION_1:
                NextState = CHOOSE_OPP;

            // Return from Function (opcode 0xA):
            // Restores PC from ProgContext (the saved return address).
            // Execution resumes at the instruction following the original function call.
            RETURN: begin
                NextProgCounter = CurrProgContext;      // Restore return address
                NextState = CHOOSE_OPP;
            end

            // Dereference A (opcode 0xB):
            // Uses the current value of RegA as a memory address, reads the data at
            // that address, and stores the result back into RegA.
            // Effectively: RegA = Memory[RegA]
            // Reuses the READ_FROM_MEM pipeline (states 1 and 2) to complete the read.
            DE_REFERENCE_A: begin
                NextBusAddr = CurrRegA;             // Address the memory at RegA's value
                NextState = READ_FROM_MEM_1;        // Reuse read pipeline
                NextRegSelect = 1'b0;               // Target register = A
                NextProgCounter = CurrProgCounter + 1;  // Single-byte instruction
            end

            // Dereference B (opcode 0xC):
            // Same as Dereference A but for RegB.
            // Effectively: RegB = Memory[RegB]
            DE_REFERENCE_B: begin
                NextBusAddr = CurrRegB;             // Address the memory at RegB's value
                NextState = READ_FROM_MEM_1;        // Reuse read pipeline
                NextRegSelect = 1'b1;               // Target register = B
                NextProgCounter = CurrProgCounter + 1;  // Single-byte instruction
            end
        endcase
    end

endmodule
