`timescale 1ns/1ps

package riscv_pkg;
    localparam [4:0] REG_ZERO = 5'b00000; 
    
    // PC Constants  
    localparam [31:0] PC_INCREMENT = 32'd4;
    
    // ALU Control Codes
    localparam [3:0] ALU_ADD  = 4'b0000;  // Addition
    localparam [3:0] ALU_SUB  = 4'b0001;  // Subtraction
    localparam [3:0] ALU_AND  = 4'b0010;  // Bitwise AND
    localparam [3:0] ALU_OR   = 4'b0011;  // Bitwise OR
    localparam [3:0] ALU_XOR  = 4'b0100;  // Bitwise XOR
    localparam [3:0] ALU_SLL  = 4'b0101;  // Shift Left Logical
    localparam [3:0] ALU_SRL  = 4'b0110;  // Shift Right Logical
    localparam [3:0] ALU_SRA  = 4'b0111;  // Shift Right Arithmetic
    localparam [3:0] ALU_SLT  = 4'b1000;  // Set Less Than
    localparam [3:0] ALU_SLTU = 4'b1001;  // Set Less Than Unsigned
    localparam [3:0] ALU_BEQ  = 4'b1010;  // Branch Equal
    localparam [3:0] ALU_BNE  = 4'b1011;  // Branch Not Equal
    localparam [3:0] ALU_BLT  = 4'b1100;  // Branch Less Than
    localparam [3:0] ALU_BGE  = 4'b1101;  // Branch Greater Equal
    localparam [3:0] ALU_BLTU = 4'b1110;  // Branch Less Than Unsigned
    localparam [3:0] ALU_BGEU = 4'b1111;  // Branch Greater Equal Unsigned
    
    // RISC-V Instruction Opcodes
    localparam [6:0] OP_LUI    = 7'b0110111; // Load Upper Immediate
    localparam [6:0] OP_AUIPC  = 7'b0010111; // Add Upper Immediate to PC
    localparam [6:0] OP_JAL    = 7'b1101111; // Jump and Link
    localparam [6:0] OP_JALR   = 7'b1100111; // Jump and Link Register
    localparam [6:0] OP_BRANCH = 7'b1100011; // Branch instructions
    localparam [6:0] OP_LOAD   = 7'b0000011; // Load instructions
    localparam [6:0] OP_STORE  = 7'b0100011; // Store instructions
    localparam [6:0] OP_IMM    = 7'b0010011; // Immediate arithmetic
    localparam [6:0] OP_REG    = 7'b0110011; // Register arithmetic
    
    // Forwarding Control Codes
    localparam [1:0] FWD_NONE = 2'b00;
    localparam [1:0] FWD_MEM  = 2'b01;  
    localparam [1:0] FWD_WB   = 2'b10;
    
    // Memory-to-Register Control
    localparam [1:0] MEM_TO_REG_ALU = 2'b00;
    localparam [1:0] MEM_TO_REG_MEM = 2'b01;
    localparam [1:0] MEM_TO_REG_PC4 = 2'b10;
    
    // Memory Access Constants
    localparam [3:0] MEM_BYTE_ENABLE_ALL = 4'b1111;
    localparam [31:0] RESET_VALUE = 32'd0;
    localparam [31:0] NOP_INSTRUCTION = 32'h00000013;
    
    // Reset Constants for Different Bit Widths
    localparam [6:0]  RESET_7BIT  = 7'd0;
    localparam [4:0]  RESET_5BIT  = 5'd0;
    localparam [3:0]  RESET_4BIT  = 4'd0;
    localparam [2:0]  RESET_3BIT  = 3'd0;
    localparam [1:0]  RESET_2BIT  = 2'd0;
    localparam        RESET_1BIT  = 1'b0;
    
    // Function Codes for Branch Instructions
    localparam [2:0] FUNCT3_BEQ  = 3'b000;  // Branch if Equal
    localparam [2:0] FUNCT3_BNE  = 3'b001;  // Branch if Not Equal
    localparam [2:0] FUNCT3_BLT  = 3'b100;  // Branch if Less Than
    localparam [2:0] FUNCT3_BGE  = 3'b101;  // Branch if Greater/Equal
    localparam [2:0] FUNCT3_BLTU = 3'b110;  // Branch if Less Than Unsigned
    localparam [2:0] FUNCT3_BGEU = 3'b111;  // Branch if Greater/Equal Unsigned
    
    // Control Signal Constants
    localparam ENABLE  = 1'b1;
    localparam DISABLE = 1'b0;
    
    // Immediate Generation Constants
    localparam [11:0] IMM_ZERO_12BIT = 12'b000000000000;  // 12-bit zero for U-type immediates
    localparam [0:0]  LSB_ZERO = 1'b0;                    // LSB zero for J-type immediates
    
    // Function Codes for I-type and R-type Instructions
    localparam [2:0] FUNCT3_ADDI = 3'b000;      // Add Immediate / Add
    localparam [2:0] FUNCT3_SLTI = 3'b010;      // Set Less Than Immediate
    localparam [2:0] FUNCT3_SLTIU = 3'b011;     // Set Less Than Immediate Unsigned
    localparam [2:0] FUNCT3_XORI = 3'b100;      // XOR Immediate
    localparam [2:0] FUNCT3_ORI  = 3'b110;      // OR Immediate
    localparam [2:0] FUNCT3_ANDI = 3'b111;      // AND Immediate
    localparam [2:0] FUNCT3_SLLI = 3'b001;      // Shift Left Logical Immediate
    localparam [2:0] FUNCT3_SRLI_SRAI = 3'b101; // Shift Right Immediate
    
    // Function7 Codes
    localparam [6:0] FUNCT7_NORMAL = 7'b0000000;
    localparam [6:0] FUNCT7_ALT    = 7'b0100000;
    
endpackage