`timescale 1ns / 1ps

`include "const.v"

module E_ALU (
    input loadstore,
    input arch,
    output OvArch,
    output OvDM,

    input  [ 4:0] ALUControl,
    input  [31:0] A,
    input  [31:0] B,
    input  [ 4:0] shamt,
    output        isZero,
    output [31:0] result
);
    wire [31:0] slt   = ($signed(A) < $signed(B));
    wire [31:0] sltu  = {1'b0, A} < {1'b0, B};
    wire [31:0] slti  = ($signed(A) < $signed(B));
    wire [31:0] sltiu = {1'b0, A} < {B[31], B};

    wire [31:0] sra   = $signed($signed(B) >>> shamt);
    wire [31:0] srav  = $signed($signed(B) >>> A[4:0]);

    assign result = (ALUControl == `alu_ADD)    ? A + B :
                    (ALUControl == `alu_SUB)    ? A - B :
                    (ALUControl == `alu_SLT)    ? slt :
                    (ALUControl == `alu_SLTU)   ? sltu :
                    (ALUControl == `alu_SLTI)   ? slti :
                    (ALUControl == `alu_SLTIU)  ? sltiu :

                    (ALUControl == `alu_AND)    ? A & B :
                    (ALUControl == `alu_LUI)    ? B :
                    (ALUControl == `alu_NOR)    ? ~(A | B) :
                    (ALUControl == `alu_OR)     ? A | B :
                    (ALUControl == `alu_XOR)    ? A ^ B :

                    (ALUControl == `alu_SLL)    ? B << shamt  :
                    (ALUControl == `alu_SLLV)   ? B << A[4:0] :
                    (ALUControl == `alu_SRA)    ? sra :
                    (ALUControl == `alu_SRAV)   ? srav :
                    (ALUControl == `alu_SRL)    ? B >> shamt  :
                    (ALUControl == `alu_SRLV)   ? B >> A[4:0] :
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
