`timescale 1ns/1ps
import riscv_pkg::*;

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic       alu_src,
    output logic [1:0] mem_to_reg,
    output logic [3:0] alu_ctrl,
    output logic       lui_instr,
    output logic       auipc_instr
);
    
    // Case statements for OPCODES
    always_comb begin
        reg_write   = DISABLE;
        mem_read    = DISABLE;
        mem_write   = DISABLE;
        branch      = DISABLE;
        jump        = DISABLE;
        alu_src     = RESET_1BIT;
        mem_to_reg  = MEM_TO_REG_ALU;
        alu_ctrl    = ALU_ADD;
        lui_instr   = RESET_1BIT;
        auipc_instr = RESET_1BIT;
        
        case (opcode)
            OP_LUI: begin
                reg_write   = ENABLE;
                alu_src     = ENABLE;
                mem_to_reg  = MEM_TO_REG_ALU;
                alu_ctrl    = ALU_ADD;
                lui_instr   = ENABLE;
            end
            
            OP_AUIPC: begin
                reg_write   = ENABLE;
                alu_src     = ENABLE;
                mem_to_reg  = MEM_TO_REG_ALU;
                alu_ctrl    = ALU_ADD;
                auipc_instr = ENABLE;
            end
            
            OP_JAL: begin
                reg_write   = ENABLE;
                jump        = ENABLE;
                mem_to_reg  = MEM_TO_REG_PC4; 
                alu_src     = ENABLE;
                alu_ctrl    = ALU_ADD;
            end
            
            OP_JALR: begin
                reg_write   = ENABLE;
                jump        = ENABLE;
                mem_to_reg  = MEM_TO_REG_PC4;
                alu_src     = ENABLE;
                alu_ctrl    = ALU_ADD;
            end
            
            OP_BRANCH: begin
                branch = ENABLE;
                case (funct3)
                    FUNCT3_BEQ:  alu_ctrl = ALU_BEQ;     // BEQ
                    FUNCT3_BNE:  alu_ctrl = ALU_BNE;     // BNE
                    FUNCT3_BLT:  alu_ctrl = ALU_BLT;     // BLT
                    FUNCT3_BGE:  alu_ctrl = ALU_BGE;     // BGE
                    FUNCT3_BLTU: alu_ctrl = ALU_BLTU;    // BLTU
                    FUNCT3_BGEU: alu_ctrl = ALU_BGEU;    // BGEU
                    default: alu_ctrl = ALU_BEQ;
                endcase
            end
            
            OP_LOAD: begin
                reg_write   = ENABLE;
                mem_read    = ENABLE;
                alu_src     = ENABLE;
                mem_to_reg  = MEM_TO_REG_MEM;
                alu_ctrl    = ALU_ADD;
            end
            
            OP_STORE: begin
                mem_write   = ENABLE;
                alu_src     = ENABLE;
                alu_ctrl    = ALU_ADD;
            end
            
            OP_IMM: begin
                reg_write   = ENABLE;
                alu_src     = ENABLE;
                mem_to_reg  = MEM_TO_REG_ALU;
                case (funct3)
                    FUNCT3_ADDI:  alu_ctrl = ALU_ADD;     // ADDI
                    FUNCT3_SLTI:  alu_ctrl = ALU_SLT;     // SLTI
                    FUNCT3_SLTIU: alu_ctrl = ALU_SLTU;    // SLTIU
                    FUNCT3_XORI:  alu_ctrl = ALU_XOR;     // XORI
                    FUNCT3_ORI:   alu_ctrl = ALU_OR;      // ORI
                    FUNCT3_ANDI:  alu_ctrl = ALU_AND;     // ANDI
                    FUNCT3_SLLI:  alu_ctrl = ALU_SLL;     // SLLI
                    FUNCT3_SRLI_SRAI: begin
                        if (funct7 == FUNCT7_ALT)
                            alu_ctrl = ALU_SRA;     // SRAI
                        else
                            alu_ctrl = ALU_SRL;     // SRLI
                    end
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            
            OP_REG: begin
                reg_write   = ENABLE;
                mem_to_reg  = MEM_TO_REG_ALU;
                case (funct3)
                    FUNCT3_ADDI: begin
                        if (funct7 == FUNCT7_ALT)
                            alu_ctrl = ALU_SUB;     // SUB
                        else
                            alu_ctrl = ALU_ADD;     // ADD
                    end
                    FUNCT3_SLLI:      alu_ctrl = ALU_SLL;     // SLL
                    FUNCT3_SLTI:      alu_ctrl = ALU_SLT;     // SLT
                    FUNCT3_SLTIU:     alu_ctrl = ALU_SLTU;    // SLTU
                    FUNCT3_XORI:      alu_ctrl = ALU_XOR;     // XOR
                    FUNCT3_SRLI_SRAI: begin
                        if (funct7 == FUNCT7_ALT)
                            alu_ctrl = ALU_SRA;     // SRA
                        else
                            alu_ctrl = ALU_SRL;     // SRL
                    end
                    FUNCT3_ORI:  alu_ctrl = ALU_OR;      // OR
                    FUNCT3_ANDI: alu_ctrl = ALU_AND;     // AND
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            
            default: begin
                // NOP
            end
        endcase
    end

endmodule