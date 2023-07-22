`include "const.v"

module D_CMP (
    input  [31:0] cmp1,
    input  [31:0] cmp2,
    output        isBr,
    input  [ 3:0] brOp
);

    wire gez = $signed(cmp1) >= 0;
    wire gtz = $signed(cmp1) > 0;
    wire lez = $signed(cmp1) <= 0;
    wire ltz = $signed(cmp1) < 0;

    assign isBr = (brOp == `cmp_beq)    ? (cmp1 == cmp2) : 
                  (brOp == `cmp_bne)    ? (cmp1 != cmp2) :  
                  (brOp == `cmp_bgez)   ? gez :  
                  (brOp == `cmp_bgtz)   ? gtz :  
                  (brOp == `cmp_blez)   ? lez :  
                  (brOp == `cmp_bltz)   ? ltz :  
                  (brOp == `cmp_bltzal) ? ltz : 
                  (brOp == `cmp_bgezal) ? gez : 0;


endmodule  //CMP
