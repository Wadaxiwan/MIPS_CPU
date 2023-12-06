module ifetch(
    input                  clk,
    input                rst_n,
    input                 stop,
    input  [31:0]         dest,
    input  [31:0]       ori_pc,
    input                  jmp,
    input  [2:0]            op,
    output [31:0]           pc,
    output [31:0]          npc
);

wire [31:0]          pc_addr;
reg                   hazard;

initial begin
    hazard = 1'b0;
end

always @(*) begin
    if(stop) begin
        hazard = 1'b1;
    end
    else begin
        hazard = 1'b0;
    end
end


npc u_npc(
    .pc(pc),
    .dest(dest),
    .jmp(jmp),
    .op(op),
    .npc(npc)
);

pc u_pc(
    .clk(clk),
    .rst_n(rst_n),
    .din(npc),
    .pc(pc_addr)
);

assign pc = hazard == 1'b1 ? ori_pc : pc_addr;

endmodule