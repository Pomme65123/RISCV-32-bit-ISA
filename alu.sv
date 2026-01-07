`timescale 1ns/1ps
import riscv_pkg::*;

module alu (
    input logic     [31:0]  a,
    input logic     [31:0]  b,
    input logic     [3:0]   alu_ctrl,
    output logic    [31:0]  result,
    output logic            zero
);

    // Storing values for ALU and branch comparisons
    logic [31:0] alu_result;
    logic        comparison_result;

    // Case Operations
    always_comb begin
        comparison_result = DISABLE;
        case (alu_ctrl)
            ALU_ADD:  alu_result = a + b;
            ALU_SUB:  alu_result = a - b;
            ALU_AND:  alu_result = a & b;
            ALU_OR:   alu_result = a | b;
            ALU_XOR:  alu_result = a ^ b;
            ALU_SLL:  alu_result = a << b[4:0];
            ALU_SRL:  alu_result = a >> b[4:0];
            ALU_SRA:  alu_result = $signed(a) >>> b[4:0];
            ALU_SLT:  alu_result = ($signed(a) < $signed(b)) ? {{31{DISABLE}}, ENABLE} : RESET_VALUE;
            ALU_SLTU: alu_result = (a < b) ? {{31{DISABLE}}, ENABLE} : RESET_VALUE;
            
            ALU_BEQ:  begin
                alu_result = a - b;
                comparison_result = (a == b);
            end
            ALU_BNE:  begin
                alu_result = a - b;
                comparison_result = (a != b);
            end
            ALU_BLT:  begin
                alu_result = a - b;
                comparison_result = ($signed(a) < $signed(b));
            end
            ALU_BGE:  begin
                alu_result = a - b;
                comparison_result = ($signed(a) >= $signed(b));
            end
            ALU_BLTU: begin
                alu_result = a - b;
                comparison_result = (a < b);
            end
            ALU_BGEU: begin
                alu_result = a - b;
                comparison_result = (a >= b);
            end
            
            default: alu_result = RESET_VALUE;
        endcase
    end

    assign result = alu_result;

    // Branch Logic
    always_comb begin
        case (alu_ctrl)
            ALU_BEQ, ALU_BNE, ALU_BLT, ALU_BGE, ALU_BLTU, ALU_BGEU:
                zero = comparison_result;
            default:
                zero = (alu_result == RESET_VALUE);
        endcase
    end

endmodule