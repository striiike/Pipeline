
module D_REG (
    input             req,
    input      [4:0]  ExcIn,
    output reg [4:0]  ExcOut,
    input             bd,
    output reg        bdout,
    input      [31:0] BadVAddrIn,
    output reg [31:0] BadVAddrOut,   

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

    always @(posedge clk) begin
        if (reset | req) begin
            D_instr <= 0;
            D_pc    <= (reset) ? 32'hbfc00000 : req ? 32'hbfc00380 : 0;
            D_pc8   <= 0;
            ExcOut  <= 0;
            bdout   <= 0;
            BadVAddrOut <= 0;
        end else if (en) begin
            D_instr <= F_instr;
            D_pc    <= F_pc;
            D_pc8   <= F_pc + 8;
            ExcOut  <= ExcIn;
            bdout   <= bd;
            BadVAddrOut <= BadVAddrIn;

        end
    end




endmodule  //D_reg
