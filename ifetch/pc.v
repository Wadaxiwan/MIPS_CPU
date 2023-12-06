module pc(
    input           clk,
    input         rst_n,
    input  [31:0]   din,
    output [31:0]    pc
);

reg [31:0] pc_addr;

always @(posedge clk) begin
    if(~rst_n) begin
        pc_addr <= 32'hBFC00000;
    end 
    else begin
        pc_addr <= din;
    end
end

assign pc = pc_addr;

endmodule