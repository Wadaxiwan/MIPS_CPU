`define  M_TYPE  3'b000 
`define  R_TYPE  3'b010 // [rs]        [rt]
`define  I_TYPE  3'b011 // sa          [rt]
`define  S_TYPE  3'b100 // [base]  [offset]
`define  B_TYPE  3'b101 // [rs]        [rt]
`define  J_TYPE  3'b110 // imm         

module mycpu_top (
    input            clk             ,  // clock, 100MHz
    input            resetn          ,  // active low
    input  [5:0]     ext_int,

    output            inst_sram_en    ,
    output  [3:0]     inst_sram_wen   ,
    output  [31:0]    inst_sram_addr  ,
    output  [31:0]    inst_sram_wdata ,
    input   [31:0]    inst_sram_rdata ,  
    
    output            data_sram_en    ,
    output  [3:0]     data_sram_wen   ,
    output  [31:0]    data_sram_addr  ,
    output  [31:0]    data_sram_wdata ,
    input   [31:0]    data_sram_rdata , 

    // debug signals
    output  [31:0]    debug_wb_pc     ,  // 当前正在执行指令的PC
    output  [3:0]     debug_wb_rf_wen ,  // 当前通用寄存器组的写使能信号
    output  [4 :0]    debug_wb_rf_wnum,  // 当前通用寄存器组写回的寄存器编号
    output  [31:0]    debug_wb_rf_wdata  // 当前指令要写回的数据
);

wire  [31:0]          pc;
wire                 jmp;  // decide branch in decode, 1 jmp 0 pc+4
wire                  br;  // zero 1  not zero 0
wire  [2:0]       npc_op;  // npc op generate by controller

wire  [2:0]      rf_wsel;  // rd write sel generate by controller
wire  [31:0]    rf_wdata;  // rd write data generate by rf_mux

wire  [4:0]       alu_op;  // alu op generate by controller
wire  [31:0]     alu_out;  // alu out generate by execute

wire              ram_we;  // ram write enable generate by controller
wire  [31:0]     ram_out;  // ram out generate by ram_top

wire  [31:0]      rdata1;  //  reg1(rs) data
wire  [31:0]      rdata2;  //  reg2(rt) data
wire  [1:0]       rs_sel;  //  rt select
wire  [1:0]       rt_sel;  //  rt select
wire  [31:0]         imm;  //  imm gen data
wire  [31:0]         dest;  //  dest
wire  [31:0]        inst;  //  instruction

wire [4:0]              rd;  // rd number
wire [5:0]            func;  
wire [5:0]          opcode;  
wire [2:0]           itype;  
wire                rf_nwe;  
wire                is_ram;
wire [1:0]         hilo_we;
wire  [63:0]      hilo_out;


wire  [31:0]         if_pc;
wire  [31:0]           npc;
wire  [31:0]       if_inst;

wire  [31:0]         id_pc;
wire  [1:0]     id_hilo_we;
wire  [31:0]     id_rdata1;  
wire  [31:0]     id_rdata2;
wire  [1:0]      id_rs_sel;  
wire  [1:0]      id_rt_sel;
wire  [31:0]        id_imm;  
wire  [4:0]      id_alu_op;  
wire             id_ram_we;  
wire  [2:0]     id_rf_wsel; 
wire  [4:0]          id_rd;  
wire  [5:0]        id_func;  
wire  [5:0]      id_opcode;  
wire             id_rf_nwe;
wire             id_is_ram;
wire            id_is_movz;
wire  [31:0]    out_rdata1;
wire  [31:0]    out_rdata2;


wire [31:0]          ex_pc;
wire [31:0]     ex_alu_out;
wire  [2:0]     ex_rf_wsel;  // rd write sel generate by controller
wire  [4:0]          ex_rd;  // rd register
wire [31:0]      ex_rdata1;
wire [31:0]      ex_rdata2;
wire             ex_ram_we;  // ram write enable generate by controller
wire             ex_rf_nwe;
wire             ex_is_ram;
wire            ex_is_movz;
wire [63:0]    ex_hilo_out;

wire [31:0]         mem_pc;
wire [31:0]    mem_alu_out;
wire [31:0]    mem_ram_out;
wire [31:0]     mem_rdata1;
wire  [2:0]    mem_rf_wsel;
wire  [4:0]         mem_rd;  // rd register
wire [63:0]   mem_hilo_out;
wire            mem_rf_nwe;
reg           hazard_stall;
wire             exe_stall;

initial begin
    hazard_stall = 1'b0;
end

always @(*) begin
    if(id_ex_hazard_mem) begin
        hazard_stall = 1'b1;
    end
    else begin
        hazard_stall = 1'b0;
    end
