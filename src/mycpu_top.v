module mycpu_top(
    input  [5:0]  ext_int,      
    input         aclk,
    input         aresetn, 
    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       ,
    //debug
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output [31:0] debug_wb_pc
);

cpu_axi_interface cpu_axi_interface(
    .clk           ( aclk           ),
    .resetn        ( aresetn        ),

    .inst_req      ( CPU.inst_req      ),
    .inst_wr       ( CPU.inst_wr       ),
    .inst_size     ( CPU.inst_size     ),
    .inst_addr     ( CPU.inst_addr     ),
    .inst_wdata    ( CPU.inst_wdata    ),
    .inst_rdata    ( CPU.inst_rdata    ),
    .inst_addr_ok  ( CPU.inst_addr_ok  ),
    .inst_data_ok  ( CPU.inst_data_ok  ),

    .data_req      ( CPU.data_req      ),
    .data_wr       ( CPU.data_wr       ),
    .data_size     ( CPU.data_size     ),
    .data_addr     ( CPU.data_addr     ),
    .data_wdata    ( CPU.data_wdata    ),
    .data_rdata    ( CPU.data_rdata    ),
    .data_addr_ok  ( CPU.data_addr_ok  ),
    .data_data_ok  ( CPU.data_data_ok  ),

    .arid          ( arid          ),
    .araddr        ( araddr        ),
    .arlen         ( arlen         ),
    .arsize        ( arsize        ),
    .arburst       ( arburst       ),
    .arlock        ( arlock        ),
    .arcache       ( arcache       ),
    .arprot        ( arprot        ),
    .arvalid       ( arvalid       ),
    .arready       ( arready       ),
    .rid           ( rid           ),
    .rdata         ( rdata         ),
    .rresp         ( rresp         ),
    .rlast         ( rlast         ),
    .rvalid        ( rvalid        ),
    .rready        ( rready        ),
    .awid          ( awid          ),
    .awaddr        ( awaddr        ),
    .awlen         ( awlen         ),
    .awsize        ( awsize        ),
    .awburst       ( awburst       ),
    .awlock        ( awlock        ),
    .awcache       ( awcache       ),
    .awprot        ( awprot        ),
    .awvalid       ( awvalid       ),
    .awready       ( awready       ),
    .wid           ( wid           ),
    .wdata         ( wdata         ),
    .wstrb         ( wstrb         ),
    .wlast         ( wlast         ),
    .wvalid        ( wvalid        ),
    .wready        ( wready        ),
    .bid           ( bid           ),
    .bresp         ( bresp         ),
    .bvalid        ( bvalid        ),
    .bready        ( bready        )
);

CPU CPU (
    .ext_int   (ext_int       ),   //high active

    .clk      (aclk       ),
    .resetn   (aresetn    ),   //low active



    //debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

endmodule