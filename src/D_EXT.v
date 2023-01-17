module D_EXT (
    input  [15:0] D_EXTIn,
    input  [ 1:0] D_EXTOp,
    output [31:0] D_EXTOut
);


    assign D_EXTOut = (D_EXTOp == 2'b10) ?            {D_EXTIn, 16'h00} : // lui
                      (D_EXTOp == 2'b01) ? {{16{D_EXTIn[15]}}, D_EXTIn} : // sign_ext
                                                  {{16{1'b0}}, D_EXTIn} ; // zero_ext


endmodule
