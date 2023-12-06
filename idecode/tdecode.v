`define  M_TYPE  3'b000 
`define  R_TYPE  3'b010 // [rs]        [rt]
`define  I_TYPE  3'b011 // sa          [rt]
`define  S_TYPE  3'b100 // [base]  [offset]
`define  B_TYPE  3'b101 // [rs]        [rt]
`define  J_TYPE  3'b110 // imm         

module tdecode(
    input [5:0]   opcode,
    input [5:0]     func,
    output  [2:0]  itype
);

assign itype =  ({3{opcode == 6'b000000 && func != 6'b000000}} & `R_TYPE) |
                ({3{opcode == 6'b000000 && func == 6'b000000}} & `I_TYPE) |
                ({3{opcode == 6'b000101}} & `B_TYPE) |
                ({3{opcode == 6'b000010}} & `J_TYPE) |
                ({3{opcode == 6'b101011 || opcode == 6'b100011 }} & `S_TYPE) ;

endmodule