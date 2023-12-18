`define EX_INT   5'h00 // interrupt
`define EX_ADEL  5'h04 // address error exception (load or instruction fetch)
`define EX_ADES  5'h05 // address error exception (store)
`define EX_SYS   5'h08 // syscall exception
`define EX_BP    5'h09 // breakpoint exception
`define EX_RI    5'h0a // reserved instruction exception
`define EX_OV    5'h0c // coprocessor unusable exception

module ifetch(
    input                                  clk,
    input                                rst_n,
    input                         hazard_stall,
    input                            exe_stall,
    input                          cond_branch,
    input                 ie_mfc0_hazard_stall,
    input                 im_mfc0_hazard_stall,
    // input                 iw_mfc0_hazard_stall,
    input                            int_flush,
    input                            ifetch_ex,
    input  [31:0]                       int_pc,
    input  [31:0]                         dest,
    input                                  jmp,
    input  [2:0]                            op,
    output [31:0]                           pc,
    output [31:0]                          npc,
    output [31:0]               inst_sram_addr,
    output                      cond_exe_stall,
    output                      cond_cp0_stall,
    output                              cp0_ex,
    output [4:0]                    cp0_excode,
    output [31:0]                 cp0_badvaddr
);

reg [31:0]   saved_pc;

initial begin
    saved_pc = 32'hBFC00000;
end

npc u_npc(
    .pc(pc),
    .dest(dest),
    .jmp(jmp),
    .int_flush(int_flush),
    .int_pc(int_pc),
    .op(op),
    .npc(npc)
);

pc u_pc(
    .clk(clk),
    .ie_mfc0_hazard_stall(ie_mfc0_hazard_stall),
    .im_mfc0_hazard_stall(im_mfc0_hazard_stall),
    // .iw_mfc0_hazard_stall(iw_mfc0_hazard_stall),
    .hazard_stall(hazard_stall),
    .cond_branch(cond_branch),
    .exe_stall(exe_stall),
    .saved_pc(saved_pc),
    .rst_n(rst_n),
    .din(npc),
    .pc(pc),
    .cond_exe_stall(cond_exe_stall),
    .cond_cp0_stall(cond_cp0_stall)
);

always @(posedge clk) begin
    if (rst_n == 1'b0) begin
        saved_pc <= 32'hBFC00000;
    end else begin
        saved_pc <= pc;
    end
end



assign cp0_ex = pc[1:0] != 2'b00;
assign cp0_excode = `EX_ADEL;
assign cp0_badvaddr = cp0_ex ? pc : 32'h0;

assign inst_sram_addr = ((npc[1:0] != 2'b00 | ifetch_ex) & ~int_flush) ? 32'h0 : npc;


endmodule