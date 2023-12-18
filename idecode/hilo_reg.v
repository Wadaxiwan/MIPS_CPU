`timescale 1ns / 1ps

module hilo(
    input               clk,
    input             rst_n,
    input  [1:0]         we,
    input  [63:0]   hilo_in,
    output [63:0]  hilo_out
);

reg [31:0]   HI_reg;
reg [31:0]   LO_reg;


initial begin
    HI_reg = 32'h0;
    LO_reg = 32'h0;
end


 always @(negedge clk) begin
     if(~rst_n) begin
         HI_reg <= 32'h0;
         LO_reg <= 32'h0;
     end else begin
         if(we[1] == 1'b1) begin
            HI_reg  <= hilo_in[63:32];
         end
         if(we[0] == 1'b1) begin
             LO_reg <= hilo_in[31:0];
         end
     end
 end

//always @(*) begin
//    if(we[1] == 1'b1) begin
//        HI_reg = hilo_in[63:32];
//    end 
//    if(we[0] == 1'b1) begin
//        LO_reg = hilo_in[31:0];
//    end
//end

// assign HI_reg = {32{we[1]}} & hilo_in[63:32];
// assign LO_reg = {32{we[0]}} & hilo_in[31:0];

assign hilo_out = {HI_reg, LO_reg};


endmodule