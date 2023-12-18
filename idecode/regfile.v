`timescale 1ns / 1ps

module regfile(
    input            clk,
    input  [4:0]  raddr1,
    output [31:0] rdata1,
    input  [4:0]  raddr2,
    output [31:0] rdata2,
    input             we,
    input  [4:0]   waddr,
    input  [31:0]  wdata
);

reg [31:0] regfile[31:0];

// initial begin
// //    $readmemh("../../../../lab_1.data/additional_reg_data1",regfile);
// $readmemh("../../../../lab_1.data/additional_reg_data2",regfile);
// //$readmemh("../../../../lab_1.data/base_reg_data",regfile);
// end
integer i;

initial begin
    for (i = 0; i < 32; i = i + 1) begin
        regfile[i] <= 32'h0;
    end
end


always @(negedge clk) begin
    if(we) begin
        if(waddr == 5'b00000) begin
            regfile[waddr] <= 32'h0;
        end else begin
            regfile[waddr] <= wdata;
        end
    end
end

assign rdata1 = regfile[raddr1];
assign rdata2 = regfile[raddr2];


endmodule