`timescale 1ns/1ps

module reg_file_tb;

    logic        clk;
    logic        rst_n;
    logic        we;
    logic [4:0]  ra1;
    logic [4:0]  ra2;
    logic [4:0]  wa;
    logic [31:0] wd;
    logic [31:0] rd1;
    logic [31:0] rd2;
    
    int test_count = 0;
    int pass_count = 0;
    
    parameter CLK_PERIOD = 10;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    reg_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .ra1(ra1),
        .ra2(ra2),
        .wa(wa),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    task check_result(
        input string test_name,
        input [31:0] expected_rd1,
        input [31:0] expected_rd2
    );
        test_count++;
        if (rd1 === expected_rd1 && rd2 === expected_rd2) begin
            $display("PASS: %s - rd1: 0x%08h, rd2: 0x%08h", test_name, rd1, rd2);
            pass_count++;
        end else begin
            $display("FAIL: %s - rd1: 0x%08h (exp: 0x%08h), rd2: 0x%08h (exp: 0x%08h)", 
                     test_name, rd1, expected_rd1, rd2, expected_rd2);
        end
    endtask
    
    task write_register(
        input [4:0]  addr,
        input [31:0] data
    );
        wa = addr;
        wd = data;
        we = 1'b1;
        @(posedge clk);
        we = 1'b0;
        #1;
    endtask
    
    task read_registers(
        input [4:0] addr1,
        input [4:0] addr2
    );
        ra1 = addr1;
        ra2 = addr2;
        #1;
    endtask
    
    initial begin
        $display("=== Register File Test Bench ===");
        $display("Testing RISC-V register file with dual-port read and x0 constraints");
        $display();
        
        rst_n = 1'b0;
        we = 1'b0;
        ra1 = 5'b0;
        ra2 = 5'b0;
        wa = 5'b0;
        wd = 32'b0;
        
        // Test reset functionality
        $display("--- Testing Reset Functionality ---");
        
        // Apply reset
        rst_n = 1'b0;
        #(2*CLK_PERIOD);
        
        // Check that all readable registers are zero after reset
        read_registers(5'd1, 5'd31); // Read x1 and x31
        check_result("Reset test (x1, x31)", 32'h00000000, 32'h00000000);
        
        read_registers(5'd15, 5'd16); // Read x15 and x16
        check_result("Reset test (x15, x16)", 32'h00000000, 32'h00000000);
        
        // Release reset
        rst_n = 1'b1;
        #(CLK_PERIOD);
        
        $display("\n--- Testing x0 Register Constraint ---");
        
        // Test reading x0 (should always be zero)
        read_registers(5'd0, 5'd0);
        check_result("x0 read test", 32'h00000000, 32'h00000000);
        
        // Try to write to x0 (should be ignored)
        write_register(5'd0, 32'hDEADBEEF);
        read_registers(5'd0, 5'd1);
        check_result("x0 write ignored test", 32'h00000000, 32'h00000000);
        
        $display("\n--- Testing Basic Write/Read Operations ---");
        
        // Write to register x1
        write_register(5'd1, 32'h12345678);
        read_registers(5'd1, 5'd0);
        check_result("Write/Read x1", 32'h12345678, 32'h00000000);
        
        // Write to register x31
        write_register(5'd31, 32'hABCDEF00);
        read_registers(5'd31, 5'd1);
        check_result("Write/Read x31", 32'hABCDEF00, 32'h12345678);
        
        // Write to register x15
        write_register(5'd15, 32'h55AA55AA);
        read_registers(5'd15, 5'd31);
        check_result("Write/Read x15", 32'h55AA55AA, 32'hABCDEF00);
        
        $display("\n--- Testing Dual-Port Read Operations ---");
        
        // Write multiple registers
        write_register(5'd2, 32'h11111111);
        write_register(5'd3, 32'h22222222);
        write_register(5'd4, 32'h33333333);
        write_register(5'd5, 32'h44444444);
        
        // Test simultaneous reads of different register pairs
        read_registers(5'd2, 5'd3);
        check_result("Dual read (x2, x3)", 32'h11111111, 32'h22222222);
        
        read_registers(5'd4, 5'd5);
        check_result("Dual read (x4, x5)", 32'h33333333, 32'h44444444);
        
        read_registers(5'd1, 5'd15);
        check_result("Dual read (x1, x15)", 32'h12345678, 32'h55AA55AA);
        
        // Test reading same register from both ports
        read_registers(5'd2, 5'd2);
        check_result("Same register dual read", 32'h11111111, 32'h11111111);
        
        $display("\n--- Testing Write Enable Control ---");
        
        // Try writing with write enable disabled
        we = 1'b0;
        wa = 5'd10;
        wd = 32'hBADBAD00;
        @(posedge clk);
        #1;
        
        read_registers(5'd10, 5'd0);
        check_result("Write disabled test", 32'h00000000, 32'h00000000);
        
        // Now write with write enable
        write_register(5'd10, 32'hC00D0000);
        read_registers(5'd10, 5'd0);
        check_result("Write enabled test", 32'hC00D0000, 32'h00000000);
        
        $display("\n--- Testing Register Persistence ---");
        
        // Verify previously written data is still there
        read_registers(5'd1, 5'd2);
        check_result("Data persistence (x1, x2)", 32'h12345678, 32'h11111111);
        
        read_registers(5'd31, 5'd15);
        check_result("Data persistence (x31, x15)", 32'hABCDEF00, 32'h55AA55AA);
        
        $display("\n--- Testing All Registers ---");
        
        // Write unique values to several registers
        for (int i = 1; i <= 10; i++) begin
            write_register(i[4:0], 32'h10000000 + i);
        end
        
        // Read them back in pairs
        read_registers(5'd1, 5'd6);
        check_result("Sequential test (x1, x6)", 32'h10000001, 32'h10000006);
        
        read_registers(5'd3, 5'd8);
        check_result("Sequential test (x3, x8)", 32'h10000003, 32'h10000008);
        
        read_registers(5'd5, 5'd10);
        check_result("Sequential test (x5, x10)", 32'h10000005, 32'h1000000A);
        
        $display("\n--- Testing Edge Cases ---");
        
        // Test maximum values
        write_register(5'd20, 32'hFFFFFFFF);
        read_registers(5'd20, 5'd0);
        check_result("Maximum value test", 32'hFFFFFFFF, 32'h00000000);
        
        // Test minimum values
        write_register(5'd21, 32'h00000000);
        read_registers(5'd21, 5'd20);
        check_result("Zero value test", 32'h00000000, 32'hFFFFFFFF);
        
        // Test alternating bit patterns
        write_register(5'd22, 32'h55555555);
        write_register(5'd23, 32'hAAAAAAAA);
        read_registers(5'd22, 5'd23);
        check_result("Bit pattern test", 32'h55555555, 32'hAAAAAAAA);
        
        $display("\n--- Testing Reset During Operation ---");
        
        // Write some data
        write_register(5'd25, 32'h99999999);
        read_registers(5'd25, 5'd0);
        check_result("Pre-reset data", 32'h99999999, 32'h00000000);
        
        // Apply reset asynchronously
        rst_n = 1'b0;
        #1;
        read_registers(5'd25, 5'd1);
        check_result("After async reset", 32'h00000000, 32'h00000000);
        
        // Release reset and verify normal operation
        rst_n = 1'b1;
        @(posedge clk);
        write_register(5'd26, 32'h77777777);
        read_registers(5'd26, 5'd25);
        check_result("Post-reset operation", 32'h77777777, 32'h00000000);
        
        // Summary
        $display("\n=== Test Results Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", test_count - pass_count);
        
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("Some tests failed. Review the output above.");
        end
        
        $display("\n=== Register File Testbench Completed ===");
        $finish;
    end
    
    initial begin
        $monitor("Time: %0t | CLK: %b | RST_N: %b | WE: %b | WA: x%0d | WD: 0x%08h | RA1: x%0d | RA2: x%0d | RD1: 0x%08h | RD2: 0x%08h",
                 $time, clk, rst_n, we, wa, wd, ra1, ra2, rd1, rd2);
    end

endmodule