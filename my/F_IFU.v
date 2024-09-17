`include "const.v"
module F_IFU (
    input         req,
    input         eret,
    input  [31:0] EPC,
    output        AdEL,
    output        F_eret,
    output [31:0] F_BadVAddr,

    input         en,
    input         clk,
    input  [31:0] npc,
    input         rst,
    input  [31:0] i_instr,
    output [31:0] inst_sram_addr,
    output [31:0] pc
);
    reg  [31:0] pcReg;

    assign pc      = pcReg;
    assign F_eret  = i_instr == `op_eret;

    // exception

    // assign AdEL    = (|pc[1:0] || pc > 32'h6ffc || pc < 32'h3000);
    assign AdEL       = |pc[1:0];
    assign F_BadVAddr = (AdEL) ? pc : 0;
    // exception end    

    // assign inst_sram_addr = (rst) ? 32'h00000000 : 
    //                         (req) ? 32'hbfc00380 : 
    //                         (en)  ?    ((F_eret) ? EPC :    npc) : 
                            
    //                                           pc ;

    assign inst_sram_addr = pc;
    always @(posedge clk) begin
        if (rst) begin
            pcReg <= 32'h80000000;
        end else if (en) begin
            pcReg <= npc;
        end;
    end



endmodule
