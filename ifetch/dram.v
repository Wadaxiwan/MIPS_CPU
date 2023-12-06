module dram (
    input         clk      ,
    input  [15:0] ram_addr ,
    input  [31:0] ram_wdata,
    input         ram_wen  ,
    output [31:0] ram_rdata
);
			
// Í¬²½Ğ´ Òì²½¶Á
reg [31:0] mem [0:65535];

initial begin
// $readmemh("../../../../lab_1.data/base_data_data", mem);
// $readmemh("../../../../lab_1.data/additional_data_data1", mem);
 $readmemh("../../../../lab_1.data/additional_data_data2", mem);  
end

always @(negedge clk) begin
    if (ram_wen) begin
        mem[ram_addr] <= ram_wdata;
    end
end

assign ram_rdata = mem[ram_addr];

endmodule
