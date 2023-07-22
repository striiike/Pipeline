

module E_REG (

    input             clk,
    input             reset,
    input             clr,
    input             en,
    input      [31:0] D_instr,
    input      [31:0] D_pc,
    input      [31:0] D_pc8,
    input      [31:0] D_ext,
    input      [31:0] D_RD1,
    input      [31:0] D_RD2,
    output reg [31:0] E_instr,
    output reg [31:0] E_pc,
    output reg [31:0] E_pc8,
    output reg [31:0] E_ext,
    output reg [31:0] E_RD1,
    output reg [31:0] E_RD2
);


    always @(posedge clk) begin
        if (reset || (clr && en)) begin


            E_instr <= 0;
            E_pc    <= (reset) ? 32'h80000000 : (clr) ? D_pc : 0;
            E_pc8   <= (reset) ? 32'h80000000 : (clr) ? D_pc8 : 0;
            E_ext   <= 0;
            E_RD1   <= 0;
            E_RD2   <= 0;

        end else if (en) begin
            E_instr <= D_instr;
            E_pc    <= D_pc;
            E_pc8   <= D_pc8;
            E_ext   <= D_ext;
            E_RD1   <= D_RD1;
            E_RD2   <= D_RD2;

        end
    end




endmodule  //E_REG
