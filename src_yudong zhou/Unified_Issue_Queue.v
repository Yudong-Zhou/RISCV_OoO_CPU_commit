////////////////////////////////////////////////////////////////////////////////////////////
// Function: module for Unified_Issue_Queue of RISC-V Out-of-Order Processor
//
// Author: Yudong Zhou
//
// Create date: 11/9/2024
//
// RS implementation:
// | vaild | Opeartion | Dest Reg | Src Reg1 | Src1 Ready | Src Reg2 | Src2 Ready | imm | FU# | ROB# |
//                                |  Data from ARF Reg1   |   Data from ARF Reg2  |
////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module Unified_Issue_Queue #(
    parameter   RS_SIZE     =   16,     // RS size  = 16 instructions
    parameter   AR_SIZE     =   7,      // Architectural Register size = 2^7 = 128 registers
    parameter   AR_ARRAY    =   128,    // AR number = 128
    parameter   FU_SIZE     =   2,      // FU size  = 2^2 >= 3 units
    parameter   FU_ARRAY    =   3       // FU number = 3
)(
    input                       clk,
    input                       rstn,   // negedge reset

    // decode info
    input [6 : 0]               opcode_in,
    input [2 : 0]               funct3_in,
    input [6 : 0]               funct7_in,

    // Rename & ARF info
    input [AR_SIZE - 1 : 0]     rs1_in,
    input [31 : 0]              rs1_value_in,
    input [AR_SIZE - 1 : 0]     rs2_in,
    input [31 : 0]              rs2_value_in,
    input [AR_SIZE - 1 : 0]     rd_in,

    // backforth logic judgement
    input [AR_ARRAY - 1 : 0]    rs1_ready_in,   // if reg pi is ready, then rs1_ready_in[i] = 1
    input [AR_ARRAY - 1 : 0]    rs2_ready_in,
    input [FU_ARRAY - 1 : 0]    fu_ready_in,    // if FU NO.i is ready, then fu_ready_in[i] = 1
    
    // output signals
    output reg [AR_SIZE - 1 : 0]        rs1_out1,
    output reg [AR_SIZE - 1 : 0]        rs2_out1,
    output reg [AR_SIZE - 1 : 0]        rd_out1,
    output reg [AR_SIZE - 1 : 0]        rs1_out2,
    output reg [AR_SIZE - 1 : 0]        rs2_out2,
    output reg [AR_SIZE - 1 : 0]        rd_out2,
    output reg [31 : 0]                 rs1_value_out1,
    output reg [31 : 0]                 rs2_value_out1,
    output reg [31 : 0]                 rs1_value_out2,
    output reg [31 : 0]                 rs2_value_out2,
    output reg                          fu_number_out

    output reg                          stall;
);

    /////////////////////////////////////////////////////////////////

    // operation parameter
    parameter ADD   =  4'd1;
    parameter ADDI  =  4'd2;
    parameter LUI   =  4'd3;
    parameter ORI   =  4'd4;
    parameter XOR   =  4'd5;
    parameter SRAI  =  4'd6;
    parameter LB    =  4'd7;
    parameter LW    =  4'd8;
    parameter SB    =  4'd9;
    parameter SW    =  4'd10;

    /////////////////////////////////////////////////////////////////

    // operation info
    reg                         vaild       [RS_SIZE - 1 : 0];
    reg [3 : 0]                 operation   [RS_SIZE - 1 : 0];

    // instruction info
    reg [AR_SIZE - 1 : 0]       dest_reg    [RS_SIZE - 1 : 0];
    reg [AR_SIZE - 1 : 0]       src_reg1    [RS_SIZE - 1 : 0];
    reg                         src1_ready  [RS_SIZE - 1 : 0];
    reg [31 : 0]                src1_data   [RS_SIZE - 1 : 0];
    reg [AR_SIZE - 1 : 0]       src_reg2    [RS_SIZE - 1 : 0];
    reg                         src2_ready  [RS_SIZE - 1 : 0];
    reg [31 : 0]                src2_data   [RS_SIZE - 1 : 0];
    reg [31 : 0]                imm         [RS_SIZE - 1 : 0];
    
    // FU info
    reg [FU_SIZE - 1 : 0]       fu_number   [RS_SIZE - 1 : 0];

    // initializations
    integer i               = 0;
    reg fu_alu_round        = 0;

    //update ready signals
    integer k               = 0; 

    // output logic
    integer j               = 0;
    reg     issue_count     = 0;    
    /////////////////////////////////////////////////////////////////
    
    // operation judgement
    reg [3 : 0] op_type;
    always @(*) begin
        op_type = 5'd0;
        case (opcode_in)
            7'b0110011: begin // R-type
                case (funct3_in)
                    3'b000: op_type = ADD;
                endcase
            end
            7'b0010011: begin // I-type
                case (funct3_in)
                    3'b000: op_type = ADDI;
                    3'b100: op_type = XOR;
                    3'b101: op_type = SRAI;
                    3'b110: op_type = ORI;
                endcase
            end
            7'b0110111: op_type = LUI; // U-type
            7'b0000011: begin // Load
                case (funct3_in)
                    3'b000: op_type = LB;
                    3'b010: op_type = LW;
                endcase
            end
            7'b0100011: begin // Store
                case (funct3_in)
                    3'b000: op_type = SB;
                    3'b010: op_type = SW;
                endcase
            end
        endcase
    end

    // initializations and dispatch
    always @(posedge clk or negedge rstn) begin
        stall <= 1'b0;
        if (!reset) begin
            for (i = 0; i < RS_SIZE; i = i + 1) begin
                valid[i]        <= 'b0;
                operation[i]    <= 'b0;
                dest_reg[i]     <= 'b0;
                src_reg1[i]     <= 'b0;
                src1_data[i]    <= 'b0;
                src_reg2[i]     <= 'b0;
                src2_data[i]    <= 'b0;
                imm[i]          <= 'b0;
                fu_number[i]    <= 'b0;
                src1_ready[i]   <= 'b0;
                src2_ready[i]   <= 'b0;
            end
        end
        else begin
            for (i = 0; i < RS_SIZE; i = i + 1) begin
                if (!valid[i]) begin
                    valid[i]        <= 1'b1;
                    operation[i]    <= op_type;
                    dest_reg[i]     <= rd_in;
                    src_reg1[i]     <= rs1_in;
                    src1_data[i]    <= rs1_value_in;
                    src_reg2[i]     <= rs2_in;
                    src2_data[i]    <= rs2_value_in;
                    imm[i]          <= imm_in;
                    if (op_type == LB || op_type == LW || op_type == SB || op_type == SW) begin
                        fu_number[i]    <= 2'b10;
                    end
                    else begin // round robin
                        fu_number[i]    <=  fu_alu_round;
                        fu_alu_round    <= ~fu_alu_round;
                    end
                    break;
                end
            end
            if (i == RS_SIZE) stall <= 1'b1;
        end
    end

    // update source_ready signals
    always @(posedge clk or negedge rstn) begin
        for (k = 0; k < RS_SIZE; k = k + 1) begin
            if (valid[k]) begin
                if (rs1_ready_in[src_reg1[k]]) begin
                    src1_ready[k] <= 1'b1;
                end
                if (rs2_ready_in[src_reg2[k]]) begin
                    src2_ready[k] <= 1'b1;
                end
            end
        end
    end

    // output signals
    always @(posedge clk or negedge rstn) begin
        for (j = 0; j < RS_SIZE; j = j + 1) begin
            if (vaild[j] && src1_ready[j] && src2_ready[j] && rd_ready[j] && fu_ready_in[fu_number[j]]) begin
                if (issue_count == 0)
                    rs1_out1            <= src_reg1[j];
                    rs2_out1            <= src_reg2[j];
                    rd_out1             <= dest_reg[j];
                    rs1_value_out1      <= src1_data[j];
                    rs2_value_out1      <= src2_data[j];
                    fu_number_out       <= fu_number[j];
                    vaild[j]            <= 1'b0;
                    issue_count         <= 1;
                else if (issue_count == 1)
                    rs1_out2            <= src_reg1[j];
                    rs2_out2            <= src_reg2[j];
                    rd_out2             <= dest_reg[j];
                    rs1_value_out2      <= src1_data[j];
                    rs2_value_out2      <= src2_data[j];
                    fu_number_out       <= fu_number[j];
                    vaild[j]            <= 1'b0;
                    issue_count         <= 0;
                    break;
            end
        end
        if (j == RS_SIZE) stall <= 1'b1;
    end

endmodule