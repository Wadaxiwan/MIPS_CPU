`define  M_TYPE  3'b000 
`define  R_TYPE  3'b010 // [rs]        [rt]
`define  I_TYPE  3'b011 // sa          [rt]
`define  S_TYPE  3'b100 // [base]  [offset]
`define  B_TYPE  3'b101 // [rs]        [rt]
`define  J_TYPE  3'b110 // imm    
`define BEQ       5'b00111 
`define BNE       5'b11000 
`define BGEZ      5'b11001 
`define BGTZ      5'b11010 
`define BLEZ      5'b11011 
`define BLTZ      5'b11100
`define NPC_PC4   3'b000
`define NPC_B     3'b010
`define NPC_J     3'b011   
`define NPC_JR    3'b100 
`define EX_INT   5'h00 // interrupt
`define EX_ADEL  5'h04 // address error exception (load or instruction fetch)
`define EX_ADES  5'h05 // address error exception (store)
`define EX_SYS   5'h08 // syscall exception
`define EX_BP    5'h09 // breakpoint exception
`define EX_RI    5'h0a // reserved instruction exception
`define EX_OV    5'h0c // coprocessor unusable exception
`define EX_ERET  5'h0d // eret exception

module idecode(
    input                          clk,  // 时钟信号
    input  [31:0]                 inst,  // 指令
    input  [4:0]                 rf_rd,  // 写寄存器堆编号
    input  [31:0]             rf_wdata,  // 写寄存器数据
    input                        rf_we,  // 是否写寄存器
    input                    if_cp0_ex,
    input [4:0]          if_cp0_excode, 
    input                   idecode_ex,  // [TODO]
    output [31:0]               rdata1,  // 读取的寄存器数值1
    output [31:0]               rdata2,  // 读取的寄存器数值2
    output [1:0]                rs_sel,  // 选择rt的数据来源
    output [1:0]                rt_sel,  // 选择rt的数据来源
    output [31:0]                  imm,  // 立即数
    output [4:0]                alu_op,  // ALU操作
    output [2:0]                npc_op,  // NPC操作
    output                      ram_we,  // 写存储使能信号
    output [2:0]               rf_wsel,  // 选择写回寄存器的数据来源
    output                      rf_nwe,  // 通用寄存器组写使能信号（但不包含movz指令的判定）
    output [4:0]                    rd,  // 当前译码指令的目的寄存器编号
    output [5:0]                  func,  // 当前译码指令的功能码
    output [5:0]                opcode,  // 当前译码指令的操作码
    output                      is_ram,  // 当前指令是否访存
    output [2:0]                ram_op,  // 当前指令访存行为
    output                       of_op,  // 当前指令是否需要overflow判断
    output [1:0]               hilo_we,   // HILO写使能信号
    output [3:0]               ram_wen,
    output [1:0]              ram_sign,
    output                   id_cp0_ex,
    output [4:0]         id_cp0_excode,
    output                   id_cp0_bd,
    output                   id_cp0_we,
    output [4:0]           id_cp0_addr,
    output           id_cp0_eret_flush
);

wire [4:0]                 rs;  //  源寄存器1编号
wire [4:0]                 rt;  //  源寄存器2编号
wire [2:0]            sext_op;  //  符号扩展操作
wire                   rf_twe;  //  特判全零指令

wire                   cp0_ex;
wire [4:0]             cp0_excode;


assign id_cp0_eret_flush = inst == 32'h42000018;
assign soft_interrupt = inst == 32'h1000ffff;

assign id_cp0_ex = cp0_ex | if_cp0_ex | id_cp0_eret_flush | soft_interrupt;
assign id_cp0_excode = if_cp0_ex ? if_cp0_excode : (id_cp0_eret_flush ? `EX_ERET : (soft_interrupt ? `EX_INT :cp0_excode ));  // only keep the first exception


// Operation code and function code
assign opcode = inst[31:26];
assign func = inst[5:0];

// Except J / JAL and other don't use rs (rs = 0)
assign rs = ({5{opcode != 6'b000010 && opcode != 6'b000011}} & inst[25:21]);  
            
// Except J / JAL / opcode == 000001 (BZ Serial) / load serial               
assign rt = ( {5{opcode != 6'b000001 && opcode != 6'b000010 && opcode != 6'b000011 &&  opcode[5:3] != 3'b100}} & inst[20:16] ); 


