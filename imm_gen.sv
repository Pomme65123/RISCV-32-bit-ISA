`timescale 1ns/1ps
import riscv_pkg::*;

module imm_gen (
    input  logic [31:0] instr,
    output logic [31:0] imm
);

    // Find OPCODE
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    /* 
        Combinational logic for
        OP_LUI, OP_AUIPC, OP_JAL, OP_JALR,
         OP_BRANCH, OP_LOAD, OP_STORE, OP_IMM
    */

    always_comb begin
        case (opcode)
            OP_LUI, OP_AUIPC: begin
                // U-type: imm[31:12] = instr[31:12], imm[11:0] = 0
                imm = {instr[31:12], IMM_ZERO_12BIT};
            end
            OP_JAL: begin
                // J-type: imm[20|10:1|11|19:12] = instr[31|30:21|20|19:12]
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], LSB_ZERO};
            end
            OP_JALR, OP_LOAD, OP_IMM: begin
                // I-type: imm[11:0] = instr[31:20]
                imm = {{20{instr[31]}}, instr[31:20]};
            end
            OP_BRANCH: begin
                // B-type: imm[12|10:5|4:1|11] = instr[31|30:25|11:8|7]
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], LSB_ZERO};
            end
            OP_STORE: begin
                // S-type: imm[11:5|4:0] = instr[31:25|11:7]
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            default: begin
                imm = RESET_VALUE;
            end
        endcase
    end

endmodule