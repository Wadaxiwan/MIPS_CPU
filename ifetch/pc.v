module pc(
    input                     clk,
    input                   rst_n,
    input            hazard_stall,
    input               exe_stall,
    input             cond_branch,
    input  [31:0]        saved_pc,
    input  [31:0]             din,
    output [31:0]              pc,
    output reg     cond_exe_stall
);

reg [31:0] pc_addr;

initial begin
    pc_addr = 32'hBFC00000;
    cond_exe_stall = 1'b0;
end

always @(posedge clk) begin
    if(~rst_n) begin
        pc_addr <= 32'hBFC00000;
        cond_exe_stall <= 1'b0;
    end 
    else if(cond_branch && exe_stall) begin
        pc_addr <= saved_pc;
        cond_exe_stall <= 1'b1;
    end else begin
        pc_addr <= din;
        cond_exe_stall <= 1'b0;
    end
end

assign pc = (hazard_stall | exe_stall) ? saved_pc : pc_addr;

endmodule