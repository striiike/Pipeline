`include "const.v"

// `include "D_GRF.v"
// `include "F_block.v"
// `include "D_block.v"
// `include "E_block.v"
// `include "M_block.v"
// `include "W_block.v"


module CPU (
    input       clk,
    input       resetn,
    input [5:0] ext_int,

    // new
    //inst sram-like 
    output         inst_req,
    output         inst_wr,
    output [1 : 0] inst_size,
    output [ 31:0] inst_addr,
    output [ 31:0] inst_wdata,
    input  [ 31:0] inst_rdata,
    input          inst_addr_ok,
    input          inst_data_ok,

    //data sram-like 
    output         data_req,
    output         data_wr,
    output [1 : 0] data_size,
    output [ 31:0] data_addr,
    output [ 31:0] data_wdata,
    input  [ 31:0] data_rdata,
    input          data_addr_ok,
    input          data_data_ok,

    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output [31:0] debug_wb_pc
);

  assign inst_wr = 0;
  assign inst_size = 2'b10;
  assign inst_wdata = 32'b0;
  wire F_allowin, D_allowin, E_allowin, M_allowin, W_allowin;
  wire F_valid, D_valid, E_valid, M_valid, W_valid;
  wire F_ready_go, D_ready_go, E_ready_go, M_ready_go, W_ready_go;

  // assign macroscopic_pc = M_pc;
  // wire [31:0] D_Tuse_rs, D_Tuse_rt, E_Tnew, M_Tnew, W_Tnew;

  // wire D_stall_rs_E, D_stall_rs_M, D_stall_rt_E, D_stall_rt_M, D_stall_rt, D_stall_rs;
  // wire D_stall, D_stall_mdu, D_instr_mdu, busy, start;

  // wire [4:0] E_SAddr, M_SAddr;

  // wire D_Syscall, D_Break, E_OvArch, E_OvDM;
  // wire F_eret, D_eret, E_eret, M_eret;
  wire [31:0] M_cp0, W_cp0, EPC, D_badVAddr, E_badVAddr, M_badVAddr, cp0_EPC;
  wire [4:0] F_exc, D_exc, E_exc, M_exc;
  // wire [31:0] M_BadVAddr_new;
  // wire F_bd, E_bd, M_bd;
  // wire E_mtc0, M_mtc0;
  // wire M_AdEL, M_AdES;

  // wire en;
  // assign en = 1'b1;

  // wire [4:0] F_ExcCode, E_ExcCode, M_ExcCode;
  // wire [4:0] D_ExcCode_new, E_ExcCode_new, M_ExcCode_new;

  // /// exception
  // assign F_ExcCode = (F_AdEL) ? 5'd4 : 5'd0;

//   assign D_ExcCode_new = (D_ExcCode) ? D_ExcCode :
//                          (D_Break)   ? 5'd9      :
//                          (D_Syscall) ? 5'd8      :
//                          (D_RI)      ? 5'd10     : 5'd0;

