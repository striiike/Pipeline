module mycpu_top (
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

wire [31:0] inst_addr, data_addr;
cpu cpu(
    .clk               (clk               ),
    .resetn            (resetn            ),
    .ext_int           (ext_int           ),
    .req_inst          (req_inst),
    .req_data          (req_data),
    .inst_sram_en      (inst_sram_en       ),
    .inst_sram_wen     (inst_sram_wen      ),
    .inst_sram_addr    (inst_addr     ),
    .inst_sram_wdata   (inst_sram_wdata    ),
    .inst_sram_rdata   (inst_sram_rdata    ),
    .data_sram_en      (data_sram_en       ),
    .data_sram_wen     (data_sram_wen      ),
    .data_sram_addr    (data_addr     ),
    .data_sram_wdata   (data_sram_wdata    ),
    .data_sram_rdata   (data_sram_rdata    )
    // .debug_wb_pc       (debug_wb_pc       ),
    // .debug_wb_rf_wen   (debug_wb_rf_wen   ),
    // .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    // .debug_wb_rf_wdata (debug_wb_rf_wdata )
);

assign inst_sram_addr = (inst_addr[31:29] == 3'b100 || inst_addr[31:29] == 3'b101) ? {3'b0, inst_addr[28:0]} : inst_addr;
assign data_sram_addr = (data_addr[31:29] == 3'b100 || data_addr[31:29] == 3'b101) ? {3'b0, data_addr[28:0]} : data_addr;


endmodule