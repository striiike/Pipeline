
module D_REG (
    input            req,
    input      [4:0] ExcIn,
    output reg [4:0] ExcOut,
    input            bd,
    output reg       bdout,

    input             clk,
    input             reset,
    input             clr,
    input             en,
    input      [31:0] F_instr,
    input      [31:0] F_pc,
    output reg [31:0] D_instr,
    output reg [31:0] D_pc,
    output reg [31:0] D_pc8
);

    initial begin
        D_instr = 0;
        D_pc    = 0;
        D_pc8   = 0;
        ExcOut  = 0;
        bdout   = 0;
    end


    always @(posedge clk) begin
        if (reset | req) begin
            D_instr <= 0;
            D_pc    <= (reset) ? 32'h3000 : req ? 32'h4180 : 0;
            D_pc8   <= 0;
            ExcOut  <= 0;
            bdout   <= 0;
        end else if (en) begin
            D_instr <= F_instr;
            D_pc    <= F_pc;
            D_pc8   <= F_pc + 8;
            ExcOut  <= ExcIn;
            bdout   <= bd;
        end
    end




endmodule  //D_reg
