`define ALUB_RT   2'b01
`define ALUB_RS   2'b10
`define ALUB_EXT  2'b11 


module execute(
    input [5:0]       func,
    input [5:0]     opcode,
    input           rf_nwe,
    input [4:0]     alu_op,
    input [1:0]     rs_sel,
    input [1:0]     rt_sel,
    input [31:0]    rdata1,
    input [31:0]    rdata2,
    input [31:0]       imm,
    output[31:0]   alu_out,
    output            zero,
    output         rf_nwef
);

wire         Cout;
wire [31:0] data1;
wire [31:0] data2;

assign data1 = (rs_sel == `ALUB_EXT) ? imm : rdata1;
assign data2 = (rt_sel == `ALUB_EXT) ? imm : rdata2;

alu u_alu(
    .A(data1),
    .B(data2),
    .Cin(1'b0),
    .Card(alu_op),
    .F(alu_out),
    .Cout(Cout),
    .Zero(zero)  // Ω”»Îbr
);

assign rf_nwef =  (opcode == 6'b000000 && func == 6'b001010 && zero == 1'b1) |
                  ((opcode != 6'b000000 || func != 6'b001010) && rf_nwe) ;

endmodule