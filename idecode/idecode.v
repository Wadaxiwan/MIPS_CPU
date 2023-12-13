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

module idecode(
    input                          clk,  // ʱ���ź�
    input  [31:0]                 inst,  // ָ��
    input  [4:0]                 rf_rd,  // д�Ĵ����ѱ��
    input  [31:0]             rf_wdata,  // д�Ĵ�������
    input                        rf_we,  // �Ƿ�д�Ĵ���
    output [31:0]               rdata1,  // ��ȡ�ļĴ�����ֵ1
    output [31:0]               rdata2,  // ��ȡ�ļĴ�����ֵ2
    output [1:0]                rs_sel,  // ѡ��rt��������Դ
    output [1:0]                rt_sel,  // ѡ��rt��������Դ
    output [31:0]                  imm,  // ������
    output [4:0]                alu_op,  // ALU����
    output [2:0]                npc_op,  // NPC����
    output                      ram_we,  // д�洢ʹ���ź�
    output [2:0]               rf_wsel,  // ѡ��д�ؼĴ�����������Դ
    output                      rf_nwe,  // ͨ�üĴ�����дʹ���źţ���������movzָ����ж���
    output [4:0]                    rd,  // ��ǰ����ָ���Ŀ�ļĴ������
    output [5:0]                  func,  // ��ǰ����ָ��Ĺ�����
    output [5:0]                opcode,  // ��ǰ����ָ��Ĳ�����
    output [2:0]                 itype,  // ��ǰ����ָ���ָ������
    output                      is_ram,  // ��ǰָ���Ƿ�ô�
    output [2:0]                ram_op,  // ��ǰָ��ô���Ϊ
    output                       of_op,  // ��ǰָ���Ƿ���Ҫoverflow�ж�
    output [1:0]               hilo_we   // HILOдʹ���ź�
);

wire [4:0]                 rs;  //  Դ�Ĵ���1���
wire [4:0]                 rt;  //  Դ�Ĵ���2���
wire [2:0]            sext_op;  //  ������չ����
wire                   rf_twe;  //  ����ȫ��ָ��

assign opcode = inst[31:26];
assign func = inst[5:0];

tdecode u_tdecode(
    .opcode(opcode),
    .func(func),
    .itype(itype)
);

// Except J / JAL and other don't use rs (rs = 0)
assign rs = ({5{opcode != 6'b000010 && opcode != 6'b000011}} & inst[25:21]);  
            
// Except J / JAL / opcode == 000001 (BZ Serial) / load serial               
assign rt = ( {5{opcode != 6'b000001 && opcode != 6'b000010 && opcode != 6'b000011 &&  opcode[5:3] != 3'b100}} & inst[20:16] ); 


assign rd = ({5{opcode == 6'b000000}} & inst[15:11]) |                          // R-R ALU / mfhi 
            ({5{opcode[5:3] == 3'b001}} & inst[20:16]) |                        // R-Imm
            ({5{opcode[5:3] == 3'b100}} & inst[20:16]) |                        // Load
            ({5{opcode == 6'b000001}} & 5'd31) |                                // bltzal / bgezal
            ({5{opcode == 6'b000011}} & 5'd31);                                 // JALR


controller u_controller(
    .itype(itype),
    .opcode(opcode),
    .func(func),
    .rt(inst[20:16]),  // make it zero may influence the result in some instructions
    .rs_sel(rs_sel),
    .rt_sel(rt_sel),
    .alu_op(alu_op),
    .npc_op(npc_op),
    .rf_we(rf_twe),
    .rf_wsel(rf_wsel),
    .sext_op(sext_op),
    .ram_we(ram_we),
    .is_ram(is_ram),
    .ram_op(ram_op),
    .hilo_we(hilo_we),
    .of_op(of_op)
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
