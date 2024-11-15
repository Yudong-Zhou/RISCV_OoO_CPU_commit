////////////////////////////////////////////////////////////////////////////////////////////
// Function: testbench for Unified_Issue_Queue of RISC-V Out-of-Order Processor
//
// Author: Yudong Zhou
//
// Create date: 11/13/2024
//
////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module UIQ_testbench ();
    // set up parameters
	parameter   ResetValue	    = 2'b00;
	parameter   HalfCycle		= 5;				//Half of the Clock Period is 5 ns
	localparam  Cycle		    = 2 * HalfCycle;	//The length of the entire Clock Period

    parameter   RS_SIZE     =   16;     // RS size  = 16 instructions
    parameter   AR_SIZE     =   7;      // Architectural Register size = 2^7 = 128 registers
    parameter   AR_ARRAY    =   128;    // AR number = 128
    parameter   FU_SIZE     =   2;      // FU size  = 2^2 >= 3 units
    parameter   FU_ARRAY    =   3;      // FU number = 3

    // set up signals
    reg                         clk;
    reg                         rstn;  

    reg [6 : 0]                 opcode_in;
    reg [2 : 0]                 funct3_in;
    reg [6 : 0]                 funct7_in;

    reg [AR_SIZE - 1 : 0]       rs1_in;
    reg [31 : 0]                rs1_value_in;
    reg [AR_SIZE - 1 : 0]       rs2_in;
    reg [31 : 0]                rs2_value_in;
    reg [31 : 0]                imm_value_in;
    reg [AR_SIZE - 1 : 0]       rd_in;

    reg [AR_ARRAY : 0]          rs1_ready_from_ROB_in;
    reg [AR_ARRAY : 0]          rs2_ready_from_ROB_in;

    reg [FU_ARRAY - 1 : 0]      fu_ready_from_FU_in;  
    reg [AR_SIZE - 1 : 0]       reg_tag_from_FU_in;  
    reg [31 : 0]                reg_value_from_FU_in;
    
    wire [AR_SIZE - 1 : 0]      rs1_out1;
    wire [AR_SIZE - 1 : 0]      rs2_out1;
    wire [AR_SIZE - 1 : 0]      rd_out1;
    wire [31 : 0]               rs1_value_out1;
    wire [31 : 0]               rs2_value_out1;
    wire [31 : 0]               imm_value_out1;
    wire [FU_SIZE - 1 : 0]      fu_number_out1; 

    wire [AR_SIZE - 1 : 0]      rs1_out2;
    wire [AR_SIZE - 1 : 0]      rs2_out2;
    wire [AR_SIZE - 1 : 0]      rd_out2;
    wire [31 : 0]               rs1_value_out2;
    wire [31 : 0]               rs2_value_out2;
    wire [31 : 0]               imm_value_out2;
    wire [FU_SIZE - 1 : 0]      fu_number_out2; 

    wire [AR_SIZE - 1 : 0]      rs1_out3;
    wire [AR_SIZE - 1 : 0]      rs2_out3;
    wire [AR_SIZE - 1 : 0]      rd_out3;
    wire [31 : 0]               rs1_value_out3;
    wire [31 : 0]               rs2_value_out3;
    wire [31 : 0]               imm_value_out3;
    wire [FU_SIZE - 1 : 0]      fu_number_out3; 

    wire                        stall_out;

    // set up the instruction
    reg [31:0] instruction;

    /*
    // instantiate the UIQ module
    Decoder decoder_inst (
        .instruction    (instruction),

        .opcode         (opcode_in),
        .funct3         (funct3_in),
        .funct7         (funct7_in),
        .rs1            (rs1_in),
        .rs2            (rs2_in),
        .rd             (rd_in),
        .imm            (imm_value_in)
    );
    */

    Unified_Issue_Queue UIQ_inst (
        .clk                        (clk),
        .rstn                       (rstn),

        .opcode_in                  (opcode_in),
        .funct3_in                  (funct3_in),
        .funct7_in                  (funct7_in),
        .rs1_in                     (rs1_in),
        .rs1_value_in               (rs1_value_in),
        .rs2_in                     (rs2_in),
        .rs2_value_in               (rs2_value_in),
        .imm_value_in               (imm_value_in),
        .rd_in                      (rd_in),
        .rs1_ready_from_ROB_in      (rs1_ready_from_ROB_in),
        .rs2_ready_from_ROB_in      (rs2_ready_from_ROB_in),
        .fu_ready_from_FU_in        (fu_ready_from_FU_in),
        .reg_tag_from_FU_in         (reg_tag_from_FU_in),
        .reg_value_from_FU_in       (reg_value_from_FU_in),

        .rs1_out1                   (rs1_out1),
        .rs2_out1                   (rs2_out1),
        .rd_out1                    (rd_out1),
        .rs1_value_out1             (rs1_value_out1),
        .rs2_value_out1             (rs2_value_out1),
        .imm_value_out1             (imm_value_out1),
        .fu_number_out1             (fu_number_out1),
        .rs1_out2                   (rs1_out2),
        .rs2_out2                   (rs2_out2),
        .rd_out2                    (rd_out2),
        .rs1_value_out2             (rs1_value_out2),
        .rs2_value_out2             (rs2_value_out2),
        .imm_value_out2             (imm_value_out2),
        .fu_number_out2             (fu_number_out2),
        .rs1_out3                   (rs1_out3),
        .rs2_out3                   (rs2_out3),
        .rd_out3                    (rd_out3),
        .rs1_value_out3             (rs1_value_out3),
        .rs2_value_out3             (rs2_value_out3),
        .imm_value_out3             (imm_value_out3),
        .fu_number_out3             (fu_number_out3),
        .stall_out                  (stall_out)
    );
        
    // clock source
    initial clk = 1'b1;
    always #(HalfCycle) clk = ~clk;

    // set up the reset signal
    initial begin
            rstn = 1'b1;
        #1  rstn = 1'b0;
        #1  rstn = 1'b1;
    end

    // set up the instruction
    initial begin
        #Cycle  instruction = 32'h33822200; // add x4,x5,x2
    end
    
    // set up the input signals
    initial begin
        #Cycle begin
            opcode_in               = 7'b0110011;
            funct3_in               = 3'b000;
            funct7_in               = 7'b0000000;
            rs1_in                  = 7'd5;
            rs2_in                  = 7'd2;
            rd_in                   = 7'd4;
            rs1_value_in            = 32'd1;
            rs2_value_in            = 32'd1;
            imm_value_in            = 32'd0;
            rs1_ready_from_ROB_in   = 129'b111111;
            rs2_ready_from_ROB_in   = 129'b111111;
            fu_ready_from_FU_in     = 3'b111;
            reg_tag_from_FU_in      = 7'b0;
            reg_value_from_FU_in    = 32'h0;
        end
    end

    initial #50 $stop;

endmodule