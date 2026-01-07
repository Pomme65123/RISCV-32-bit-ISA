`timescale 1ns/1ps

module imm_gen_tb;

    logic [31:0] instr;
    logic [31:0] imm;
    
    imm_gen dut (
        .instr(instr),
        .imm(imm)
    );
    
    int test_count = 0;
    int pass_count = 0;
    logic [31:0] expected_imm;
    
    parameter CLK_PERIOD = 10;

    task check_result(input string test_name, input logic [31:0] expected);
        test_count++;
        if (imm === expected) begin
            $display("PASS: %s - Expected: 0x%08h, Got: 0x%08h", test_name, expected, imm);
            pass_count++;
        end else begin
            $display("FAIL: %s - Expected: 0x%08h, Got: 0x%08h", test_name, expected, imm);
        end
    endtask
    
    initial begin
        $display("=== Immediate Generator Test Bench ===");
        $display("Testing all instruction types and immediate extraction patterns");
        $display();
        
        // Test U-type instructions (LUI, AUIPC)
        $display("--- Testing U-type Instructions ---");
        
        // LUI with positive immediate
        instr = 32'h12345037; // LUI x0, 0x12345
        #CLK_PERIOD;
        expected_imm = 32'h12345000;
        check_result("LUI positive immediate", expected_imm);
        
        // LUI with negative immediate (MSB = 1)
        instr = 32'hFEDCB037; // LUI x0, 0xFEDCB
        #CLK_PERIOD;
        expected_imm = 32'hFEDCB000;
        check_result("LUI negative immediate", expected_imm);
        
        // AUIPC with positive immediate
        instr = 32'h00001017; // AUIPC x0, 0x00001
        #CLK_PERIOD;
        expected_imm = 32'h00001000;
        check_result("AUIPC positive immediate", expected_imm);
        
        // Test I-type instructions (JALR, LOAD, IMM)
        $display("\n--- Testing I-type Instructions ---");
        
        // ADDI with positive immediate
        instr = 32'h00C00093; // ADDI x1, x0, 12
        #CLK_PERIOD;
        expected_imm = 32'h0000000C;
        check_result("ADDI positive immediate", expected_imm);
        
        // ADDI with negative immediate
        instr = 32'hFF400093; // ADDI x1, x0, -12
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFF4;
        check_result("ADDI negative immediate", expected_imm);
        
        // JALR with positive immediate
        instr = 32'h008000E7; // JALR x1, 8(x0)
        #CLK_PERIOD;
        expected_imm = 32'h00000008;
        check_result("JALR positive immediate", expected_imm);
        
        // JALR with negative immediate
        instr = 32'hFF8000E7; // JALR x1, -8(x0)
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFF8;
        check_result("JALR negative immediate", expected_imm);
        
        // Load with positive immediate
        instr = 32'h00402083; // LW x1, 4(x0)
        #CLK_PERIOD;
        expected_imm = 32'h00000004;
        check_result("LW positive immediate", expected_imm);
        
        // Load with negative immediate
        instr = 32'hFFC02083; // LW x1, -4(x0)
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFFC;
        check_result("LW negative immediate", expected_imm);
        
        // Test S-type instructions (STORE)
        $display("\n--- Testing S-type Instructions ---");
        
        // SW with positive immediate
        instr = 32'h00102223; // SW x1, 4(x0)
        #CLK_PERIOD;
        expected_imm = 32'h00000004;
        check_result("SW positive immediate", expected_imm);
        
        // SW with negative immediate
        instr = 32'hFE102E23; // SW x1, -4(x0)
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFFC;
        check_result("SW negative immediate", expected_imm);
        
        // Test B-type instructions (BRANCH)
        $display("\n--- Testing B-type Instructions ---");
        
        // BEQ with positive immediate
        instr = 32'h00100463; // BEQ x0, x1, 8
        #CLK_PERIOD;
        expected_imm = 32'h00000008;
        check_result("BEQ positive immediate", expected_imm);
        
        // BEQ with negative immediate
        instr = 32'hFE100EE3; // BEQ x0, x1, -4
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFFC;
        check_result("BEQ negative immediate", expected_imm);
        
        // BNE with larger positive immediate
        instr = 32'h02101463; // BNE x0, x1, 40
        #CLK_PERIOD;
        expected_imm = 32'h00000028;
        check_result("BNE larger positive immediate", expected_imm);
        
        // Test J-type instructions (JAL)
        $display("\n--- Testing J-type Instructions ---");
        
        // JAL with positive immediate
        instr = 32'h008000EF; // JAL x1, 8
        #CLK_PERIOD;
        expected_imm = 32'h00000008;
        check_result("JAL positive immediate", expected_imm);
        
        // JAL with negative immediate
        instr = 32'hFF9FF0EF; // JAL x1, -8
        #CLK_PERIOD;
        expected_imm = 32'hFFFFFFF8;
        check_result("JAL negative immediate", expected_imm);
        
        // JAL with larger positive immediate
        instr = 32'h100000EF; // JAL x1, 256
        #CLK_PERIOD;
        expected_imm = 32'h00000100;
        check_result("JAL larger positive immediate", expected_imm);
        
        // Test edge cases
        $display("\n--- Testing Edge Cases ---");
        
        // Maximum positive immediate for I-type
        instr = 32'h7FF00093; // ADDI x1, x0, 2047
        #CLK_PERIOD;
        expected_imm = 32'h000007FF;
        check_result("I-type maximum positive immediate", expected_imm);
        
        // Maximum negative immediate for I-type
        instr = 32'h80000093; // ADDI x1, x0, -2048
        #CLK_PERIOD;
        expected_imm = 32'hFFFFF800;
        check_result("I-type maximum negative immediate", expected_imm);
        
        // Maximum positive U-type immediate
        instr = 32'h7FFFF037; // LUI x0, 0x7FFFF
        #CLK_PERIOD;
        expected_imm = 32'h7FFFF000;
        check_result("U-type maximum positive immediate", expected_imm);
        
        // Test default case (invalid opcode)
        $display("\n--- Testing Default Case ---");
        instr = 32'h12345678; // Invalid opcode
        #CLK_PERIOD;
        expected_imm = 32'h00000000;
        check_result("Invalid opcode (default case)", expected_imm);
        
        // Test with all zeros
        instr = 32'h00000000; // NOP-like instruction
        #CLK_PERIOD;
        expected_imm = 32'h00000000;
        check_result("All zeros instruction", expected_imm);
        
        $display("\n=== Test Results Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", test_count - pass_count);
        
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("Some tests failed. Review the output above.");
        end
        
        $display("\n=== Test Bench Complete ===");
        $finish;
    end
    
    initial begin
        $monitor("Time: %0t | Instruction: 0x%08h | Immediate: 0x%08h", 
                 $time, instr, imm);
    end

endmodule