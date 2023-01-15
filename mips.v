`include "CPU.v"
`include "BRIDGE.v"
`include "TC.v"
module mips (
    input         clk,            // 时钟信号
    input         reset,          // 同步复位信号
    input         interrupt,      // 外部中断信号
    output [31:0] macroscopic_pc, // 宏观 PC

    output [31:0] i_inst_addr,  // IM 读取地址（取指 PC）
    input  [31:0] i_inst_rdata, // IM 读取数据

    output [31:0] m_data_addr,   // DM 读写地址
    input  [31:0] m_data_rdata,  // DM 读取数据
    output [31:0] m_data_wdata,  // DM 待写入数据
    output [ 3:0] m_data_byteen, // DM 字节使能信号

    output [31:0] m_int_addr,   // 中断发生器待写入地址
    output [ 3:0] m_int_byteen, // 中断发生器字节使能信号

    output [31:0] m_inst_addr,  // M 级 PC

    output        w_grf_we,    // GRF 写使能信号
    output [ 4:0] w_grf_addr,  // GRF 待写入寄存器编号
    output [31:0] w_grf_wdata, // GRF 待写入数据

    output [31:0] w_inst_addr  // W 级 PC
);

    wire [31:0] PrAddr, PrWD, PrRD;
    wire [3:0] PrByteen;

    wire [31:2] TCAddr;
    wire [31:0] TCRD1, TCRD2, TCWD;


    CPU CPU (
        .clk         (clk),
        .reset       (reset),
        .i_inst_rdata(i_inst_rdata),
        .i_inst_addr (i_inst_addr),

        .HWInt         (HWInt),
        .macroscopic_pc(macroscopic_pc),

        // for bridge
        .m_data_rdata (PrRD),
        .m_data_addr  (PrAddr),
        .m_data_wdata (PrWD),
        .m_data_byteen(PrByteen),

        .m_inst_addr(m_inst_addr),
        .w_grf_we   (w_grf_we),
        .w_grf_addr (w_grf_addr),
        .w_grf_wdata(w_grf_wdata),
        .w_inst_addr(w_inst_addr)
    );


    BRIDGE BRIDGE (
        .PrAddr   (PrAddr),
        .PrWD     (PrWD),
        .PrByteen (PrByteen),
        .TCAddr   (TCAddr),
        .TCWE1    (TCWE1),
        .TCWE2    (TCWE2),
        .TCWD     (TCWD),

        .IntByteen(m_int_byteen),
        .IntAddr  (m_int_addr),

        .DMByteen (m_data_byteen),
        .DMWD     (m_data_wdata),
        .DMAddr   (m_data_addr),

        .TCRD1    (TCRD1),
        .TCRD2    (TCRD2),
        .DMRD     (m_data_rdata),
        .PrRD     (PrRD)
    );


    wire [5:0] HWInt = {3'b000, interrupt, IRQ2, IRQ1};

    TC TC1 (
        .clk  (clk),
        .reset(reset),
        .Addr (TCAddr),
        .WE   (TCWE1),
        .Din  (TCWD),
        .Dout (TCRD1),
        .IRQ  (IRQ1)
    );

    TC TC2 (
        .clk  (clk),
        .reset(reset),
        .Addr (TCAddr),
        .WE   (TCWE2),
        .Din  (TCWD),
        .Dout (TCRD2),
        .IRQ  (IRQ2)
    );





endmodule
