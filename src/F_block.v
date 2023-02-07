`include "const.v"
module F_block (
    input             clk,
    input             reset,

    // handshake signal
    input       allowin_next,
    output      allowin,
    input       valid_last,
    output      ready_go,
    output  reg    valid,   
    

    output            inst_req,
    output     [31:0] inst_addr,
    input      [31:0] inst_rdata,
    input             inst_addr_ok ,
    input             inst_data_ok ,

    // data
    input      [31:0]           pc_in,
    output reg [31:0]           pc_out,
    output reg [31:0]           instr_out,

    // exception
    input             req,
    input             eret,
    input      [31:0] EPC,
    
    output            F_eret,
    output reg     [4:0]      exc_o,
    output  reg   [31:0] badVAddr_o,

    input             bdIn,
    output reg        bdOut

    //exception end  
);
    reg req_state;

    // exception
    wire AdEL;
    assign AdEL     = |pc_in[1:0];
    // exception end    


    // always @(posedge clk ) begin
    //     if (reset) req_state <= 0;
    //     else if (inst_addr_ok) req_state <= 1;
    //     else if (inst_data_ok) req_state <= 0; 
    // end

    reg req_flag;
    always @(posedge clk ) begin
        if (reset) req_flag <= 1'b0;
        else if (inst_addr_ok) req_flag <= 1'b1;
        else if (inst_data_ok) req_flag <= 1'b0;
    end

    assign inst_req = !req_flag;
    assign inst_addr = pc_in;


    assign allowin    = allowin_next && (inst_addr_ok);

    // assign ready_go   = ready_go && valid;
    always @(posedge clk ) begin
        if (reset) begin
            valid <= 0;
            pc_out    <= 32'hbfc00000;

        end
        else if (allowin_next) begin
            valid  <= valid_last && inst_addr_ok  && !(AdEL);
            pc_out <= pc_in;
            exc_o  <= (AdEL) ? 5'd4 : 5'd0;
            badVAddr_o <= (AdEL) ? pc_in : 0;
        end
    end




endmodule
