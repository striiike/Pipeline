
module cache(
    input clk,
    input reset,

    input refill,
    output miss,
    output cache_hit,
    // write
    input en,
    input [31:0] addr_w,
    input [31:0] data_w,
    input [3:0]  wen,

    // read
    input en_r,
    input [31:0] addr_r,
    output [31:0] data_r
);

    wire [5:0] index_r, index_w;
    wire [13:0] tag_r, tag_w, tag_r0, tag_r1;

    // addr is word aligned
    assign {tag_r, index_r} = addr_r[19:0];
    assign {tag_w, index_w} = addr_w[19:0];

    wire valid_r0, valid_r1;
    
    wire hit0, hit1, hit;
    
    assign hit0 = en_r && ({1'b1, tag_r} == {valid_r0, tag_r0});
    assign hit1 = en_r && ({1'b1, tag_r} == {valid_r1, tag_r1});
    assign hit = hit0 | hit1;

    assign miss = !hit && en_r;


    reg [63:0] lru;
    always @(posedge clk) begin
        if (reset) begin
            lru <= 64'b0;  
        end else if (refill) begin
            lru[index_w] <= ~lru[index_w];
        end else begin
            lru[index_r] <= hit0 ? 1'b1 : 
                            hit1 ? 1'b0 :
                            lru[index_r];
        end
    end

    tag tag0(
        .clk    (clk),
        .we     (refill && !lru[index_w]),
        .a      (index_w),
        .d      ({1'b1, tag_w}),

        .dpra   (index_r),
        .dpo    ({valid_r0, tag_r0})
    );

    tag tag1(
        .clk    (clk),
        .we     (refill && lru[index_w]),
        .a      (index_w),
        .d      ({1'b1, tag_w}),

        .dpra   (index_r),
        .dpo    ({valid_r1, tag_r1})
    );

    wire [31:0] data_r0, data_r1;
    reg [1:0] hit_save;
    always @(posedge clk) begin
        if (reset) hit_save <= 2'b0;
        else hit_save <= {hit1, hit0};
    end
    assign cache_hit = |hit_save;
    assign data_r = hit_save[0] ? data_r0 : 
                    hit_save[1] ? data_r1 : 0;

    way way0(
        .clk    (clk),
        // .reset  ( reset  ),
        .refill (refill && !lru[index_w]),
        .en     (refill && !lru[index_w]),
        .addr_w (addr_w),
        .data_w (data_w),
        .wen    (wen),

        .en_r   (hit0),
        .addr_r (addr_r),
        .data_r (data_r0)
    );

    way way1(
        .clk    (clk),
        // .reset  ( reset  ),
        .refill (refill && lru[index_w]),
        .en     (refill && lru[index_w]),
        .addr_w (addr_w),
        .data_w (data_w),
        .wen    (wen),

        .en_r   (hit1),
        .addr_r (addr_r),
        .data_r (data_r1)
    );



endmodule