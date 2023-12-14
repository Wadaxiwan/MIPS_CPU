module id_ex(
    input                        clk,   // clock
    input                     resetn,   // resetn
    input       [31:0]         if_pc,   // pc data from if/id pipe
    input       [31:0]         rdata1,  //  reg1 data include forwarding
    input       [31:0]         rdata2,  //  reg2 data include forwarding
    input       [1:0]          rs_sel,  //  rs select
    input       [1:0]          rt_sel,  //  rt select
    input       [31:0]         imm,     //  imm gen data
    input       [4:0]          alu_op,  // alu op generate by controller
    input                     ram_we,   // ram write enable generate by controller
    input       [3:0]        ram_wen,   // ram read/write bit generate by controller
    input       [1:0]       ram_sign,   // ram raad/write sign generate by controller
    input       [2:0]        rf_wsel,   // rd write sel generate by controller
    input       [4:0]             rd,   // rd reg addr generate by controller
    input       [5:0]           func,   // function code generate by controller
    input       [5:0]         opcode,   // operation code generate by controller
    input                     rf_nwe,   // rd write enable generate by controller
    input                     is_ram,   // the instruction is ram instruction
    input                    is_movz,   // the instruction is movz instruction
    input               hazard_stall,   // id/ex hazard 
    input                  exe_stall,   // ex/mem stall
    input       [1:0]        hilo_we,   // hilo write enable generate by controller

    input                    int_flush,
    input                       cp0_ex,  // first in ifetch , this inst is a exception
    input      [4:0]        cp0_excode,  // first in ifetch
    input      [31:0]  if_cp0_badvaddr,  // first in ifetch
    input                       cp0_we,  // first in idecode
    input                       cp0_bd,  // first in idecode , this inst is a branch delay slot
    input      [4:0]          cp0_addr,  // first in idecode
    input               cp0_eret_flush,

    output reg  [31:0]         id_pc,   // pc data to id/ex pipe
    output reg  [31:0]     id_rdata1,   //  reg1(rs) data to id/ex pipe
    output reg  [31:0]     id_rdata2,   //  reg2(rt) data to id/ex pipe
    output reg  [1:0]      id_rs_sel,   //  rs select to id/ex pipe
    output reg  [1:0]      id_rt_sel,   //  rt select to id/ex pipe
    output reg  [31:0]        id_imm,  //  imm gen data to id/ex pipe
    output reg  [4:0]      id_alu_op,  //  alu op data to id/ex pipe
    output reg             id_ram_we,  //  ram write enable to id/ex pipe
    output reg  [2:0]     id_rf_wsel,  //  rd write sel to id/ex pipe
    output reg  [4:0]          id_rd,  //  rd reg addr to id/ex pipe
    output reg  [5:0]        id_func,  //  function code to id/ex pipe
    output reg  [5:0]      id_opcode,  //  operation code to id/ex pipe
    output reg             id_rf_nwe,  // rd write enable to id/ex pipe
    output reg             id_is_ram,  // the instruction is ram instruction to id/ex pipe
    output reg            id_is_movz,   // the instruction is movz instruction to id/ex pipe
    output reg  [3:0]     id_ram_wen,
    output reg  [1:0]     id_ram_sign,
    output reg  [1:0]     id_hilo_we,  //  reg1(rs) data to id/ex pipe
    output reg  [4:0]     id_cp0_excode,    
    output reg            id_cp0_ex,        
    output reg  [31:0]    id_cp0_badvaddr,  // first in ifetch
    output reg            id_cp0_we,        // first in ifetch
    output reg            id_cp0_bd,        // first in idecode , this inst is a branch delay slot
    output reg  [4:0]     id_cp0_addr,      // first in idecode
    output reg            id_cp0_eret_flush
);



initial begin
    id_pc = 32'h0;
    id_rdata1 = 32'h0;
    id_rdata2 = 32'h0;
    id_imm = 32'h0;
    id_rt_sel = 2'h0;
    id_rs_sel = 2'h0;
    id_alu_op = 5'h0;
    id_ram_we = 1'b0;
    id_rf_wsel = 3'h0;
    id_rd = 5'h0;
    id_func = 6'h0;
    id_opcode = 6'h0;
    id_rf_nwe = 1'b0;
    id_is_ram = 1'b0;
    id_is_movz = 1'b0;
    id_hilo_we = 2'h0;
    id_ram_wen = 4'h0;
    id_ram_sign = 2'h0;
    id_cp0_ex = 1'b0;
    id_cp0_excode = 5'h0;
    id_cp0_badvaddr = 32'h0;
    id_cp0_we = 1'b0;
    id_cp0_bd = 1'b0;
    id_cp0_addr = 5'h0;
    id_cp0_eret_flush = 1'b0;
end

always @(posedge clk) begin
    // initial the id/ex pipe
    if (resetn == 1'b0 | hazard_stall | int_flush) begin
        id_pc <= 32'h0;
        id_rt_sel <= 2'h0;
        id_rs_sel <= 2'h0;  
        id_imm <= 32'h0;    
        id_alu_op <= 5'h0;  
        id_ram_we <= 1'b0;  
        id_rf_wsel <= 3'h0; 
        id_rd <= 5'h0;
        id_func <= 6'h0;   
        id_opcode <= 6'h0; 
        id_rf_nwe <= 1'b0; 
        id_is_ram <= 1'b0; 
        id_is_movz <= 1'b0;
        id_rdata1 <= 32'h0;
        id_rdata2 <= 32'h0;
        id_hilo_we <= 2'h0;
        id_ram_wen <= 4'h0;
        id_ram_sign <= 2'h0;
        id_cp0_ex <= 1'b0;
        id_cp0_excode <= 5'h0;
        id_cp0_badvaddr <= 32'h0;
        id_cp0_we <= 1'b0;
        id_cp0_bd <= 1'b0;
        id_cp0_addr <= 5'h0;
        id_cp0_eret_flush <= 1'b0;
    end
    // save the data to id/ex pipe register
    else if(!exe_stall) begin
        id_pc <= if_pc;
        id_rt_sel <= rt_sel;
        id_rs_sel <= rs_sel;
        id_imm <= imm;
        id_alu_op <= alu_op;
        id_ram_we <= ram_we;
        id_rf_wsel <= rf_wsel;
        id_rd <= rd;
        id_func <= func;
        id_opcode <= opcode;
        id_rf_nwe <= rf_nwe;
        id_is_ram <= is_ram;
        id_is_movz <= is_movz;
        id_rdata1 <= rdata1;
        id_rdata2 <= rdata2;
        id_hilo_we <= hilo_we;
        id_ram_wen <= ram_wen;
        id_ram_sign <= ram_sign;
        id_cp0_ex <= cp0_ex;
        id_cp0_excode <= cp0_excode;
        id_cp0_badvaddr <= if_cp0_badvaddr;
        id_cp0_we <= cp0_we;
        id_cp0_bd <= cp0_bd;
        id_cp0_addr <= cp0_addr;
        id_cp0_eret_flush <= cp0_eret_flush;
    end
end



endmodule