module mem_wb(
    input                            clk,  // clock
    input                         resetn,  // resetn
    input       [31:0]             ex_pc,  // pc data from ex/mem seg reg
    input       [31:0]        ex_alu_out,  // alu out from ex/mem seg reg
    input       [31:0]           ram_out,  // ram out from ram seg reg
    input       [31:0]         ex_rdata1,  // reg1(rs) data from ex/mem seg reg
    input       [2:0]         ex_rf_wsel,  // rd write sel from ex/mem seg reg
    input                      ex_rf_nwe,  // rd write enable from ex/mem seg reg
    input       [63:0]       ex_hilo_out,  // hilo out from ex/mem seg reg
    input       [4:0]              ex_rd,  // rd register addr from ex/mem seg reg
    output reg  [31:0]            mem_pc,  // pc data to mem/wb seg reg
    output reg  [31:0]       mem_alu_out,  // alu out to mem/wb seg reg
    output reg  [31:0]       mem_ram_out,  // ram out to mem/wb seg reg
    output reg  [31:0]        mem_rdata1,  // reg1(rs) data to mem/wb seg reg
    output reg  [2:0]        mem_rf_wsel,  // regfile write sel to mem/wb seg reg
    output reg                mem_rf_nwe,  // rd write enable to mem/wb seg reg
    output reg  [4:0]             mem_rd,   // rd register to mem/wb seg reg
    output reg  [63:0]      mem_hilo_out   // hilo out to mem/wb seg reg
);


initial begin
    mem_pc = 32'h0;
    mem_alu_out = 32'h0;
    mem_ram_out = 32'h0;
    mem_rdata1 = 32'h0;
    mem_rf_wsel = 3'h0;
    mem_rf_nwe = 1'b0;
    mem_rd = 5'h0;
    mem_hilo_out = 64'h0;
end

always @(posedge clk) begin
    if (resetn == 1'b0) begin
        mem_pc <= 32'h0;
        mem_alu_out <= 32'h0;
        mem_ram_out <= 32'h0;
        mem_rdata1 <= 32'h0;
        mem_rf_wsel <= 3'h0;
        mem_rf_nwe <= 1'b0;
        mem_rd <= 5'h0;
        mem_hilo_out <= 64'h0;
    end
    else begin
        mem_pc <= ex_pc;
        mem_alu_out <= ex_alu_out;  
        mem_ram_out <= ram_out;     
        mem_rdata1 <= ex_rdata1;    
        mem_rf_wsel <= ex_rf_wsel; 
        mem_rf_nwe <= ex_rf_nwe;     
        mem_rd <= ex_rd;    
        mem_hilo_out <= ex_hilo_out;    
    end
end

endmodule