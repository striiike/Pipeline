`include "const.v"
module W_block (
    input                       clk,
    input                       reset,

    // handshake signal
    input        allowin_next,
    output       allowin,
    input        valid_last,
    output       ready_go,
    output reg   valid,   
    

    input   [31:0] data_rdata   ,
    input          data_addr_ok ,
    input          data_data_ok ,  

    // fwd
    output [4:0]    fwd_addr,

    // data
    input      [31:0]           pc_i,
    output     [31:0]           pc_o,
    input      [31:0]           instr_i,
    output reg [31:0]           instr_o,

    input      [31:0]           ext_i,
    input      [31:0]           alu_i,
    input      [31:0]           mdu_i,
    input      [31:0]           cp0_i,
    input      [31:0]           RD_i,

    output     [31:0]           W_Wdata,
    output     [4:0]            W_Addr,
    output                      W_en


);
    // done, allowin, valid, ready_go

    wire [31:0] W_pc8, alu_i, W_ext, W_RD, mdu_i;
    wire [31:0] W_out ;
    wire [4:0] W_rs, W_rt, W_rd, W_SAddr;

    wire [2:0] W_fsel;
    wire [1:0] W_sel_A3;

    wire [2:0] W_sel_ld;
    wire loadstore;
    // w-connect
    assign W_rs = instr_i[25:21];
    assign W_rt = instr_i[20:16];
    assign W_rd = instr_i[15:11];
    // W_CTRLSS
    CTRL W_CTRL (
        .instr   (instr_i),
        .loadstore(loadstore),
        .W_fsel  (W_fsel),
        .W_sel_A3(W_sel_A3),
        .W_en_GRF(W_en_GRF),
        .W_Addr  (W_SAddr),
        .M_sel_ld(W_sel_ld),
        .W_Tnew  (W_Tnew)
    );
    // W_CTRL

    assign fwd_addr = W_SAddr;

    M_LB W_LB (
        .M_sel_ld(W_sel_ld),
        .RD      (data_rdata),
        .addr10  (alu_i[1:0]),
        .RD_real (W_RD)
    );




    assign W_out       = (W_fsel == `w_alu) ? alu_i : 
                         (W_fsel == `w_pc8) ? pc_i + 8 : 
                         (W_fsel == `w_mdu) ? mdu_i :
                         (W_fsel == `w_cp0) ? cp0_i :
                                              W_RD;



    assign ready_go = !loadstore || loadstore && data_data_ok;

    assign W_Addr   =  (W_sel_A3 == `grf_rt) ? W_rt : 
                       (W_sel_A3 == `grf_rd) ? W_rd : 
                       (W_sel_A3 == `grf_ra) ? 5'b11111 : 
                                                5'b00000;
    assign W_Wdata  = W_out;
    assign W_en     = ready_go && valid_last && W_en_GRF;
    assign pc_o     = pc_i;




endmodule