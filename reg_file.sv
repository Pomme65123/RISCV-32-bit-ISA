module reg_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,        // Write enable
    input  logic [4:0]  ra1,       // Read address 1
    input  logic [4:0]  ra2,       // Read address 2
    input  logic [4:0]  wa,        // Write address
    input  logic [31:0] wd,        // Write data
    output logic [31:0] rd1,       // Read data 1
    output logic [31:0] rd2        // Read data 2
);

    // Create 32 registers of 32 bits each
    logic [31:0] registers [31:0];

    // Initialize register file
    // Write operation
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (we && wa != 5'b00000) begin
            registers[wa] <= wd;
        end
    end
    
    // Read every cycle and address 0 is always 0
    assign rd1 = (ra1 == 5'b00000) ? 32'h00000000 : registers[ra1];
    assign rd2 = (ra2 == 5'b00000) ? 32'h00000000 : registers[ra2];

endmodule