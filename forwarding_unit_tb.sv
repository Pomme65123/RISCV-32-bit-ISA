`timescale 1ns/1ps

module forwarding_unit_tb;

    logic [4:0] rs1_ex;
    logic [4:0] rs2_ex;
    logic [4:0] rd_mem;
    logic [4:0] rd_wb;
    logic       reg_write_mem;
    logic       reg_write_wb;
    logic [1:0] forward_a;
    logic [1:0] forward_b;
    
    int test_count = 0;
    int pass_count = 0;
    
    parameter CLK_PERIOD = 10;
    
    forwarding_unit dut (
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    task check_result(
        input string test_name,
        input [1:0] expected_forward_a,
        input [1:0] expected_forward_b
    );
        test_count++;
        #1;
        if (forward_a === expected_forward_a && forward_b === expected_forward_b) begin
            $display("PASS: %s - forward_a: %0d, forward_b: %0d", test_name, forward_a, forward_b);
            pass_count++;
        end else begin
            $display("FAIL: %s - forward_a: %0d (exp: %0d), forward_b: %0d (exp: %0d)", 
                     test_name, forward_a, expected_forward_a, forward_b, expected_forward_b);
        end
    endtask
    
    task set_inputs(
        input [4:0] rs1,
        input [4:0] rs2,
        input [4:0] rd_m,
        input [4:0] rd_w,
        input reg_wr_m,
        input reg_wr_w
    );
        rs1_ex = rs1;
        rs2_ex = rs2;
        rd_mem = rd_m;
        rd_wb = rd_w;
        reg_write_mem = reg_wr_m;
        reg_write_wb = reg_wr_w;
    endtask
    
    initial begin
        $display("=== Forwarding Unit Test Bench ===");
        $display("Testing RISC-V pipeline forwarding logic");
        $display("Forward codes: 00=No forward, 01=Forward from WB, 10=Forward from MEM");
        $display();
        
        rs1_ex = 5'b0;
        rs2_ex = 5'b0;
        rd_mem = 5'b0;
        rd_wb = 5'b0;
        reg_write_mem = 1'b0;
        reg_write_wb = 1'b0;
        
        $display("--- Testing No Forwarding Cases ---");
        
        // Test 1: No hazards, no forwarding needed
        set_inputs(5'd1, 5'd2, 5'd3, 5'd4, 1'b1, 1'b1);
        check_result("No hazards", 2'b00, 2'b00);
        
        // Test 2: Register write disabled, no forwarding
        set_inputs(5'd1, 5'd2, 5'd1, 5'd2, 1'b0, 1'b0);
        check_result("Write disabled", 2'b00, 2'b00);
        
        // Test 3: x0 register involved (should not forward)
        set_inputs(5'd0, 5'd0, 5'd0, 5'd1, 1'b1, 1'b1);
        check_result("x0 register cases", 2'b00, 2'b00);
        
        $display("\n--- Testing EX Hazard (MEM Stage Forwarding) ---");
        
        // Test 4: EX hazard on rs1 (forward from MEM)
        set_inputs(5'd5, 5'd6, 5'd5, 5'd7, 1'b1, 1'b1);
        check_result("EX hazard rs1 only", 2'b10, 2'b00);
        
        // Test 5: EX hazard on rs2 (forward from MEM)
        set_inputs(5'd8, 5'd9, 5'd9, 5'd10, 1'b1, 1'b1);
        check_result("EX hazard rs2 only", 2'b00, 2'b10);
        
        // Test 6: EX hazard on both rs1 and rs2 (forward from MEM)
        set_inputs(5'd11, 5'd12, 5'd12, 5'd13, 1'b1, 1'b1);
        check_result("EX hazard both operands (different rd_mem)", 2'b00, 2'b10);
        
        // Test 7: Same register for both rs1 and rs2, EX hazard
        set_inputs(5'd13, 5'd13, 5'd13, 5'd14, 1'b1, 1'b1);
        check_result("EX hazard same reg both operands", 2'b10, 2'b10);
        
        $display("\n--- Testing MEM Hazard (WB Stage Forwarding) ---");
        
        // Test 8: MEM hazard on rs1 (forward from WB)
        set_inputs(5'd15, 5'd16, 5'd17, 5'd15, 1'b1, 1'b1);
        check_result("MEM hazard rs1 only", 2'b01, 2'b00);
        
        // Test 9: MEM hazard on rs2 (forward from WB)
        set_inputs(5'd18, 5'd19, 5'd20, 5'd19, 1'b1, 1'b1);
        check_result("MEM hazard rs2 only", 2'b00, 2'b01);
        
        // Test 10: MEM hazard on both operands with same rd_wb
        set_inputs(5'd21, 5'd21, 5'd22, 5'd21, 1'b1, 1'b1);
        check_result("MEM hazard both operands same rd", 2'b01, 2'b01);
        
        // Test 11: MEM hazard on both operands with different rd_wb
        set_inputs(5'd23, 5'd24, 5'd25, 5'd23, 1'b1, 1'b1);
        check_result("MEM hazard both operands (different rd_wb)", 2'b01, 2'b00);
        
        $display("\n--- Testing Priority (EX Hazard Takes Precedence) ---");
        
        // Test 12: Both EX and MEM hazard on rs1, EX wins
        set_inputs(5'd26, 5'd27, 5'd26, 5'd26, 1'b1, 1'b1);
        check_result("EX priority over MEM hazard rs1", 2'b10, 2'b00);
        
        // Test 13: Both EX and MEM hazard on rs2, EX wins
        set_inputs(5'd28, 5'd29, 5'd29, 5'd29, 1'b1, 1'b1);
        check_result("EX priority over MEM hazard rs2", 2'b00, 2'b10);
        
        // Test 14: Complex case - EX hazard rs1, MEM hazard rs2
        set_inputs(5'd30, 5'd31, 5'd30, 5'd31, 1'b1, 1'b1);
        check_result("EX hazard rs1, MEM hazard rs2", 2'b10, 2'b01);
        
        // Test 15: Complex case - MEM hazard rs1, EX hazard rs2
        set_inputs(5'd1, 5'd2, 5'd2, 5'd1, 1'b1, 1'b1);
        check_result("MEM hazard rs1, EX hazard rs2", 2'b01, 2'b10);
        
        $display("\n--- Testing Register Write Enable Control ---");
        
        // Test 16: EX hazard but reg_write_mem disabled
        set_inputs(5'd3, 5'd4, 5'd3, 5'd5, 1'b0, 1'b1);
        check_result("EX hazard but write disabled", 2'b00, 2'b00);
        
        // Test 17: MEM hazard but reg_write_wb disabled  
        set_inputs(5'd6, 5'd7, 5'd8, 5'd6, 1'b1, 1'b0);
        check_result("MEM hazard but write disabled", 2'b00, 2'b00);
        
        // Test 18: Both write enables disabled
        set_inputs(5'd9, 5'd10, 5'd9, 5'd10, 1'b0, 1'b0);
        check_result("Both writes disabled", 2'b00, 2'b00);
        
        $display("\n--- Testing x0 Register Special Cases ---");
        
        // Test 19: x0 as destination (should never forward)
        set_inputs(5'd11, 5'd12, 5'd0, 5'd0, 1'b1, 1'b1);
        check_result("x0 as destination", 2'b00, 2'b00);
        
        // Test 20: x0 as source (should never forward)
        set_inputs(5'd0, 5'd0, 5'd13, 5'd14, 1'b1, 1'b1);
        check_result("x0 as source", 2'b00, 2'b00);
        
        // Test 21: Mixed x0 cases
        set_inputs(5'd0, 5'd15, 5'd0, 5'd15, 1'b1, 1'b1);
        check_result("Mixed x0 cases", 2'b00, 2'b01);
        
        $display("\n--- Testing Edge Cases ---");
        
        // Test 22: Maximum register numbers
        set_inputs(5'd31, 5'd30, 5'd31, 5'd30, 1'b1, 1'b1);
        check_result("Maximum register numbers", 2'b10, 2'b01);
        
        // Test 23: Same register for all fields
        set_inputs(5'd16, 5'd16, 5'd16, 5'd17, 1'b1, 1'b1);
        check_result("Same register multiple fields", 2'b10, 2'b10);
        
        // Test 24: Complex forwarding scenario
        set_inputs(5'd17, 5'd18, 5'd19, 5'd18, 1'b1, 1'b1);
        check_result("Complex scenario", 2'b00, 2'b01);
        
        // Test 25: All different registers
        set_inputs(5'd20, 5'd21, 5'd22, 5'd23, 1'b1, 1'b1);
        check_result("All different registers", 2'b00, 2'b00);
        
        $display("\n--- Testing Comprehensive Scenarios ---");
        
        // Test 26: Pipeline bubble simulation
        set_inputs(5'd24, 5'd25, 5'd0, 5'd0, 1'b0, 1'b0);
        check_result("Pipeline bubble", 2'b00, 2'b00);
        
        // Test 27: Back-to-back hazards
        set_inputs(5'd26, 5'd26, 5'd26, 5'd28, 1'b1, 1'b1);
        check_result("Back-to-back hazards", 2'b10, 2'b10);
        
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
        
        $display("\n=== Forwarding Unit Testbench Completed ===");
        $finish;
    end

endmodule