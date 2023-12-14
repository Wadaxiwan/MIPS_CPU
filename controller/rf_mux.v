`define WB_ALU    3'b001
`define WB_RS     3'b010 
`define WB_RAM    3'b011
`define WB_HI     3'b100
`define WB_LO     3'b101
`define WB_PC8    3'b110
`define WB_CP0    3'b111

module rf_mux(
    input  [2:0]         rf_wsel,
    input             mem_rf_nwe,
    input             mem_cp0_ex,
    input              int_flush,
    input  [31:0]             pc,
    input  [31:0]         alu_in,
    input  [31:0]          rs_in,
    input  [31:0]         ram_in,
    input  [63:0]        hilo_in,
    input  [31:0]         cp0_in,
    output [31:0]       rf_wdata,
    output                rf_nwe
);

assign rf_wdata = ({32{rf_wsel == `WB_ALU}} & alu_in) |
                ({32{rf_wsel == `WB_RS}} & rs_in) |
                ({32{rf_wsel == `WB_RAM}} & ram_in) |
                ({32{rf_wsel == `WB_HI}} & hilo_in[63:32]) |
                ({32{rf_wsel == `WB_LO}} & hilo_in[31:0]) |
                ({32{rf_wsel == `WB_PC8}} & (pc + 32'h8)) |
                ({32{rf_wsel == `WB_CP0}} & cp0_in);
                
assign rf_nwe = (mem_cp0_ex | int_flush) ? 1'b0 : mem_rf_nwe;

endmodule