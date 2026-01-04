`timescale 1ns/1ps

module instr_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 1024
) (
    input logic [ADDR_WIDTH-1:0] addr,
    input logic                  clk,
    output logic [DATA_WIDTH-1:0] data
);

    localparam logic [DATA_WIDTH-1:0] NOP = 32'h00000013; // ADDI x0, x0, 0

    // Create Memory Array
    logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
    logic [$clog2(MEM_SIZE)-1:0] word_addr;

    assign word_addr = addr[$clog2(MEM_SIZE)+1:2]; // Remove byte offset

    // Initialize Memory
    initial begin
        // Clear Memory
        for (int i = 0; i < MEM_SIZE; i++) begin
            memory[i] = NOP; // NOP instruction
        end

        // Initialize Memory with sample instructions
        memory[0] = 32'h00500093;  // addi x1, x0, 5      (x1 = 5)
        memory[1] = 32'h00600113;  // addi x2, x0, 6      (x2 = 6)
        memory[2] = 32'h002081b3;  // add  x3, x1, x2     (x3 = x1 + x2 = 11)
        memory[3] = 32'h40208233;  // sub  x4, x1, x2     (x4 = x1 - x2 = -1)
        memory[4] = 32'h0020f2b3;  // and  x5, x1, x2     (x5 = x1 & x2 = 4)
        memory[5] = 32'h0020e333;  // or   x6, x1, x2     (x6 = x1 | x2 = 7)
        memory[6] = 32'h0020c3b3;  // xor  x7, x1, x2     (x7 = x1 ^ x2 = 3)
        memory[7] = 32'h00209413;  // slli x8, x1, 2      (x8 = x1 << 2 = 20)
        memory[8] = 32'h0020a4b3;  // slt  x9, x1, x2     (x9 = (x1 < x2) ? 1 : 0 = 1)
        memory[9] = NOP;
        memory[10] = NOP;
        memory[11] = NOP;
    end

    // Output the data from the memory address
    always_ff @(posedge clk) begin
        data <= memory[word_addr];
    end
endmodule