module ifetch(
    input                  clk,
    input                rst_n,
    input         hazard_stall,
    input            exe_stall,
    input  [31:0]         dest,
    input                  jmp,
    input  [2:0]            op,
    output [31:0]           pc,
    output [31:0]          npc
);

reg [31:0] saved_pc;
wire stall = hazard_stall | exe_stall;

npc u_npc(
    .pc(pc),
    .dest(dest),
    .jmp(jmp),
    .op(op),
    .npc(npc)
);

pc u_pc(
    .clk(clk),
    .stall(stall),
    .saved_pc(saved_pc),
    .rst_n(rst_n),
    .din(npc),
    .pc(pc)
);

always @(posedge clk) begin
    if (rst_n == 1'b0) begin
        saved_pc <= 32'h0;
    end else begin
        saved_pc <= pc;
    end
end


endmodule