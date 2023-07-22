`include "const.v"

module CTRL (
    input [31:0] instr,
    input [ 1:0] stage,

    // D
    output [1:0] D_sel_EXT,
    output [1:0] D_sel_NPC,
    output [3:0] D_sel_CMP,

    output [31:0] D_Tuse_rs,
    output [31:0] D_Tuse_rt,

    output D_instr_mdu,

    // E
    output [4:0] E_sel_ALU,
    output [3:0] E_sel_MDU,
    output  E_fsel,
    output  E_sel_srcB,

    output [ 4:0] E_Addr,
    output [31:0] E_Tnew,
    output [ 4:0] E_SAddr,

    // M
    output [1:0] M_fsel,
    output [1:0] M_sel_st,
    output [2:0] M_sel_ld,

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
    output load,
    output mtc0,
    output eret,
    output RI,
    output en_CP0,
    output syscall,
    output loadstore,
    output arch,
    output jump,
    output Break
    

);

    wire [5:0] op, f;
    wire [4:0] rs, rt, rd;
    assign op = instr[31:26];
    assign f  = instr[ 5: 0];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];

    // -------- definition of code --------
    // ---- arch operation ----
    wire add   = (op == `op_r && f == `f_add  );
    wire addi  = (op == `op_addi );
    wire addu  = (op == `op_r && f == `f_addu );
    wire addiu = (op == `op_addiu);
    wire sub   = (op == `op_r && f == `f_sub  );
    wire subu  = (op == `op_r && f == `f_subu );
    wire slt   = (op == `op_r && f == `f_slt  );
    wire slti  = (op == `op_slti );
    wire sltu  = (op == `op_r && f == `f_sltu );
    wire sltiu = (op == `op_sltiu);
    wire mult  = (op == `op_r && f == `f_mult );
    wire multu = (op == `op_r && f == `f_multu);
    wire div   = (op == `op_r && f == `f_div  );
    wire divu  = (op == `op_r && f == `f_divu );
    // ---- logic operation ----
    wire And   = (op == `op_r && f == `f_and  );
    wire andi  = (op == `op_andi );
    wire lui   = (op == `op_lui  );
    wire Nor   = (op == `op_r && f == `f_nor  );
    wire Or    = (op == `op_r && f == `f_or   );
    wire ori   = (op == `op_ori  );
    wire Xor   = (op == `op_r && f == `f_xor  );
    wire xori  = (op == `op_xori );
    // ---- shift operation ----
    wire sll   = (op == `op_r && f == `f_sll  );
    wire sllv  = (op == `op_r && f == `f_sllv );
    wire sra   = (op == `op_r && f == `f_sra  );
    wire srav  = (op == `op_r && f == `f_srav );
    wire srl   = (op == `op_r && f == `f_srl  );
    wire srlv  = (op == `op_r && f == `f_srlv );    
    // ---- branch operation ----
    wire beq   = (op == `op_beq  );
    wire bne   = (op == `op_bne  );
    wire bgez  = (op == `op_branch && rt == `rt_bgez  );
    wire bgtz  = (op == `op_bgtz );
    wire blez  = (op == `op_blez );
    wire bltz  = (op == `op_branch && rt == `rt_bltz  );
    wire bltzal= (op == `op_branch && rt == `rt_bltzal);
    wire bgezal= (op == `op_branch && rt == `rt_bgezal);
    wire j     = (op == `op_j    );
    wire jal   = (op == `op_jal  );
    wire jr    = (op == `op_r && f == `f_jr   );    
    wire jalr  = (op == `op_r && f == `f_jalr );
    // ---- data-moving operation ----
    wire mfhi  = (op == `op_r && f == `f_mfhi );
    wire mflo  = (op == `op_r && f == `f_mflo );
    wire mthi  = (op == `op_r && f == `f_mthi );
    wire mtlo  = (op == `op_r && f == `f_mtlo );
    // ---- memory-fetching operation ----
    wire lb    = (op == `op_lb   );
    wire lbu   = (op == `op_lbu  );    
    wire lh    = (op == `op_lh   );
    wire lhu   = (op == `op_lhu  );
    wire lw    = (op == `op_lw   );
    wire sb    = (op == `op_sb   );
    wire sh    = (op == `op_sh   );
    wire sw    = (op == `op_sw   );    
    // ---- self-trapped operation ----
    assign Break    = (op == `op_r && f == `f_break  );
    assign syscall  = (op == `op_r && f == `f_syscall);
    // ---- priority operation ----
    assign mtc0     = (instr[31:21] == `op_mtc0);
    wire mfc0       = (instr[31:21] == `op_mfc0);
    assign eret     = (instr == `op_eret);


    // extra
    wire mul = (op == `op_mul && f == `f_mul);
    // wire mul = 0;




    assign arch = add | addi | sub;
    wire store, branch, cal_r, cal_i, md, mt, mf;
    assign loadstore = load | store;

    assign cal_r =  add | sub | addu | subu | mul |
                    slt | sltu |
                    sll | sllv | sra | srav | srl | srlv |
                    And | Or | Xor | Nor; // exclude jr & jalr & mt/mf/md

    assign cal_i = addi | addiu | 
                   slti | sltiu |
                   andi | ori | xori;                 

    assign load   = lw | lh | lb | lbu | lhu;
    assign store  = sw | sh | sb;
    assign branch = beq | bne | bgez | bgtz | blez | bltz;
    wire branchal = bltzal | bgezal;
    


    assign D_instr_mdu = md | mt | mf;

    assign md = mult | multu | div | divu;
    assign mt = mtlo | mthi;
    assign mf = mflo | mfhi;

    // assign shiftS  = sll | srl | sra;
    // assign shiftV = sllv | srlv | srav;
    wire shift = sll | srl | sra | sllv | srlv | srav;

    // // ---- exception ---- 
    // assign RI = ~(load | store | branch | branchal | cal_i | cal_r 
    //             | j | jr | jal | jalr | lui
    //             | md | mt | mf 
    //             | sll | srl | sra
    //             | sllv | srlv | srav
    //             | mtc0 | mfc0 | eret | syscall | Break);

    // assign en_CP0 = mtc0;
    // assign jump = branch | branchal | j | jr | jal | jalr; // delayed branching
    // // ---- exception end ----


    // -------- main controller --------
    assign W_en_GRF = cal_i | cal_r | branchal | jal | jalr | load | mfhi | mflo | mfc0 | lui;

    assign W_sel_A3 = (cal_r | mf)             ? `grf_rd : 
                      (jal | jalr | branchal)  ? `grf_ra : 
                                                 `grf_rt ;

    assign E_sel_MDU = (mul)  ? `mdu_mul :
                    //    (mult) ? `mdu_mult : 
                    //    (multu) ? `mdu_multu :
                    //    (div) ? `mdu_div :
                    //    (divu) ? `mdu_divu :
                    //    (mfhi) ? `mdu_mfhi :
                    //    (mflo) ? `mdu_mflo :
                    //    (mthi) ? `mdu_mthi :
                       (mtlo) ? `mdu_mtlo : 4'b1111;

    assign M_en_DM   = (store);

    assign D_sel_EXT = (load | store | branch | branchal 
                       | addi | addiu | slti | sltiu) ? 2'b01 :
                       (lui)                          ? 2'b10 :  
                                                        2'b00;

    assign D_sel_NPC =  (branch | branchal) ? `npc_offset : 
                        (j | jal)           ? `npc_index : 
                        (jr | jalr)         ? `npc_ra : 
                                                2'b11;

    assign D_sel_CMP =  (beq)       ? `cmp_beq : 
                        (bne)       ? `cmp_bne : 
                        (bgez)      ? `cmp_bgez : 
                        (bgtz)      ? `cmp_bgtz : 
                        (blez)      ? `cmp_blez : 
                        (bltz)      ? `cmp_bltz : 
                        (bltzal)    ? `cmp_bltzal : 
                        (bgezal)    ? `cmp_bgezal : 4'd0;

    assign E_sel_srcB = (load | store | cal_i | lui) ? `alu_imm : `alu_rd2;

    assign E_sel_ALU =  (add | addi | addu | addiu) ? `alu_ADD :
                        (sub | subu)                ? `alu_SUB :
                        (slt)                       ? `alu_SLT : 
                        (sltu)                      ? `alu_SLTU : 
                        (slti)                      ? `alu_SLTI : 
                        (sltiu)                     ? `alu_SLTIU : 
                        (And | andi)                ? `alu_AND : 
                        (lui)                       ? `alu_LUI : 
                        (Nor)                       ? `alu_NOR : 
                        (ori | Or)                  ? `alu_OR : 
                        (xori | Xor)                ? `alu_XOR : 
                        (load)                      ? `alu_ADD : 
                        (store)                     ? `alu_ADD :
                        (sll)                       ? `alu_SLL : 
                        (sllv)                      ? `alu_SLLV :
                        (sra)                       ? `alu_SRA :
                        (srav)                      ? `alu_SRAV :
                        (srl)                       ? `alu_SRL :
                        (srlv)                      ? `alu_SRLV :
                        // (mul)                       ? `alu_mul :
                                                        5'b0;

    assign M_sel_st = (sw) ? 2'b00 :
                      (sh) ? 2'b01 :
                      (sb) ? 2'b10 : 2'b11;

    assign M_sel_ld = (lw)  ? 3'd1 :
                      (lh)  ? 3'd2 :
                      (lhu) ? 3'd3 : 
                      (lb)  ? 3'd4 : 
                      (lbu) ? 3'd5 : 3'b0;





    // -------- forward controller --------
    assign E_Addr = (lui)                   ? rt : 
                    (jal | jalr | branchal) ? 31 : 
                                              5'b0; 

    assign M_Addr = (cal_r | mf)            ? rd : 
                    (jal | jalr | branchal) ? 31 : 
                    (lui | cal_i)           ? rt : 
                                              5'b0; 

    assign W_Addr = (cal_r | mf)                ? rd : 
                    (jal | jalr | branchal)     ? 31 : 
                    (load | cal_i | lui | mfc0) ? rt : 
                                                  5'b0;  

    assign E_fsel = (jal | jalr | branchal) ? `e_fsel_pc8 : 
                                              `e_fsel_ext ;

    assign M_fsel = (jal | jalr | branchal) ? `m_fsel_pc8 : 
                    (mf | mul)                    ? `m_fsel_mdu : 
                                              `m_fsel_alu ;


    assign W_fsel = (load)                  ? `wd3_rd  : 
                    (jal | jalr | branchal) ? `wd3_pc  : 
                    (mf | mul)              ? `wd3_mdu : 
                    (mfc0)                  ? `wd3_cp0 :
                                              `wd3_alu ;






    // -------- stall controller --------
    assign E_SAddr = (cal_r | mf)            ? rd : 
                     (jal | jalr | branchal) ? 31 : 
                                               rt ;

    assign M_SAddr = (cal_r | mf)            ? rd : 
                     (jal | jalr | branchal) ? 31 : 
                                               rt ;

    assign D_Tuse_rs = (cal_i | cal_r | load | store | md | mt) ? 1 : 
                       (branch | jr | jalr | branchal)          ? 0 :      // only bgezal and bltzal, so Tuse_rt excluded
                                                                `inf;

    assign D_Tuse_rt = (cal_r | md)     ? 1 :
                       (store | mtc0)   ? 2 : 
                       (branch)         ? 0 : 
                                        `inf;

    assign E_Tnew = (cal_r | cal_i | mf)    ? 1 : 
                    (load | mfc0)           ? 2 : 
                                              0;

    assign M_Tnew = (load | mfc0) ? 1 : 
                                    0 ;

    assign W_Tnew = 0;












endmodule 
