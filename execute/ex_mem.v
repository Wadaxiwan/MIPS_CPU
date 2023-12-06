
module ex_mem(
    input                          clk,  // clock
    input                       resetn,  // resetn
    input       [31:0]           id_pc,  // pc data from id/ex seg reg
    input       [31:0]         alu_out,  // alu out generate by execute
    input                           br,  // zero generate by execute
    input       [2:0]       id_rf_wsel,  // rd write sel from id/ex seg reg
    input       [4:0]            id_rd,  // rd register addr from id/ex seg reg
    input       [31:0]       id_rdata1,  // reg1(rs) data from id/ex seg reg
    input       [31:0]       id_rdata2,  // reg2(rt) data from id/ex seg reg
    input                    id_ram_we,  // ram write enable from id/ex seg reg
    input                      rf_nwef,  // rd write enable regenerate by execute (include movz)
    input                    id_is_ram,  // the is ram instruction from id/ex seg reg
    input                   id_is_movz,  // the is movz instruction from id/ex seg reg
    output reg [31:0]           ex_pc,   // pc data to ex/mem seg reg
    output reg [31:0]      ex_alu_out,   // alu out to ex/mem seg reg
    output reg  [2:0]      ex_rf_wsel,   // rd write sel to ex/mem seg reg
    output reg  [4:0]           ex_rd,   // rd register to ex/mem seg reg
    output reg [31:0]       ex_rdata1,  //  reg1(rs) data to ex/mem seg reg
    output reg [31:0]       ex_rdata2,  //  reg2(rt) data to ex/mem seg reg
    output reg              ex_ram_we,  // ram write enable to ex/mem seg reg
    output reg              ex_rf_nwe,  // rd write enable to ex/mem seg reg
    output reg              ex_is_ram,  // the is ram instruction to ex/mem seg reg
    output reg              ex_is_movz  // the is movz instruction to ex/mem seg reg
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
end

always @(posedge clk) begin
    if (resetn == 1'b0) begin
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
    end
    else begin
        ex_pc <= id_pc;
        ex_alu_out <= alu_out;  //
        ex_rf_wsel <= id_rf_wsel; //
        ex_rd <= id_rd;           //
        ex_rdata1 <= id_rdata1;  //
        ex_rdata2 <= id_rdata2;  //
        ex_ram_we <= id_ram_we;  //
        ex_rf_nwe <= rf_nwef;    //
        ex_is_ram <= id_is_ram;  //
        ex_is_movz <= id_is_movz;  //
    end
end


endmodule