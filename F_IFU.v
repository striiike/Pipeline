module F_IFU (
    input         req,
    input         eret,
    input  [31:0] EPC,
    output        AdEL,

    input         en,
    input         clk,
    input  [31:0] npc,
    input         rst,
    input  [31:0] i_instr,
    output [31:0] pc
);
    reg  [31:0] instrMem[0:4095];
    reg  [31:0] pcReg;
    wire [31:0] pc_real;

    integer i, j = 0;

    initial begin
        pcReg = 32'h00003000;
        j <= 0;
    end

    assign pc_real = pcReg - 32'h00003000;
    assign pc      = (eret) ? EPC : pcReg;
    wire instr   = i_instr;

    // exception

    assign AdEL    = (|pc[1:0] || pc > 32'h6ffc || pc < 32'h3000);

    // exception end    


    always @(posedge clk) begin
        if (rst | req) begin
            pcReg <= (req) ? 32'h4180 : 32'h00003000;
            j     <= 0;
        end else if (en) begin

            // j           <= j + 1;
            // instrMem[j] <= i_instr;
            // if (pc == 32'h00004288) begin
            //     $write("%d@%hx: $ 30 <= %h", $time, pc, i_instr);
            //     for (i = 0; i < j; i = i + 1) begin
            //         $write("%h", instrMem[i]);
            //     end
            //     $display("%h", i_instr);
            // end

            pcReg <= npc;
        end else;
    end



endmodule
