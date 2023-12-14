`define NPC_PC4   3'b000
`define NPC_B     3'b010
`define NPC_J     3'b011   
`define NPC_JR    3'b100 

module npc(
    input  [31:0]            pc,
    input  [31:0]          dest,
    input                   jmp, // 1 jmp 0 pc+4
    input             int_flush,
    input  [31:0]        int_pc,
    input  [2:0]             op,
    output [31:0]           npc      
);

assign npc = int_flush ? int_pc : (jmp ? dest : (pc + 16'd4)) ;

endmodule