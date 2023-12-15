module div(
    input                 clk,
    input              resetn,
    input                sign,   // 0: unsigned, 1: signed
    input           int_flush,
    input [31:0]            A,
    input [31:0]            B,
    input          sourceData,
    output [63:0]           F,
    output  reg       hasData,
    output  reg        dataOK
);
 
reg           dividend_tvalid;   // 被除数
reg            divisor_tvalid;

reg          dividendu_tvalid;   // 被除数
reg           divisoru_tvalid;

wire          dividend_tready;
wire           divisor_tready;
wire              dout_tvalid;

wire         dividendu_tready;
wire          divisoru_tready;
wire             doutu_tvalid;

wire [63:0]            F_sign;
wire [63:0]          F_unsign;

reg  [2:0]              state;
reg  [31:0]          dividend;
reg  [31:0]           divisor;
reg                    r_sign;

assign F = r_sign ? F_sign : F_unsign;

initial begin
    dividend_tvalid <= 1'b0;
    divisor_tvalid <= 1'b0;
    dividendu_tvalid <= 1'b0;
    divisoru_tvalid <= 1'b0;
    dividend <= 32'h0;
    divisor <= 32'h0;
    hasData <= 1'b0;
    dataOK <= 1'b0;
    state <= 3'b000;
    r_sign <= 1'b0;
end

always @(posedge clk) begin
    if(~resetn | int_flush) begin
        dividend_tvalid <= 1'b0;
        divisor_tvalid <= 1'b0;
        dividendu_tvalid <= 1'b0;
        divisoru_tvalid <= 1'b0;
        dividend <= 32'h0;
        divisor <= 32'h0;
        hasData <= 1'b0;
        dataOK <= 1'b0;
        state <= 3'b000;
        r_sign <= 1'b0;
    end
    else begin
    case (state)
        3'b000:
            if(sourceData) begin
                if (sign) begin
                    divisor_tvalid <= 1'b1;
                    dividend_tvalid <= 1'b1;
                end else begin
                    divisoru_tvalid <= 1'b1;
                    dividendu_tvalid <= 1'b1;
                end
                r_sign <= sign;
                hasData <= 1'b1;
                dataOK <= 1'b0;
                state <= 3'b001;
                dividend <= A;
                divisor <= B;
            end
            else begin
                divisor_tvalid <= 1'b0;
                dividend_tvalid <= 1'b0;
                divisoru_tvalid <= 1'b0;
                dividendu_tvalid <= 1'b0;
                dataOK <= 1'b0;
                hasData <= 1'b0;
                dividend <= 32'h0;
                divisor <= 32'h0;
            end
        3'b001:
            if(r_sign && divisor_tready && dividend_tready) begin
                divisor_tvalid <= 1'b0;
                dividend_tvalid <= 1'b0;
                state <= 3'b010;
            end
            else if(!r_sign && divisoru_tready && dividendu_tready) begin
                divisoru_tvalid <= 1'b0;
                dividendu_tvalid <= 1'b0;
                state <= 3'b010;
            end
        3'b010:
            if((r_sign && dout_tvalid) || (!r_sign && doutu_tvalid)) begin
                dataOK <= 1'b1;
                hasData <= 1'b0;
                state <= 3'b000;
                dividend <= 32'h0;
                divisor <= 32'h0;
            end
    endcase
    end
end


div_ip u_div_ip(
    .aclk(clk),
    .s_axis_dividend_tvalid(dividend_tvalid),
    .s_axis_divisor_tvalid(divisor_tvalid),
    .s_axis_dividend_tdata(dividend),
    .s_axis_divisor_tdata(divisor),
    .s_axis_dividend_tready(dividend_tready),
    .s_axis_divisor_tready(divisor_tready),
    .m_axis_dout_tvalid(dout_tvalid),   
    .m_axis_dout_tdata(F_sign)
);


divu_ip u_divu_ip(
    .aclk(clk),
    .s_axis_dividend_tvalid(dividendu_tvalid),
    .s_axis_divisor_tvalid(divisoru_tvalid),
    .s_axis_dividend_tdata(dividend),
    .s_axis_divisor_tdata(divisor),
    .s_axis_dividend_tready(dividendu_tready),
    .s_axis_divisor_tready(divisoru_tready),
    .m_axis_dout_tvalid(doutu_tvalid),   
    .m_axis_dout_tdata(F_unsign)
);

endmodule