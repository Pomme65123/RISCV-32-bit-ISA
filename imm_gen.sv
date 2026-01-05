`timescale 1ns/1ps

module imm_gen.sv (
    input  logic [31:0] instr,
    output logic [31:0] imm
);

    // OPCODES

    /* 
        Combinational logic for
        OP_LUI, OP_AUIPC, OP_JAL, OP_JALR,
         OP_BRANCH, OP_LOAD, OP_STORE, OP_IMM
    */

endmodule