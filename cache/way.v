module way(
    input wire clk,
    input wire reset,

    input wire refill,
    // write
    input wire en,
    input wire [31:0] addr_w,
    input wire [31:0] data_w,
    input wire [3:0]  wen,

    // read
    input wire en_r,
    input wire [31:0] addr_r,
    output wire [31:0] data_r
);


    wire [5:0] index_r, index_w;
    wire [13:0] tag_r, tag_w, tag_r0, tag_r1;
    assign {tag_r, index_r} = addr_r[19:0];
    assign {tag_w, index_w} = addr_w[19:0];

    bank bank (
        .addra      (index_w),
        .clka       (clk),
        .dina       (data_w),
        .ena        (en),
        .wea        (wen),

        .addrb      (index_r),
        .clkb       (clk),
        .doutb      (data_r),
        .enb        (en_r)
    );

endmodule