`include "const.v"
// F
// MUX_npc
`define f_pc4 1'b0
`define f_npc 1'b1

// E
// MUX_srcB
`define e_rd2 1'b0
`define e_ext 1'b1

// W
// MUX_WD3
`define w_rd 3'b000
`define w_alu 3'b001
`define w_pc8 3'b010
`define w_mdu 3'b011
`define w_cp0 3'b100

`define grf_rt 2'b00
`define grf_rd 2'b01
`define grf_ra 2'b10

`define ext_zero 2'b00
`define ext_sign 2'b01
`define ext_lui 2'b10


`define e_fsel_pc8 2'b01
`define e_fsel_ext 2'b00

`define m_fsel_mdu 2'b10
`define m_fsel_pc8 2'b01
`define m_fsel_alu 2'b00

`define m_sw 2'b00
`define m_sh 2'b01
`define m_sb 2'b10

module mycpu_top (
    input         clk,
    input         resetn,
    input  [5:0]  ext_int,

    // output [31:0] macroscopic_pc,   
    // output [31:0] m_inst_addr,

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
    wire [31:0] D_Tuse_rs, D_Tuse_rt, E_Tnew, M_Tnew, W_Tnew;

    wire D_stall_rs_E, D_stall_rs_M, D_stall_rt_E, D_stall_rt_M, D_stall_rt, D_stall_rs;
    wire D_stall, D_stall_mdu, D_instr_mdu, busy, start;

    wire [4:0] E_SAddr, M_SAddr;

    wire D_Syscall, D_Break, E_OvArch, E_OvDM;
    wire F_eret, D_eret, E_eret, M_eret;
    wire [31:0] M_cp0, W_cp0, EPC, F_BadVAddr, D_BadVAddr, E_BadVAddr, M_BadVAddr;
    wire [31:0] M_BadVAddr_new;
    wire F_bd, D_bd, E_bd, M_bd;
    wire E_mtc0, M_mtc0;
    wire M_AdEL, M_AdES;
    
    wire en;
    assign en = 1'b1;

    wire [4:0] F_ExcCode, D_ExcCode, E_ExcCode, M_ExcCode;
    wire [4:0] D_ExcCode_new, E_ExcCode_new, M_ExcCode_new;

    /// exception
    assign F_ExcCode = (F_AdEL) ? 5'd4 : 5'd0;

    assign D_ExcCode_new = (D_ExcCode) ? D_ExcCode :
                           (D_Break)   ? 5'd9      :
                           (D_Syscall) ? 5'd8      :
                           (D_RI)      ? 5'd10     : 5'd0;

    assign E_ExcCode_new = (E_ExcCode) ? E_ExcCode :
                           (E_OvArch)  ? 5'd12     : 5'd0;

    assign M_ExcCode_new = (M_ExcCode) ? M_ExcCode :
                           (M_AdEL)    ? 5'd4      : 
                           (M_AdES)    ? 5'd5      : 5'd0;

    assign M_BadVAddr_new = (M_AdEL || M_AdES) ? M_alu : M_BadVAddr;

    /// exception end

    // -------- F-Stage --------
    // F-wire
    wire [31:0] F_pc, F_instr;
    wire [31:0] MUX_npc;

    wire        F_sel_npc, F_AdEL;

    // F-connect
    assign MUX_npc     = (F_sel_npc == `f_npc) ? D_npc : F_pc + 4;

    assign F_instr = (F_AdEL) ? 0 : inst_sram_rdata;
    assign F_bd = D_jump; 
    F_IFU F_IFU (
        .req    (req),
        .eret   (D_eret),
        .EPC    (EPC),
        .AdEL   (F_AdEL),
        .F_eret   (F_eret),
        .F_BadVAddr (F_BadVAddr),

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
        .req    (req),
        .ExcIn  (F_ExcCode),
        .ExcOut (D_ExcCode),
        .bd     (F_bd),
        .bdout  (D_bd),
        .BadVAddrIn(F_BadVAddr),
        .BadVAddrOut(D_BadVAddr),

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

    assign D_stall_mdu  = (busy || start) && D_instr_mdu;
    wire D_stall_eret = (F_eret || D_eret) & ((E_mtc0 & (E_rd == 5'd14)) || (M_mtc0 & (M_rd == 5'd14)));
    assign D_stall      = D_stall_rs | D_stall_rt | D_stall_mdu | D_stall_eret;


    // D_CTRL
    CTRL D_CTRL (
        .syscall    (D_Syscall),
        .Break      (D_Break),
        .RI         (D_RI),
        .eret       (D_eret),
        .jump       (D_jump),

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
        .req    (req),
        .ExcIn  (D_ExcCode_new),
        .ExcOut (E_ExcCode),
        .bd     (D_bd),
        .bdout  (E_bd),
        .BadVAddrIn(D_BadVAddr),
        .BadVAddrOut(E_BadVAddr),

        .clk    (clk),
        .reset  (~resetn),
        .clr    (D_stall),
        .en     (en),
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
        .mtc0     (E_mtc0),
        .loadstore(loadstore),
        .arch     (arch),

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

    E_MDU E_MDU (
        .req      (req),
        .clk      (clk),
        .reset    (~resetn),
        .A        (HMUX_srcA),
        .B        (HMUX_srcB),
        .E_sel_MDU(E_sel_MDU),
        .E_mdu    (E_mdu),
        .busy     (busy),
        .start    (start)
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

        .req    (req),
        .ExcIn  (E_ExcCode_new),
        .ExcOut (M_ExcCode),
        .bd     (E_bd),
        .bdout  (M_bd),        
        .BadVAddrIn(E_BadVAddr),
        .BadVAddrOut(M_BadVAddr),

        .clk    (clk),
        .reset  (~resetn),
        .clr    (clr),
        .en     (en),
        .E_instr(E_instr),
        .E_pc   (E_pc),
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

    assign M_out   = (M_fsel == `m_fsel_pc8) ? M_pc8 : 
                     (M_fsel == `m_fsel_alu) ? M_alu : 
                     M_mdu;

    // M_CTRL
    CTRL M_CTRL (
        .mtc0    (M_mtc0),
        .en_CP0  (en_CP0),
        .eret    (M_eret),
        .loadstore(M_loadstore),

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

    assign data_sram_addr   = M_alu & 32'h1FFFFFFF ;
    
    assign data_sram_wdata  = (M_sel_st == `m_sw) ? HMUX_WD : 
                              (M_sel_st == `m_sh) ? {2{HMUX_WD[15:0]}} : 
                              (M_sel_st == `m_sb) ? {4{HMUX_WD[7:0]}} : 
                                                    0;
    assign data_sram_wen = (req) ? 0 : byteEn;
    assign data_sram_en  = |byteEn || M_loadstore;
    // assign m_inst_addr   = M_pc;

    M_BE M_BE (
        .Ov      (M_Ov),
        .addr    (M_alu & 32'h1FFFFFFF),
        .AdES    (M_AdES),
        .AdEL    (M_AdEL),

        .M_sel_st(M_sel_st),
        .M_sel_ld(M_sel_ld),
        .addr10  (M_alu[1:0]),
        .byteEn  (byteEn)
    );


    CP0 CP0(
    .clk       (clk),
    .reset     (~resetn),
    .WE        (en_CP0),
    .A1        (M_rd),
    .A2        (M_rd),
    .DIn       (HMUX_WD),
    .DOut      (M_cp0),
    .BDIn      (M_bd),
    .VPC       (M_pc),
    .BadVAddrIn(M_BadVAddr_new),
    .ExcCodeIn (M_ExcCode_new),
    .HWInt     (ext_int),
    .EXLClr    (M_eret),
    .Req       (req),
    .EPCOut    (EPC)
    );


    // -------- W-Stage --------
    // W-wire
    wire [31:0] W_pc8, W_instr, W_alu, W_ext, W_RD, W_mdu;

    wire [4:0] W_Addr;
    wire [4:0] W_rs, W_rt, W_rd;

    wire [2:0] W_fsel;
    wire [1:0] W_sel_A3;

    wire [2:0] W_sel_ld;

    W_REG W_REG (

        .req    (req),
        .cp0    (M_cp0),
        .cp0out (W_cp0),


        .clk    (clk),
        .reset  (~resetn),
        .clr    (clr),
        .en     (en),
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
    //    .Ov      (M_Ov),
        .addr    (W_alu & 32'h1FFFFFFF),
    //    .AdEL    (M_AdEL), // xian mei yong

        .M_sel_ld(W_sel_ld),
        .RD      (data_sram_rdata),
        .addr10  (W_alu[1:0]),
        .RD_real (W_RD)
    );


    assign debug_wb_rf_wen   = (W_en_GRF) ? 4'b1111 : 0;
    assign debug_wb_rf_wnum  = MUX_A3;
    assign debug_wb_rf_wdata = W_out;
    assign debug_wb_pc       = W_pc;

    assign W_out       = (W_fsel == `w_alu) ? W_alu : 
                         (W_fsel == `w_pc8) ? W_pc8 : 
                         (W_fsel == `w_mdu) ? W_mdu :
                         (W_fsel == `w_cp0) ? W_cp0 :
                                              W_RD;

endmodule  //mips

