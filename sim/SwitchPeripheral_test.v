`timescale 1ns / 1ps

module SwitchPeripheral_TB;

    // DUT inputs
    reg        CLK;
    reg        RESET;
    reg [15:0] SWITCH;
    reg        BUS_WE;
    reg [7:0]  BUS_ADDR;
    reg [7:0]  BUS_DATA_DRIVE; // driven by TB when writing
    reg        BUS_DRIVE;       // 1 = TB drives BUS_DATA (write), 0 = Z (read)

    // Tristate bus
    wire [7:0] BUS_DATA;
    assign BUS_DATA = BUS_DRIVE ? BUS_DATA_DRIVE : 8'hZZ;

    // DUT instantiation
    SwitchPeripheral dut (
        .CLK      (CLK),
        .RESET    (RESET),
        .SWITCH   (SWITCH),
        .BUS_WE   (BUS_WE),
        .BUS_DATA (BUS_DATA),
        .BUS_ADDR (BUS_ADDR)
    );

    // Clock: 100 MHz -> 10 ns period
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // Task: perform a bus read and check result
    task bus_read;
        input [7:0]  addr;
        input [7:0]  expected;
        input [63:0] test_name; // 8-char label packed
        begin
            BUS_WE    = 0;
            BUS_ADDR  = addr;
            BUS_DRIVE = 0; // release bus so DUT can drive
            @(posedge CLK); // address presented; DUT latches on this edge
            @(posedge CLK); // wait one more cycle for output to appear
            #1;             // small delta after clock edge
            if (BUS_DATA === expected)
                $display("PASS | addr=0x%02h  expected=0x%02h  got=0x%02h  SWITCH=%b",
                         addr, expected, BUS_DATA, SWITCH);
            else
                $display("FAIL | addr=0x%02h  expected=0x%02h  got=0x%02h  SWITCH=%b",
                         addr, expected, BUS_DATA, SWITCH);
        end
    endtask

    // Task: verify BUS_DATA is high-Z (peripheral not driving)
    task bus_check_z;
        input [7:0] addr;
        begin
            BUS_WE    = 0;
            BUS_ADDR  = addr;
            BUS_DRIVE = 0;
            @(posedge CLK);
            @(posedge CLK);
            #1;
            if (BUS_DATA === 8'hZZ)
                $display("PASS | addr=0x%02h  bus correctly high-Z", addr);
            else
                $display("FAIL | addr=0x%02h  expected Z  got=0x%02h", addr, BUS_DATA);
        end
    endtask

    integer i;

    initial begin
        // -- Initialise -------------------------------------------------------
        RESET        = 1;
        SWITCH       = 16'h0000;
        BUS_WE       = 0;
        BUS_ADDR     = 8'h00;
        BUS_DRIVE    = 0;
        BUS_DATA_DRIVE = 8'h00;

        repeat(4) @(posedge CLK);
        RESET = 0;
        @(posedge CLK);

        // ====================================================================
        $display("\n=== TEST 1: All switches OFF ===");
        SWITCH = 16'h0000;
        bus_read(8'h80, 8'h00, "CAR_EN  "); // SWITCH[0]   = 0
        bus_read(8'h81, 8'h00, "SENS    "); // SWITCH[2:1] = 0
        bus_read(8'h82, 8'h00, "FG      "); // SWITCH[6:3] = 0
        bus_read(8'h83, 8'h00, "BG      "); // SWITCH[10:7]= 0
        bus_read(8'h84, 8'h00, "CAR_SEL "); // SWITCH[12:11]=0
        bus_read(8'h85, 8'h00, "CURS_SEL"); // SWITCH[14:13]=0

        // ====================================================================
        $display("\n=== TEST 2: All switches ON ===");
        SWITCH = 16'hFFFF;
        bus_read(8'h80, 8'h01, "CAR_EN  "); // SWITCH[0]    = 1
        bus_read(8'h81, 8'h03, "SENS    "); // SWITCH[2:1]  = 2'b11
        bus_read(8'h82, 8'h0F, "FG      "); // SWITCH[6:3]  = 4'b1111 -> 8'h0F (zero-extended to low nibble)
        bus_read(8'h83, 8'h0F, "BG      "); // SWITCH[10:7] = 4'b1111 -> 8'h0F (zero-extended to low nibble)
        bus_read(8'h84, 8'h03, "CAR_SEL "); // SWITCH[12:11]= 2'b11
        bus_read(8'h85, 8'h03, "CURS_SEL"); // SWITCH[14:13]= 2'b11

        // ====================================================================
        $display("\n=== TEST 3: Specific switch patterns ===");

        // Only car enable on
        SWITCH = 16'h0001;
        bus_read(8'h80, 8'h01, "CAR_EN  ");
        bus_read(8'h81, 8'h00, "SENS    ");

        // Sensitivity = 2'b10
        SWITCH = 16'b0000_0000_0000_0100; // SWITCH[2]=1, SWITCH[1]=0
        bus_read(8'h81, 8'h02, "SENS=10 ");

        // FG colour = 4'b1010
        SWITCH = 16'b0000_0000_0101_0000; // SWITCH[6:3] = 4'b1010
        bus_read(8'h82, 8'h0A, "FG=1010 ");

        // BG colour = 4'b0101
        SWITCH = 16'b0000_0010_1000_0000; // SWITCH[10:7] = 4'b0101
        bus_read(8'h83, 8'h05, "BG=0101 ");

        // Car select = 2'b10
        SWITCH = 16'b0001_0000_0000_0000; // SWITCH[12:11] = 2'b10 -> bit12=1,bit11=0
        bus_read(8'h84, 8'h02, "CARSEL10");

        // Cursor colour = 2'b01
        SWITCH = 16'b0010_0000_0000_0000; // SWITCH[14:13] = 2'b01 -> bit13=1,bit14=0
        bus_read(8'h85, 8'h01, "CURS=01 ");

        // ====================================================================
        $display("\n=== TEST 4: Write attempt (peripheral is read-only, bus_re must clear) ===");
        SWITCH = 16'hFFFF;
        BUS_WE    = 1;   // write enable set
        BUS_ADDR  = 8'h80;
        BUS_DRIVE = 1;
        BUS_DATA_DRIVE = 8'hAB;
        @(posedge CLK);
        @(posedge CLK);
        #1;
        // After a write cycle the peripheral should NOT be driving the bus
        if (BUS_DATA === 8'hAB) // TB is driving, so TB value should be seen
            $display("PASS | Write cycle: bus driven by TB as expected (0xAB)");
        else
            $display("FAIL | Write cycle: unexpected bus value 0x%02h", BUS_DATA);
        // Release bus and check peripheral doesn't latch anything unexpected
        BUS_WE    = 0;
        BUS_DRIVE = 0;

        // ====================================================================
        $display("\n=== TEST 5: Address outside 0x8x range -> bus must be Z ===");
        SWITCH = 16'hFFFF;
        bus_check_z(8'h70); // addr[7:4] = 7 -> not 8
        bus_check_z(8'h90); // addr[7:4] = 9 -> not 8
        bus_check_z(8'hFF);
        bus_check_z(8'h00);

        // ====================================================================
        $display("\n=== TEST 6: RESET clears output ===");
        SWITCH   = 16'hFFFF;
        BUS_WE   = 0;
        BUS_ADDR = 8'h80;
        BUS_DRIVE = 0;
        @(posedge CLK);  // latch the read
        RESET = 1;
        @(posedge CLK);
        #1;
        if (BUS_DATA === 8'hZZ)
            $display("PASS | RESET: bus is Z (bus_re cleared)");
        else
            $display("FAIL | RESET: expected Z  got=0x%02h", BUS_DATA);
        RESET = 0;

        // ====================================================================
        $display("\n=== TEST 7: Dynamic switch change ===");
        SWITCH   = 16'h0000;
        BUS_ADDR = 8'h80;
        BUS_WE   = 0;
        BUS_DRIVE = 0;
        @(posedge CLK);
        @(posedge CLK);
        #1;
        $display("SWITCH=0000: addr=0x80 BUS_DATA=0x%02h (expect 0x00)", BUS_DATA);
        SWITCH = 16'hFFFF;
        @(posedge CLK);
        @(posedge CLK);
        #1;
        $display("SWITCH=FFFF: addr=0x80 BUS_DATA=0x%02h (expect 0x01)", BUS_DATA);

        // ====================================================================
        $display("\n=== All tests done ===");
        $finish;
    end

endmodule
