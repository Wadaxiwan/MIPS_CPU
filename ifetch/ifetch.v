module ifetch(
    input                      clk,
    input                    rst_n,
    input             hazard_stall,
    input                exe_stall,
    input              cond_branch,
    input  [31:0]             dest,
    input                      jmp,
    input  [2:0]                op,
    output [31:0]               pc,
    output [31:0]              npc,
    output          cond_exe_stall
);

reg [31:0] saved_pc;


npc u_npc(
    .pc(pc),
    .dest(dest),
    .jmp(jmp),
    .op(op),
    .npc(npc)
);

pc u_pc(
    .clk(clk),
    .hazard_stall(hazard_stall),
    .cond_branch(cond_branch),
    .exe_stall(exe_stall),
    .saved_pc(saved_pc),
    .rst_n(rst_n),
    .din(npc),
    .pc(pc),
    .cond_exe_stall(cond_exe_stall)
);

always @(posedge clk) begin
    if (rst_n == 1'b0) begin
        saved_pc <= 32'hBFC00000;
    end else begin
        saved_pc <= pc;
    end
end


endmodule