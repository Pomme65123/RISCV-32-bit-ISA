`timescale 1ns/1ps
import riscv_pkg::*;

module hazard_detection_unit (
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    input  logic [4:0] rd_ex,
    input  logic       mem_read_ex,
    input  logic       branch_taken_ex,
    input  logic       jump_ex,
    output logic       stall_if,
    output logic       stall_id,
    output logic       flush_id,
    output logic       flush_ex
);

// Internal signal to track when a load-use hazard is detected
    logic load_use_hazard;
    
    /*
        Check for load hazards:
        - Instruction in EX stage is a load operation
        - Destination register is not x0
        - Destination register matches a source register in the ID stage
    */ 
    always_comb begin
        load_use_hazard = mem_read_ex && (rd_ex != REG_ZERO) && ((rd_ex == rs1_id) || (rd_ex == rs2_id));
    end
    
    // Determines pipeline control signals
    always_comb begin
        // All control signals should be inactive
        stall_if = DISABLE;
        stall_id = DISABLE;
        flush_id = DISABLE;
        flush_ex = DISABLE;
        
        if (load_use_hazard) begin
            stall_if = ENABLE;
            stall_id = ENABLE;
            flush_ex = ENABLE;
        end else if (branch_taken_ex || jump_ex) begin
            flush_id = ENABLE;
            flush_ex = ENABLE;
        end
    end

    
endmodule