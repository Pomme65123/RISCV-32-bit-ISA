`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a, b;
    logic [3:0] alu_ctrl;
    logic [31:0] result;
    logic zero;
    
    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b0001;
    localparam [3:0] ALU_AND  = 4'b0010;
    localparam [3:0] ALU_OR   = 4'b0011;
    localparam [3:0] ALU_XOR  = 4'b0100;
    localparam [3:0] ALU_SLL  = 4'b0101;
    localparam [3:0] ALU_SRL  = 4'b0110;
    localparam [3:0] ALU_SRA  = 4'b0111;
    localparam [3:0] ALU_SLT  = 4'b1000;
    localparam [3:0] ALU_SLTU = 4'b1001;
    localparam [3:0] ALU_BEQ  = 4'b1010;
    localparam [3:0] ALU_BNE  = 4'b1011;
    localparam [3:0] ALU_BLT  = 4'b1100;
    localparam [3:0] ALU_BGE  = 4'b1101;
    localparam [3:0] ALU_BLTU = 4'b1110;
    localparam [3:0] ALU_BGEU = 4'b1111;

    alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    task test_operation(
        input [3:0] op,
        input [31:0] val_a,
        input [31:0] val_b,
        input [31:0] expected_result,
        input expected_zero,
        input string op_name
    );
        a = val_a;
        b = val_b;
        alu_ctrl = op;
        #10;
        
        if (result === expected_result && zero === expected_zero) begin
            $display("PASS %s: a=%h, b=%h, result=%h, zero=%b", 
                     op_name, a, b, result, zero);
        end else begin
            $display("FAIL %s: a=%h, b=%h, result=%h (expected %h), zero=%b (expected %b)", 
                     op_name, a, b, result, expected_result, zero, expected_zero);
        end
    endtask

    initial begin
        $display("=== ALU Testbench Started ===");
        
        // Test ADD operations
        $display("\n--- Testing ADD ---");
        test_operation(ALU_ADD, 32'h12345678, 32'h87654321, 32'h99999999, 1'b0, "ADD");
        test_operation(ALU_ADD, 32'h00000000, 32'h00000000, 32'h00000000, 1'b1, "ADD (zero)");
        test_operation(ALU_ADD, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, 1'b1, "ADD (overflow)");
        
        // Test SUB operations
        $display("\n--- Testing SUB ---");
        test_operation(ALU_SUB, 32'h87654321, 32'h12345678, 32'h7530eca9, 1'b0, "SUB");
        test_operation(ALU_SUB, 32'h12345678, 32'h12345678, 32'h00000000, 1'b1, "SUB (equal)");
        test_operation(ALU_SUB, 32'h00000000, 32'h00000001, 32'hFFFFFFFF, 1'b0, "SUB (underflow)");
        
        // Test AND operations
        $display("\n--- Testing AND ---");
        test_operation(ALU_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, 1'b1, "AND");
        test_operation(ALU_AND, 32'hFFFFFFFF, 32'h12345678, 32'h12345678, 1'b0, "AND");
        
        // Test OR operations
        $display("\n--- Testing OR ---");
        test_operation(ALU_OR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, 1'b0, "OR");
        test_operation(ALU_OR, 32'h00000000, 32'h00000000, 32'h00000000, 1'b1, "OR (zero)");
        
        // Test XOR operations
        $display("\n--- Testing XOR ---");
        test_operation(ALU_XOR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, 1'b0, "XOR");
        test_operation(ALU_XOR, 32'h12345678, 32'h12345678, 32'h00000000, 1'b1, "XOR (same)");
        
        // Test SLL operations
        $display("\n--- Testing SLL ---");
        test_operation(ALU_SLL, 32'h00000001, 32'h00000004, 32'h00000010, 1'b0, "SLL");
        test_operation(ALU_SLL, 32'h12345678, 32'h00000000, 32'h12345678, 1'b0, "SLL (no shift)");
        test_operation(ALU_SLL, 32'h80000000, 32'h00000001, 32'h00000000, 1'b1, "SLL (shift out)");
        
        // Test SRL operations
        $display("\n--- Testing SRL ---");
        test_operation(ALU_SRL, 32'h80000000, 32'h00000004, 32'h08000000, 1'b0, "SRL");
        test_operation(ALU_SRL, 32'h12345678, 32'h00000000, 32'h12345678, 1'b0, "SRL (no shift)");
        test_operation(ALU_SRL, 32'h00000001, 32'h00000001, 32'h00000000, 1'b1, "SRL (shift out)");
        
        // Test SRA operations
        $display("\n--- Testing SRA ---");
        test_operation(ALU_SRA, 32'h80000000, 32'h00000004, 32'hF8000000, 1'b0, "SRA (negative)");
        test_operation(ALU_SRA, 32'h7FFFFFFF, 32'h00000004, 32'h07FFFFFF, 1'b0, "SRA (positive)");
        
        // Test SLT operations
        $display("\n--- Testing SLT ---");
        test_operation(ALU_SLT, 32'h80000000, 32'h7FFFFFFF, 32'h00000001, 1'b0, "SLT (neg < pos)");
        test_operation(ALU_SLT, 32'h7FFFFFFF, 32'h80000000, 32'h00000000, 1'b1, "SLT (pos !< neg)");
        test_operation(ALU_SLT, 32'h12345678, 32'h12345678, 32'h00000000, 1'b1, "SLT (equal)");
        
        // Test SLTU operations
        $display("\n--- Testing SLTU ---");
        test_operation(ALU_SLTU, 32'h80000000, 32'h7FFFFFFF, 32'h00000000, 1'b1, "SLTU (unsigned)");
        test_operation(ALU_SLTU, 32'h00000001, 32'h00000002, 32'h00000001, 1'b0, "SLTU");
        
        // Test Branch operations
        $display("\n--- Testing Branch Operations ---");
        
        // BEQ
        test_operation(ALU_BEQ, 32'h12345678, 32'h12345678, 32'h00000000, 1'b1, "BEQ (equal)");
        test_operation(ALU_BEQ, 32'h12345678, 32'h87654321, 32'h8acf1357, 1'b0, "BEQ (not equal)");
        
        // BNE
        test_operation(ALU_BNE, 32'h12345678, 32'h87654321, 32'h8acf1357, 1'b1, "BNE (not equal)");
        test_operation(ALU_BNE, 32'h12345678, 32'h12345678, 32'h00000000, 1'b0, "BNE (equal)");
        
        // BLT
        test_operation(ALU_BLT, 32'h80000000, 32'h7FFFFFFF, 32'h00000001, 1'b1, "BLT (neg < pos)");
        test_operation(ALU_BLT, 32'h7FFFFFFF, 32'h80000000, 32'hFFFFFFFF, 1'b0, "BLT (pos !< neg)");
        
        // BGE
        test_operation(ALU_BGE, 32'h7FFFFFFF, 32'h80000000, 32'hFFFFFFFF, 1'b1, "BGE (pos >= neg)");
        test_operation(ALU_BGE, 32'h80000000, 32'h7FFFFFFF, 32'h00000001, 1'b0, "BGE (neg !>= pos)");
        
        // BLTU
        test_operation(ALU_BLTU, 32'h7FFFFFFF, 32'h80000000, 32'hFFFFFFFF, 1'b1, "BLTU (unsigned)");
        test_operation(ALU_BLTU, 32'h80000000, 32'h7FFFFFFF, 32'h00000001, 1'b0, "BLTU (unsigned)");
        
        // BGEU
        test_operation(ALU_BGEU, 32'h80000000, 32'h7FFFFFFF, 32'h00000001, 1'b1, "BGEU (unsigned)");
        test_operation(ALU_BGEU, 32'h7FFFFFFF, 32'h80000000, 32'hFFFFFFFF, 1'b0, "BGEU (unsigned)");
        
        $display("\n=== ALU Testbench Completed ===");
        $finish;
    end

endmodule