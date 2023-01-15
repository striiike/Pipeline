
`define op_r 6'b000000
`define op_beq 6'b000100
`define op_j 6'b000010
`define op_jal 6'b000011
`define op_lui 6'b001111
`define op_lw 6'b100011
`define op_ori 6'b001101
`define op_sw 6'b101011
`define op_sb 6'b101000
`define op_lb 6'b100000
`define op_bne 6'b000101

`define op_lh   6'b100001
`define op_sh   6'b101001
`define op_addi 6'b001000
`define op_andi 6'b001100

`define op_mtc0    11'b010000_00100
`define op_mfc0    11'b010000_00000
`define op_eret    32'b010000_1000_0000_0000_0000_0000_011000

`define f_add 6'b100000
`define f_sub 6'b100010
`define f_and 6'b100100
`define f_jalr 6'b001001
`define f_jr 6'b001000
`define f_or 6'b100101
`define f_sll 6'b000000
`define f_sllv 6'b000100
`define f_slt 6'b101010
`define f_sltu 6'b101011

`define f_mfhi  6'b010000
`define f_mflo  6'b010010
`define f_mthi  6'b010001
`define f_mtlo  6'b010011
`define f_mult  6'b011000
`define f_multu 6'b011001
`define f_div   6'b011010
`define f_divu  6'b011011

`define f_syscall 6'b001100


// RegDst
`define grf_rt 2'b00
`define grf_rd 2'b01
`define grf_ra 2'b10

// Branch
`define npc_offset 2'b00
`define npc_index 2'b01
`define npc_ra 2'b10

// memtoreg
`define wd3_alu 3'b001
`define wd3_rd 3'b000
`define wd3_pc 3'b010
`define wd3_mdu 3'b011
`define wd3_cp0 3'b100

// ALUSrc
`define alu_rd2 2'b00
`define alu_imm 2'b01

// ALUControl
`define AND 4'b0000
`define OR 4'b0001
`define ADD 4'b0010
`define SUB 4'b0110
`define SLT 4'b0111
`define LUI 4'b1000
`define SLL 4'b1010
`define SLTU 4'b1011

`define e_fsel_pc8 2'b01
`define e_fsel_ext 2'b00

`define m_fsel_mdu 2'b10
`define m_fsel_pc8 2'b01
`define m_fsel_alu 2'b00

`define inf 100

