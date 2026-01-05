`timescale 1ns/1ps

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
        forward_a = 2'b00;
        forward_b = 2'b00;
        
        // Forward for ALU input A (rs1)
        if (reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs1_ex)) begin
            forward_a = 2'b10;  // Forward from MEM stage
        end else if (reg_write_wb && (rd_wb != 5'b00000) && (rd_wb == rs1_ex) && 
                    !(reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs1_ex))) begin
            forward_a = 2'b01;  // Forward from WB stage
        end
        
        // Forward for ALU input B (rs2)
        if (reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs2_ex)) begin
            forward_b = 2'b10;  // Forward from MEM stage
        end else if (reg_write_wb && (rd_wb != 5'b00000) && (rd_wb == rs2_ex) &&
                    !(reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs2_ex))) begin
            forward_b = 2'b01;  // Forward from WB stage
        end
    end


endmodule