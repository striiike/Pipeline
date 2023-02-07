`include "const.v"
module D_block (
    input                       clk,
    input                       reset,

    // handshake signal
    input       allowin_next,
    output      allowin,
    input       valid_last,
    output      ready_go,
    output reg     valid,   
    
    input      [31:0] inst_rdata,
    input             inst_addr_ok ,
    input             inst_data_ok ,
   
    // forwarding
    input   [4 :0]              E_SAddr,    // 0 if instruction does not write   
    input   [4 :0]              M_SAddr,
    input   [4 :0]              W_SAddr,    // 0 if instruction does not write
    input   W_fwd_ok,
    input [31:0] W_fwd_data,

    input start,
    input busy,
 

    // data
    input      [31:0]           pc_i,
    output reg [31:0]           pc_o,
    output reg [31:0]           instr_o,
    output     [4:0]            A1_o,
    output     [4:0]            A2_o,
    input      [31:0]           RD1_i,
    output reg [31:0]           RD1_o,
    input      [31:0]           RD2_i,
    output reg [31:0]           RD2_o,
    input      [31:0]           ext_i,
    output reg [31:0]           ext_o,

    output reg                  br_o,
    output reg [31:0]           npc_o,

    // exception 
    input cancel,
    input [31:0] EPC,

    output eret,
    input      [4:0]           exc_i,
    output reg [4:0]           exc_o,
    input      [31:0]           badVAddr_i,
    output reg [31:0]           badVAddr_o,
    input      [31:0]           bd_i,
    output reg [31:0]           bd_o

);
    // done, allowin, valid, ready_go
    
    reg done;
    
    reg [31:0] inst_save;
    reg inst_saved;
    
    always @(posedge clk) if (inst_data_ok && !inst_saved) inst_save <= inst_rdata;
    always @(posedge clk) begin
        if (reset) inst_saved <= 1'b0;
        else if (ready_go && allowin_next) inst_saved <= 1'b0;
        else if (valid_last && inst_data_ok) inst_saved <= 1'b1;
    end
    
    reg cancel_save;
    always @(posedge clk) begin
        if (reset) cancel_save <= 1'b0;
        else if (ready_go && allowin_next) cancel_save <= 1'b0;
        else if (cancel) cancel_save <= 1'b1;
    end


    wire [31:0] inst = inst_saved ? inst_save : (inst_data_ok) ? inst_rdata : 0;
    wire inst_ok = inst_data_ok || inst_saved;


    wire [31:0] D_RD1, D_RD2, D_npc, D_ext, fwd_RD1, fwd_RD2;
    wire [31:0] W_pc;
    wire [4:0] D_rs, D_rt, D_rd;
    wire [15:0] D_imm;
    wire [25:0] D_index;



    wire        W_en_GRF, fwd_stall, mdu_stall;

    wire [ 1:0] D_sel_A3;
    wire [ 1:0] D_sel_EXT;
    wire [ 1:0] D_sel_NPC;
    wire [ 3:0] D_sel_CMP;


    // D-connect
    reg [31:0] pc_in, D_instr, D_BadVAddr;
    reg [4:0] D_ExcCode;

    assign D_rs         = inst[25:21];
    assign D_rt         = inst[20:16];
    assign D_rd         = inst[15:11];
    assign D_imm        = inst[15:0];
    assign D_index      = inst[25:0];


    assign A1_o = D_rs;
    assign A2_o = D_rt;
    

    wire D_instr_mdu;
    // D_CTRL
    CTRL D_CTRL (
        .syscall    (D_Syscall),
        .Break      (D_Break),
        .RI         (D_RI),
        .eret       (D_eret),
        .jump       (D_jump),

        .D_instr_mdu (D_instr_mdu),

        .instr      (inst),
        .D_sel_EXT  (D_sel_EXT),
        .D_sel_NPC  (D_sel_NPC),
        .D_sel_CMP  (D_sel_CMP)
    );
    assign eret = D_eret;
    // D_CTRL
    D_EXT D_EXT (
        .D_EXTIn (D_imm),
        .D_EXTOp (D_sel_EXT),
        .D_EXTOut(D_ext)
    );

    D_CMP D_CMP (
        .cmp1(fwd_RD1),
        .cmp2(fwd_RD2),
        .isBr(isBr),
        .brOp(D_sel_CMP)
    );

    D_NPC D_NPC (
        .eret  (D_eret),
        .EPC   (EPC),
        .sel   (D_sel_NPC),
        .pc    (pc_i),
        .brCtrl(isBr),
        .imm16 ({{16{D_imm[15]}}, D_imm}),
        .imm26 ({pc_i[31:28], D_index, 2'b00}),
        .ra    (fwd_RD1),
        .npc   (D_npc),
        .isNPC (F_sel_npc)
    );

    // hazard
    // assign HMUX_RD1     = (D_rs == E_Addr && E_Addr != 5'b0) ? E_out : 
    //                         (D_rs == M_Addr && M_Addr != 5'b0) ? M_out : D_RD1;
    // assign HMUX_RD2     = (D_rt == E_Addr && E_Addr != 5'b0) ? E_out : 
    //                         (D_rt == M_Addr && M_Addr != 5'b0) ? M_out : D_RD2;

    assign fwd_RD1     = D_rs == W_SAddr && D_rs != 5'd0 ? W_fwd_data : RD1_i;
    assign fwd_RD2     = D_rt == W_SAddr && D_rt != 5'd0 ? W_fwd_data : RD2_i;

    assign fwd_stall = (D_rs == E_SAddr || D_rs == M_SAddr || D_rs == W_SAddr && !W_fwd_ok) && D_rs != 5'd0
                    || (D_rt == E_SAddr || D_rt == M_SAddr || D_rt == W_SAddr && !W_fwd_ok) && D_rt != 5'd0;


    assign mdu_stall = (start || busy) && D_instr_mdu;


    assign ready_go = inst_ok && !fwd_stall && !mdu_stall;

    always @(posedge clk ) begin
        if (reset) begin
            valid <= 0;
            pc_o     <= 32'hbfc00000;
            instr_o  <= 0;
            npc_o    <= 0;
            br_o      <= 0;

            exc_o <= 0;
            badVAddr_o <= 0;
        end
        else if (allowin_next) begin
            valid    <= valid_last && ready_go && !(|exc_i) && !cancel_save;
            pc_o     <= pc_i;
            instr_o  <= (cancel_save) ? 0 : inst;

            RD1_o    <= fwd_RD1;
            RD2_o    <= fwd_RD2;
            ext_o    <= D_ext;

            exc_o    <=  (exc_i)     ? exc_i :
                         (D_Break)   ? 5'd9      :
                         (D_Syscall) ? 5'd8      :
                         (D_RI)      ? 5'd10     : 5'd0;
            badVAddr_o <= badVAddr_i;
            
        end

        if (ready_go) begin
            br_o     <= F_sel_npc && !cancel_save;
            npc_o    <= D_npc;
        end


    end





endmodule