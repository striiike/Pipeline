`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮�?关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮�?关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时�?1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共�?
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持�?0
    output wire base_ram_ce_n,       //BaseRAM片�?�，低有�?
    output wire base_ram_oe_n,       //BaseRAM读使能，低有�?
    output wire base_ram_we_n,       //BaseRAM写使能，低有�?

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�?0
    output wire ext_ram_ce_n,       //ExtRAM片�?�，低有�?
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有�?
    output wire ext_ram_we_n,       //ExtRAM写使能，低有�?

    //直连串口信号
    output wire txd,  //直连串口发�?�端
    input  wire rxd,  //直连串口接收�?

    //Flash存储器信号，参�?? JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效�?16bit模式无意�?
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧�?
    output wire flash_ce_n,         //Flash片�?�信号，低有�?
    output wire flash_oe_n,         //Flash读使能信号，低有�?
    output wire flash_we_n,         //Flash写使能信号，低有�?
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash�?16位模式时请设�?1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素�?3�?
    output wire[2:0] video_green,  //绿色像素�?3�?
    output wire[1:0] video_blue,   //蓝色像素�?2�?
    output wire video_hsync,       //行同步（水平同步）信�?
    output wire video_vsync,       //场同步（垂直同步）信�?
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐�?
    
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M, cpu_clk, soc_clk;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(cpu_clk), // 时钟输出1，频率在IP配置界面中设�?
  .clk_out2(soc_clk), // 时钟输出2，频率在IP配置界面中设�?
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出�?"1"表示时钟稳定�?
                     // 后级电路复位信号应当由它生成（见下）
 );

reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge cpu_clk or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

wire clk, resetn;
assign clk = cpu_clk;
assign resetn = ~reset_of_clk10M;

//reg for base ram
reg [31:0] base_ram_data_r;
reg [19:0] base_ram_addr_r;
reg [3:0] base_ram_be_n_r;
reg base_ram_ce_n_r;
reg base_ram_oe_n_r;
reg base_ram_we_n_r;
//reg for ext ram
reg [31:0] ext_ram_data_r;
reg [19:0] ext_ram_addr_r;
reg [3:0] ext_ram_be_n_r;
reg ext_ram_ce_n_r;
reg ext_ram_oe_n_r;
reg ext_ram_we_n_r;

//cpu inst sram
wire        cpu_inst_en;
wire [3 :0] cpu_inst_wen;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_wen;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;
//inst sram
wire        inst_sram_en;
wire [3 :0] inst_sram_wen;
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_wdata;
wire [31:0] inst_sram_rdata;
//data sram
wire        data_sram_en;
wire [3 :0] data_sram_wen;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire [31:0] data_sram_rdata;
//conf
wire        conf_en;
wire [3 :0] conf_wen;
wire [31:0] conf_addr;
wire [31:0] conf_wdata;
wire [31:0] conf_rdata;

//reg count;
reg [19:0] inst_addr_save, data_addr_save;
reg inst_en_save, data_en_save;

reg [1:0] stage_inst, stage_data;
wire req_inst, req_data;

assign req_inst = (stage_inst == 2'b0) && (!base_ram_ce_n && (!base_ram_oe_n || !base_ram_we_n)) ;

assign req_data = ((stage_data == 2'b0) && (!ext_ram_ce_n && (!ext_ram_oe_n || !ext_ram_we_n))) ||
                  ((stage_inst != 2'b10) && (cpu_data_en && inst_sram_en && !base_ram_ce_n)) ;


reg [31:0] base_addr_save, base_data_save;
reg [3:0] base_wen_save;
reg icache_refill;

wire [31:0] icache_data_r;



//out
wire icache_miss, icache_hit;

wire [19:0] base_addr = inst_sram_en ? inst_sram_addr[21:2] : cpu_inst_addr[21:2];
wire [3:0] base_be_n = (|inst_sram_wen) ? ~inst_sram_wen : 4'b0;
wire base_ce_n = ~cpu_inst_en & ~inst_sram_en;
wire base_oe_n = ~(cpu_inst_en & ~(|cpu_inst_wen)) & ~(inst_sram_en & ~(|inst_sram_wen));
wire base_we_n = ~(cpu_inst_en & (|cpu_inst_wen)) & ~(inst_sram_en & (|inst_sram_wen));
wire [31:0] base_data = ~base_ram_we_n ? inst_sram_wdata : 32'bz;

assign base_ram_addr = icache_miss ? base_addr : 0;
assign base_ram_be_n = icache_miss ? base_be_n : 1;
assign base_ram_ce_n = icache_miss ? base_ce_n : 1;
assign base_ram_oe_n = icache_miss ? base_oe_n : 1;
assign base_ram_we_n = icache_miss ? base_we_n : 1;
assign base_ram_data = icache_miss ? base_data : 32'bz;

assign ext_ram_addr = data_sram_addr[21:2];
assign ext_ram_be_n = (|data_sram_wen) ? ~data_sram_wen : 4'b0;
assign ext_ram_ce_n = ~data_sram_en;
assign ext_ram_oe_n = ~(data_sram_en & ~(|data_sram_wen));
assign ext_ram_we_n = ~(data_sram_en & (|data_sram_wen));
assign ext_ram_data = ~ext_ram_we_n ?data_sram_wdata : 32'bz;

cache icache(
    .clk    (clk),
    .reset  (!resetn),
    .refill (icache_refill && !(cpu_data_en && inst_sram_en/* && icache_miss && ~data_sram_en)*/)),
    .cache_hit (icache_hit),

    .miss   (icache_miss),
    .en     (icache_refill),
    .addr_w (base_addr_save),
    .data_w (base_ram_data),
    .wen    (4'b1111),
    .en_r   (!base_oe_n),
    .addr_r (base_addr),
    .data_r (icache_data_r)
);



always @(posedge clk) begin
    if (!resetn) begin
        base_ram_data_r <= 32'b0;
        ext_ram_data_r <= 32'b0;

        stage_inst <= 0;
        stage_data <= 0;
        base_addr_save <= 0;
        icache_refill <= 0;
        // base_wen_save <= 0;
    end else begin
        /*
        // case (stage_inst) 
        //     2'b00: begin
        //         if (cpu_data_en && inst_sram_en) begin
        //             stage_inst <= 2'b10;
        //         end
        //         else if (!base_ram_ce_n && (!base_ram_oe_n || !base_ram_we_n)) begin
        //             stage_inst <= 2'b1;
        //         end else begin
        //             stage_inst <= 2'b0;
        //         end
        //     end
        //     2'b01: begin
        //         if (cpu_data_en && inst_sram_en) begin
        //             stage_inst <= 2'b10;
        //         end else begin
        //             stage_inst <= 2'b0;
        //             base_ram_data_r <= base_ram_data;
        //         end
                
        //     end
        //     2'b10: begin
        //         stage_inst <= 2'b0;
        //         base_ram_data_r <= base_ram_data;
        //     end
        // endcase
        */
        case (stage_inst) 
            2'b00: begin
                if (icache_miss) begin
                    base_addr_save <= base_addr;
                    icache_refill <= 1'b1;
                    if (cpu_data_en && inst_sram_en) begin
                        stage_inst <= 2'b10;
                    end else begin
                        stage_inst <= 2'b1;
                    end
                end 
            end
            2'b01: begin

                // stage_inst <= 2'b0;
                // base_ram_data_r <= base_ram_data;
                // icache_refill <= 1'b0;

                if (cpu_data_en && inst_sram_en && icache_miss/* && ~data_sram_en*/) begin
                    base_addr_save <= base_addr;
                    icache_refill <= 1'b1;
                    stage_inst <= 2'b10;
                end else begin
                    stage_inst <= 2'b0;
                    base_ram_data_r <= base_ram_data;
                    icache_refill <= 1'b0;
                end
                
            end
            2'b10: begin
                stage_inst <= 2'b0;
                base_ram_data_r <= base_ram_data;
                icache_refill <= 1'b0;
            end
        endcase

        case (stage_data) 
            2'b0: begin
                if (!ext_ram_ce_n && (!ext_ram_oe_n || !ext_ram_we_n)) begin
                    stage_data <= 2'b1;
                end else begin
                    stage_data <= 2'b0;
                end
            end
            2'b1: begin
                stage_data <= 2'b0;
                ext_ram_data_r <= ext_ram_data;
            end
        endcase
    end
end









assign cpu_inst_rdata  = icache_hit ? icache_data_r : base_ram_data_r;
assign inst_sram_rdata = icache_hit ? icache_data_r : base_ram_data_r;
assign data_sram_rdata = ext_ram_data_r;

mycpu_top u_mycpu_top(
    .clk               (clk               ),
    .resetn            (resetn            ),
    .ext_int           (6'b0),
    .req_inst          (req_inst),
    .req_data          (req_data),
    .inst_sram_en      (cpu_inst_en       ),
    .inst_sram_wen     (cpu_inst_wen      ),
    .inst_sram_addr    (cpu_inst_addr     ),
    .inst_sram_wdata   (cpu_inst_wdata    ),
    .inst_sram_rdata   (cpu_inst_rdata    ),
    .data_sram_en      (cpu_data_en       ),
    .data_sram_wen     (cpu_data_wen      ),
    .data_sram_addr    (cpu_data_addr     ),
    .data_sram_wdata   (cpu_data_wdata    ),
    .data_sram_rdata   (cpu_data_rdata    )
);

bridge_1x3 u_bridge_1x3(
    .clk             (clk             ),
    .resetn          (resetn          ),
    .cpu_data_en     (cpu_data_en     ),
    .cpu_data_wen    (cpu_data_wen    ),
    .cpu_data_addr   (cpu_data_addr   ),
    .cpu_data_wdata  (cpu_data_wdata  ),
    .cpu_data_rdata  (cpu_data_rdata  ),
    .inst_sram_en    (inst_sram_en    ),
    .inst_sram_wen   (inst_sram_wen   ),
    .inst_sram_addr  (inst_sram_addr  ),
    .inst_sram_wdata (inst_sram_wdata ),
    .inst_sram_rdata (inst_sram_rdata ),
    .data_sram_en    (data_sram_en    ),
    .data_sram_wen   (data_sram_wen   ),
    .data_sram_addr  (data_sram_addr  ),
    .data_sram_wdata (data_sram_wdata ),
    .data_sram_rdata (data_sram_rdata ),
    .conf_en         (conf_en         ),
    .conf_wen        (conf_wen        ),
    .conf_addr       (conf_addr       ),
    .conf_wdata      (conf_wdata      ),
    .conf_rdata      (conf_rdata      )
);

confreg u_confreg(
    .clk        (clk        ),
    .resetn     (resetn     ),
    .conf_en    (conf_en    ),
    .conf_wen   (conf_wen   ),
    .conf_addr  (conf_addr  ),
    .conf_wdata (conf_wdata ),
    .conf_rdata (conf_rdata ),
    .txd        (txd        ),
    .rxd        (rxd        ),
    // .led        (leds        ),
    .switch     (8'b0     )
);

endmodule
