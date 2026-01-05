`timescale 1ns/1ps

module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 1024
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic                    we,
    input  logic [3:0]              be,
    output logic [DATA_WIDTH-1:0]   rdata
);

    // Create Memory
    logic [7:0] memory [0:MEM_SIZE*4-1];
    logic [ADDR_WIDTH-1:0] byte_addr;
    
    assign byte_addr = addr;

    // Create Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Clearse memory on reset
            for (int i = 0; i < MEM_SIZE*4; i++) begin
                memory[i] <= 8'h00;
            end
        end else if (we && (byte_addr < MEM_SIZE*4 - 3)) begin
            if (be[0]) memory[byte_addr]     <= wdata[7:0];
            if (be[1]) memory[byte_addr + 1] <= wdata[15:8];
            if (be[2]) memory[byte_addr + 2] <= wdata[23:16];
            if (be[3]) memory[byte_addr + 3] <= wdata[31:24];
        end
    end

    // Create Read (asynchronous)
    always_comb begin
        if (byte_addr < MEM_SIZE*4 - 3) begin
            rdata = {memory[byte_addr + 3], memory[byte_addr + 2], 
                     memory[byte_addr + 1], memory[byte_addr]};
        end else begin
            rdata = 32'h00000000;
        end
    end

endmodule