module D_GRF (
    input  [31:0] instr,
    input  [31:0] pc,
    input         clk,
    input         rst,
    input  [ 4:0] A1,
    input  [ 4:0] A2,
    input  [ 4:0] A3,
    input         WE,
    input  [31:0] WD3,
    output [31:0] RD1,
    output [31:0] RD2
);
    reg [31:0] grf[0:31];

    // reg [31:0] instrMem[0:1023];

    assign RD1 = (A1 == A3 && A3 != 5'b0 && WE) ? WD3 : grf[A1];
    assign RD2 = (A2 == A3 && A3 != 5'b0 && WE) ? WD3 : grf[A2];

    integer i = 0;

    integer j = 0;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            grf[i] <= 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                grf[i] <= 0;
            end
        end else begin
            // j <= j + 1;
            // instrMem[j] <= instr;
            // if (pc == 32'h0000322c) begin
            //     $write("%d@%hx: $ 30 <= %h", $time, pc, instr);
            //     for (i = 0; i < j; i = i + 1) begin
            //         $write("%h", instrMem[i]);
            //     end
            //     $display ("%h", instr);
            // end
            if (WE && A3 > 0) begin

                grf[A3] <= WD3;
            end

        end
    end



endmodule
