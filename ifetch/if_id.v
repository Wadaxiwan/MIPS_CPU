`timescale 1ns / 1ps
module if_id(
        input                 clk,
        input                 resetn,
        input                 jmp,
        input                 exe_stall,
        input                 hazard_stall,
        input                 cond_exe_stall,
        input                 cond_cp0_stall,
        input                 int_div_stall,
        input                 ie_mfc0_hazard_stall,
        input                 im_mfc0_hazard_stall,
        input                 int_flush,
        input                 cp0_ex,  // first in ifetch , this inst is a exception
        input    [4:0]        cp0_excode,  // first in ifetch
        input    [31:0]       cp0_badvaddr,  // first in ifetch
        input    [31:0]       pc,
        input    [31:0]       inst,
        output   [31:0]       if_pc,
        output   [31:0]       if_inst,
        output   reg          if_cp0_ex,
        output   reg [4:0]    if_cp0_excode, 
        output   reg [31:0]   if_cp0_badvaddr 
    );
    
reg [31:0] reg_if_pc;
reg [31:0] reg_if_inst;

initial begin
    reg_if_pc = 32'h0;
    reg_if_inst = 32'h0; 
    if_cp0_ex = 1'b0;
    if_cp0_excode = 5'h0;
    if_cp0_badvaddr = 32'h0;
end


always @(posedge clk) begin
    if (resetn == 1'b0 | cond_exe_stall | cond_cp0_stall | int_flush) begin  
        reg_if_pc <= 32'h0;
        reg_if_inst <= 32'h0;
        if_cp0_ex <= 1'b0;
        if_cp0_excode <= 5'h0;
        if_cp0_badvaddr <= 32'h0;
    end
    else if (hazard_stall | exe_stall | ie_mfc0_hazard_stall | im_mfc0_hazard_stall | int_div_stall) begin
        reg_if_pc <= reg_if_pc;
        reg_if_inst <= reg_if_inst;
        if_cp0_ex <= if_cp0_ex;
        if_cp0_excode <= if_cp0_excode;
        if_cp0_badvaddr <= if_cp0_badvaddr;
    end else
    begin
        reg_if_pc <= pc;
        reg_if_inst <= inst;
        if_cp0_ex <= cp0_ex;
        if_cp0_excode <= cp0_excode;
        if_cp0_badvaddr <= cp0_badvaddr;
    end
end
    
assign if_pc = reg_if_pc;
assign if_inst = reg_if_inst;

endmodule
