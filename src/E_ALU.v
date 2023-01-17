`timescale 1ns / 1ps

`define alu_AND 4'b0000
`define alu_OR 4'b0001
`define alu_ADD 4'b0010
`define alu_SUB 4'b0110
`define alu_SLT 4'b0111
`define alu_LUI 4'b1000
`define alu_SLL 4'b1010
`define alu_SLTU 4'b1011

module E_ALU (
    input loadstore,
    input arch,
    output OvArch,
    output OvDM,

    input  [ 3:0] ALUControl,
    input  [31:0] A,
    input  [31:0] B,
    input  [ 4:0] shamt,
    output        isZero,
    output [31:0] result
);
    wire [31:0] slt = ($signed(A) < $signed(B));

    assign result = (ALUControl == `alu_AND) ? A & B :
                    (ALUControl == `alu_OR) ? A | B :
                    (ALUControl == `alu_SUB) ? A - B :
                    (ALUControl == `alu_ADD) ? A + B :
                    (ALUControl == `alu_SLT) ? slt :
                    (ALUControl == `alu_LUI) ? B :
                    (ALUControl == `alu_SLL) ? B << shamt : 
                    (ALUControl == `alu_SLTU) ? (A < B) : 
                    0;

    wire [32:0] tempA = {A[31], A};
    wire [32:0] tempB = {B[31], B};
    wire [32:0] overadd = tempA + tempB, oversub = tempA - tempB;
    
    assign OvArch = arch && (
                        (ALUControl == `alu_ADD && overadd[31] != overadd[32])
                     || (ALUControl == `alu_SUB && oversub[31] != oversub[32]));

    assign OvDM = loadstore && (
                        (ALUControl == `alu_ADD && overadd[31] != overadd[32])
                     || (ALUControl == `alu_SUB && oversub[31] != oversub[32]));



endmodule
