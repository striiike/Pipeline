`define lw  3'd1
`define lh  3'd2
`define lhu 3'd3
`define lb  3'd4
`define lbu 3'd5


module M_LB (
   input        Ov,
   input  [31:0]addr,

   input  [ 2:0] M_sel_ld,
   input  [31:0] RD,
   input  [ 1:0] addr10,
   output [31:0] RD_real
);
   assign RD_real =  M_sel_ld == `lw      ? RD :
                     M_sel_ld == `lh  ? (
                        addr10 == 2'b00 ? {{16{RD[15]}}, RD[15: 0]} :
                        addr10 == 2'b10 ? {{16{RD[31]}}, RD[31:16]} : 32'b0
                     ) :
                     M_sel_ld == `lhu ? (
                        addr10 == 2'b00 ? {{16'd0}, RD[15: 0]} :
                        addr10 == 2'b10 ? {{16'd0}, RD[31:16]} : 32'b0
                     ) :
                     M_sel_ld == `lb   ? (
                        addr10 == 2'b00 ? {{24{RD[7]}}, RD[ 7: 0]} :
                        addr10 == 2'b01 ? {{24{RD[15]}}, RD[15: 8]} : 
                        addr10 == 2'b10 ? {{24{RD[23]}}, RD[23:16]} :
                        addr10 == 2'b11 ? {{24{RD[31]}}, RD[31:24]} : 32'b0
                     ) :
                     M_sel_ld == `lbu  ? (
                        addr10 == 2'b00 ? {{24'd0}, RD[ 7: 0]} :
                        addr10 == 2'b01 ? {{24'd0}, RD[15: 8]} : 
                        addr10 == 2'b10 ? {{24'd0}, RD[23:16]} :
                        addr10 == 2'b11 ? {{24'd0}, RD[31:24]} : 32'b0
                     ) : 32'b0;



   always @(*) begin

      //   if (M_sel_ld == `lw) begin          //
      //       if (|addr10[1:0])  AdEL = 1'b1;
      //   end
      //   if (M_sel_ld == `lh || M_sel_ld == `lhu) begin          //
      //       if (addr10[0])  AdEL = 1'b1;
      //   end
      //   if (M_sel_ld == `lh  || M_sel_ld == `lb ||
      //       M_sel_ld == `lhu || M_sel_ld == `lbu) begin   // load timer with lb & lh
      //       if ((addr >= 32'h7f00 && addr <= 32'h7f0b)
      //         ||(addr >= 32'h7f10 && addr <= 32'h7f1b)) AdEL = 1'b1;
      //   end
      //   if (M_sel_ld == `lw  || M_sel_ld == `lh || M_sel_ld == `lb ||
      //       M_sel_ld == `lhu || M_sel_ld == `lbu) begin 
      //       if (Ov) AdEL = 1'b1;                            // arch overflow
      //       if (!((addr >= 32'h7f00 && addr <= 32'h7f0b)    // addr overflow  
      //         ||(addr >= 32'h7f10 && addr <= 32'h7f1b)
      //         ||(addr >= 32'h0000 && addr <= 32'h2fff)
      //         ||(addr >= 32'h7f20 && addr <= 32'h7f23))) AdEL = 1'b1;
      //   end

    end
endmodule  //M_LB load in byte
