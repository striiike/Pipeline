`include "const.v"
module E_block (
    input                       clk,
    input                       reset,

    // handshake signal
    input       allowin_next,
    output      allowin,
    input       valid_last,
    output      ready_go,
    output  reg    valid,   
    
   
    // fwd
    output [4:0] fwd_addr,

    output start,
    output busy,

    // data
    input      [31:0]           pc_i,
    output reg [31:0]           pc_o,
    input      [31:0]           instr_i,
    output reg [31:0]           instr_o,
    output reg [4:0]            A1_o,
    output reg [4:0]            A2_o,
    input      [31:0]           RD1_i,
    output reg [31:0]           RD1_o,
    input      [31:0]           RD2_i,
    output reg [31:0]           RD2_o,
    input      [31:0]           ext_i,
    output reg [31:0]           ext_o,
    output reg [31:0]           alu_o,
    output reg [31:0]           mdu_o,

    // exception 
    input      [4:0]           exc_i,
    output reg [4:0]           exc_o,
    input      [31:0]           badVAddr_i,
    output reg [31:0]           badVAddr_o,
    input      [31:0]           bd_i,
    output reg [31:0]           bd_o

);
    // done, allowin, valid, ready_go
    wire [31:0] E_pc, E_pc8, instr_i, E_RD1, E_RD2, E_alu, E_ext, E_mdu;
    wire [4:0] E_shamt;
    wire [4:0] E_rs, E_rt, E_rd, E_Addr, E_SAddr;

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

    // E-connect
    assign E_rs      = instr_i[25:21];
    assign E_rt      = instr_i[20:16];
    assign E_rd      = instr_i[15:11];

    // assign HMUX_srcA = (E_rs == M_Addr && M_Addr != 5'b0) ? M_out : 
    //                    (E_rs == W_Addr && W_Addr != 5'b0) ? W_out : E_RD1;
    // assign HMUX_srcB = (E_rt == M_Addr && M_Addr != 5'b0) ? M_out : 
    //                    (E_rt == W_Addr && W_Addr != 5'b0) ? W_out : E_RD2;

    assign HMUX_srcA = RD1_i;
    assign HMUX_srcB = RD2_i;

    assign MUX_srcB  = (E_sel_srcB == `e_rd2) ? HMUX_srcB : ext_i;

    assign E_out     = (E_fsel == `e_fsel_pc8) ? E_pc8 : E_ext;

    assign E_shamt   = instr_i[10:6];

    // E_CTRL
    CTRL E_CTRL (
        .mtc0     (E_mtc0),
        .loadstore(loadstore),
        .arch     (arch),

        .instr     (instr_i),
        .E_sel_ALU (E_sel_ALU),
        .E_fsel    (E_fsel),
        .E_sel_srcB(E_sel_srcB),
        .E_Addr    (E_Addr),
        .E_Tnew    (E_Tnew),
        .E_SAddr   (E_SAddr),
        .E_sel_MDU (E_sel_MDU)
    );
    // E_CTRL

    assign fwd_addr = (valid_last) ? E_SAddr : 0;

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

    wire  req = 0;
    E_MDU E_MDU (
        .req      (req),
        .clk      (clk),
        .reset    (reset),
        .A        (HMUX_srcA),
        .B        (HMUX_srcB),
        .E_sel_MDU(E_sel_MDU),
        .E_mdu    (E_mdu),
        .busy     (busy),
        .start    (start)
    );


    


    assign ready_go = 1;

    always @(posedge clk ) begin
        if (reset) begin
            valid <= 0;
            instr_o <= 0;
            alu_o <= 0;
            RD2_o <= 0;

            exc_o <= 0;
            badVAddr_o <= 0;
        end

        else if (allowin_next) begin
            valid    <= valid_last && ready_go && !(|exc_i);
            pc_o     <= pc_i;
            instr_o  <= instr_i;

            RD1_o    <= RD1_i;
            RD2_o    <= RD2_i;

            ext_o    <= ext_i;
            alu_o    <= E_alu;
            mdu_o    <= E_mdu; 

            exc_o    <=  (exc_i) ? exc_i :
                         (E_OvArch)  ? 5'd12     : 5'd0;

            badVAddr_o <= badVAddr_i;
        end
    end





endmodule