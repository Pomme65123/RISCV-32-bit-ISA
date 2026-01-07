`timescale 1ns/1ps
import riscv_pkg::*;

module forwarding_unit (
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_mem,
    input  logic [4:0] rd_wb,
    input  logic       reg_write_mem,
    input  logic       reg_write_wb,
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        // Default: no forwarding
        forward_a = FWD_NONE;
        forward_b = FWD_NONE;
        
        // Forward for ALU input A (rs1)
        if (reg_write_mem && (rd_mem != REG_ZERO) && (rd_mem == rs1_ex)) begin
            forward_a = FWD_MEM; 
        end else if (reg_write_wb && (rd_wb != REG_ZERO) && (rd_wb == rs1_ex)) begin
            forward_a = FWD_WB;
        end
        
        // Forward for ALU input B (rs2)
        if (reg_write_mem && (rd_mem != REG_ZERO) && (rd_mem == rs2_ex)) begin
            forward_b = FWD_MEM;
        end else if (reg_write_wb && (rd_wb != REG_ZERO) && (rd_wb == rs2_ex)) begin
            forward_b = FWD_WB;
        end
    end


endmodule