module mem_wb(
    input                            clk,  // clock
    input                         resetn,  // resetn
    input                     div_finish,
    input                  int_div_stall,
    input       [5:0]          ex_opcode,
    input       [5:0]            ex_func,
    input       [31:0]             ex_pc,  // pc data from ex/mem seg reg
    input       [31:0]        ex_alu_out,  // alu out from ex/mem seg reg
    input       [31:0]           ram_out,  // ram out from ram seg reg
    input       [31:0]         ex_rdata1,  // reg1(rs) data from ex/mem seg reg
    input       [31:0]         ex_rdata2,  // reg2(rt) data from ex/mem seg reg
    input       [2:0]         ex_rf_wsel,  // rd write sel from ex/mem seg reg
    input                      ex_rf_nwe,  // rd write enable from ex/mem seg reg
    input       [63:0]       ex_hilo_out,  // hilo out from ex/mem seg reg
    input       [4:0]              ex_rd,  // rd register addr from ex/mem seg reg
    input                     ex_cp0_tag,
    input                      int_flush,
    input                      ex_cp0_ex,  
    input      [4:0]       ex_cp0_excode,  
    input      [31:0]    ex_cp0_badvaddr,
    input                      ex_cp0_we,
    input                      ex_cp0_bd,
    input      [4:0]         ex_cp0_addr,
    input              ex_cp0_eret_flush,
    output reg  [31:0]            mem_pc,  // pc data to mem/wb seg reg
    output reg  [31:0]       mem_alu_out,  // alu out to mem/wb seg reg
    output reg  [31:0]       mem_ram_out,  // ram out to mem/wb seg reg
    output reg  [31:0]        mem_rdata1,  // reg1(rs) data to mem/wb seg reg
    output reg  [31:0]        mem_rdata2,  // reg2(rt) data to mem/wb seg reg
    output reg  [2:0]        mem_rf_wsel,  // regfile write sel to mem/wb seg reg
    output reg                mem_rf_nwe,  // rd write enable to mem/wb seg reg
    output reg  [4:0]             mem_rd,   // rd register to mem/wb seg reg
    output reg  [5:0]           mem_func,   
    output reg  [5:0]         mem_opcode,   
    output reg  [63:0]      mem_hilo_out,   // hilo out to mem/wb seg reg
    output reg                mem_cp0_ex,  
    output reg [4:0]      mem_cp0_excode,  
    output reg [31:0]   mem_cp0_badvaddr,
    output reg                mem_cp0_we,
    output reg                mem_cp0_bd,
    output reg [4:0]        mem_cp0_addr,
    output reg        mem_cp0_eret_flush,
    output reg               mem_cp0_tag
);


initial begin
    mem_pc = 32'h0;
    mem_alu_out = 32'h0;
    mem_ram_out = 32'h0;
    mem_rdata1 = 32'h0;
    mem_rdata2 = 32'h0;
    mem_rf_wsel = 3'h0;
    mem_rf_nwe = 1'b0;
    mem_rd = 5'h0;
    mem_hilo_out = 64'h0;
    mem_opcode = 6'h0;
    mem_func = 6'h0;
    mem_cp0_ex = 1'b0;
    mem_cp0_excode = 5'h0;
    mem_cp0_badvaddr = 32'h0;
    mem_cp0_we = 1'b0;
    mem_cp0_bd = 1'b0;
    mem_cp0_addr = 5'h0;
    mem_cp0_eret_flush = 1'b0;
    mem_cp0_tag = 1'b0;
end

always @(posedge clk) begin
    if (resetn == 1'b0 | int_flush) begin
        mem_pc <= 32'h0;
        mem_alu_out <= 32'h0;
        mem_ram_out <= 32'h0;
        mem_rdata1 <= 32'h0;
        mem_rdata2 <= 32'h0;
        mem_rf_wsel <= 3'h0;
        mem_rf_nwe <= 1'b0;
        mem_rd <= 5'h0;
        mem_hilo_out <= 64'h0;
        mem_opcode <= 6'h0;
        mem_func <= 6'h0;
        mem_cp0_ex <= 1'b0;
        mem_cp0_excode <= 5'h0;
        mem_cp0_badvaddr <= 32'h0;
        mem_cp0_we <= 1'b0;
        mem_cp0_bd <= 1'b0;
        mem_cp0_addr <= 5'h0;
        mem_cp0_eret_flush <= 1'b0;
        mem_cp0_tag <= 1'b0;
    end
    else if(~int_div_stall) begin
        mem_pc <= ex_pc;
        mem_alu_out <= ex_alu_out;  
        mem_ram_out <= ram_out;     
        mem_rdata1 <= ex_rdata1;
        mem_rdata2 <= ex_rdata2;    
        mem_rf_wsel <= ex_rf_wsel; 
        mem_rf_nwe <= ex_rf_nwe;     
        mem_rd <= ex_rd;    
        mem_hilo_out <= ex_hilo_out;
        mem_opcode <= ex_opcode;
        mem_func <= ex_func;    
        mem_cp0_ex <= ex_cp0_ex;
        mem_cp0_excode <= ex_cp0_excode;
        mem_cp0_badvaddr <= ex_cp0_badvaddr;
        mem_cp0_we <= ex_cp0_we;
        mem_cp0_bd <= ex_cp0_bd;
        mem_cp0_addr <= ex_cp0_addr;
        mem_cp0_eret_flush <= ex_cp0_eret_flush;
        mem_cp0_tag <=  div_finish ? 1'b0 : ex_cp0_tag;
    end
end

endmodule