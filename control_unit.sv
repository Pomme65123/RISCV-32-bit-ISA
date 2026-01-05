`timescale 1ns/1ps

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

    // OPCODE Definitions
    localparam [6:0] OP_LUI    = 7'b0110111; // Load Upper Immediate
    localparam [6:0] OP_AUIPC  = 7'b0010111; // Add Upper Immediate to PC
    localparam [6:0] OP_JAL    = 7'b1101111; // Jump and Link
    localparam [6:0] OP_JALR   = 7'b1100111; // Jump and Link Register
    localparam [6:0] OP_BRANCH = 7'b1100011; // Branch instructions
    localparam [6:0] OP_LOAD   = 7'b0000011; // Load instructions
    localparam [6:0] OP_STORE  = 7'b0100011; // Store instructions
    localparam [6:0] OP_IMM    = 7'b0010011; // Immediate arithmetic
    localparam [6:0] OP_REG    = 7'b0110011; // Register arithmetic
    
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
    
    // Case statements for OPCODES
    always_comb begin
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        alu_src = 1'b0;
        mem_to_reg = 2'b00;
        alu_ctrl = ALU_ADD;
        lui_instr = 1'b0;
        auipc_instr = 1'b0;
        
        case (opcode)
            OP_LUI: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                alu_ctrl = ALU_ADD;
                lui_instr = 1'b1;
            end
            
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                alu_ctrl = ALU_ADD;
                auipc_instr = 1'b1;
            end
            
            OP_JAL: begin
                reg_write = 1'b1;
                jump = 1'b1;
                mem_to_reg = 2'b10; 
                alu_src = 1'b1;
                alu_ctrl = ALU_ADD;
            end
            
            OP_JALR: begin
                reg_write = 1'b1;
                jump = 1'b1;
                mem_to_reg = 2'b10;
                alu_src = 1'b1;
                alu_ctrl = ALU_ADD;
            end
            
            OP_BRANCH: begin
                branch = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = ALU_BEQ;     // BEQ
                    3'b001: alu_ctrl = ALU_BNE;     // BNE
                    3'b100: alu_ctrl = ALU_BLT;     // BLT
                    3'b101: alu_ctrl = ALU_BGE;     // BGE
                    3'b110: alu_ctrl = ALU_BLTU;    // BLTU
                    3'b111: alu_ctrl = ALU_BGEU;    // BGEU
                    default: alu_ctrl = ALU_BEQ;
                endcase
            end
            
            OP_LOAD: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                alu_ctrl = ALU_ADD;
            end
            
            OP_STORE: begin
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_ctrl = ALU_ADD;
            end
            
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;     // ADDI
                    3'b010: alu_ctrl = ALU_SLT;     // SLTI
                    3'b011: alu_ctrl = ALU_SLTU;    // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;     // XORI
                    3'b110: alu_ctrl = ALU_OR;      // ORI
                    3'b111: alu_ctrl = ALU_AND;     // ANDI
                    3'b001: alu_ctrl = ALU_SLL;     // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA;     // SRAI
                        else
                            alu_ctrl = ALU_SRL;     // SRLI
                    end
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            
            OP_REG: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b00;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SUB;     // SUB
                        else
                            alu_ctrl = ALU_ADD;     // ADD
                    end
                    3'b001: alu_ctrl = ALU_SLL;     // SLL
                    3'b010: alu_ctrl = ALU_SLT;     // SLT
                    3'b011: alu_ctrl = ALU_SLTU;    // SLTU
                    3'b100: alu_ctrl = ALU_XOR;     // XOR
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA;     // SRA
                        else
                            alu_ctrl = ALU_SRL;     // SRL
                    end
                    3'b110: alu_ctrl = ALU_OR;      // OR
                    3'b111: alu_ctrl = ALU_AND;     // AND
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            
            default: begin
                // NOP
            end
        endcase
    end

endmodule