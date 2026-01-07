`timescale 1ns/1ps
import riscv_pkg::*;

module control_unit_tb;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic       branch;
    logic       jump;
    logic       alu_src;
    logic [1:0] mem_to_reg;
    logic [3:0] alu_ctrl;
    logic       lui_instr;
    logic       auipc_instr;
    
    int test_count = 0;
    int pass_count = 0;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .alu_ctrl(alu_ctrl),
        .lui_instr(lui_instr),
        .auipc_instr(auipc_instr)
    );

    task test_control_signals(
        input [6:0] test_opcode,
        input [2:0] test_funct3,
        input [6:0] test_funct7,
        input       exp_reg_write,
        input       exp_mem_read,
        input       exp_mem_write,
        input       exp_branch,
        input       exp_jump,
        input       exp_alu_src,
        input [1:0] exp_mem_to_reg,
        input [3:0] exp_alu_ctrl,
        input       exp_lui_instr,
        input       exp_auipc_instr,
        input string instruction_name
    );

        opcode = test_opcode;
        funct3 = test_funct3;
        funct7 = test_funct7;

        #10;

        test_count++;
        if (reg_write   === exp_reg_write   && 
            mem_read    === exp_mem_read    &&
            mem_write   === exp_mem_write   &&
            branch      === exp_branch      &&
            jump        === exp_jump        &&
            alu_src     === exp_alu_src     &&
            mem_to_reg  === exp_mem_to_reg  &&
            alu_ctrl    === exp_alu_ctrl    &&
            lui_instr   === exp_lui_instr   &&
            auipc_instr === exp_auipc_instr) begin
            $display("PASS %s: All control signals correct", instruction_name);
            pass_count++;
        end else begin
            $display("FAIL %s:", instruction_name);
            $display("  reg_write: %b (expected %b)", reg_write, exp_reg_write);
            $display("  mem_read:  %b (expected %b)", mem_read, exp_mem_read);
            $display("  mem_write: %b (expected %b)", mem_write, exp_mem_write);
            $display("  branch:    %b (expected %b)", branch, exp_branch);
            $display("  jump:      %b (expected %b)", jump, exp_jump);
            $display("  alu_src:   %b (expected %b)", alu_src, exp_alu_src);
            $display("  mem_to_reg:%b (expected %b)", mem_to_reg, exp_mem_to_reg);
            $display("  alu_ctrl:  %b (expected %b)", alu_ctrl, exp_alu_ctrl);
            $display("  lui_instr: %b (expected %b)", lui_instr, exp_lui_instr);
            $display("  auipc_instr:%b (expected %b)", auipc_instr, exp_auipc_instr);
        end
        $display("");
    endtask

    initial begin
        $display("=== Control Unit Testbench Started ===");
        
        opcode = 7'b0;
        funct3 = 3'b0;
        funct7 = 7'b0;
        
        #10;
        
        $display("\n--- Testing LUI (Load Upper Immediate) ---");
        test_control_signals(
            OP_LUI, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 1'b0,
            "LUI"
        );
        
        $display("--- Testing AUIPC (Add Upper Immediate to PC) ---");
        test_control_signals(
            OP_AUIPC, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b0, 1'b1,
            "AUIPC"
        );
        
        $display("--- Testing JAL (Jump and Link) ---");
        test_control_signals(
            OP_JAL, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10, ALU_ADD, 1'b0, 1'b0,
            "JAL"
        );
        
        $display("--- Testing JALR (Jump and Link Register) ---");
        test_control_signals(
            OP_JALR, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10, ALU_ADD, 1'b0, 1'b0,
            "JALR"
        );
        
        $display("--- Testing Branch Instructions ---");
        test_control_signals(
            OP_BRANCH, 3'b000, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BEQ, 1'b0, 1'b0,
            "BEQ"
        );
        
        test_control_signals(
            OP_BRANCH, 3'b001, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BNE, 1'b0, 1'b0,
            "BNE"
        );
        
        test_control_signals(
            OP_BRANCH, 3'b100, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BLT, 1'b0, 1'b0,
            "BLT"
        );
        
        test_control_signals(
            OP_BRANCH, 3'b101, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BGE, 1'b0, 1'b0,
            "BGE"
        );
        
        test_control_signals(
            OP_BRANCH, 3'b110, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BLTU, 1'b0, 1'b0,
            "BLTU"
        );
        
        test_control_signals(
            OP_BRANCH, 3'b111, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BGEU, 1'b0, 1'b0,
            "BGEU"
        );
        
        $display("--- Testing Load Instructions ---");
        test_control_signals(
            OP_LOAD, 3'b000, 7'b0000000,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b01, ALU_ADD, 1'b0, 1'b0,
            "LB/LH/LW"
        );
        
        $display("--- Testing Store Instructions ---");
        test_control_signals(
            OP_STORE, 3'b000, 7'b0000000,
            1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b0, 1'b0,
            "SB/SH/SW"
        );
        
        $display("--- Testing Immediate Arithmetic Instructions ---");
        test_control_signals(
            OP_IMM, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b0, 1'b0,
            "ADDI"
        );
        
        test_control_signals(
            OP_IMM, 3'b010, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SLT, 1'b0, 1'b0,
            "SLTI"
        );
        
        test_control_signals(
            OP_IMM, 3'b011, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SLTU, 1'b0, 1'b0,
            "SLTIU"
        );
        
        test_control_signals(
            OP_IMM, 3'b100, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_XOR, 1'b0, 1'b0,
            "XORI"
        );
        
        test_control_signals(
            OP_IMM, 3'b110, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_OR, 1'b0, 1'b0,
            "ORI"
        );
        
        test_control_signals(
            OP_IMM, 3'b111, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_AND, 1'b0, 1'b0,
            "ANDI"
        );
        
        test_control_signals(
            OP_IMM, 3'b001, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SLL, 1'b0, 1'b0,
            "SLLI"
        );
        
        test_control_signals(
            OP_IMM, 3'b101, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SRL, 1'b0, 1'b0,
            "SRLI"
        );
        
        test_control_signals(
            OP_IMM, 3'b101, 7'b0100000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SRA, 1'b0, 1'b0,
            "SRAI"
        );
        
        $display("--- Testing Register Arithmetic Instructions ---");
        test_control_signals(
            OP_REG, 3'b000, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 1'b0,
            "ADD"
        );
        
        test_control_signals(
            OP_REG, 3'b000, 7'b0100000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SUB, 1'b0, 1'b0,
            "SUB"
        );
        
        test_control_signals(
            OP_REG, 3'b001, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SLL, 1'b0, 1'b0,
            "SLL"
        );
        
        test_control_signals(
            OP_REG, 3'b010, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SLT, 1'b0, 1'b0,
            "SLT"
        );
        
        test_control_signals(
            OP_REG, 3'b011, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SLTU, 1'b0, 1'b0,
            "SLTU"
        );
        
        test_control_signals(
            OP_REG, 3'b100, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_XOR, 1'b0, 1'b0,
            "XOR"
        );
        
        test_control_signals(
            OP_REG, 3'b101, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SRL, 1'b0, 1'b0,
            "SRL"
        );
        
        test_control_signals(
            OP_REG, 3'b101, 7'b0100000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b0, 1'b0,
            "SRA"
        );
        
        test_control_signals(
            OP_REG, 3'b110, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_OR, 1'b0, 1'b0,
            "OR"
        );
        
        test_control_signals(
            OP_REG, 3'b111, 7'b0000000,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_AND, 1'b0, 1'b0,
            "AND"
        );
        
        $display("--- Testing Default Case (NOP) ---");
        test_control_signals(
            7'b1111111, 3'b111, 7'b1111111,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 1'b0,
            "Invalid Opcode (NOP)"
        );
        
        $display("--- Testing Edge Cases ---");
        test_control_signals(
            OP_BRANCH, 3'b010, 7'b0000000,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, ALU_BEQ, 1'b0, 1'b0,
            "Branch with invalid funct3"
        );
        
        test_control_signals(
            OP_IMM, 3'b011, 7'b1111111,
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, ALU_SLTU, 1'b0, 1'b0,
            "SLTIU (funct7 ignored)"
        );
        
        $display("\n=== Test Results Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", test_count - pass_count);
        
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("Some tests failed.");
        end
        
        $display("\n=== Control Unit Testbench Completed ===");
        $finish;
    end

    initial begin
        $monitor("Time: %0t | OP: %b | F3: %b | F7: %b | RegWr: %b | MemR: %b | MemW: %b | Br: %b | Jmp: %b | ALUSrc: %b | Mem2Reg: %b | ALUCtrl: %b | LUI: %b | AUIPC: %b",
                 $time, opcode, funct3, funct7, reg_write, mem_read, mem_write, branch, jump, alu_src, mem_to_reg, alu_ctrl, lui_instr, auipc_instr);
    end

endmodule