`define ALUB_RT   2'b01
`define ALUB_RS   2'b10
`define ALUB_EXT  2'b11 

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

/* rf_wsel */
`define WB_ALU    3'b001
`define WB_RS     3'b010 
`define WB_RAM    3'b011
`define WB_HI     3'b100
`define WB_LO     3'b101
`define WB_PC8    3'b110
`define WB_CP0    3'b111

module execute(
    input                       clk,
    input                     rst_n,
    input                  id_of_op,
    input                 int_flush,
    input [4:0]       id_cp0_excode,    // update in execute
    input                 id_cp0_ex,  
    input                     ex_ex,
    input [2:0]             rf_wsel,
    input [1:0]             hilo_we,
    input [4:0]              alu_op,
    input [1:0]              rs_sel,
    input [1:0]              rt_sel,
    input [31:0]             rdata1,
    input [31:0]             rdata2,
    input [31:0]                imm,
    output[31:0]            alu_out,
    output[63:0]           hilo_out,
    output                     zero,
    output                    stall,
    output [4:0]     exe_cp0_excode,    
    output               exe_cp0_ex  
    // input               rf_nwe,
    // output              rf_nwef
);

wire                  Cout;
wire [31:0]          data1;
wire [31:0]          data2;
wire [31:0]           AddF;  // Suit for HILO
   
wire [31:0]       quotient;
wire [31:0]      remainder;  
wire            sourceData;  
wire               hasData;
wire                dataOK;  
wire [63:0]        hilo_in;
wire                    OF;
wire [1:0]        hilo_nwe;


assign exe_cp0_ex = id_cp0_ex | (id_of_op & OF);
assign exe_cp0_excode = id_cp0_ex ? id_cp0_excode : `EX_OV;
assign hilo_nwe = ({2{~ex_ex}}) & ({2{dataOK}} | hilo_we);


assign data1 = (rs_sel == `ALUB_EXT) ? imm : rdata1;
assign data2 = (rt_sel == `ALUB_EXT) ? imm : rdata2;
assign sourceData = alu_op == `DIV | alu_op == `DIVU;
// assign stall = int_flush ? 1'b0 : ((rf_wsel == `WB_HI | rf_wsel == `WB_LO | hilo_we != 2'b0) & hasData & !dataOK) ;  // for non stall version (high performance)
assign stall = int_flush ? 1'b0 : hasData & !dataOK;


assign hilo_in[63:32] = ({32{hilo_we[1]}} & AddF) |
                        ({32{!hilo_we[1] & dataOK}} & remainder);  // MIPS put remainder(HI) in higher 32 bits, quotient£®LO) in lower 32 bits
assign hilo_in[31:0] = ({32{hilo_we[0]}} & alu_out) |
                       ({32{!hilo_we[0] & dataOK}} & quotient);

alu u_alu(
    .A(data1),
    .B(data2),
    .of_op(id_of_op),
    .Cin(1'b0),
    .Card(alu_op),
    .F(alu_out),
    .OF(OF),
    .AddF(AddF),
    .Cout(Cout),
    .Zero(zero)  // Ω”»Îbr
);


div u_div(
    .clk(clk),
    .resetn(rst_n),
    .sign(alu_op == `DIV),
    .int_flush(int_flush),
    .A(data1),
    .B(data2),
    .sourceData(sourceData),
    .F({quotient, remainder}),  // div IP put quotient(HI) in higher 32 bits, remainder(LO) in lower 32 bits
    .hasData(hasData),
    .dataOK(dataOK)
);


hilo u_hilo(
    .clk(clk),
    .rst_n(rst_n),
    .we(hilo_nwe),
    .hilo_in(hilo_in),
    .hilo_out(hilo_out)
);

endmodule

// assign rf_nwef =  (opcode == 6'b000000 && func == 6'b001010 && zero == 1'b1) |
//                   ((opcode != 6'b000000 || func != 6'b001010) && rf_nwe) ;