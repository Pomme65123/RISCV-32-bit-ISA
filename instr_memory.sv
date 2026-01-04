`timescale 1ns/1ps

module instr_memory.sv #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 1024
) (
    input logic [ADDR_WIDTH-1:0] addr,
    input logic                  clk,
    input logic                  data,
    
);

    // Create Memory Array

    // Initialize Memory with sample instructions

    // Output the data from the memory address
endmodule