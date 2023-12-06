module irom(
    input  [15:0] inst_addr,
    output [31:0] inst
);

reg [31:0] mem [0:65535];

initial begin
//    $readmemh("../../../../lab_1.data/base_inst_data",mem);
//     $readmemh("../../../../lab_1.data/additional_inst_data1",mem);
   $readmemh("../../../../lab_1.data/additional_inst_data2",mem);
end

assign inst = mem[inst_addr];

// IROM Mem_IROM (
//     .a      (inst_addr),
//     .spo    (inst)
// );

endmodule