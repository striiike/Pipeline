`define beq 2'b00
`define bne 2'b01
`define bbb 2'b10


module D_CMP (
    input  [31:0] cmp1,
    input  [31:0] cmp2,
    output        isBr,
    input  [ 1:0] brOp
);
    assign isBr = (brOp == `beq) ? (cmp1 == cmp2) : 
                  (brOp == `bne) ? (cmp1 != cmp2) :  
                  (brOp == `bbb) ? (cmp1 != cmp2) : 0;
    // only support beq now

endmodule  //CMP
