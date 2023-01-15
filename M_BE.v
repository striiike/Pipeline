`define sw 2'b00
`define sh 2'b01
`define sb 2'b10

module M_BE (
    input        Ov,
    input  [31:0]addr,
    output reg  AdES,

    input  [1:0] M_sel_st,
    input  [1:0] addr10,
    output [3:0] byteEn
);
    assign byteEn = (M_sel_st == `sw) ? 4'b1111 :
                    (M_sel_st == `sh) ? (
                        (addr10 == 2'b00) ? 4'b0011 :
                        (addr10 == 2'b10) ? 4'b1100 : 4'b0
                    ) :
                    (M_sel_st == `sb) ? (
                        (addr10 == 2'b00) ? 4'b0001 :
                        (addr10 == 2'b01) ? 4'b0010 : 
                        (addr10 == 2'b10) ? 4'b0100 :
                        (addr10 == 2'b11) ? 4'b1000 : 4'b0
                    ) : 4'b0000;


    always @(*) begin
        AdES = 0;

        if (M_sel_st == `sw) begin          //
            if (|addr10[1:0])  AdES = 1'b1;
        end
        if (M_sel_st == `sh) begin          //
            if (addr10[0])  AdES = 1'b1;
        end
        if (M_sel_st == `sh || M_sel_st == `sb) begin   // save timer with sb & sh
            if ((addr >= 32'h7f00 && addr <= 32'h7f0b)
              ||(addr >= 32'h7f10 && addr <= 32'h7f1b)) AdES = 1'b1;
        end
        if (M_sel_st == `sw || M_sel_st == `sh || M_sel_st == `sb) begin 
            if ((addr >= 32'h7f08 && addr <= 32'h7f0b)      // save timer.count with store
              ||(addr >= 32'h7f18 && addr <= 32'h7f1b)) AdES = 1'b1;
            if (Ov) AdES = 1'b1;                            // arch overflow
            if (!((addr >= 32'h7f00 && addr <= 32'h7f0b)    // addr overflow  
              ||(addr >= 32'h7f10 && addr <= 32'h7f1b)
              ||(addr >= 32'h0000 && addr <= 32'h2fff)
              ||(addr >= 32'h7f20 && addr <= 32'h7f23))) AdES = 1'b1;
        end

    end
endmodule  //M_BE
