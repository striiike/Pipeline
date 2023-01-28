
module W_REG (
    input             req,
    input      [31:0] cp0,
    output reg [31:0] cp0out,
    
    input             clk,
    input             reset,
    input             clr,
    input             en,
    input      [31:0] M_instr,
    input      [31:0] M_pc,
    input      [31:0] M_pc8,
    input      [31:0] M_alu,
    input      [31:0] M_RD,
    input      [31:0] M_mdu,
    output reg [31:0] W_instr,
    output reg [31:0] W_pc,
    output reg [31:0] W_pc8,
    output reg [31:0] W_alu,
    output     [31:0] W_RD,
    output reg [31:0] W_mdu
);

    assign W_RD = M_RD;
    always @(posedge clk) begin
        if (reset | req) begin
            W_instr <= 0;
            W_pc    <= req ? 32'hbfc00380 : 0;
            W_pc8   <= 0;
            W_alu   <= 0;
            W_mdu   <= 0;
            cp0out  <= 0;
        end else if (en) begin
            W_instr <= M_instr;
            W_pc    <= M_pc;
            W_pc8   <= M_pc8;
            W_alu   <= M_alu;
            W_mdu   <= M_mdu;
            cp0out  <= cp0;
        end
    end




endmodule  //W_REG
