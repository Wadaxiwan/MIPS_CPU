`define ADD       5'b00001
`define ADDU      5'b00010
`define SUB       5'b00011
`define SUBU      5'b00100 
`define EQ_B      5'b00101
`define SRA       5'b00110
`define SRL       5'b00111
`define OR        5'b01000
`define AND       5'b01001
`define XNOR      5'b01010 
`define XOR       5'b01011
`define NAND      5'b01100 
`define ZERO      5'b01101    
`define SLT       5'b01110 
`define SLL       5'b01111 
`define NOR       5'b10000 
`define LUI       5'b10001 
`define MULT      5'b10010 
`define MULTU     5'b10011 
`define DIV       5'b10100
`define DIVU      5'b10101 
`define BEQ       5'b10110
`define BNE       5'b10111
`define BGEZ      5'b11000 
`define BGTZ      5'b11001 
`define BLEZ      5'b11010 
`define BLTZ      5'b11011
`define SLTU      5'b11100 

module alu (
    input  [31:0]   A   ,
    input  [31:0]   B   ,
    input           Cin ,
    input  [4 :0]   Card,
   input            of_op,

    output [31:0]   F   ,
    output [31:0]   AddF,  // Suit for HILO
    output          Cout,
    output          OF,
    output          Zero
);
    
    wire [31:0] add_result;
    wire [31:0] addu_result;
    wire [31:0] sub_result;
    wire [31:0] subu_result;
    wire [31:0] eq_b_result;
    wire [31:0] sra_result;
    wire [31:0] srl_result;
    wire [31:0] or_result;
    wire [31:0] and_result;
    wire [31:0] xnor_result;
    wire [31:0] xor_result;
    wire [31:0] nor_result;
    wire [31:0] nand_result;
    wire [31:0] zero_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] sll_result;
    wire [31:0] eq_result;
    wire [31:0] lui_result;
    wire [63:0] mult_result;
    wire [63:0] multu_result;
    wire [31:0] beq_result;
    wire [31:0] bne_result;
    wire [31:0] bgez_result;
    wire [31:0] bftz_result;
    wire [31:0] blez_result;
    wire [31:0] bltz_result;
    wire [31:0] li_result;

    wire        add_cout;
    wire        addu_cout;
    wire        sub_cout;
    wire        subu_cout;
    wire        resub_cout;
    wire        resub_cin_cout;


    assign {add_cout, add_result}  = {A[31], A} + {B[31], B};
    assign {addu_count, addu_result}  = A + B ;
    assign {sub_cout, sub_result}  = {A[31], A} - {B[31], B};
    assign {subu_cout, subu_result}  = A - B;
    assign eq_b_result = B;
    assign sra_result = $signed(B) >>> A[4:0];  // rt >>> rs / sa
    assign srl_result = (B >> A[4:0]);
    assign or_result = A | B;
    assign and_result = A & B;
    assign xnor_result = ~(A ^ B);
    assign xor_result = A ^ B;
    assign nor_result = ~(A | B);
    assign nand_result = ~(A & B);
    assign zero_result = 32'b0;
    assign slt_result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
    assign sltu_result = ({1'b0, A} < {1'b0, B}) ? 32'b1 : 32'b0;
    assign sll_result = (B << A[4:0]);
    assign lui_result = B;
    assign mult_result = $signed(A) * $signed(B);
    assign multu_result = A * B;
    assign li_result = { B[15:0], {16{B[15]}} };

    
    assign  OF  =   ({Card == `ADD} & add_cout != add_result[31]) |
                    ({Card == `SUB} & sub_cout != sub_result[31]);

    assign  F   =   ({32{Card == `ADD}}  & add_result)  |
                    ({32{Card == `ADDU}} & addu_result) |
                    ({32{Card == `SUB}} & sub_result) |
                    ({32{Card == `SUBU}} & subu_result) |
                    ({32{Card == `NOR}} & nor_result) |
                    ({32{Card == `EQ_B}} & eq_b_result) |
                    ({32{Card == `SRA}} & sra_result) |
                    ({32{Card == `SRL}} & srl_result) |
                    ({32{Card == `OR}} & or_result) |
                    ({32{Card == `AND}} & and_result) |
                    ({32{Card == `XNOR}} & xnor_result) |
                    ({32{Card == `XOR}} & xor_result) |
                    ({32{Card == `NAND}} & nand_result) |
                    ({32{Card == `ZERO}} & zero_result) |
                    ({32{Card == `SLT}} & slt_result) |
                    ({32{Card == `SLTU}} & sltu_result) |
                    ({32{Card == `SLL}} & sll_result) |
                    ({32{Card == `BEQ}} & beq_result) |
                    ({32{Card == `LUI}} & lui_result) |
                    ({32{Card == `MULT}} & mult_result[31:0]) |
                    ({32{Card == `MULTU}} & multu_result[31:0]);


    assign AddF =   ({32{Card == `MULT}}  & mult_result[63:32])  |
                    ({32{Card == `MULTU}} & multu_result[63:32])  |
                    ({32{Card == `ADD}} & add_result);

            
    assign  Cout =  ({Card == `ADD} & add_cout) |
                    ({Card == `ADDU} & addu_cout) |
                    ({Card == `SUB} & sub_cout) |
                    ({Card == `SUBU} & subu_cout);
        
    assign  Zero =  (F == 32'b0) & (Cout == 1'b0);


endmodule