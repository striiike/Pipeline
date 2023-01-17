`define SR CP0reg[12]
`define Cause CP0reg[13]
`define EPC CP0reg[14]
`define PrID CP0reg[15]

`define IM `SR[15:10]           // state interrupt mask
`define EXL `SR[1]              // in exception level
`define IE `SR[0]               // interrupt enable

`define BD `Cause[31]           // branch delay
`define IP `Cause[15:10]        // interrupt pending    hwint 
`define ExcCode `Cause[6:2]     // exccode cause

module CP0 (
    input clk,
    input reset,

    input        WE,
    input [ 4:0] A1,  // read
    input [ 4:0] A2,  // write
    input [31:0] DIn,

    output [31:0] DOut,

    input        BDIn,
    input [31:0] VPC,
    input [ 4:0] ExcCodeIn,
    input [ 5:0] HWInt,
    input        EXLClr,

    output        Req,
    output [31:0] EPCOut
);
    reg     [31:0] CP0reg[0:31];

    integer        i;

    initial begin
        for (i = 0; i < 31; i = i + 1) begin
            CP0reg[i] <= 0;
        end
        `SR    <= 0;
        `EPC   <= 0;
        `Cause <= 0;
        `PrID  <= "h1ccup";
    end

    wire IntReq     = (|(HWInt & `IM)) && `IE && ~`EXL;
    wire ExcCodeReq = (|ExcCodeIn) && ~`EXL;

    assign Req    = IntReq | ExcCodeReq;

    assign DOut   = (A1 >= 12 && A1 <= 15) ? CP0reg[A1] : 0;
    assign EPCOut = `EPC;


    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 31; i = i + 1) begin
                CP0reg[i] <= 0;
            end
            `SR    <= 0;
            `EPC   <= 0;
            `Cause <= 0;
            `PrID  <= "h1ccup";
        end else begin
            `IP <= HWInt;
            if (EXLClr) `EXL <= 1'b0;
            if (WE && (A2 >= 12 && A2 <= 15)) begin
                CP0reg[A2] <= DIn;
            end
            if (Req) begin
                `EPC     <= VPC - (BDIn << 2);             // ((VPC >> 2) - BDIn) >> 2;
                // Cause
                `EXL     <= 1'b1;
                `ExcCode <= IntReq ? 5'b0 : ExcCodeIn;
                `BD      <= BDIn;
            end
        end
    end


endmodule  //CP0
