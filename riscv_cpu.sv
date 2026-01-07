`timescale 1ns/1ps
import riscv_pkg::*;

module riscv_cpu(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] dmem_rdata,
    input  logic [31:0] imem_data,
    output logic [31:0] imem_addr,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic [3:0]  dmem_be
);

    // Implement 5-stage RISC-V pipeline
    // Stages: IF -> ID -> EX -> MEM -> WB
    // Components needed:
    // - Program Counter
    // - Pipeline registers between stages
    // - Integration of modules
    // - Pipeline control logic

    // ===============
    // Program Counter
    // ===============

    logic [31:0] pc_current, pc_next, pc_plus4;
    logic [31:0] branch_target_ex, jump_target_ex;
    logic        branch_taken_ex;

    // ========================
    // Pipeline Control Signals
    // ========================

    logic stall_if, stall_id, flush_id, flush_ex;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_current <= RESET_VALUE;
        end else begin
            pc_current <= pc_next;
        end
    end

    always_comb begin
        pc_plus4 = pc_current + PC_INCREMENT;

        if (jump_target_ex != RESET_VALUE) begin
            pc_next = jump_target_ex;
        end else if (branch_taken_ex) begin
            pc_next = branch_target_ex;
        end else begin
            pc_next = pc_plus4;
        end

        if (stall_if) begin
            pc_next = pc_current;
        end
    end

    assign imem_addr = pc_current;

    // =======================
    // IF/ID Pipeline Register
    // =======================

    logic [31:0] pc_id, instruction_id;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_id <= RESET_VALUE;
            instruction_id <= RESET_VALUE;
        end else if (flush_id) begin
            pc_id <= RESET_VALUE;
            instruction_id <= NOP_INSTRUCTION;
        end else if (!stall_id) begin
            pc_id <= pc_plus4;
            instruction_id <= imem_data;
        end
    end

    // ========
    // ID Stage
    // ========

    logic   [31:0]    imm_id;
    logic   [6:0]     opcode_id, funct7_id;
    logic   [4:0]     rd_id, rs1_id, rs2_id;
    logic   [2:0]     funct3_id;     

    assign opcode_id = instruction_id[6:0];
    assign rd_id     = instruction_id[11:7];
    assign funct3_id = instruction_id[14:12];
    assign rs1_id    = instruction_id[19:15];
    assign rs2_id    = instruction_id[24:20];
    assign funct7_id = instruction_id[31:25];

    // Control Unit
    logic [3:0] alu_ctrl_id;
    logic [1:0]  mem_to_reg_id;
    logic       reg_write_id, mem_read_id, mem_write_id, branch_id, jump_id, alu_src_id, lui_instr_id, auipc_instr_id;

    control_unit ctrl_unit (
        .opcode      (opcode_id),
        .funct3      (funct3_id),
        .funct7      (funct7_id),
        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .branch      (branch_id),
        .jump        (jump_id),
        .alu_src     (alu_src_id),
        .lui_instr   (lui_instr_id),
        .auipc_instr (auipc_instr_id),
        .mem_to_reg  (mem_to_reg_id),
        .alu_ctrl    (alu_ctrl_id)
    );

    // Immediate Generator

    imm_gen imm_generator (
        .instr(instruction_id),
        .imm(imm_id)
    );

    // Register File

    logic [31:0] rs1_data_id, rs2_data_id, write_data_wb;
    logic [4:0]  rd_wb;
    logic        reg_write_wb;

    reg_file register_file (
        .clk        (clk),
        .rst_n      (rst_n),
        .ra1        (rs1_id),
        .ra2        (rs2_id),
        .wa         (rd_wb),
        .wd         (write_data_wb),
        .we         (reg_write_wb),
        .rd1        (rs1_data_id),
        .rd2        (rs2_data_id)
    );

    // ======================
    //ID/EX Pipeline Register
    // ======================

    logic [31:0] pc_ex, rs1_data_ex, rs2_data_ex, imm_ex;
    logic [4:0]  rs1_ex, rs2_ex, rd_ex;
    logic [3:0]  alu_ctrl_ex;
    logic [6:0]  opcode_ex;
    logic [1:0]  mem_to_reg_ex;
    logic        reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex, alu_src_ex, lui_instr_ex, auipc_instr_ex;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_ex         <= RESET_VALUE;
            rs1_data_ex   <= RESET_VALUE;
            rs2_data_ex   <= RESET_VALUE;
            imm_ex        <= RESET_VALUE;
            rs1_ex        <= RESET_5BIT;
            rs2_ex        <= RESET_5BIT;
            rd_ex         <= RESET_5BIT;
            alu_ctrl_ex   <= RESET_4BIT;
            opcode_ex     <= RESET_7BIT;
            mem_to_reg_ex <= RESET_2BIT;
            reg_write_ex  <= RESET_1BIT;
            mem_read_ex   <= RESET_1BIT;
            mem_write_ex  <= RESET_1BIT;
            branch_ex     <= RESET_1BIT;
            jump_ex       <= RESET_1BIT;
            alu_src_ex    <= RESET_1BIT;
            lui_instr_ex  <= RESET_1BIT;
            auipc_instr_ex<= RESET_1BIT;
        end else if (flush_ex) begin
            pc_ex         <= RESET_VALUE;
            rs1_data_ex   <= RESET_VALUE;
            rs2_data_ex   <= RESET_VALUE;
            imm_ex        <= RESET_VALUE;
            rs1_ex        <= RESET_5BIT;
            rs2_ex        <= RESET_5BIT;
            rd_ex         <= RESET_5BIT;
            alu_ctrl_ex   <= RESET_4BIT;
            opcode_ex     <= RESET_7BIT;
            mem_to_reg_ex <= RESET_2BIT;
            reg_write_ex  <= RESET_1BIT;
            mem_read_ex   <= RESET_1BIT;
            mem_write_ex  <= RESET_1BIT;
            branch_ex     <= RESET_1BIT;
            jump_ex       <= RESET_1BIT;
            alu_src_ex    <= RESET_1BIT;
            lui_instr_ex  <= RESET_1BIT;
            auipc_instr_ex<= RESET_1BIT;
        end else if (!stall_id) begin
            pc_ex         <= pc_id;
            rs1_data_ex   <= rs1_data_id;
            rs2_data_ex   <= rs2_data_id;
            imm_ex        <= imm_id;
            rs1_ex        <= rs1_id;
            rs2_ex        <= rs2_id;
            rd_ex         <= rd_id;
            alu_ctrl_ex   <= alu_ctrl_id;
            opcode_ex     <= opcode_id;
            mem_to_reg_ex <= mem_to_reg_id;
        end
    end

    // ========
    // EX Stage
    // ========

    logic [4:0] rd_mem;
    logic [1:0] forward_a_ex, forward_b_ex;
    logic       reg_write_mem;

    forwarding_unit fwd_unit (
        .rs1_ex        (rs1_ex),
        .rs2_ex        (rs2_ex),
        .rd_mem        (rd_mem),
        .rd_wb         (rd_wb),
        .reg_write_mem (reg_write_mem),
        .reg_write_wb  (reg_write_wb),
        .forward_a     (forward_a_ex),
        .forward_b     (forward_b_ex)
    );

    logic [31:0] alu_a, alu_b, alu_b_mux, alu_result_ex, write_data_mem, write_data_wb_fwd;
    logic        zero_ex;

    always_comb begin
        //Forwarding for ALU A
        case (forward_a_ex)
            FWD_NONE: alu_a = rs1_data_ex;
            FWD_MEM:  alu_a = write_data_mem;
            FWD_WB:   alu_a = write_data_wb_fwd;
            default:  alu_a = rs1_data_ex;
        endcase

        //Forwarding for ALU B
        case (forward_b_ex)
            FWD_NONE: alu_b_mux = rs2_data_ex;
            FWD_MEM:  alu_b_mux = write_data_mem;
            FWD_WB:   alu_b_mux = write_data_wb_fwd;
            default:  alu_b_mux = rs2_data_ex;
        endcase

        // Select between immediate and register data for ALU operand B
        if (alu_src_ex) begin
            alu_b = imm_ex;
        end else begin
            alu_b = alu_b_mux;
        end
    end

    // LUI and AUIPC
    logic [31:0] lui_auipc_result_ex;
    always_comb begin
        if (lui_instr_ex) begin
            lui_auipc_result_ex = imm_ex;
        end else if (auipc_instr_ex) begin
            lui_auipc_result_ex = pc_ex + imm_ex;
        end else begin
            lui_auipc_result_ex = alu_result_ex;
        end
    end

    // ===
    // ALU
    // ===

    alu alu_unit (
        .a          (alu_a),
        .b          (alu_b),
        .alu_ctrl   (alu_ctrl_ex),
        .result     (alu_result_ex),
        .zero       (zero_ex)
    );

    always_comb begin
        branch_taken_ex = branch_ex && zero_ex;
        branch_target_ex = pc_ex + imm_ex;

        if (jump_ex) begin
            if (opcode_ex == OP_JAL) begin // JAL
                jump_target_ex = pc_ex + imm_ex;
            end else begin // JALR
                jump_target_ex = alu_a + imm_ex;
                jump_target_ex[0] = RESET_1BIT;
            end
        end else begin
            jump_target_ex = RESET_VALUE;
        end
    end

    // ========================
    // EX/MEM Pipeline Register
    // ========================

    logic [31:0]    alu_result_mem, rs2_data_mem, pc_mem;
    logic [1:0]     mem_to_reg_mem;
    logic           mem_read_mem, mem_write_mem;
    
    // WB stage signals
    logic [31:0]    alu_result_wb, dmem_rdata_wb, pc_wb;
    logic [1:0]     mem_to_reg_wb;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_mem <= RESET_VALUE;
            rs2_data_mem   <= RESET_VALUE;
            pc_mem         <= RESET_VALUE;
            rd_mem         <= RESET_5BIT;
            mem_to_reg_mem <= RESET_2BIT;
            reg_write_mem  <= RESET_1BIT;
            mem_read_mem   <= RESET_1BIT;
            mem_write_mem  <= RESET_1BIT;
        end else begin
            alu_result_mem <= alu_result_ex;
            rs2_data_mem   <= rs2_data_ex;
            pc_mem         <= pc_ex;
            rd_mem         <= rd_ex;
            mem_to_reg_mem <= mem_to_reg_ex;
            reg_write_mem  <= reg_write_ex;
            mem_read_mem   <= mem_read_ex;
            mem_write_mem  <= mem_write_ex;
        end
    end

    // =========
    // MEM Stage
    // =========

    assign dmem_addr = alu_result_mem;
    assign dmem_wdata = rs2_data_mem;
    assign dmem_we = mem_write_mem;
    assign dmem_be = MEM_BYTE_ENABLE_ALL;
    
    always_comb begin
        case (mem_to_reg_mem)
            MEM_TO_REG_ALU: write_data_mem = alu_result_mem;
            MEM_TO_REG_MEM: write_data_mem = dmem_rdata;
            MEM_TO_REG_PC4: write_data_mem = pc_mem + PC_INCREMENT; // PC+4 for JAL/JALR
            default: write_data_mem = alu_result_mem;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_wb <= RESET_VALUE;
            dmem_rdata_wb <= RESET_VALUE;
            pc_wb         <= RESET_VALUE;
            rd_wb         <= RESET_5BIT;
            mem_to_reg_wb <= RESET_2BIT;
            reg_write_wb  <= RESET_1BIT;
        end else begin
            alu_result_wb <= alu_result_mem;
            dmem_rdata_wb <= dmem_rdata;
            pc_wb         <= pc_mem;
            rd_wb         <= rd_mem;
            mem_to_reg_wb <= mem_to_reg_mem;
            reg_write_wb  <= reg_write_mem;
        end
    end

    // ========
    // WB Stage
    // ========

    always_comb begin
        case (mem_to_reg_wb)
            MEM_TO_REG_ALU: write_data_wb = alu_result_wb;
            MEM_TO_REG_MEM: write_data_wb = dmem_rdata_wb;
            MEM_TO_REG_PC4: write_data_wb = pc_wb; // For JAL/JALR
            default: write_data_wb = alu_result_wb;
        endcase
    end

    assign rd_wb_fwd = rd_wb;
    assign reg_write_wb_fwd = reg_write_wb;
    assign write_data_wb_fwd = write_data_wb;

    // =====================
    // Hazard Detection Unit
    // =====================

    hazard_detection_unit hdu (
        .rs1_id          (rs1_id),
        .rs2_id          (rs2_id),
        .rd_ex           (rd_ex),
        .mem_read_ex     (mem_read_ex),
        .branch_taken_ex (branch_taken_ex),
        .jump_ex         (jump_ex),
        .stall_if        (stall_if),
        .stall_id        (stall_id),
        .flush_id        (flush_id),
        .flush_ex        (flush_ex)
    );

endmodule