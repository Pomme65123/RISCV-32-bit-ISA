`timescale 1ns/1ps

module data_memory_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter MEM_SIZE   = 1024;
    parameter CLK_PERIOD = 10;

    logic                    clk;
    logic                    rst_n;
    logic [ADDR_WIDTH-1:0]   addr;
    logic [DATA_WIDTH-1:0]   wdata;
    logic                    we;
    logic [3:0]              be;
    logic [DATA_WIDTH-1:0]   rdata;
    
    int test_count = 0;
    int pass_count = 0;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    data_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .be(be),
        .rdata(rdata)
    );

    // Test task for write operations
    task write_memory(
        input [31:0] test_addr,
        input [31:0] test_data,
        input [3:0]  test_be,
        input string description
    );
        addr = test_addr;
        wdata = test_data;
        we = 1'b1;
        be = test_be;

        @(posedge clk);
        we = 1'b0;
        $display("WRITE %s: addr=0x%08h, data=0x%08h, be=%b", description, test_addr, test_data, test_be);
    endtask

    // Test task for read operations
    task read_memory(
        input [31:0] test_addr,
        input [31:0] expected_data,
        input string description
    );
        addr = test_addr;
        we = 1'b0;
        repeat(2) @(posedge clk);
        
        test_count++;
        if (rdata === expected_data) begin
            $display("PASS READ %s: addr=0x%08h -> data=0x%08h", description, test_addr, rdata);
            pass_count++;
        end else begin
            $display("FAIL READ %s: addr=0x%08h -> data=0x%08h (expected 0x%08h)", 
                     description, test_addr, rdata, expected_data);
        end
    endtask

    // Test task for write-then-read operations
    task test_write_read(
        input [31:0] test_addr,
        input [31:0] test_data,
        input [3:0]  test_be,
        input [31:0] expected_read,
        input string description
    );
        write_memory(test_addr, test_data, test_be, description);   // Write
        read_memory(test_addr, expected_read, description);         // Read back
        $display("");
    endtask

    // Main test
    initial begin
        $display("=== Data Memory Testbench Started ===");
        
        // Initialize signals
        addr = 32'h00000000;
        wdata = 32'h00000000;
        we = 1'b0;
        be = 4'b0000;
        rst_n = 1'b0;  // Assert reset (active-low)
        
        // Reset sequence
        repeat(3) @(posedge clk);
        rst_n = 1'b1;  // Deassert reset (release active-low)
        repeat(2) @(posedge clk);  // Wait for memory initialization
        
        $display("Reset sequence completed, memory initialized");
        
        $display("\n--- Testing Word (32-bit) Operations ---");
        
        // Test word write/read
        test_write_read(32'h00000000, 32'h12345678, 4'b1111, 32'h12345678, "Word write/read at 0x00000000");
        test_write_read(32'h00000004, 32'hDEADBEEF, 4'b1111, 32'hDEADBEEF, "Word write/read at 0x00000004");
        test_write_read(32'h00000010, 32'hCAFEBABE, 4'b1111, 32'hCAFEBABE, "Word write/read at 0x00000010");
        
        $display("--- Testing Halfword (16-bit) Operations ---");
        
        // Test halfword writes (lower 16 bits)
        test_write_read(32'h00000020, 32'h0000ABCD, 4'b0011, 32'h0000ABCD, "Halfword write/read (lower) at 0x00000020");
        
        // Test halfword writes (upper 16 bits)
        test_write_read(32'h00000024, 32'h1234ABCD, 4'b1100, 32'h12340000, "Halfword write/read (upper) at 0x00000024");
        
        // Test overlapping halfword writes
        write_memory(32'h00000030, 32'h5555AAAA, 4'b0011, "Halfword write (lower)");
        write_memory(32'h00000030, 32'hBBBB7777, 4'b1100, "Halfword write (upper)");
        read_memory(32'h00000030, 32'hBBBBAAAA, "Combined halfword result");
        $display("");
        
        $display("--- Testing Byte (8-bit) Operations ---");
        
        // Test individual byte writes
        test_write_read(32'h00000040, 32'h000000AA, 4'b0001, 32'h000000AA, "Byte 0 write/read");
        test_write_read(32'h00000044, 32'h0000BB00, 4'b0010, 32'h0000BB00, "Byte 1 write/read");
        test_write_read(32'h00000048, 32'h00CC0000, 4'b0100, 32'h00CC0000, "Byte 2 write/read");
        test_write_read(32'h0000004C, 32'hDD000000, 4'b1000, 32'hDD000000, "Byte 3 write/read");
        
        // Test building word byte by byte
        write_memory(32'h00000050, 32'h000000EE, 4'b0001, "Build word - byte 0");
        write_memory(32'h00000050, 32'h0000FF00, 4'b0010, "Build word - byte 1");
        write_memory(32'h00000050, 32'h00AA0000, 4'b0100, "Build word - byte 2");
        write_memory(32'h00000050, 32'hBB000000, 4'b1000, "Build word - byte 3");
        read_memory(32'h00000050, 32'hBBAAFFEE, "Complete word from bytes");
        $display("");
        
        $display("--- Testing Little-Endian Byte Ordering ---");
        
        // Write word and verify byte order
        write_memory(32'h00000060, 32'h12345678, 4'b1111, "Word for endian test");
        
        // Read individual bytes to verify ordering
        write_memory(32'h00000064, 32'h00000078, 4'b0001, "Expected byte 0 (0x78)");
        write_memory(32'h00000068, 32'h00005600, 4'b0010, "Expected byte 1 (0x56)");
        write_memory(32'h0000006C, 32'h00340000, 4'b0100, "Expected byte 2 (0x34)");
        write_memory(32'h00000070, 32'h12000000, 4'b1000, "Expected byte 3 (0x12)");
        
        read_memory(32'h00000060, 32'h12345678, "Verify little-endian word");
        $display("");
        
        $display("--- Testing Address Boundary Conditions ---");
        
        // Test first valid address
        test_write_read(32'h00000000, 32'hFFFFFFFF, 4'b1111, 32'hFFFFFFFF, "First address");
        
        // Test last valid word address
        test_write_read((MEM_SIZE*4-4), 32'h87654321, 4'b1111, 32'h87654321, "Last valid word address");
        
        // Test out-of-bounds read (should return 0)
        read_memory(MEM_SIZE*4, 32'h00000000, "Out-of-bounds read");
        
        // Test out-of-bounds write (should be ignored)
        write_memory(MEM_SIZE*4, 32'hBAD00000, 4'b1111, "Out-of-bounds write (should be ignored)");
        read_memory(MEM_SIZE*4, 32'h00000000, "Verify out-of-bounds write ignored");
        $display("");
        
        $display("--- Testing Write Enable Control ---");
        
        // Test write disabled
        addr = 32'h00000080;
        wdata = 32'hDEADBEEF;
        we = 1'b0;
        be = 4'b1111;
        @(posedge clk);
        
        read_memory(32'h00000080, 32'h00000000, "Write disabled test");
        
        // Now enable write
        test_write_read(32'h00000080, 32'hABCDEF01, 4'b1111, 32'hABCDEF01, "Write enabled test");
        $display("");
        
        $display("--- Testing Mixed Access Patterns ---");
        
        // Write word, read parts
        write_memory(32'h00000090, 32'hAABBCCDD, 4'b1111, "Write full word");
        
        // Overwrite specific bytes
        write_memory(32'h00000090, 32'h000000EE, 4'b0001, "Overwrite byte 0");
        write_memory(32'h00000090, 32'h0000FF00, 4'b0010, "Overwrite byte 1");
        
        read_memory(32'h00000090, 32'hAABBFFEE, "Final mixed result");
        $display("");
        
        $display("--- Testing Alignment and Unaligned Access ---");
        
        // Test unaligned halfword access
        test_write_read(32'h00000101, 32'h0000ABCD, 4'b0011, 32'h0000ABCD, "Unaligned halfword at 0x101");
        test_write_read(32'h00000102, 32'h0000EF12, 4'b0011, 32'h0000EF12, "Unaligned halfword at 0x102");
        test_write_read(32'h00000103, 32'h00001234, 4'b0011, 32'h00001234, "Unaligned halfword at 0x103");
        
        $display("--- Testing Sequential Access Pattern ---");
        
        // Write sequential pattern
        for (int i = 0; i < 8; i++) begin
            write_memory(i*4, 32'h10000000 + i, 4'b1111, $sformatf("Sequential write %0d", i));
        end
        
        // Read back sequential pattern
        for (int i = 0; i < 8; i++) begin
            read_memory(i*4, 32'h10000000 + i, $sformatf("Sequential read %0d", i));
        end
        
        $display("--- Testing Clock Synchronization ---");
        
        // Test that reads require clock edge
        addr = 32'h00000000;
        we = 1'b0;
        $display("Before clock edge: rdata = 0x%08h", rdata);
        
        repeat(2) @(posedge clk);
        $display("After clock edges: rdata = 0x%08h", rdata);
        
        $display("\n=== Test Results Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", test_count - pass_count);
        
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("Some tests failed.");
        end
        
        $display("\n=== Data Memory Testbench Completed ===");
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time: %0t | CLK: %b | ADDR: 0x%08h | WDATA: 0x%08h | WE: %b | BE: %b | RDATA: 0x%08h",
                 $time, clk, addr, wdata, we, be, rdata);
    end

endmodule