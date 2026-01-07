`timescale 1ns/1ps

module hazard_detection_unit_tb;

    logic [4:0] rs1_id;
    logic [4:0] rs2_id;
    logic [4:0] rd_ex;
    logic       mem_read_ex;
    logic       branch_taken_ex;
    logic       jump_ex;
    logic       stall_if;
    logic       stall_id;
    logic       flush_id;
    logic       flush_ex;
    
    logic expected_stall_if;
    logic expected_stall_id;
    logic expected_flush_id;
    logic expected_flush_ex;

    int test_num = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    hazard_detection_unit dut (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_ex),
        .mem_read_ex(mem_read_ex),
        .branch_taken_ex(branch_taken_ex),
        .jump_ex(jump_ex),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .flush_id(flush_id),
        .flush_ex(flush_ex)
    );
    
    task set_inputs(
        input [4:0] rs1,
        input [4:0] rs2,
        input [4:0] rd,
        input       mem_read,
        input       branch_taken,
        input       jump
    );
        rs1_id = rs1;
        rs2_id = rs2;
        rd_ex = rd;
        mem_read_ex = mem_read;
        branch_taken_ex = branch_taken;
        jump_ex = jump;
        #1;
    endtask
    
    task check_result(
        input string test_name,
        input logic exp_stall_if,
        input logic exp_stall_id,
        input logic exp_flush_id,
        input logic exp_flush_ex
    );
        test_num++;
        expected_stall_if = exp_stall_if;
        expected_stall_id = exp_stall_id;
        expected_flush_id = exp_flush_id;
        expected_flush_ex = exp_flush_ex;
        
        if (stall_if === expected_stall_if && 
            stall_id === expected_stall_id && 
            flush_id === expected_flush_id && 
            flush_ex === expected_flush_ex) begin
            $display("PASS: Test %0d - %s", test_num, test_name);
            tests_passed++;
        end else begin
            $display("FAIL: Test %0d - %s", test_num, test_name);
            $display("  Expected: stall_if=%b, stall_id=%b, flush_id=%b, flush_ex=%b", 
                     exp_stall_if, exp_stall_id, exp_flush_id, exp_flush_ex);
            $display("  Got:      stall_if=%b, stall_id=%b, flush_id=%b, flush_ex=%b", 
                     stall_if, stall_id, flush_id, flush_ex);
            tests_failed++;
        end
    endtask
    
    initial begin
        $display("Starting Hazard Detection Unit Tests");
        $display("====================================");
        
        // Test 1: No hazard - default state
        set_inputs(5'd1, 5'd2, 5'd3, 1'b0, 1'b0, 1'b0);
        check_result("No hazard", 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Test 2: Load-use hazard with rs1 match
        set_inputs(5'd5, 5'd2, 5'd5, 1'b1, 1'b0, 1'b0);
        check_result("Load-use hazard rs1", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 3: Load-use hazard with rs2 match
        set_inputs(5'd1, 5'd7, 5'd7, 1'b1, 1'b0, 1'b0);
        check_result("Load-use hazard rs2", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 4: Load-use hazard with both rs1 and rs2 match (rd matches rs1)
        set_inputs(5'd8, 5'd8, 5'd8, 1'b1, 1'b0, 1'b0);
        check_result("Load-use hazard both regs", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 5: Load instruction but no register match
        set_inputs(5'd1, 5'd2, 5'd3, 1'b1, 1'b0, 1'b0);
        check_result("Load no match", 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Test 6: Register match but not a load instruction
        set_inputs(5'd5, 5'd2, 5'd5, 1'b0, 1'b0, 1'b0);
        check_result("Not load with match", 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Test 7: Load-use hazard with x0 register (should not cause hazard)
        set_inputs(5'd0, 5'd2, 5'd0, 1'b1, 1'b0, 1'b0);
        check_result("Load x0 no hazard rs1", 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Test 8: Load-use hazard with x0 as destination (should not cause hazard)
        set_inputs(5'd5, 5'd2, 5'd0, 1'b1, 1'b0, 1'b0);
        check_result("Load to x0 no hazard", 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Test 9: Branch taken (control hazard)
        set_inputs(5'd1, 5'd2, 5'd3, 1'b0, 1'b1, 1'b0);
        check_result("Branch taken", 1'b0, 1'b0, 1'b1, 1'b1);
        
        // Test 10: Jump (control hazard)
        set_inputs(5'd1, 5'd2, 5'd3, 1'b0, 1'b0, 1'b1);
        check_result("Jump", 1'b0, 1'b0, 1'b1, 1'b1);
        
        // Test 11: Both branch and jump (should still flush)
        set_inputs(5'd1, 5'd2, 5'd3, 1'b0, 1'b1, 1'b1);
        check_result("Branch and jump", 1'b0, 1'b0, 1'b1, 1'b1);
        
        // Test 12: Load-use hazard with branch (load-use has priority)
        set_inputs(5'd5, 5'd2, 5'd5, 1'b1, 1'b1, 1'b0);
        check_result("Load-use with branch", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 13: Load-use hazard with jump (load-use has priority)
        set_inputs(5'd7, 5'd2, 5'd7, 1'b1, 1'b0, 1'b1);
        check_result("Load-use with jump", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 14: Load-use hazard with both branch and jump (load-use has priority)
        set_inputs(5'd9, 5'd2, 5'd9, 1'b1, 1'b1, 1'b1);
        check_result("Load-use with branch and jump", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 15: Edge case - all registers same
        set_inputs(5'd15, 5'd15, 5'd15, 1'b1, 1'b0, 1'b0);
        check_result("All registers same", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 16: Edge case - maximum register values
        set_inputs(5'd31, 5'd30, 5'd31, 1'b1, 1'b0, 1'b0);
        check_result("Max register values", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 17: Load with rs2 = x0, rd matches rs1
        set_inputs(5'd10, 5'd0, 5'd10, 1'b1, 1'b0, 1'b0);
        check_result("Load rs2=x0 rd=rs1", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 18: Load with rs1 = x0, rd matches rs2
        set_inputs(5'd0, 5'd11, 5'd11, 1'b1, 1'b0, 1'b0);
        check_result("Load rs1=x0 rd=rs2", 1'b1, 1'b1, 1'b0, 1'b1);
        
        // Test 19: All signals active except no register match
        set_inputs(5'd12, 5'd13, 5'd14, 1'b1, 1'b1, 1'b1);
        check_result("All signals no match", 1'b0, 1'b0, 1'b1, 1'b1);
        
        // Test 20: Sequential register values with load-use hazard
        set_inputs(5'd20, 5'd21, 5'd20, 1'b1, 1'b0, 1'b0);
        check_result("Sequential regs load-use", 1'b1, 1'b1, 1'b0, 1'b1);
        
        $display("\n====================================");
        $display("Test Summary:");
        $display("Total Tests: %0d", test_num);
        $display("Passed: %0d", tests_passed);
        $display("Failed: %0d", tests_failed);
        
        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        $finish;
    end
    
endmodule