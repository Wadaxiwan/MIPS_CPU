`define  M_TYPE  3'b000 
`define  R_TYPE  3'b010 // [rs]        [rt]
`define  I_TYPE  3'b011 // sa          [rt]
`define  S_TYPE  3'b100 // [base]  [offset]
`define  B_TYPE  3'b101 // [rs]        [rt]
`define  J_TYPE  3'b110 // imm         
`define ADD       5'b00001
`define ADDU      5'b00010
`define SUB       5'b00011
`define SUBU      5'b00100
`define RESUB     5'b00101
`define RESUB_Cin 5'b00110  
`define BEQ       5'b00111
`define EQ_B      5'b01000
`define SRA       5'b01001
`define SRL       5'b01010
`define OR        5'b01011
`define AND       5'b01100
`define XNOR      5'b01101 
`define XOR       5'b01110
`define NAND      5'b01111 
`define ZERO      5'b10000    
`define SLT       5'b10001 
`define SLL       5'b10010 
`define NOR       5'b10011 
`define LUI       5'b10100 
`define MULT      5'b10110 
`define MULTU     5'b10110 
`define DIV       5'b10111
`define DIVU      5'b10111 
`define BNE       5'b11000 
`define BGEZ      5'b11001 
`define BGTZ      5'b11010 
`define BLEZ      5'b11011 
`define BLTZ      5'b11100
`define LI        5'b11101 
`define SLTU      5'b11110 
`define NPC_PC4   3'b000
`define NPC_B     3'b010
`define NPC_J     3'b011   
`define NPC_JR    3'b100   
`define WB_ALU    3'b001
`define WB_RS     3'b010 
`define WB_RAM    3'b011
`define WB_HI     3'b100
`define WB_LO     3'b101
`define WB_PC8    3'b110
`define EXT_Z     3'b001
`define EXT_S     3'b010
`define EXT_B     3'b011
`define EXT_J     3'b100
`define EXT_L     3'b101
`define EXT_I     3'b110
`define ALUB_RT   2'b01
`define ALUB_RS   2'b10
`define ALUB_EXT  2'b11 
`define RAM_B     3'b001
`define RAM_BU    3'b010
`define RAM_H     3'b011
`define RAM_HU    3'b100
`define RAM_W     3'b101


module controller(
    input [2:0]          itype,
    input [5:0]         opcode,
    input [5:0]           func,
    input [4:0]             rt,
    output [1:0]        rs_sel,
    output [1:0]        rt_sel,
    output [4:0]        alu_op,
    output [2:0]        npc_op,
    output               rf_we,
    output [2:0]       rf_wsel,
    output [2:0]       sext_op,
    output              ram_we,
    output              is_ram,
    output [2:0]        ram_op,
    output               of_op
);

// 根据指令的类型决定PC跳转的方向
assign npc_op = ({3{opcode == 6'b000000 && (func != 5'b001000 || func != 5'b001001) }} & `NPC_PC4) |    // Except JR or JALR
                ({3{opcode == 6'b000100}} & `NPC_B) |
                ({3{opcode == 6'b000101}} & `NPC_B) |
                ({3{opcode == 6'b000001}} & `NPC_B) |
                ({3{opcode == 6'b000111}} & `NPC_B) |
                ({3{opcode == 6'b000110}} & `NPC_B) |
                ({3{opcode == 6'b000000 && func == 6'b001000}} & `NPC_JR) |                              // JR                  
                ({3{opcode == 6'b000000 && func == 6'b001001}} & `NPC_JR) |                              // JALR
                ({3{opcode == 6'b000010}} & `NPC_J) |                                                   // J
                ({3{opcode == 6'b000011}} & `NPC_J) |                                                   // JAL
                ({3{opcode[5:3] == 3'b001}} & `NPC_PC4) |                                               // R-Imm ALU 
                ({3{opcode[5:3] == 3'b100}} & `NPC_PC4) |                                               // Store
                ({3{opcode[5:3] == 3'b101}} & `NPC_PC4);                                               // Load

// 根据指令的类型决定是否要写寄存器堆
assign rf_we = ({opcode == 6'b000000 && func != 6'b001000 } & 1'b1)   |   // R-R ALU / MFHI / MFLO / MTHI / MTLO  Except JR But Include JALR
               ({opcode == 6'b000001 && rt == 5'b10001} & 1'b1)   |       // BGEZAL  Branch with link PC + 8
               ({opcode == 6'b000001 && rt == 5'b10000} & 1'b1)   |       // BLTZAL  Branch with link PC + 8
               ({opcode == 6'b000011} & 1'b1) |                           // JAL  Branch with link PC + 8  
               ({opcode[5:3] == 3'b001} & 1'b1) |                         // R-Imm ALU
               ({opcode[5:3] == 3'b100} & 1'b1);                          // Load

// 根据指令的类型决定写寄存器堆的来源
assign rf_wsel = ({3{opcode == 6'b000000 && (func[5:2] != 4'b0100 && func != 6'b001001)}} & `WB_ALU) |  // R-R ALU Except MFHI / MFLO / MTHI / MTLO
                 ({3{opcode == 6'b000000 && func == 6'b010000}}  & `WB_HI) |   // MFHI
                 ({3{opcode == 6'b000000 && func == 6'b010010}}  & `WB_LO) |   // MFLO
                 ({3{opcode == 6'b000000 && func == 6'b001001}} & `WB_PC8) |   // JALR
                 ({3{opcode == 6'b000000 && (func == 6'b010011 || func == 6'b010001)}}  & `WB_RS) |   // MTHI / MTLO
                 ({3{opcode == 6'b000001}} & `WB_PC8) |                        // BGEZAL(also include BGEZ but don't use)
                 ({3{opcode == 6'b000011}} & `WB_PC8) |                        // JAL
                 ({3{opcode[5:3] == 6'b001}} & `WB_ALU) |                      // R-Imm ALU
                 ({3{opcode[5:3] == 6'b100}} & `WB_RAM);                       // Load


// 根据指令的类型决定ALU操作数的来源
assign rs_sel = ({2{opcode == 6'b000000 && func == 6'b000000}} & `ALUB_EXT) | 
                ({2{opcode == 6'b000000 && func == 6'b000010}} & `ALUB_EXT) | 
                ({2{opcode == 6'b000000 && func == 6'b000011}} & `ALUB_EXT) | 
                ({2{opcode == 6'b000000 && (func != 6'b000000 && func != 6'b000010 && func != 6'b000011)}} & `ALUB_RS);      // R-R ALU


assign rt_sel = ({2{opcode == 6'b000000}} & `ALUB_RT) |      // R-R ALU
                ({2{opcode[5:3] == 3'b001}} & `ALUB_EXT) |   // R-Imm
                ({2{opcode[5:3] == 3'b100}} & `ALUB_EXT) |   // Load
                ({2{opcode[5:3] == 3'b101}} & `ALUB_EXT) |   // Store      
                ({2{opcode == 6'b000100}} & `ALUB_RT) |      // BEQ
                ({2{opcode == 6'b000101}} & `ALUB_RT) ;      // BNE


// 根据指令的类型决定符号扩展的操作
assign sext_op = ({3{opcode == 6'b001111}} & `EXT_L) |
                 ({3{opcode[5:2] == 4'b0011 && opcode != 6'b001111}} & `EXT_Z) |
                 ({3{opcode == 6'b000001 || opcode[5:2] == 4'b0001}} & `EXT_B) |
                 ({3{opcode == 6'b000010 || opcode == 6'b000011}} & `EXT_J) |
                 ({3{opcode[5:2] == 4'b0010 || opcode[5:3] == 3'b100 || opcode[5:3] == 3'b101}} & `EXT_S) |
                 ({3{opcode == 6'b000000 && (func == 6'b000000 || func == 6'b000011 || func == 6'b000010)}} & `EXT_I);

// 根据指令的类型决定是否要写存储器
assign ram_we = opcode[5:3] == 3'b101 ? 1'b1 : 1'b0;

assign is_ram = opcode[5:3] == 3'b100 || opcode[5:3] == 3'b101;

// 根据指令的类型决定ALU操作
assign alu_op = ({5{ opcode == 6'b000000 && func == 6'b100000 }} & `ADD) |
                ({5{ opcode == 6'b000000 && func == 6'b100001 }} & `ADDU) |
                ({5{ opcode == 6'b001000 }} & `ADD) |
                ({5{ opcode == 6'b001001 }} & `ADDU) |
                ({5{ opcode == 6'b000000 && func == 6'b100010 }} & `SUB) |
                ({5{ opcode == 6'b000000 && func == 6'b100011 }} & `SUBU) |
                ({5{ opcode == 6'b000000 && func == 6'b101010 }} & `SLT) |
                ({5{ opcode == 6'b001010 }} & `SLT) |
                ({5{ opcode == 6'b000000 && func == 6'b101011 }} & `SLTU) |
                ({5{ opcode == 6'b001011 }} & `SLTU) |
                ({5{ opcode == 6'b000000 && func == 6'b011010 }} & `DIV) |
                ({5{ opcode == 6'b000000 && func == 6'b011011 }} & `DIVU) |
                ({5{ opcode == 6'b000000 && func == 6'b011000 }} & `MULT) |
                ({5{ opcode == 6'b000000 && func == 6'b011001 }} & `MULTU) |
                ({5{ opcode == 6'b000000 && func == 6'b100100 }} & `AND) |
                ({5{ opcode == 6'b001100 }} & `AND) |
                ({5{ opcode == 6'b001111 }} & `LUI) |
                ({5{ opcode == 6'b000000 && func == 6'b100111 }} & `NOR ) |
                ({5{ opcode == 6'b000000 && func == 6'b100101 }} & `OR ) |
                ({5{ opcode == 6'b001101 }} & `OR ) |
                ({5{ opcode == 6'b000000 && func == 6'b100110 }} & `XOR) |
                ({5{ opcode == 6'b001110 }} & `XOR) |
                ({5{ opcode == 6'b000000 && (func == 6'b000100 || func == 6'b000000) }} & `SLL) |
                ({5{ opcode == 6'b000000 && (func == 6'b000111 || func == 6'b000011) }} & `SRA) |
                ({5{ opcode == 6'b000000 && (func == 6'b000110 || func == 6'b000010) }} & `SRL) |
                ({5{ opcode == 6'b000100 }} & `BEQ) |
                ({5{ opcode == 6'b000101 }} & `BNE) |
                ({5{ opcode == 6'b000001 && rt == 5'b00001 }} & `BGEZ) |
                ({5{ opcode == 6'b000111 }} & `BGTZ) |
                ({5{ opcode == 6'b000110 }} & `BLEZ) |
                ({5{ opcode == 6'b000001 && rt == 5'b10001 }} & `BGEZ) |
                ({5{ opcode == 6'b000001 && rt == 5'b00000 }} & `BLTZ) |
                ({5{ opcode == 6'b000001 && rt == 5'b10000 }} & `BLTZ) |
                ({5{ opcode[5:3] == 3'b100 }} & `ADD) |
                ({5{ opcode[5:3] == 3'b101 }} & `ADD);


assign ram_op = ({3{ opcode == 6'b100000 || opcode == 6'b101000 }} & `RAM_B) |
                ({3{ opcode == 6'b100100 }} & `RAM_BU) |
                ({3{ opcode == 6'b100001|| opcode == 6'b101001 }} & `RAM_H) |
                ({3{ opcode == 6'b100101 }} & `RAM_HU) |
                ({3{ opcode == 6'b100011|| opcode == 6'b101011 }} & `RAM_W);

assign of_op =  ( opcode == 6'b000000 && func == 6'b100000 ) |
                ( opcode == 6'b001000 ) |
                ( opcode == 6'b000000 && func == 6'b100010 ) |
                ( opcode == 6'b100001 ) |
                ( opcode == 6'b100101 ) |
                ( opcode == 6'b100011 ) |
                ( opcode == 6'b101001 ) |
                ( opcode == 6'b101011 ) ;
             

endmodule