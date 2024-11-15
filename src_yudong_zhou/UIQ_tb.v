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

    parameter   RS_SIZE     =   16,     // RS size  = 16 instructions
    parameter   AR_SIZE     =   7,      // Architectural Register size = 2^7 = 128 registers
    parameter   AR_ARRAY    =   128,    // AR number = 128
    parameter   FU_SIZE     =   2,      // FU size  = 2^2 >= 3 units
    parameter   FU_ARRAY    =   3       // FU number = 3

    // set up input signals
    reg                         clk;
    reg                         rstn;   // negedge reset

    reg [6 : 0]                 opcode_in;
    reg [2 : 0]                 funct3_in;
    reg [6 : 0]                 funct7_in;

    reg [AR_SIZE - 1 : 0]       rs1_in;
    reg [31 : 0]                rs1_value_in;
    reg [AR_SIZE - 1 : 0]       rs2_in;
    reg [31 : 0]                rs2_value_in;
    reg [31 : 0]                imm_value_in;
    reg [AR_SIZE - 1 : 0]       rd_in;

    reg [AR_ARRAY - 1 : 0]      rs1_ready_in;
    reg [AR_ARRAY - 1 : 0]      rs2_ready_in;
    reg [FU_ARRAY - 1 : 0]      fu_ready_in;

    // set up output signals
    wire [AR_SIZE - 1 : 0]      rs1_out1;
    wire [AR_SIZE - 1 : 0]      rs2_out1;
    wire [AR_SIZE - 1 : 0]      rd_out1;
    wire [AR_SIZE - 1 : 0]      rs1_out2;
    wire [AR_SIZE - 1 : 0]      rs2_out2;
    wire [AR_SIZE - 1 : 0]      rd_out2;
    wire [31 : 0]               rs1_value_out1;
    wire [31 : 0]               rs2_value_out1;
    wire [31 : 0]               rs1_value_out2;
    wire [31 : 0]               rs2_value_out2;
    wire [FU_SIZE - 1 : 0]      fu_number_out1;
    wire [FU_SIZE - 1 : 0]      fu_number_out2;

    wire                        stall;

    // set up the instruction
    wire [31:0] instruction;

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

    Unified_Issue_Queue #(
        .RS_SIZE    (RS_SIZE),
        .AR_SIZE    (AR_SIZE),
        .AR_ARRAY   (AR_ARRAY),
        .FU_SIZE    (FU_SIZE),
        .FU_ARRAY   (FU_ARRAY)
    ) UIQ_inst (
        .clk            (clk),
        .rstn           (rstn),
        .opcode_in      (opcode_in),
        .funct3_in      (funct3_in),
        .funct7_in      (funct7_in),
        .rs1_in         (rs1_in),
        .rs1_value_in   (rs1_value_in),
        .rs2_in         (rs2_in),
        .rs2_value_in   (rs2_value_in),
        .imm_value_in   (imm_value_in),
        .rd_in          (rd_in),
        .rs1_ready_in   (rs1_ready_in),
        .rs2_ready_in   (rs2_ready_in),
        .fu_ready_in    (fu_ready_in),
        
        .rs1_out1       (rs1_out1),
        .rs2_out1       (rs2_out1),
        .rd_out1        (rd_out1),
        .rs1_out2       (rs1_out2),
        .rs2_out2       (rs2_out2),
        .rd_out2        (rd_out2),
        .rs1_value_out1 (rs1_value_out1),
        .rs2_value_out1 (rs2_value_out1),
        .rs1_value_out2 (rs1_value_out2),
        .rs2_value_out2 (rs2_value_out2),
        .fu_number_out1 (fu_number_out1),
        .fu_number_out2 (fu_number_out2),
        .stall          (stall)
    );
    
    // clock source
    initial clk = 1'b1;
    always #(HalfCycle)     Clock =	~Clock;

    initial begin
        
    end

    


endmodule