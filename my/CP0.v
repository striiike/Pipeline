`define BadVAddr CP0reg[8]
`define Count    CP0reg[9]
`define Compare  CP0reg[11]
`define SR       CP0reg[12]
`define Cause    CP0reg[13]
`define EPC      CP0reg[14]
`define PrID     CP0reg[15]

`define Bev     `SR[22]
`define IM      `SR[15:8]            // state interrupt mask
`define EXL     `SR[1]               // in exception level
`define IE      `SR[0]               // interrupt enable

`define BD      `Cause[31]           // branch delay
`define TI      `Cause[30]           // timer interrupt
`define IP      `Cause[15:8]        // interrupt pending    hwint & swint
`define ExcCode `Cause[6:2]          // exccode cause

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
    input [31:0] BadVAddrIn,
    input [ 4:0] ExcCodeIn,
    input [ 5:0] HWInt,
    input        EXLClr,    // eret

    output        Req,
    output [31:0] EPCOut
);
    reg     [31:0] CP0reg[0:31];

    reg     halfClk;

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

    wire [7:0] Intsrc = {HWInt[5] | `TI, HWInt[4:0], `Cause[9:8]};
    wire IntReq     = (|(Intsrc & `IM)) && `IE && ~`EXL;
    wire ExcCodeReq = (|ExcCodeIn) && ~`EXL;

    assign Req    = IntReq | ExcCodeReq;
    // assign Req = 0;



    assign DOut   = (A1 >= 8 && A1 <= 15) ? CP0reg[A1] : 0;
    assign EPCOut = `EPC;


    always @(posedge clk) begin
        if (reset) begin
            `SR[31:23] <= 0;
            `SR[22]    <= 1;
            `SR[21:16] <= 0;
            `SR[7:0]   <= 0;
            `Cause <= 0;
            `PrID  <= "h1ccup";
        end else begin
            `IP <= Intsrc;
            if (EXLClr) `EXL <= 1'b0;
            if (WE && (A2 >= 5'd8 && A2 <= 5'd15)) begin
                if (A2 == 5'd9)  `Count   <= DIn;
                if (A2 == 5'd11) `Compare <= DIn;
                if (A2 == 5'd12) begin
                    `SR[15:8] <= DIn[15:8];
                    `SR[ 1:0] <= DIn[1:0];                   
                end
                if (A2 == 5'd13) begin
                    `Cause[9:8] <= DIn[9:8];    
                end
                if (A2 == 5'd14) `EPC  <= DIn;
                if (A2 == 5'd15) `PrID <= DIn;
                
            end
            if (Req) begin
                `EPC     <= VPC - (BDIn << 2);             
                `BadVAddr <= BadVAddrIn;
                // Cause
                `EXL     <= 1'b1;
                `ExcCode <= IntReq ? 5'b0 : ExcCodeIn;
                `BD      <= BDIn;
            end
            // timer
            if (`Count == `Compare && `Compare != 32'd0) begin   // 存疑
                `TI <= 1;
            end else begin
                `TI <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            `Compare <= 0;
            halfClk  <= 0;
        end
        else begin
            `Count <= `Count + (halfClk == 1);
            halfClk <= (halfClk == 0) ? 1 : 0;
        end

    end


endmodule  //CP0
