module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 1024
) (
    input  logic                    clk,
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic                    we,
    input  logic [3:0]              be,
    output logic [DATA_WIDTH-1:0]   rdata
);

    // Create Memory

    // Initialize Memory

    // Create Write

    // Create Read


endmodule