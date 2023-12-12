`timescale 1ns / 1ps
module if_id(
        input clk,
        input resetn,
        input jmp,
        input hazard_stall,
        input [31:0] pc,
        input [31:0] inst,
        output [31:0] if_pc,
        output [31:0] if_inst
    );
    
reg [31:0] reg_if_pc;
reg [31:0] reg_if_inst;

initial begin
    reg_if_pc = 32'h0;
    reg_if_inst = 32'h0; 
end


always @(posedge clk) begin
    if (resetn == 1'b0) begin
        reg_if_pc <= 32'h0;
        reg_if_inst <= 32'h0;
    end
    else if (hazard_stall == 1'b1) begin
        reg_if_pc <= reg_if_pc;
        reg_if_inst <= reg_if_inst;
    end else
    begin
        reg_if_pc <= pc;
        reg_if_inst <= inst;
    end
end
    
assign if_pc = reg_if_pc;
assign if_inst = reg_if_inst;

endmodule
