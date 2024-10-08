module M_REG (

    input             clk,
    input             reset,
    input             clr,
    input             en,
    input      [31:0] E_instr,
    input      [31:0] E_pc,
    input      [31:0] E_pc8,
    input      [31:0] E_ext,
    input      [31:0] E_RD1,
    input      [31:0] E_RD2,
    input      [31:0] E_alu,
    input      [31:0] E_mdu,
    output reg [31:0] M_instr,
    output reg [31:0] M_pc,
    output reg [31:0] M_pc8,
    output reg [31:0] M_ext,
    output reg [31:0] M_RD1,
    output reg [31:0] M_RD2,
    output reg [31:0] M_alu,
    output reg [31:0] M_mdu
);

    always @(posedge clk) begin
        if (reset || (clr && en)) begin
            M_instr <= 0;
            M_pc    <= (reset) ? 32'hbfc00000 : 0;
            M_pc8   <= 0;
            M_ext   <= 0;
            M_RD1   <= 0;
            M_RD2   <= 0;
            M_alu   <= 0;
            M_mdu   <= 0;

        end else if (en) begin
            M_instr <= E_instr;
            M_pc    <= E_pc;
            M_pc8   <= E_pc8;
            M_ext   <= E_ext;
            M_RD1   <= E_RD1;
            M_RD2   <= E_RD2;
            M_alu   <= E_alu;
            M_mdu   <= E_mdu;

        end
    end




endmodule  //M_REG
