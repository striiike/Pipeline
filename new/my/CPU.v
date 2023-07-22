`include "const.v"

module cpu (
    input         clk,
    input         resetn,
    input  [5:0]  ext_int,

    input         req_inst,
    input         req_data,

    input  [31:0] inst_sram_rdata,
    output [31:0] inst_sram_addr,

    output        inst_sram_en,
    output [3:0]  inst_sram_wen,
    output [31:0] inst_sram_wdata,


    input  [31:0] data_sram_rdata,    
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    output [ 3:0] data_sram_wen,
    output        data_sram_en,

    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output [31:0] debug_wb_pc
);

    assign inst_sram_en = 1;
    assign inst_sram_wen = 0;
    assign inst_sram_wdata = 32'b0;

    // assign macroscopic_pc = M_pc;
    wire stall_inst; 

    wire [31:0] D_Tuse_rs, D_Tuse_rt, E_Tnew, M_Tnew, W_Tnew;

    wire D_stall_rs_E, D_stall_rs_M, D_stall_rt_E, D_stall_rt_M, D_stall_rt, D_stall_rs;
    wire D_stall, D_stall_mdu, D_stall_mdu_E, D_stall_mdu_M, D_instr_mdu, busy, start;

    wire [4:0] E_SAddr, M_SAddr;
    
    wire en;
    assign en = 1'b1;

    // -------- F-Stage --------
    // F-wire
    wire [31:0] F_pc, F_instr;
    wire [31:0] MUX_npc;

    wire        F_sel_npc;

    // F-connect
    assign MUX_npc     = (F_sel_npc == `f_npc) ? D_npc : F_pc + 4;

    assign F_instr = inst_sram_rdata;

    F_IFU F_IFU (

        .i_instr  (inst_sram_rdata),
        .inst_sram_addr (inst_sram_addr),
        .en     (~D_stall),
        .clk    (clk),
        .npc    (MUX_npc),
        .rst    (~resetn),
        .pc     (F_pc)
    );

    // -------- D-Stage --------
    // D-wire
    wire [31:0] D_pc, D_pc8, D_instr, D_RD1, D_RD2, D_npc, D_ext;
    wire [31:0] W_pc;
    wire [4:0] D_rs, D_rt, D_rd;
    wire [15:0] D_imm;
    wire [25:0] D_index;

    wire [31:0] MUX_ext;
    wire [31:0] HMUX_RD1;
    wire [31:0] HMUX_RD2;
    wire [ 4:0] MUX_A3;
    wire [31:0] W_out;

    wire        W_en_GRF;

    wire [ 1:0] D_sel_A3;
    wire [ 1:0] D_sel_EXT;
    wire [ 1:0] D_sel_NPC;
    wire [ 3:0] D_sel_CMP;


    D_REG D_REG (
        .clk    (clk),
        .reset  (~resetn),
        .clr    (clr),
        .en     (~D_stall),
        .F_instr(F_instr),
        .F_pc   (F_pc),
        .D_instr(D_instr),
        .D_pc   (D_pc),
        .D_pc8  (D_pc8)
    );

    // D-connect
    assign D_rs         = D_instr[25:21];
    assign D_rt         = D_instr[20:16];
    assign D_rd         = D_instr[15:11];
    assign D_imm        = D_instr[15:0];
    assign D_index      = D_instr[25:0];

    assign MUX_A3       = (W_sel_A3 == `grf_rt) ? W_rt : (W_sel_A3 == `grf_rd) ? W_rd : (W_sel_A3 == `grf_ra) ? 5'b11111 : 5'b00000;

    // hazard
    assign HMUX_RD1     = (D_rs == E_Addr && E_Addr != 5'b0) ? E_out : (D_rs == M_Addr && M_Addr != 5'b0) ? M_out : D_RD1;
    assign HMUX_RD2     = (D_rt == E_Addr && E_Addr != 5'b0) ? E_out : (D_rt == M_Addr && M_Addr != 5'b0) ? M_out : D_RD2;

    // stall
    assign D_stall_rs_E = (E_SAddr != 5'b0 && D_rs == E_SAddr) && (E_Tnew > D_Tuse_rs);
    assign D_stall_rs_M = (M_SAddr != 5'b0 && D_rs == M_SAddr) && (M_Tnew > D_Tuse_rs);

    assign D_stall_rs   = D_stall_rs_E | D_stall_rs_M;

    assign D_stall_rt_E = (E_SAddr != 5'b0 && D_rt == E_SAddr) && (E_Tnew > D_Tuse_rt);
    assign D_stall_rt_M = (M_SAddr != 5'b0 && D_rt == M_SAddr) && (M_Tnew > D_Tuse_rt);

    assign D_stall_rt   = D_stall_rt_E | D_stall_rt_M;

    // assign D_stall_mdu  = (busy || start) && D_instr_mdu;
    // assign D_stall_mdu_E = (busy || start) && (E_SAddr != 5'b0 && D_rt == E_SAddr);
    // assign D_stall_mdu_M = (busy || start) && (M_SAddr != 5'b0 && D_rt == M_SAddr);
    // assign D_stall_mdu = D_stall_mdu_E | D_stall_mdu_M;
    assign D_stall_mdu = busy || start;
    // wire D_stall_eret = (F_eret || D_eret) & ((E_mtc0 & (E_rd == 5'd14)) || (M_mtc0 & (M_rd == 5'd14)));
    assign D_stall      = D_stall_rs | D_stall_rt | D_stall_mdu | stall_inst | req_inst | req_data;


    // D_CTRL
    CTRL D_CTRL (
        .instr      (D_instr),
        .D_sel_EXT  (D_sel_EXT),
        .D_sel_NPC  (D_sel_NPC),
        .D_sel_CMP  (D_sel_CMP),
        .D_Tuse_rs  (D_Tuse_rs),
        .D_Tuse_rt  (D_Tuse_rt),
        .D_instr_mdu(D_instr_mdu)
    );
    // D_CTRL

    D_GRF D_GRF (
        .instr(F_instr),
        .pc   (W_pc),
        .clk  (clk),
        .rst  (~resetn),
        .A1   (D_rs),
        .A2   (D_rt),
        .A3   (MUX_A3),
        .WE   (W_en_GRF),
        .WD3  (W_out),
        .RD1  (D_RD1),
        .RD2  (D_RD2)
    );

    D_EXT D_EXT (
        .D_EXTIn (D_imm),
        .D_EXTOp (D_sel_EXT),
        .D_EXTOut(D_ext)
    );

    D_CMP D_CMP (
        .cmp1(HMUX_RD1),
        .cmp2(HMUX_RD2),
        .isBr(isBr),
        .brOp(D_sel_CMP)
    );

    D_NPC D_NPC (
        .sel   (D_sel_NPC),
        .pc    (D_pc),
        .brCtrl(isBr),
        .imm16 ({{16{D_imm[15]}}, D_imm}),
        .imm26 ({D_pc[31:28], D_index, 2'b00}),
        .ra    (HMUX_RD1),
        .npc   (D_npc),
        .isNPC (F_sel_npc)
    );
    // -------- E-Stage --------

    // E-wire
    wire [31:0] E_pc, E_pc8, E_instr, E_RD1, E_RD2, E_alu, E_ext, E_mdu;
    wire [4:0] E_shamt;
    wire [4:0] E_rs, E_rt, E_rd, E_Addr;

    wire [31:0] HMUX_srcA;
    wire [31:0] HMUX_srcB;
    wire [31:0] MUX_srcB;
    wire [31:0] E_out;

    wire loadstore;
    wire arch;
    wire E_load;

    wire [3:0] E_sel_MDU;
    wire [4:0] E_sel_ALU;
    wire E_sel_srcB;
    wire E_fsel;
    E_REG E_REG (

        .clk    (clk),
        .reset  (~resetn),
        .clr    (D_stall),
        .en     (!req_data),
        .D_instr(D_instr),
        .D_pc   (D_pc),
        .D_pc8  (D_pc8),
        .D_ext  (D_ext),
        .D_RD1  (HMUX_RD1),
        .D_RD2  (HMUX_RD2),
        .E_instr(E_instr),
        .E_pc   (E_pc),
        .E_pc8  (E_pc8),
        .E_ext  (E_ext),
        .E_RD1  (E_RD1),
        .E_RD2  (E_RD2)
    );

    // E-connect
    assign E_rs      = E_instr[25:21];
    assign E_rt      = E_instr[20:16];
    assign E_rd      = E_instr[15:11];

    assign HMUX_srcA = (E_rs == M_Addr && M_Addr != 5'b0) ? M_out : 
                       (E_rs == W_Addr && W_Addr != 5'b0) ? W_out : E_RD1;
    assign HMUX_srcB = (E_rt == M_Addr && M_Addr != 5'b0) ? M_out : 
                       (E_rt == W_Addr && W_Addr != 5'b0) ? W_out : E_RD2;

    assign MUX_srcB  = (E_sel_srcB == `e_rd2) ? HMUX_srcB : E_ext;

    assign E_out     = (E_fsel == `e_fsel_pc8) ? E_pc8 : E_ext;

    assign E_shamt   = E_instr[10:6];

    // E_CTRL
    CTRL E_CTRL (
        .instr     (E_instr),
        .E_sel_ALU (E_sel_ALU),
        .E_fsel    (E_fsel),
        .E_sel_srcB(E_sel_srcB),
        .E_Addr    (E_Addr),
        .E_Tnew    (E_Tnew),
        .E_SAddr   (E_SAddr),
        .E_sel_MDU (E_sel_MDU)
    );
    // E_CTRL

    E_ALU E_ALU (

        .loadstore(loadstore),
        .arch     (arch),
        .OvArch   (E_OvArch),
        .OvDM     (E_OvDM),

        .ALUControl(E_sel_ALU),
        .A         (HMUX_srcA),
        .B         (MUX_srcB),
        .shamt     (E_shamt),
        .result    (E_alu)
    );

    // assign start = E_sel_MDU == `mdu_mul;
    reg [31:0] E_inst_save;
    reg [31:0] E_pc_save;
    always @(posedge clk) begin
        if (~resetn) begin
            E_inst_save <= 0;
            E_pc_save   <= 0;
        end else if (start) begin
            E_inst_save <= E_instr;
            E_pc_save   <= E_pc;
        end
    end

    E_MDU E_MDU (
        // .req      (req),
        .clk      (clk),
        .reset    (~resetn),
        .A        (HMUX_srcA),
        .B        (HMUX_srcB),
        .E_sel_MDU(E_sel_MDU),
        .E_mdu    (E_mdu),
        .busy     (busy),
        .start    (start),
        .done     (done)
    );


    // -------- M-Stage --------
    // M-wire
    wire [31:0] M_pc, M_pc8, M_instr, M_RD1, M_RD2, M_alu, M_ext, M_RD, M_RD_temp, M_mdu;
    wire [4:0] M_rs, M_rt, M_rd, M_Addr;

    wire [ 3:0] byteEn;

    wire [31:0] HMUX_WD;

    wire [31:0] M_out;

    wire [1:0] M_fsel, M_sel_st;
    wire [2:0] M_sel_ld;

    wire M_loadstore;


    M_REG M_REG (
        
        .clk    (clk),
        .reset  (~resetn),
        .clr    ((start)),
        .en     (!req_data),
        .E_instr((done) ? E_inst_save : E_instr),
        .E_pc   ((done) ? E_pc_save : E_pc),
        .E_pc8  (E_pc8),
        .E_ext  (E_ext),
        .E_RD1  (HMUX_srcA),
        .E_RD2  (HMUX_srcB),
        .E_alu  (E_alu),
        .E_mdu  (E_mdu),
        .M_instr(M_instr),
        .M_pc   (M_pc),
        .M_pc8  (M_pc8),
        .M_ext  (M_ext),
        .M_RD1  (M_RD1),
        .M_RD2  (M_RD2),
        .M_alu  (M_alu),
        .M_mdu  (M_mdu)
    );

    // M-connect

    assign M_rs    = M_instr[25:21];
    assign M_rt    = M_instr[20:16];
    assign M_rd    = M_instr[15:11];

    assign HMUX_WD = (M_rt == W_Addr && W_Addr != 5'b0) ? W_out : M_RD2;

    assign M_out   = (M_fsel == `m_fsel_pc8) ? M_pc + 8 : 
                     (M_fsel == `m_fsel_alu) ? M_alu : 
                     M_mdu;

    // M_CTRL
    CTRL M_CTRL (
        .load(M_load),

        .instr   (M_instr),
        .M_fsel  (M_fsel),
        .M_sel_st(M_sel_st),
        .M_sel_ld(M_sel_ld),
        .M_Addr  (M_Addr),
        .M_Tnew  (M_Tnew),
        .M_SAddr (M_SAddr),
        .M_en_DM (M_en_DM)
    );
    // M_CTRL

    assign data_sram_addr = M_alu;
    wire debug = ((M_alu & 32'hffc00000) == 32'h80000000);
    assign stall_inst = ((M_alu & 32'hffc00000) == 32'h80000000) && data_sram_en;
    
    assign data_sram_wdata  = (M_sel_st == `m_sw) ? HMUX_WD : 
                              (M_sel_st == `m_sh) ? {2{HMUX_WD[15:0]}} : 
                              (M_sel_st == `m_sb) ? {4{HMUX_WD[7:0]}} : 
                                                    0;
    assign data_sram_wen = (M_load) ? 4'b0000 : byteEn;
    assign data_sram_en  = |byteEn || M_load;
    // assign m_inst_addr   = M_pc;

    M_BE M_BE (
        .Ov      (M_Ov),
        .addr    (M_alu),
        .AdES    (M_AdES),
        .AdEL    (M_AdEL),

        .M_sel_st(M_sel_st),
        .M_sel_ld(M_sel_ld),
        .addr10  (M_alu[1:0]),
        .byteEn  (byteEn)
    );

    assign EPC = 0;
    assign M_cp0 = 0;
    assign req = 0;

    // CP0 CP0(
    // .clk       (clk),
    // .reset     (~resetn),
    // .WE        (en_CP0),
    // .A1        (M_rd),
    // .A2        (M_rd),
    // .DIn       (HMUX_WD),
    // .DOut      (M_cp0),
    // .BDIn      (M_bd),
    // .VPC       (M_pc),
    // .BadVAddrIn(M_BadVAddr_new),
    // .ExcCodeIn (M_ExcCode_new),
    // .HWInt     (int),
    // .EXLClr    (M_eret),
    // .Req       (req),
    // .EPCOut    (EPC)
    // );


    // -------- W-Stage --------
    // W-wire
    wire [31:0] W_pc8, W_instr, W_alu, W_ext, W_RD, W_mdu;

    wire [4:0] W_Addr;
    wire [4:0] W_rs, W_rt, W_rd;

    wire [2:0] W_fsel;
    wire [1:0] W_sel_A3;

    wire [2:0] W_sel_ld;

    W_REG W_REG (

        .clk    (clk),
        .reset  (~resetn),
        .clr    (clr),
        .en     (!req_data),
        .M_instr(M_instr),
        .M_pc   (M_pc),
        .M_pc8  (M_pc8),
        .M_alu  (M_alu),
        .M_RD   (data_sram_rdata),
        .M_mdu  (M_mdu),
        .W_instr(W_instr),
        .W_pc   (W_pc),
        .W_pc8  (W_pc8),
        .W_alu  (W_alu),
        .W_RD   (M_RD),
        .W_mdu  (W_mdu)
    );

    // w-connect
    assign W_rs = W_instr[25:21];
    assign W_rt = W_instr[20:16];
    assign W_rd = W_instr[15:11];
    // W_CTRLSS
    CTRL W_CTRL (
        .instr   (W_instr),
        .W_fsel  (W_fsel),
        .W_sel_A3(W_sel_A3),
        .W_en_GRF(W_en_GRF),
        .W_Addr  (W_Addr),
        .M_sel_ld(W_sel_ld),
        .W_Tnew  (W_Tnew)
    );
    // W_CTRL

    M_LB M_LB (

        .addr    (W_alu & 32'h1FFFFFFF),
        .M_sel_ld(W_sel_ld),
        .RD      (M_RD),
        .addr10  (W_alu[1:0]),
        .RD_real (W_RD)
    );


    assign debug_wb_rf_wen   = (W_en_GRF) ? 4'b1111 : 0;
    assign debug_wb_rf_wnum  = MUX_A3;
    assign debug_wb_rf_wdata = W_out;
    assign debug_wb_pc       = W_pc;

    always @(posedge clk) begin
        if (W_en_GRF && MUX_A3 != 0) begin
            $display("@%h: $%d <= %h", W_pc, MUX_A3, W_out);
        end
    end

    assign W_out       = (W_fsel == `w_alu) ? W_alu : 
                         (W_fsel == `w_pc8) ? W_pc + 8 : 
                         (W_fsel == `w_mdu) ? W_mdu :
                        //  (W_fsel == `w_cp0) ? W_cp0 :
                                              W_RD;

endmodule  //mips