//   assign E_ExcCode_new = (E_ExcCode) ? E_ExcCode :
//                          (E_OvArch)  ? 5'd12     : 5'd0;

  // assign M_ExcCode_new = (M_ExcCode) ? M_ExcCode :
  //                        (M_AdEL)    ? 5'd4      : 
  //                        (M_AdES)    ? 5'd5      : 5'd0;

  // assign M_BadVAddr_new = (M_AdEL || M_AdES) ? M_alu : M_BadVAddr;

  /// exception end

  // -------- F-Stage --------
  // F-wire
  wire [31:0] F_pc, F_instr;
  wire [31:0] MUX_npc;
  wire D_jump;
  wire F_sel_npc, F_AdEL;

  // F-connect


  reg [31:0] pc;
  wire [31:0] npc = (F_sel_npc == `f_npc) ? D_npc : pc + 4;
  always @(posedge clk) begin
    if (!resetn) pc <= 32'hbfc0_0000;
    else if (exc_req) pc <= 32'hbfc0_0380;
    else if (eret) pc <= cp0_EPC;
    else if (F_allowin) pc <= npc;
    else pc <= F_pc;
  end

  assign F_pc = pc;

  wire [31:0] D_pc, D_instr;

  F_block F_block (
      .clk  (clk),
      .reset(!resetn),


      .allowin_next(D_allowin),
      .allowin     (F_allowin),
      .valid_last  (1),
      .valid       (F_valid),

      .inst_req    (inst_req),
      .inst_addr   (inst_addr),
      .inst_rdata  (inst_rdata),
      .inst_addr_ok(inst_addr_ok),
      .inst_data_ok(inst_data_ok),

      .pc_in    (F_pc),
      .pc_out   (D_pc),
      .instr_out(D_instr),
      // .req             ( req             ),
      // .eret            ( eret            ),
      // .EPC             ( EPC             ),
      // .F_eret          ( F_eret          ),
      .exc_o (D_exc),
      .badVAddr_o      ( D_badVAddr      )
      // .bdIn            ( bdIn            ),
      // .bdOut           ( bdOut           )
  );



  // -------- D-Stage --------
  // D-wire
  wire [31:0] MUX_ext, W_wdata;
  wire [31:0] HMUX_RD1;
  wire [31:0] HMUX_RD2;
  wire [ 4:0] MUX_A3;
  wire [ 4:0] A1_out, A2_out;
  wire [31:0] W_out;
  wire [ 4:0] W_Addr;

  wire [31:0] D_RD1, D_RD2, grf_RD1, grf_RD2, D_ext, D_npc;
  D_GRF GRF (
      .clk(clk),
      .rst(!resetn),
      .A1 (A1_out),
      .A2 (A2_out),
      .A3 (W_Addr),
      .WE (W_en_GRF),
      .WD3(W_wdata),
      .RD1(grf_RD1),
      .RD2(grf_RD2)
  );
  // hazard
  // assign HMUX_RD1     = (D_rs == E_Addr && E_Addr != 5'b0) ? E_out : 
  //                         (D_rs == M_Addr && M_Addr != 5'b0) ? M_out : D_RD1;
  // assign HMUX_RD2     = (D_rt == E_Addr && E_Addr != 5'b0) ? E_out : 
  //                         (D_rt == M_Addr && M_Addr != 5'b0) ? M_out : D_RD2;


  wire [31:0] E_pc, E_instr, E_RD1, E_RD2, E_ext, E_alu, E_mdu;
  assign D_allowin = D_ready_go && E_ready_go && M_ready_go && W_ready_go ||
                       D_ready_go && !D_valid || !F_valid;


  wire [4:0] E_SAddr, M_SAddr, W_SAddr;
  wire [31:0] W_fwd_data;
  wire W_fwd_ok;

  D_block D_block (
      .clk         (clk),
      .reset       (!resetn),

      .allowin_next(E_allowin),
      // .allowin      ( D_allowin      ),
      .ready_go    (D_ready_go),
      .valid_last  (F_valid),
      .valid       (D_valid),

      .inst_rdata  (inst_rdata),
      .inst_addr_ok(inst_addr_ok),
      .inst_data_ok(inst_data_ok),


      // silly stall way (temporary)
      .E_SAddr(E_SAddr),
      .M_SAddr(M_SAddr),
      .W_SAddr(W_SAddr),
      .W_fwd_data(W_fwd_data),
      .W_fwd_ok(W_fwd_ok),

      .start(mdu_start),
      .busy (mdu_busy),




      .pc_i(D_pc),
      .pc_o(E_pc),

      .instr_o(E_instr),

      .A1_o (A1_out),
      .A2_o (A2_out),
      .RD1_i(grf_RD1),
      .RD1_o(E_RD1),
      .RD2_i(grf_RD2),
      .RD2_o(E_RD2),
      .ext_i(ext_in),
      .ext_o(E_ext),
      .br_o (F_sel_npc),
      .npc_o(D_npc),

      .cancel(exc_req),
      .eret(eret),
      .EPC (cp0_EPC),
      .exc_i          ( D_exc          ),
      .exc_o         ( E_exc         ),
      .badVAddr_i     ( D_badVAddr     ),
      .badVAddr_o    ( E_badVAddr    ),
      .bd_i           ( bd_in           ),
      .bd_o          ( bd_out          )
  );




  // -------- E-Stage --------

  // E-wire
  wire [31:0] M_pc, M_instr, M_alu, M_mdu, M_ext, M_RD;
  wire [31:0] M_RD1, M_RD2, W_RD1, W_RD2;
  assign E_allowin = E_ready_go && M_ready_go && W_ready_go ||
                       E_ready_go && !E_valid ||
                       E_ready_go && M_ready_go && !M_valid || !D_valid;
  E_block E_block (
      .clk         (clk),
      .reset       (!resetn),
      .allowin_next(M_allowin),
      // .allowin      ( E_allowin      ),
      .ready_go    (E_ready_go),
      .valid_last  (D_valid),
      .valid       (E_valid),

      .fwd_addr(E_SAddr),

      .start(mdu_start),
      .busy (mdu_busy),

      .pc_i   (E_pc),
      .pc_o   (M_pc),
      .instr_i(E_instr),
      .instr_o(M_instr),
      .RD1_i  (E_RD1),
      .RD1_o  (M_RD1),
      .RD2_i  (E_RD2),
      .RD2_o  (M_RD2),
      .ext_i  (E_ext),
      .ext_o  (M_ext),
      .alu_o  (M_alu),
      .mdu_o  (M_mdu),

      .exc_i           ( E_exc           ),
      .exc_o           ( M_exc           ),
      .badVAddr_i      ( E_badVAddr      ),
      .badVAddr_o      ( M_badVAddr      ),
      .bd_i            ( bd_i            ),
      .bd_o            ( bd_o            )
  );


  // -------- M-Stage --------
  // M-wire
  wire [31:0] W_pc, W_instr, W_alu, W_mdu;
  assign M_allowin = M_ready_go && W_ready_go || M_ready_go && !M_valid || !E_valid;
  M_block M_block (
      .clk  (clk),
      .reset(!resetn),

      .allowin_next(W_allowin),
      // .allowin      ( M_allowin      ),
      .ready_go    (M_ready_go),
      .valid_last  (E_valid),
      .valid       (M_valid),

      .fwd_addr(M_SAddr),


      .data_req    (data_req),
      .data_wr     (data_wr),
      .data_size   (data_size),
      .data_addr   (data_addr),
      .data_wdata  (data_wdata),
      .data_rdata  (data_rdata),
      .data_addr_ok(data_addr_ok),
      .data_data_ok(data_data_ok),
      .pc_i        (M_pc),
      .pc_o        (W_pc),
      .instr_i     (M_instr),
      .instr_o     (W_instr),
      .RD1_i       (M_RD1),
      .RD1_o       (W_RD1),
      .RD2_i       (M_RD2),
      .RD2_o       (W_RD2),
      .ext_i       (M_ext),
      .ext_o       (W_ext),
      .alu_i       (M_alu),
      .alu_o       (W_alu),
      .mdu_i       (M_mdu),
      .mdu_o       (W_mdu),
      .RD_o        (W_RD),
      .cp0_o       (W_cp0),


      .exc_req (exc_req),
      .cp0_EPC (cp0_EPC),
      .ext_int (ext_int),

      .exc_i           ( M_exc           ),
      .exc_o           ( exc_o           ),
      .badVAddr_i      ( M_badVAddr      ),
      .badVAddr_o      ( badVAddr_o      ),
      .bd_i            ( bd_i            ),
      .bd_o            ( bd_o            )
  );





  // -------- W-Stage --------
  // W-wire
  wire [ 1:0] W_sel_A3;


  wire [31:0] out_pc;
  assign W_allowin = W_ready_go || !M_valid;

  W_block u_W_block (
      .clk         (clk),
      .reset       (!resetn),
      .allowin_next(1),
      // .allowin      ( W_allowin      ),
      .ready_go    (W_ready_go),
      .valid_last  (M_valid),
      .valid       (W_valid),

      .data_rdata  (data_rdata),
      .data_addr_ok(data_addr_ok),
      .data_data_ok(data_data_ok),

      .fwd_addr(W_SAddr),

      .pc_i   (W_pc),
      .pc_o   (out_pc),
      .instr_i(W_instr),
      .ext_i  (W_ext),
      .alu_i  (W_alu),
      .mdu_i  (W_mdu),
      .cp0_i  (W_cp0),
      .RD_i   (W_RD),
      .W_Wdata(W_wdata),
      .W_Addr (W_Addr),
      .W_en   (W_en_GRF)
  );

  // assign W_SAddr    = W_Addr;
  assign W_fwd_data        = W_wdata;
  assign W_fwd_ok          = W_en_GRF;

  assign debug_wb_rf_wen   = (W_en_GRF) ? 4'b1111 : 0;
  assign debug_wb_rf_wnum  = W_Addr;
  assign debug_wb_rf_wdata = W_wdata;
  assign debug_wb_pc       = out_pc;

endmodule  //mips

