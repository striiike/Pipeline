module BRIDGE (
    input [31:0] PrAddr,
    input [31:0] PrWD,
    input [ 3:0] PrByteen,

    output [31:2] TCAddr,
    output        TCWE1,
    output        TCWE2,
    output [31:0] TCWD,

    output [ 3:0] IntByteen,
    output [31:0] IntAddr,

    output [ 3:0] DMByteen,
    output [31:0] DMWD,
    output [31:0] DMAddr,

    input [31:0] TCRD1,
    input [31:0] TCRD2,
    input [31:0] DMRD,

    output [31:0] PrRD
);

    assign TCAddr    = PrAddr[31:2];
    assign TCWE1     = (PrAddr >= 32'h7f00 && PrAddr <= 32'h7f0b) && (|PrByteen);
    assign TCWE2     = (PrAddr >= 32'h7f10 && PrAddr <= 32'h7f1b) && (|PrByteen);
    assign TCWD      = (TCWE1 | TCWE2) ? PrWD : 0;

    assign IntByteen = (PrAddr >= 32'h7f20 && PrAddr <= 32'h7f23) ? PrByteen : 0;
    assign IntAddr   = (PrAddr >= 32'h7f20 && PrAddr <= 32'h7f23) ? PrAddr   : 0;

    assign DMByteen  = (PrAddr >= 32'h0000 && PrAddr <= 32'h2fff) ? PrByteen : 0;
    assign DMAddr    = (PrAddr >= 32'h0000 && PrAddr <= 32'h2fff) ? PrAddr   : 0;
    assign DMWD      = (|DMByteen) ? PrWD : 0;

    assign PrRD      = (PrAddr >= 32'h7f00 && PrAddr <= 32'h7f0b) ? TCRD1 :
                       (PrAddr >= 32'h7f10 && PrAddr <= 32'h7f1b) ? TCRD2 :
                       (PrAddr >= 32'h0000 && PrAddr <= 32'h2fff) ? DMRD  : 0;





endmodule  //bridge
