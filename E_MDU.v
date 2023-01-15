`define mdu_mult 4'd1
`define mdu_multu 4'd2
`define mdu_div 4'd3
`define mdu_divu 4'd4
`define mdu_mfhi 4'd5
`define mdu_mflo 4'd6
`define mdu_mthi 4'd7
`define mdu_mtlo 4'd8

module E_MDU (
    input             req,
    input             clk,
    input             reset,
    input      [31:0] A,
    input      [31:0] B,
    input      [ 3:0] E_sel_MDU,
    output     [31:0] E_mdu,
    output reg        busy,
    output            start
);
    reg [31:0] hi, lo, hi_temp, lo_temp;
    reg [31:0] status;
    initial begin
        hi      <= 0;
        lo      <= 0;
        hi_temp <= 0;
        lo_temp <= 0;
        busy    <= 1'b0;
        status  <= 0;
    end
    assign E_mdu = (E_sel_MDU == `mdu_mfhi) ? hi : (E_sel_MDU == `mdu_mflo) ? lo : 0;
    assign start = (E_sel_MDU == `mdu_mult) || (E_sel_MDU == `mdu_multu) || (E_sel_MDU == `mdu_div) || (E_sel_MDU == `mdu_divu);

    always @(posedge clk) begin
        if (reset | (status == 0 && req)) begin
            hi      <= 0;
            lo      <= 0;
            hi_temp <= 0;
            lo_temp <= 0;
            busy    <= 1'b0;
            status  <= 0;
        end else begin
            if (status == 0) begin
                case (E_sel_MDU)
                    `mdu_mult: begin
                        busy               <= 1'b1;
                        status             <= 4;
                        {hi_temp, lo_temp} <= $signed(A) * $signed(B);
                    end
                    `mdu_multu: begin
                        busy               <= 1'b1;
                        status             <= 4;
                        {hi_temp, lo_temp} <= A * B;
                    end
                    `mdu_div: begin
                        busy    <= 1'b1;
                        status  <= 9;
                        lo_temp <= $signed(A) / $signed(B);
                        hi_temp <= $signed(A) % $signed(B);
                    end
                    `mdu_divu: begin
                        busy    <= 1'b1;
                        status  <= 9;
                        lo_temp <= A / B;
                        hi_temp <= A % B;
                    end
                    `mdu_mthi: begin
                        hi <= A;
                    end
                    `mdu_mtlo: begin
                        lo <= A;
                    end

                endcase
            end else begin
                if (status == 1) begin
                    {hi, lo} <= {hi_temp, lo_temp};
                    status   <= status - 1;
                    busy     <= 1'b0;
                end else begin
                    status <= status - 1;
                end
            end
        end

    end





endmodule  //E_MDU
