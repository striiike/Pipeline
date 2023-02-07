`include "const.v"
module M_block (
    input                       clk,
    input                       reset,

    // handshake signal
    input       allowin_next,
    output      allowin,
    input       valid_last,
    output      ready_go,
    output reg   valid,   
    

    output         data_req,
    output         data_wr,
    output  [1:0]  data_size,
    output  [31:0] data_addr,
    output  [31:0] data_wdata,
    input   [31:0] data_rdata   ,
    input          data_addr_ok ,
    input          data_data_ok ,        
   
    // fwd
    output [4:0] fwd_addr,

    // data
    input      [31:0]           pc_i,
    output reg [31:0]           pc_o,
    input      [31:0]           instr_i,
    output reg [31:0]           instr_o,
    input      [31:0]           RD1_i,
    output reg [31:0]           RD1_o,
    input      [31:0]           RD2_i,
    output reg [31:0]           RD2_o,
    input      [31:0]           ext_i,
    output reg [31:0]           ext_o,
    input      [31:0]           alu_i,
    output reg [31:0]           alu_o,
    input      [31:0]           mdu_i,
    output reg [31:0]           mdu_o,
    output reg [31:0]           RD_o,
    output reg [31:0]           cp0_o,

    // interrupt
    input [5:0] ext_int,

    // exception 
    output exc_req,
    output [31:0] cp0_EPC,

    input      [4:0]           exc_i,
    output reg [4:0]           exc_o,
    input      [31:0]           badVAddr_i,
    output reg [31:0]           badVAddr_o,
    input      [31:0]           bd_i,
    output reg [31:0]           bd_o

);
    // done, allowin, valid, ready_go

    wire [31:0] M_pc, M_pc8, M_RD1, M_RD2, M_alu, M_ext, M_RD, M_RD_temp, M_mdu,M_cp0;
    wire [4:0] M_rs, M_rt, M_rd, M_Addr;

    wire [ 3:0] byteEn;

    wire [31:0] HMUX_WD,EPC;

    wire [31:0] M_out;

    wire [1:0] M_fsel, M_sel_st;
    wire [2:0] M_sel_ld;

    wire M_loadstore;

    // M-connect

    assign M_rs    = instr_i[25:21];
    assign M_rt    = instr_i[20:16];
    assign M_rd    = instr_i[15:11];

    assign HMUX_WD = /*(M_rt == W_Addr && W_Addr != 5'b0) ? W_out :*/ RD2_i;

    assign M_out   = (M_fsel == `m_fsel_pc8) ? M_pc+8 : 
                     (M_fsel == `m_fsel_alu) ? M_alu : 
                                               M_mdu;

    
    wire jump;
    // M_CTRL
    CTRL M_CTRL (
        .mtc0    (M_mtc0),
        .en_CP0  (en_CP0),
        .eret    (M_eret),
        .loadstore(M_loadstore),
        .jump       (jump),

        .instr   (instr_i),
        .M_fsel  (M_fsel),
        .M_sel_st(M_sel_st),
        .M_sel_ld(M_sel_ld),
        .M_Addr  (M_Addr),
        .M_Tnew  (M_Tnew),
        .M_SAddr (M_SAddr),
        .M_en_DM (M_en_DM)
    );
    // M_CTRL
    
    assign fwd_addr = (valid_last) ? M_SAddr : 0;



    reg req_state;
    always @(posedge clk ) begin
        if (reset) req_state <= 0;
        else if (data_addr_ok && data_req) req_state <= 1;
        else if (data_data_ok) req_state <= 0; 
    end


    assign data_addr   = (valid_last) ? alu_i & 32'h1FFFFFFF : 0;
    
    assign data_wdata  =(valid_last) ?  ((M_sel_st == `m_sw) ? HMUX_WD : 
                         (M_sel_st == `m_sh) ? {2{HMUX_WD[15:0]}} : 
                         (M_sel_st == `m_sb) ? {4{HMUX_WD[7:0]}} : 
                                                     0 ) : 0;
    assign data_wr     =(valid_last) ?  |byteEn && req_state == 0 : 0;
    assign data_req    = (|exccode) ? 0 : 
                         (valid_last) ? M_loadstore && req_state == 0 : 0;



    // assign data_addr   = 0;
    
    // assign data_wdata  =  0 ;
    // assign data_wr     =  0;
    // assign data_req    =  0;


    // assign m_inst_addr   = M_pc;

    M_BE M_BE (
        // .Ov      (M_Ov),
        .addr    (alu_i & 32'h1FFFFFFF),
        .AdES    (M_AdES),
        .AdEL    (M_AdEL),
        .data_size (data_size),

        .M_sel_st(M_sel_st),
        .M_sel_ld(M_sel_ld),
        .addr10  (alu_i[1:0]),
        .byteEn  (byteEn)
    );

    // exception 
    wire [4:0] exccode;
    wire [31:0] badVAddr;
    assign exccode = 
                     (exc_i) ? exc_i :
                     (M_AdEL)    ? 5'd4      : 
                     (M_AdES)    ? 5'd5      : 5'd0;

    assign badVAddr = 
                     (M_AdEL || M_AdES) ? alu_i : 
                                          badVAddr_i;
    assign cp0_EPC = EPC;

    // branch delay slot
    reg prev_branch; // if previous instruction is branch/jump
    always @(posedge clk) begin
        if (reset) prev_branch <= 1'b0;
        else if (valid_last && ready_go && allowin_next) prev_branch <= jump; /*&& !(valid_last);*/
    end


    wire M_bd = prev_branch;
    CP0 CP0(
    
    .clk       (clk),
    .reset     (reset),
    .WE        (en_CP0),
    .A1        (M_rd),
    .A2        (M_rd),
    .DIn       (HMUX_WD),
    .DOut      (M_cp0),
    .BDIn      (M_bd),
    .VPC       (pc_i),
    .BadVAddrIn(badVAddr),
    .ExcCodeIn (exccode),
    .HWInt     (ext_int),
    .EXLClr    (M_eret),
    .Req       (req),
    .EPCOut    (EPC)
    );
    assign exc_req = req;

    assign ready_go = !M_loadstore || M_loadstore && data_addr_ok;

    always @(posedge clk ) begin
        if (reset) begin
            valid <= 0;
            instr_o  <= 0;

            exc_o <= 0;
            badVAddr_o <= 0;
        end
        else if (allowin_next) begin
            valid    <= valid_last && ready_go && !(|exccode);
            pc_o     <= pc_i;
            instr_o  <= instr_i;

            RD1_o    <= RD1_i;
            RD2_o    <= RD2_i;

            ext_o    <= ext_i;
            alu_o    <= alu_i;
            mdu_o    <= mdu_i; 

            cp0_o    <= M_cp0;
        end
    end





endmodule