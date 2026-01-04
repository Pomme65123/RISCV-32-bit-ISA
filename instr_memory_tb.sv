`timescale 1ns/1ps

module instr_memory_tb;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter MEM_SIZE   = 1024;
    parameter CLK_PERIOD = 10;

    logic [ADDR_WIDTH-1:0] addr;
    logic                  clk;
    logic [DATA_WIDTH-1:0] data;
    
    logic [DATA_WIDTH-1:0] expected_instructions [0:11];
    


    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    instr_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) dut (
        .addr(addr),
        .clk(clk),
        .data(data)
    );

    // Initialize expected values
    initial begin
        expected_instructions[0]  = 32'h00500093; // addi x1, x0, 5
        expected_instructions[1]  = 32'h00600113; // addi x2, x0, 6
        expected_instructions[2]  = 32'h002081b3; // add  x3, x1, x2
        expected_instructions[3]  = 32'h40208233; // sub  x4, x1, x2
        expected_instructions[4]  = 32'h0020f2b3; // and  x5, x1, x2
        expected_instructions[5]  = 32'h0020e333; // or   x6, x1, x2
        expected_instructions[6]  = 32'h0020c3b3; // xor  x7, x1, x2
        expected_instructions[7]  = 32'h00209413; // slli x8, x1, 2
        expected_instructions[8]  = 32'h0020a4b3; // slt  x9, x1, x2
        expected_instructions[9]  = 32'h00000013;
        expected_instructions[10] = 32'h00000013;
        expected_instructions[11] = 32'h00000013;
    end

    task test_instruction_fetch(
        input [31:0] test_addr,
        input [31:0] expected_data,
        input string description
    );
        addr = test_addr;
        
        /*
            THIS IS IMPORTANT
            WE NEED THE 2 @(posedge clk) SO test_operation CAN READ THE DATA AFTER THE CLK EDGE
        */
        repeat(2) @(posedge clk);
        
        if (data === expected_data) begin
            $display("PASS %s: addr=0x%08h -> data=0x%08h", description, test_addr, data);
        end else begin
            $display("FAIL %s: addr=0x%08h -> data=0x%08h (expected 0x%08h)", 
                     description, test_addr, data, expected_data);
        end
    endtask

    task display_instruction(
        input [31:0] instruction,
        input string description
    );
        logic [6:0] opcode;
        logic [4:0] rd, rs1, rs2;
        logic [11:0] imm;
        
        opcode = instruction[6:0];
        rd     = instruction[11:7];
        rs1    = instruction[19:15];
        rs2    = instruction[24:20];
        imm    = instruction[31:20];
        
        $display("  Instruction: %s", description);
        $display("    Binary:  %b", instruction);
        $display("    Hex:     0x%08h", instruction);
        $display("    Opcode:  %b (0x%02h)", opcode, opcode);
        $display("    rd:      x%0d", rd);
        $display("    rs1:     x%0d", rs1);
        $display("    rs2:     x%0d", rs2);
        $display("    imm:     %0d (0x%03h)", $signed(imm), imm);
        $display("");
    endtask

    initial begin
        $display("=== Instruction Memory Testbench Started ===");
        
        addr = 32'h00000000;
        
        repeat(3) @(posedge clk);
        
        $display("\n--- Testing Sequential Instruction Fetch ---");
        
        for (int i = 0; i < 12; i++) begin
            test_instruction_fetch(i * 4, expected_instructions[i], 
                                 $sformatf("Instruction %0d", i));
        end
        
        $display("\n--- Testing Word Alignment ---");
        
        test_instruction_fetch(32'h00000000, expected_instructions[0], "Address 0x00000000");
        test_instruction_fetch(32'h00000001, expected_instructions[0], "Address 0x00000001 (should align to 0x00000000)");
        test_instruction_fetch(32'h00000002, expected_instructions[0], "Address 0x00000002 (should align to 0x00000000)");
        test_instruction_fetch(32'h00000003, expected_instructions[0], "Address 0x00000003 (should align to 0x00000000)");
        
        test_instruction_fetch(32'h00000004, expected_instructions[1], "Address 0x00000004");
        test_instruction_fetch(32'h00000005, expected_instructions[1], "Address 0x00000005 (should align to 0x00000004)");
        test_instruction_fetch(32'h00000006, expected_instructions[1], "Address 0x00000006 (should align to 0x00000004)");
        test_instruction_fetch(32'h00000007, expected_instructions[1], "Address 0x00000007 (should align to 0x00000004)");
        
        $display("\n--- Testing Boundary Conditions ---");
        
        // Test the first address
        test_instruction_fetch(32'h00000000, expected_instructions[0], "First memory location");
        
        // Test an address with NOP
        test_instruction_fetch(32'h00000030, 32'h00000013, "Uninitialized location (should be NOP)");
        
        // Test last memory word
        test_instruction_fetch((MEM_SIZE-1) * 4, 32'h00000013, "Near memory boundary");
        
        $display("\n--- Instruction Decode Examples ---");
        
        // Displays decoded instructions
        display_instruction(expected_instructions[0], "ADDI x1, x0, 5");
        display_instruction(expected_instructions[1], "ADDI x2, x0, 6");
        display_instruction(expected_instructions[2], "ADD x3, x1, x2");
        display_instruction(expected_instructions[3], "SUB x4, x1, x2");
        display_instruction(expected_instructions[8], "SLT x9, x1, x2");
        
        $display("\n--- Testing Clock Edge Behavior ---");
        
        addr = 32'h00000000;
        repeat(2) @(posedge clk);
        $display("Data at address 0x00000000: 0x%08h", data);
        
        // Test case on negative edge clk
        addr = 32'h00000004;
        @(negedge clk)
        $display("Data before clock edge: 0x%08h (should be previous instruction)", data);
        repeat(2) @(posedge clk);
        $display("Data after clock edge: 0x%08h (should be new instruction)", data);
        
        $display("\n--- Performance Test ---");

        $display("Testing rapid sequential instruction fetch:");
        for (int i = 0; i < 8; i++) begin
            addr = i * 4;
            repeat(2) @(posedge clk);
            $display("  PC=0x%08h: Instruction=0x%08h", addr, data);
        end
        
        $display("\n=== Instruction Memory Testbench Completed ===");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t | CLK: %b | ADDR: 0x%08h | DATA: 0x%08h", 
                 $time, clk, addr, data);
    end

endmodule