assign rd = ({5{opcode == 6'b000000}} & inst[15:11]) |                          // R-R ALU / mfhi 
            ({5{opcode[5:3] == 3'b001}} & inst[20:16]) |                        // R-Imm
            ({5{opcode[5:3] == 3'b100}} & inst[20:16]) |                        // Load
            ({5{opcode == 6'b010000 && inst[25:21] == 5'b00000}} & inst[20:16]) |  // MFC0
            ({5{opcode == 6'b000001}} & 5'd31) |                                // bltzal / bgezal
            ({5{opcode == 6'b000011}} & 5'd31);                                 // JALR


controller u_controller(
    .clk(clk),
    .resetn(resetn),
    .opcode(opcode),
    .func(func),
    .rs(inst[25:21]),
    .rt(inst[20:16]),  // make it zero may influence the result in some instructions
    .rd(inst[15:11]),
    .cp0_wsel(inst[2:0]),
    .rs_sel(rs_sel),
    .rt_sel(rt_sel),
    .alu_op(alu_op),
    .npc_op(npc_op),
    .rf_we(rf_twe),
    .ram_wen(ram_wen),
    .ram_sign(ram_sign),
    .rf_wsel(rf_wsel),
    .sext_op(sext_op),
    .ram_we(ram_we),
    .is_ram(is_ram),
    .ram_op(ram_op),
    .hilo_we(hilo_we),
    .of_op(of_op),
    .cp0_ex(cp0_ex),
    .cp0_excode(cp0_excode),
    .cp0_bd(id_cp0_bd),
    .cp0_we(id_cp0_we),
    .cp0_addr(id_cp0_addr)
);

sext u_ext(
    .op(sext_op),
    .din(inst[25:0]),
    .ext(imm)
);


regfile u_regfile(
    .clk(clk),
    .raddr1(rs),
    .rdata1(rdata1),
    .raddr2(rt),
    .rdata2(rdata2),
    .we(rf_we),
    .waddr(rf_rd),
    .wdata(rf_wdata)
);

assign rf_nwe = inst[31:0] == 32'b0 ? 1'b0 : rf_twe;


endmodule


// assign rs = ({5{opcode == 6'b000000 && func != 6'b000000}} & inst[25:21]) |    //  add / sub / div(u) / mult(u) / mthi / mtlo (rd = rs + rt) 
//             ({5{opcode == 6'b001000}} & inst[25:21]) |                         // addi
//             ({5{opcode == 6'b001001}} & inst[25:21]) |                         // addiu
//             ({5{opcode == 6'b001010}} & inst[25:21]) |                         // slt
//             ({5{opcode == 6'b001011}} & inst[25:21]) |                         // sltiu

//             ({5{opcode == 6'b000101}} & inst[25:21]) |                          // bnq
//             ({5{opcode == 6'b000100}} & inst[25:21]) |                          // beq
//             ({5{opcode == 6'b000111}} & inst[25:21]) |                          // bgtz
//             ({5{opcode == 6'b000110}} & inst[25:21]) |                          // blez
//             ({5{opcode == 6'b000001}} & inst[25:21]) |                          // bltz

//             ({5{opcode == 6'b100011}} & inst[25:21]) |                          // lw 
//             ({5{opcode == 6'b100000}} & inst[25:21]) |                          // lb
//             ({5{opcode == 6'b100100}} & inst[25:21]) |                          // lbu
//             ({5{opcode == 6'b100001}} & inst[25:21]) |                          // lh
//             ({5{opcode == 6'b100101}} & inst[25:21]) |                          // lhu

//             ({5{opcode == 6'b101000}} & inst[25:21]) |                          // sb
//             ({5{opcode == 6'b101001}} & inst[25:21]) |                          // sh
//             ({5{opcode == 6'b101011}} & inst[25:21]) |                          // sw

// ({5{opcode == 6'b000000 && func != 6'b000000}} & inst[20:16]) |     //  add / sub / div(u) / mult(u)  (rd = rs + rt) 
// ({5{opcode != 6'b000010 && opcode != 6'b100011}} & inst[20:16]);    //  not j / lw / bltz / bgezal



// assign rs = ({5{op == 6'b000000 && func != 6'b000000}} & inst[25:21]) |
//             ({5{op == 6'000101}} & inst[25:21]);

// assign rt = (op == 6'b000010) ? 5'b00000 : inst[20:16];
// assign rd = ({5{op == 6'b000000 }} & inst[15:11]);
// assign shamt = ({5{op == 6'b000000 && func == 6'b000000}} & inst[10:6]);
// assign offset = ({16{op == 6'b000101}} & inst[15:0]);
// ext u_ext(opcode, {16{0'b0}, offset}, ext_offset);
// assign instr_index = ({26{op == 6'b000010}} & inst[25:0]);
