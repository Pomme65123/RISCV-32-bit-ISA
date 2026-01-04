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
    
    // Case statements for OPCODES


endmodule