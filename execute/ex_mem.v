
module ex_mem(
    input                         clk,  // clock
    input                      resetn,  // resetn
    input       [31:0]          id_pc,  // pc data from id/ex seg reg
    input       [31:0]        alu_out,  // alu out generate by execute
    input       [63:0]       hilo_out,  // ram out generate by execute
    input                          br,  // zero generate by execute
    input       [2:0]      id_rf_wsel,  // rd write sel from id/ex seg reg
    input       [4:0]           id_rd,  // rd register addr from id/ex seg reg
    input       [31:0]      id_rdata1,  // reg1(rs) data from id/ex seg reg
    input       [31:0]      id_rdata2,  // reg2(rt) data from id/ex seg reg
    input                   id_ram_we,  // ram write enable from id/ex seg reg
    input                   id_rf_nwe,  // rd write enable  from id/ex seg reg (deperated from execute owing to the remove of movz)
    input                   id_is_ram,  // the is ram instruction from id/ex seg reg
    input                  id_is_movz,  // the is movz instruction from id/ex seg reg
    input      [3:0]       id_ram_wen,
    input      [1:0]      id_ram_sign,
    input      [5:0]        id_opcode,
    input      [5:0]          id_func,
    input                   exe_stall,
    output reg [31:0]           ex_pc,   // pc data to ex/mem seg reg
    output reg [31:0]      ex_alu_out,   // alu out to ex/mem seg reg
    output reg  [2:0]      ex_rf_wsel,   // rd write sel to ex/mem seg reg
    output reg  [4:0]           ex_rd,   // rd register to ex/mem seg reg
    output reg [31:0]       ex_rdata1,  //  reg1(rs) data to ex/mem seg reg
    output reg [31:0]       ex_rdata2,  //  reg2(rt) data to ex/mem seg reg
    output reg [63:0]     ex_hilo_out,  // ram write enable to ex/mem seg reg
    output reg [5:0]        ex_opcode,
    output reg [5:0]          ex_func,
    output reg              ex_ram_we,  // ram write enable to ex/mem seg reg
    output reg              ex_rf_nwe,  // rd write enable to ex/mem seg reg
    output reg              ex_is_ram,  // the is ram instruction to ex/mem seg reg
    output reg             ex_is_movz,  // the is movz instruction to ex/mem seg reg
    output reg [3:0]       ex_ram_wen,
    output reg [1:0]      ex_ram_sign
);


initial begin
    ex_pc = 32'h0;
    ex_alu_out = 32'h0;
    ex_rf_wsel = 3'h0;
    ex_rd = 5'h0;
    ex_rdata1 = 32'h0;
    ex_rdata2 = 32'h0;
    ex_ram_we = 1'b0;
    ex_rf_nwe = 1'b0;
    ex_is_movz = 1'b0;
    ex_hilo_out = 64'h0;
    ex_opcode = 6'h0;
    ex_func = 6'h0;
    ex_ram_wen = 4'h0;
    ex_ram_sign = 2'h0;
end

always @(posedge clk) begin
    if (resetn == 1'b0 | exe_stall) begin
        ex_pc <= 32'h0;
        ex_alu_out <= 32'h0;
        ex_rf_wsel <= 3'h0;
        ex_rd <= 5'h0;  
        ex_rdata1 <= 32'h0;
        ex_rdata2 <= 32'h0;
        ex_ram_we <= 1'b0;
        ex_rf_nwe <= 1'b0;
        ex_is_ram <= 1'b0;
        ex_is_movz <= 1'b0;
        ex_hilo_out <= 64'h0;
        ex_ram_wen <= 4'h0;
        ex_ram_sign <= 2'h0;
    end
    else begin
        ex_pc <= id_pc;
        ex_alu_out <= alu_out;  
        ex_rf_wsel <= id_rf_wsel;
        ex_rd <= id_rd;          
        ex_rdata1 <= id_rdata1;  
        ex_rdata2 <= id_rdata2;  
        ex_ram_we <= id_ram_we;  
        ex_rf_nwe <= id_rf_nwe;    
        ex_is_ram <= id_is_ram;  
        ex_is_movz <= id_is_movz;
        ex_hilo_out <= hilo_out;
        ex_opcode <= id_opcode;
        ex_func <= id_func;
        ex_ram_wen <= id_ram_wen;
        ex_ram_sign <= id_ram_sign;
    end
end


endmodule