`define cmp_beq 2'b00
`define cmp_bne 2'b01
`define cmp_bbb 2'b10

`define mdu_mult 4'd1
`define mdu_multu 4'd2
`define mdu_div 4'd3
`define mdu_divu 4'd4
`define mdu_mfhi 4'd5
`define mdu_mflo 4'd6
`define mdu_mthi 4'd7
`define mdu_mtlo 4'd8

module u_CTRL (
    input [31:0] instr,
    input [ 1:0] stage,

    // D
    output [1:0] D_sel_EXT,
    output [1:0] D_sel_NPC,
    output [1:0] D_sel_CMP,

    output [31:0] D_Tuse_rs,
    output [31:0] D_Tuse_rt,

    output D_instr_mdu,

    // E
    output [3:0] E_sel_ALU,
    output [3:0] E_sel_MDU,
    output  E_fsel,
    output  E_sel_srcB,

    output [ 4:0] E_Addr,
    output [31:0] E_Tnew,
    output [ 4:0] E_SAddr,

    // M
    output [1:0] M_fsel,
    output [1:0] M_sel_st,
    output [1:0] M_sel_ld,

    output [ 4:0] M_Addr,
    output [31:0] M_Tnew,
    output [ 4:0] M_SAddr,

    output       M_en_DM,

    // W
    output [2:0] W_fsel,
    output [1:0] W_sel_A3,

    output W_en_GRF,

    output [ 4:0] W_Addr,
    output [31:0] W_Tnew,

    // exception
    output mtc0,
    output eret,
    output RI,
    output en_CP0,
    output syscall,
    output loadstore,
    output arch,
    output jump
    

);

    wire [5:0] op, f;
    wire [4:0] rs, rt, rd;
    assign op = instr[31:26];
    assign f  = instr[ 5: 0];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];



    wire lh    = (op == `op_lh   );
    wire sh    = (op == `op_sh   );
    wire lb    = (op == `op_lb   );
    wire lw    = (op == `op_lw   );
    wire sb    = (op == `op_sb   );
    wire sw    = (op == `op_sw   );
    wire beq   = (op == `op_beq  );
    wire j     = (op == `op_j    );
    wire jal   = (op == `op_jal  );
    wire ori   = (op == `op_ori  );
    wire lui   = (op == `op_lui  );
    wire bne   = (op == `op_bne  );
    wire addi  = (op == `op_addi );
    wire andi  = (op == `op_andi );

    wire add   = (op == `op_r && f == `f_add  );
    wire jalr  = (op == `op_r && f == `f_jalr );
    wire jr    = (op == `op_r && f == `f_jr   );
    wire sll   = (op == `op_r && f == `f_sll  );
    wire sllv  = (op == `op_r && f == `f_sllv );
    wire slt   = (op == `op_r && f == `f_slt  );
    wire sub   = (op == `op_r && f == `f_sub  );
    wire Or    = (op == `op_r && f == `f_or   );
    wire And   = (op == `op_r && f == `f_and  );
    wire sltu  = (op == `op_r && f == `f_sltu );

    wire mfhi  = (op == `op_r && f == `f_mfhi );
    wire mflo  = (op == `op_r && f == `f_mflo );
    wire mthi  = (op == `op_r && f == `f_mthi );
    wire mtlo  = (op == `op_r && f == `f_mtlo );
    wire mult  = (op == `op_r && f == `f_mult );
    wire multu = (op == `op_r && f == `f_multu);
    wire div   = (op == `op_r && f == `f_div  );
    wire divu  = (op == `op_r && f == `f_divu );

    assign mtc0     = (instr[31:21] == `op_mtc0);
    wire mfc0     = (instr[31:21] == `op_mfc0);
    assign eret     = (instr == `op_eret);
    assign syscall  = (op == `op_r && f == `f_syscall);
    assign arch = add | addi | sub;


    wire load, store, branch, cal_r, cal_i, mc, mt, mf;
    assign loadstore = load | store;
    // exception 
    assign RI = !(load | store | branch | cal_i | cal_r 
                    | j | jr | jal | lui
                    | mc | mt | mf 
                    | mtc0 | mfc0 | eret | syscall
                    | (instr == 0));

    assign en_CP0 = mtc0;
    assign jump = branch | j | jr | jal;
    // exception end

    assign cal_r = add | sub | slt | sltu |
                    sll | 
                    And | Or; // exclude jr & jalr & mt/mf/md

    assign cal_i = addi | andi | ori;                 

    assign load   = lw | lh | lb;
    assign store  = sw | sh | sb;
    assign branch = beq | bne;


    assign D_instr_mdu = mc | mt | mf;

    assign mc = mult | multu | div | divu;
    assign mt = mtlo | mthi;
    assign mf = mflo | mfhi;

    // assign shiftS  = sll | srl | sra;
    // assign shiftV = sllv | srlv | srav;



    assign W_en_GRF = ~(store | branch | j | jr | mt | mc | eret | mtc0 | syscall);

    assign W_sel_A3 = (cal_r | mf) ? `grf_rd : 
                        (jal) ? `grf_ra : `grf_rt;

    assign E_sel_MDU = (mult) ? `mdu_mult : 
                       (multu) ? `mdu_multu :
                       (div) ? `mdu_div :
                       (divu) ? `mdu_divu :
                       (mfhi) ? `mdu_mfhi :
                       (mflo) ? `mdu_mflo :
                       (mthi) ? `mdu_mthi :
                       (mtlo) ? `mdu_mtlo : 4'b1111;

    assign E_fsel = (jal) ? `e_fsel_pc8 : `e_fsel_ext;
    
    assign E_Addr = (lui) ? rt : 
                    (jal) ? 31 : 5'b0;      // if grf is not writeable then writeAddress is 0

    assign M_Addr = (cal_r | mf) ? rd : 
                           (jal) ? 31 : 
                   (lui | cal_i) ? rt : 5'b0;      // if grf is not writeable then writeAddress is 0

    assign W_Addr =     (cal_r | mf) ? rd : 
                               (jal) ? 31 : 
                (load | cal_i | lui | mfc0) ? rt : 5'b0;      // if grf is not writeable then writeAddress is 0

    assign E_SAddr = (cal_r | mf) ? rd : 
                       (jal) ? 31 : rt;

    assign M_SAddr = (cal_r | mf) ? rd : 
                       (jal) ? 31 : rt;

    assign D_Tuse_rs = (cal_i | cal_r | load | store | mc | mt) ? 1 : 
                                       (branch | jr ) ? 0 : `inf;

    assign D_Tuse_rt = (cal_r | mc) ? 1 :
                       (store | mtc0) ? 2 : 
                      (branch) ? 0 : `inf;

    assign E_Tnew = (cal_r | cal_i | mf) ? 1 : 
                             (load | mfc0) ? 2 : 0;

    assign M_Tnew = (load | mfc0) ? 1 : 0;

    assign W_Tnew = 0;

    assign M_en_DM = (store);

    assign M_fsel = (jal) ? `m_fsel_pc8 : (mf) ? `m_fsel_mdu : `m_fsel_alu;


    assign W_fsel = (load) ? `wd3_rd : 
                     (jal) ? `wd3_pc : 
                     (mf) ? `wd3_mdu : 
                    (mfc0) ? `wd3_cp0:
                             `wd3_alu;

    assign D_sel_EXT =                   (lui) ? 2'b10 : 
                       (load | store | branch | addi) ? 2'b01 : 2'b00;

    assign D_sel_NPC =  (branch) ? `npc_offset : 
                       (j | jal) ? `npc_index : 
                            (jr) ? `npc_ra : 2'b11;

    assign D_sel_CMP =  (beq) ? `cmp_beq : 
                        (bne) ? `cmp_bne : 
                        (bne) ? `cmp_bne : 2'b11;

    assign E_sel_srcB = (load | store | cal_i | lui) ? `alu_imm : `alu_rd2;

    assign E_sel_ALU =  
                        (lui) ? `LUI : 
                        (load) ? `ADD : 
                        (store) ? `ADD :
                        (ori) ? `OR : 
                        (add | addi) ? `ADD : 
                        (sub) ? `SUB : 
                        (And | andi) ? `AND : 
                        (Or) ? `OR : 
                        (sll) ? `SLL : 
                        (slt) ? `SLT : 
                        (sltu) ? `SLTU :
                        4'b0000;

    assign M_sel_st = (sw) ? 2'b00 :
                      (sh) ? 2'b01 :
                      (sb) ? 2'b10 : 2'b11;
    assign M_sel_ld = (lw) ? 2'b00 :
                      (lh) ? 2'b01 :
                      (lb) ? 2'b10 : 2'b11;
    // assign D_Tuse_rs = (add | sub | ori | )








endmodule  //_CTRL
