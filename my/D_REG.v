
module D_REG (
    input             clk,
    input             reset,
    input             clr,
    input             en,
    input      [31:0] F_instr,
    input      [31:0] F_pc,
    output [31:0] D_instr,
    output reg [31:0] D_pc,
    output reg [31:0] D_pc8
);

    reg [31:0] instr_save;
    reg instr_saved;

    always @(posedge clk) begin
        if (reset) begin
            instr_save <= 0;
            instr_saved <= 0;
        end else if (en) begin 
            instr_save <= 0;
            instr_saved <= 0;
        end else begin 
            instr_save <= (instr_saved) ? instr_save : F_instr;
            instr_saved <= 1;
        end 
    end

    assign D_instr = (reset) ? 0 : (instr_saved) ? instr_save : F_instr;

    always @(posedge clk) begin
        if (reset) begin
            // D_instr <= 0;
            D_pc    <= (reset) ? 32'h80000000 : 0;
            D_pc8   <= 0;
        end else if (en) begin
            // D_instr <= F_instr;
            D_pc    <= F_pc;
            D_pc8   <= F_pc + 8;
        end
    end




endmodule  //D_reg
