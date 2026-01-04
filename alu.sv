`timescale 1ns/1ps

module alu (
    input logic     [31:0]  a,
    input logic     [31:0]  b,
    input logic     [3:0]   alu_ctrl,
    output logic    [31:0]  result,
    output logic            zero
);

    // ALU Control Codes
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

    // Storing values for ALU and branch comparisons
    logic [31:0] alu_result;
    logic        comparison_result;

    // Case Operations
    always_comb begin
        comparison_result = 1'b0; // Needs a default value
        case (alu_ctrl)
            ALU_ADD:  alu_result = a + b;
            ALU_SUB:  alu_result = a - b;
            ALU_AND:  alu_result = a & b;
            ALU_OR:   alu_result = a | b;
            ALU_XOR:  alu_result = a ^ b;
            ALU_SLL:  alu_result = a << b[4:0];
            ALU_SRL:  alu_result = a >> b[4:0];
            ALU_SRA:  alu_result = $signed(a) >>> b[4:0];
            ALU_SLT:  alu_result = ($signed(a) < $signed(b)) ? 32'h00000001 : 32'h00000000;
            ALU_SLTU: alu_result = (a < b) ? 32'h00000001 : 32'h00000000;
            
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
            
            default: alu_result = 32'h00000000;
        endcase
    end

    assign result = alu_result;

    // Branch Logic
    always_comb begin
        case (alu_ctrl)
            ALU_BEQ, ALU_BNE, ALU_BLT, ALU_BGE, ALU_BLTU, ALU_BGEU:
                zero = comparison_result;
            default:
                zero = (alu_result == 32'h00000000);
        endcase
    end

endmodule