end


// 数据相关 R-R 
wire   id_ex_rs_hazard_reg =  !id_is_ram & id_rf_nwe & id_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;         // ID和EX段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_ex_rt_hazard_reg =  !id_is_ram & id_rf_nwe & id_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;         // ID和EX段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向
wire   id_ex_hazard_mem    =  (id_is_ram & id_rf_nwe & if_inst[25:21] != 5'b00000 & id_rd == if_inst[25:21]) || 
                              (id_is_ram & id_rf_nwe & if_inst[20:16] != 5'b00000 & id_rd == if_inst[20:16]);   // 需要停顿，store 此时不需要判断 rt 是不是有冒险，可以等到下一个周期判断，此处可优化 [TODO]
                              


// 访存数据相关
wire   id_mem_rs_hazard_mem = ex_is_ram & ex_rf_nwe & ex_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;        // ID和MEM段相关，需要访存且需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_mem_rt_hazard_mem = ex_is_ram & ex_rf_nwe & ex_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;  // ID和MEM段相关，需要访存且需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向
wire   id_mem_rs_hazard_reg = !ex_is_ram & ex_rf_nwe & ex_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;      // ID和MEM段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_mem_rt_hazard_reg = !ex_is_ram & ex_rf_nwe & ex_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;    // ID和MEM段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向


assign inst = inst_sram_rdata;
assign ram_out = data_sram_rdata;

if_id u_if_id(
    .clk(clk),
    .resetn(resetn),
    .hazard_stall(hazard_stall),
    .exe_stall(exe_stall),
    .jmp(jmp),
    .pc(pc),
    .inst(inst),
    .if_pc(if_pc),
    .if_inst(if_inst)
);

ifetch u_ifetch(
    .clk(clk),
    .hazard_stall(hazard_stall),
    .exe_stall(exe_stall),
    .rst_n(resetn),
    .dest(dest),
    .jmp(jmp),
    .op(npc_op),
    .pc(pc),
    .npc(npc)
);


idecode u_idecode(
    .clk(clk),
    .inst(if_inst),
    .rf_rd(mem_rd),
    .rf_wdata(rf_wdata),
    .rf_we(mem_rf_nwe),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .rs_sel(rs_sel),
    .rt_sel(rt_sel),
    .imm(imm),
    .alu_op(alu_op),
    .npc_op(npc_op),
    .ram_we(ram_we),
    .rf_wsel(rf_wsel), 
    .rf_nwe(rf_nwe),
    .rd(rd),  
    .func(func), 
    .opcode(opcode), 
    .itype(itype),
    .is_ram(is_ram),
    .hilo_we(hilo_we)
    // .ram_op(ram_op),
    // .of_op(of_op)
);

forward u_forward(
    .clk(clk),
    .resetn(resetn),
    .pc(if_pc),
    .ex_pc(ex_pc),
    .imm(imm),
    .alu_op(alu_op),
    .npc_op(npc_op),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .hilo_out(hilo_out),
    .ex_hilo_out(ex_hilo_out),
    .id_rdata1(id_rdata1),
    .alu_out(alu_out),
    .ram_out(ram_out),
    .id_rf_wsel(id_rf_wsel),
    .ex_rf_wsel(ex_rf_wsel),
    .ex_rdata1(ex_rdata1),
    .ex_alu_out(ex_alu_out),
    .id_ex_hazard_mem(id_ex_hazard_mem),
    .id_ex_rs_hazard_reg(id_ex_rs_hazard_reg),
    .id_mem_rs_hazard_mem(id_mem_rs_hazard_mem),
    .id_mem_rs_hazard_reg(id_mem_rs_hazard_reg),
    .id_ex_rt_hazard_reg(id_ex_rt_hazard_reg),
    .id_mem_rt_hazard_mem(id_mem_rt_hazard_mem),
    .id_mem_rt_hazard_reg(id_mem_rt_hazard_reg),
    // .id_is_movz(id_is_movz),
    // .ex_is_movz(ex_is_movz),
    .out_rdata1(out_rdata1),
    .out_rdata2(out_rdata2),
    .dest(dest),
    .jmp(jmp)
);

id_ex u_id_ex(
    .clk(clk),
    .resetn(resetn),
    .if_pc(if_pc),
    .rdata1(out_rdata1),
    .rdata2(out_rdata2),
    .rs_sel(rs_sel),
    .rt_sel(rt_sel),
    .imm(imm),
    .alu_op(alu_op),
    .ram_we(ram_we),
    .rf_wsel(rf_wsel),
    .rd(rd),
    .func(func),
    .opcode(opcode),
    .itype(itype),
    .rf_nwe(rf_nwe),
    .is_ram(is_ram),
    .is_movz(is_movz),
    .hilo_we(hilo_we),
    .exe_stall(exe_stall),
    .hazard_stall(hazard_stall),
    .id_pc(id_pc),
    .id_rdata1(id_rdata1),
    .id_rdata2(id_rdata2),
    .id_rs_sel(id_rs_sel),
    .id_rt_sel(id_rt_sel),
    .id_imm(id_imm),
    .id_alu_op(id_alu_op),
    .id_ram_we(id_ram_we),
    .id_rf_wsel(id_rf_wsel),
    .id_rd(id_rd),
    .id_func(id_func),
    .id_opcode(id_opcode),
    .id_rf_nwe(id_rf_nwe),
    .id_is_ram(id_is_ram),
    .id_is_movz(id_is_movz),
    .id_hilo_we(id_hilo_we)
);

execute u_execute(
    .clk(clk),
    .rst_n(resetn),
    .rf_wsel(id_rf_wsel),
    .hilo_we(id_hilo_we),
    .alu_op(id_alu_op),
    .rs_sel(id_rs_sel),
    .rt_sel(id_rt_sel),
    .rdata1(id_rdata1),
    .rdata2(id_rdata2),
    .imm(id_imm),
    .alu_out(alu_out),
    .hilo_out(hilo_out),
    .zero(br),
    .stall(exe_stall)
    // .rf_nwe(id_rf_nwe),
    // .id_rf_nwe(id_rf_nwe)
);

ex_mem u_ex_mem(
    .clk(clk),
    .resetn(resetn),
    .id_pc(id_pc),
    .alu_out(alu_out),
    .hilo_out(hilo_out),
    .br(br),
    .id_rf_wsel(id_rf_wsel),
    .id_rd(id_rd),
    .id_rdata1(id_rdata1),
    .id_rdata2(id_rdata2),
    .id_ram_we(id_ram_we),
    .id_rf_nwe(id_rf_nwe),
    .id_is_ram(id_is_ram),
    .id_is_movz(id_is_movz),
    .exe_stall(exe_stall),
    .ex_pc(ex_pc),
    .ex_alu_out(ex_alu_out),
    .ex_rf_wsel(ex_rf_wsel),
    .ex_rd(ex_rd),
    .ex_rdata1(ex_rdata1),
    .ex_rdata2(ex_rdata2),
    .ex_ram_we(ex_ram_we),
    .ex_rf_nwe(ex_rf_nwe),
    .ex_is_ram(ex_is_ram),
    .ex_is_movz(ex_is_movz),
    .ex_hilo_out(ex_hilo_out)
);

mem_wb u_mem_wb(
    .clk(clk),
    .resetn(resetn),
    .ex_pc(ex_pc),
    .ex_alu_out(ex_alu_out),
    .ram_out(ram_out),
    .ex_rdata1(ex_rdata1),
    .ex_rf_wsel(ex_rf_wsel),
    .ex_rf_nwe(ex_rf_nwe),
    .ex_hilo_out(ex_hilo_out),
    .ex_rd(ex_rd),
    .mem_pc(mem_pc),
    .mem_alu_out(mem_alu_out),
    .mem_ram_out(mem_ram_out),
    .mem_rdata1(mem_rdata1),
    .mem_rf_wsel(mem_rf_wsel),
    .mem_rf_nwe(mem_rf_nwe),
    .mem_rd(mem_rd),
    .mem_hilo_out(mem_hilo_out)
);

rf_mux u_rf_mux(
    .pc(mem_pc),
    .rf_wsel(mem_rf_wsel),
    .alu_in(mem_alu_out),
    .rs_in(mem_rdata1),
    .ram_in(mem_ram_out),
    .hilo_in(mem_hilo_out),
    .rf_wdata(rf_wdata)
);

assign data_sram_en    = 1'b1;
assign data_sram_wen   = {4{id_ram_we}};
assign data_sram_addr  = (alu_out[31:28] >= 4'h8 && alu_out[31:28] < 4'hC) ? {3'b0, alu_out[28:0]}: alu_out;
assign data_sram_wdata = id_rdata2;

assign inst_sram_en    = 1'b1;
assign inst_sram_wen   = {4{1'b0}};
assign inst_sram_addr  = (npc[31:28] >= 4'h8 && npc[31:28] < 4'hC) ? {3'b0, npc[28:0]}: npc;
assign inst_sram_wdata = 32'b0;

assign debug_wb_pc = mem_pc;
assign debug_wb_rf_wdata = rf_wdata;
assign debug_wb_rf_wen = {4{mem_rf_nwe}};
assign debug_wb_rf_wnum = mem_rd;

endmodule