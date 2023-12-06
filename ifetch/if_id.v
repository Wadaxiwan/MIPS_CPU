`timescale 1ns / 1ps
module if_id(
        input clk,
        input resetn,
        input jmp,
        input [31:0] pc,
        input [31:0] inst,
        output reg [31:0] if_pc,
        output reg [31:0] if_inst
    );
    
initial begin
    if_pc = 32'h0;
    if_inst = 32'h0; 
end


always @(posedge clk) begin
    if (resetn == 1'b0 || jmp == 1'b1) begin
        if_pc <= 32'h0;
        if_inst <= 32'h0;
    end
    else begin
        if_pc <= pc;
        if_inst <= inst;
    end
end
    
endmodule
