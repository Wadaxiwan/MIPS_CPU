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

wire  [31:0]              pc;
wire                     jmp;  // decide branch in decode, 1 jmp 0 pc+4
wire                      br;  // zero 1  not zero 0
wire  [2:0]           npc_op;  // npc op generate by controller

wire  [2:0]          rf_wsel;  // rd write sel generate by controller
wire  [31:0]    mux_rf_wdata;  // rd write data generate by rf_mux
wire               mux_rf_we;

wire  [4:0]           alu_op;  // alu op generate by controller
wire  [31:0]         alu_out;  // alu out generate by execute

wire                  ram_we;  // ram write enable generate by controller
wire  [31:0]         ram_out;  // ram out generate by ram_top

wire  [31:0]          rdata1;  //  reg1(rs) data
wire  [31:0]          rdata2;  //  reg2(rt) data
wire  [1:0]           rs_sel;  //  rt select
wire  [1:0]           rt_sel;  //  rt select
wire  [31:0]             imm;  //  imm gen data
wire  [31:0]            dest;  //  dest
wire  [31:0]            inst;  //  instruction
wire                   of_op;


/* CP0 */
wire                   int_flush;
wire [31:0]               int_pc;
wire [31:0]            cp0_rdata;


wire                      cp0_ex;  // first in ifetch , this inst is a exception
wire  [4:0]           cp0_excode;  // first in ifetch
wire  [31:0]        cp0_badvaddr;  // first in ifetch

wire                   if_cp0_ex; 
wire  [4:0]        if_cp0_excode; 
wire  [31:0]     if_cp0_badvaddr; 


wire                      cp0_we;  // first in idecode
wire                      cp0_bd;  // first in idecode , this inst is a branch delay slot
wire   [4:0]            cp0_addr;  // first in idecode
wire              cp0_eret_flush;

wire  [4:0]      ide_cp0_excode;    // update in idecode
wire             ide_cp0_ex;        // update in idecode

wire  [4:0]      id_cp0_excode;    
wire             id_cp0_ex;        
wire  [31:0]     id_cp0_badvaddr;  // first in ifetch
wire             id_cp0_we;        // first in ifetch
wire             id_cp0_bd;        // first in idecode , this inst is a branch delay slot
wire  [4:0]      id_cp0_addr;      // first in idecode
wire             id_cp0_eret_flush;

wire  [4:0]      exe_cp0_excode;    // update in execute
wire             exe_cp0_ex;        // update in execute
wire             cp0_tag;
wire             div_finish;

wire  [4:0]      ex_cp0_excode;    // first in ifetch
wire             ex_cp0_ex;        // first in ifetch , this inst is a exception
wire  [31:0]     ex_cp0_badvaddr;  // first in ifetch
wire             ex_cp0_we;        // first in ifetch
wire             ex_cp0_bd;        // first in idecode , this inst is a branch delay slot
wire  [4:0]      ex_cp0_addr;      // first in idecode
wire             ex_cp0_eret_flush;
wire             ex_cp0_tag;

wire  [4:0]      memory_cp0_excode;    // first in ifetch
wire             memory_cp0_ex;        // first in ifetch , this inst is a exception
wire  [31:0]     memory_cp0_badvaddr;  // first in ifetch

wire  [4:0]      mem_cp0_excode;    // first in ifetch
wire             mem_cp0_ex;        // first in ifetch , this inst is a exception
wire  [31:0]     mem_cp0_badvaddr;  // first in ifetch
wire             mem_cp0_we;        // first in ifetch
wire             mem_cp0_bd;        // first in idecode , this inst is a branch delay slot
wire  [4:0]      mem_cp0_addr;      // first in idecode
wire             mem_cp0_eret_flush;
wire             mem_cp0_tag;


/* CP0 End */
wire              ifetch_ex;
wire             idecode_ex;
wire                  ex_ex;


wire [4:0]              rd;  // rd number
wire [5:0]            func;  
wire [5:0]          opcode;  
wire                rf_nwe;  
wire                is_ram;
wire [1:0]         hilo_we;
wire  [63:0]      hilo_out;
wire           cond_branch;
wire        cond_exe_stall;
wire   [3:0]       ram_wen;
wire   [1:0]      ram_sign;

wire  [31:0]         if_pc;
wire  [31:0]           npc;
wire  [31:0]       if_inst;
wire              id_of_op;

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
wire   [3:0]    id_ram_wen;
wire   [1:0]   id_ram_sign;
wire  [31:0]    out_rdata1;
wire  [31:0]    out_rdata2;

wire   [3:0]    ex_ram_wen;
wire   [1:0]   ex_ram_sign;
wire  [5:0]        ex_func;  
wire  [5:0]      ex_opcode;  
wire [31:0]          ex_pc;
wire [31:0]     ex_alu_out;
wire  [2:0]     ex_rf_wsel;  // rd write sel generate by controller
wire  [4:0]          ex_rd;  // rd register
wire [31:0]      ex_rdata1;
wire [31:0]      ex_rdata2;
wire             ex_ram_we;  // ram write enable generate by controller
wire             ex_rf_nwe;
wire             ex_is_ram;
wire [63:0]    ex_hilo_out;

wire  [5:0]        mem_func;  
wire  [5:0]      mem_opcode; 
wire [31:0]          mem_pc;
wire [31:0]     mem_alu_out;
wire [31:0]     mem_ram_out;
wire [31:0]      mem_rdata1;
wire [31:0]      mem_rdata2;
wire  [2:0]     mem_rf_wsel;
wire  [4:0]          mem_rd;  // rd register
wire [63:0]    mem_hilo_out;
wire             mem_rf_nwe;
reg            hazard_stall;
reg    ie_mfc0_hazard_stall;
reg    im_mfc0_hazard_stall;
wire              exe_stall;
wire          int_div_stall;




initial begin
    hazard_stall = 1'b0;
    ie_mfc0_hazard_stall = 1'b0;
    im_mfc0_hazard_stall = 1'b0;
end

// always @(*) begin
//     if(id_wb_rs_hazard_mfc0 | id_wb_rt_hazard_mfc0) begin
//         iw_mfc0_hazard_stall = 1'b1;
//     end
//     else begin
//         iw_mfc0_hazard_stall = 1'b0;
//     end
// end

// 数据相关 R-R 
wire   id_ex_rs_hazard_reg =  !id_is_ram & id_rf_nwe & id_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;         // ID和EX段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_ex_rt_hazard_reg =  !id_is_ram & id_rf_nwe & id_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;         // ID和EX段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向
wire   id_ex_hazard_mem    =  (id_is_ram & id_rf_nwe & if_inst[25:21] != 5'b00000 & id_rd == if_inst[25:21]) || 
                              (id_is_ram & id_rf_nwe & if_inst[20:16] != 5'b00000 & id_rd == if_inst[20:16]);   // 需要停顿，store 此时不需要判断 rt 是不是有冒险，可以等到下一个周期判断，此处可优化 [TODO]
wire   id_ex_rs_hazard_mfc0 = id_rf_wsel == `WB_CP0 & id_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;  // 需要停顿两个周期，等到下一个周期会因为 id_mem_rt/rs_hazard_mfc0 再次被检测到从而再暂停，因此只需要暂停一个周期                          
wire   id_ex_rt_hazard_mfc0 = id_rf_wsel == `WB_CP0 & id_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;


// 访存数据相关
wire   id_mem_rs_hazard_mem = ex_is_ram & ex_rf_nwe & ex_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;        // ID和MEM段相关，需要访存且需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_mem_rt_hazard_mem = ex_is_ram & ex_rf_nwe & ex_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;  // ID和MEM段相关，需要访存且需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向
wire   id_mem_rs_hazard_reg = !ex_is_ram & ex_rf_nwe & ex_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;      // ID和MEM段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rs相同，只需要定向
wire   id_mem_rt_hazard_reg = !ex_is_ram & ex_rf_nwe & ex_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;    // ID和MEM段相关，不需要访存但需要写回的指令，并且写回的寄存器编号与当前译码指令的rt相同，只需要定向
wire   id_mem_rs_hazard_mfc0 = ex_rf_wsel == `WB_CP0 & ex_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;  // 需要停顿一个周期    
wire   id_mem_rt_hazard_mfc0 = ex_rf_wsel == `WB_CP0 & ex_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;

wire   id_wb_rs_hazard_mfc0 = mem_rf_wsel == `WB_CP0 & mem_rd == if_inst[25:21] & if_inst[25:21] != 5'b00000;  // 需要停顿一个周期    
wire   id_wb_rt_hazard_mfc0 = mem_rf_wsel == `WB_CP0 & mem_rd == if_inst[20:16] & if_inst[20:16] != 5'b00000;


always @(*) begin
    if(id_ex_hazard_mem) begin
        hazard_stall = 1'b1;
    end
    else begin
        hazard_stall = 1'b0;
    end
end

always @(*) begin
    if(id_ex_rs_hazard_mfc0 | id_ex_rt_hazard_mfc0) begin
        ie_mfc0_hazard_stall = 1'b1;
    end
    else begin
        ie_mfc0_hazard_stall = 1'b0;
    end
end

always @(*) begin
    if(id_mem_rs_hazard_mfc0 | id_mem_rt_hazard_mfc0) begin
        im_mfc0_hazard_stall = 1'b1;
    end
    else begin
        im_mfc0_hazard_stall = 1'b0;
    end
end

assign inst = inst_sram_rdata;

// CP0 exception
assign ifetch_ex = if_cp0_ex | id_cp0_ex | ex_cp0_ex | mem_cp0_ex;
assign idecode_ex = id_cp0_ex | ex_cp0_ex | mem_cp0_ex;
assign ex_ex = (ex_cp0_ex & ~ex_cp0_tag) | (mem_cp0_ex & ~mem_cp0_tag);   // 当 ex/mem 和 mem/wb 都没有异常或都带上了除法标记（意味着在除法之后的指令） 除法允许写入hilo寄存器

if_id u_if_id(
    .clk(clk),
    .resetn(resetn),
    .hazard_stall(hazard_stall),
    .exe_stall(exe_stall),
    .cond_exe_stall(cond_exe_stall),
    .cond_cp0_stall(cond_cp0_stall),
    .int_div_stall(int_div_stall),
    .ie_mfc0_hazard_stall(ie_mfc0_hazard_stall),
    .im_mfc0_hazard_stall(im_mfc0_hazard_stall),
    .int_flush(int_flush),
    .cp0_ex(cp0_ex),
    .cp0_excode(cp0_excode),
    .cp0_badvaddr(cp0_badvaddr),
    .jmp(jmp),
    .pc(pc),
    .inst(inst),
    .if_pc(if_pc),
    .if_inst(if_inst),
    .if_cp0_ex(if_cp0_ex),
    .if_cp0_excode(if_cp0_excode),
    .if_cp0_badvaddr(if_cp0_badvaddr)
);

ifetch u_ifetch(
    .clk(clk),
    .ifetch_ex(ifetch_ex),
    .ie_mfc0_hazard_stall(ie_mfc0_hazard_stall),
    .im_mfc0_hazard_stall(im_mfc0_hazard_stall),
    .hazard_stall(hazard_stall),
    .exe_stall(exe_stall),
    .cond_branch(cond_branch),
    .int_flush(int_flush),
    .int_pc(int_pc),
    .rst_n(resetn),
    .dest(dest),
    .jmp(jmp),
    .op(npc_op),
    .pc(pc),
    .npc(npc),
    .inst_sram_addr(inst_sram_addr),
    .cond_exe_stall(cond_exe_stall),
    .cond_cp0_stall(cond_cp0_stall),
    .cp0_ex(cp0_ex),
    .cp0_excode(cp0_excode),
    .cp0_badvaddr(cp0_badvaddr)
);


idecode u_idecode(
    .clk(clk),
    .resetn(resetn),
    .inst(if_inst),
    .idecode_ex(idecode_ex),
    .if_cp0_ex(if_cp0_ex),
    .if_cp0_excode(if_cp0_excode),
    .rf_rd(mem_rd),
    .rf_wdata(mux_rf_wdata),
    .rf_we(mux_rf_we),
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
    .is_ram(is_ram),
    .hilo_we(hilo_we),
    .ram_wen(ram_wen),
    .ram_sign(ram_sign),
    .id_cp0_ex(ide_cp0_ex),
    .id_cp0_excode(ide_cp0_excode),
    .id_cp0_bd(cp0_bd),
    .id_cp0_we(cp0_we),
    .id_cp0_addr(cp0_addr),
    .id_cp0_eret_flush(cp0_eret_flush),
    .of_op(of_op)
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
    .cp0_out(cp0_rdata),
    .id_ex_hazard_mem(id_ex_hazard_mem),
    .id_ex_rs_hazard_reg(id_ex_rs_hazard_reg),
    .id_mem_rs_hazard_mem(id_mem_rs_hazard_mem),
    .id_mem_rs_hazard_reg(id_mem_rs_hazard_reg),
    .id_ex_rt_hazard_reg(id_ex_rt_hazard_reg),
    .id_mem_rt_hazard_mem(id_mem_rt_hazard_mem),
    .id_mem_rt_hazard_reg(id_mem_rt_hazard_reg),
    .id_wb_rs_hazard_mfc0(id_wb_rs_hazard_mfc0),
    .id_wb_rt_hazard_mfc0(id_wb_rt_hazard_mfc0),
    .out_rdata1(out_rdata1),
    .out_rdata2(out_rdata2),
    .dest(dest),
    .cond_branch(cond_branch),
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
    .ram_wen(ram_wen),
    .ram_sign(ram_sign),
    .rf_wsel(rf_wsel),
    .of_op(of_op),
    .rd(rd),
    .func(func),
    .opcode(opcode),
    .rf_nwe(rf_nwe),
    .is_ram(is_ram),
    .hilo_we(hilo_we),
    .exe_stall(exe_stall),
    .hazard_stall(hazard_stall),
    .ie_mfc0_hazard_stall(ie_mfc0_hazard_stall),
    .im_mfc0_hazard_stall(im_mfc0_hazard_stall),
    .int_div_stall(int_div_stall),
    .int_flush(int_flush),
    .cp0_ex(ide_cp0_ex),
    .cp0_excode(ide_cp0_excode),
    .if_cp0_badvaddr(if_cp0_badvaddr),
    .cp0_we(cp0_we),
    .cp0_bd(cp0_bd),
    .cp0_addr(cp0_addr),
    .cp0_eret_flush(cp0_eret_flush),
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
    .id_hilo_we(id_hilo_we),
    .id_ram_wen(id_ram_wen),
    .id_ram_sign(id_ram_sign),
    .id_cp0_ex(id_cp0_ex),
    .id_cp0_excode(id_cp0_excode),
    .id_cp0_badvaddr(id_cp0_badvaddr),
    .id_cp0_we(id_cp0_we),
    .id_cp0_bd(id_cp0_bd),
    .id_cp0_addr(id_cp0_addr),
    .id_cp0_eret_flush(id_cp0_eret_flush),
    .id_of_op(id_of_op)
);

execute u_execute(
    .clk(clk),
    .rst_n(resetn),
    .id_of_op(id_of_op),
    .id_cp0_ex(id_cp0_ex),
    .id_cp0_excode(id_cp0_excode),
    .ex_ex(ex_ex),
    .int_flush(int_flush),
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
    .stall(exe_stall),
    .exe_cp0_ex(exe_cp0_ex),
    .exe_cp0_excode(exe_cp0_excode),
    .cp0_tag(cp0_tag),
    .div_finish(div_finish)
    // .rf_nwe(id_rf_nwe),
    // .id_rf_nwe(id_rf_nwe)
);

ex_mem u_ex_mem(
    .clk(clk),
    .resetn(resetn),
    .id_pc(id_pc),
    .alu_out(alu_out),
    .hilo_out(hilo_out),
    .div_finish(div_finish),
    .int_flush(int_flush),
    .cp0_tag(cp0_tag),
    .exe_cp0_ex(exe_cp0_ex),
    .exe_cp0_excode(exe_cp0_excode),
    .int_div_stall(int_div_stall),
    .memory_cp0_ex(memory_cp0_ex),
    .memory_cp0_excode(memory_cp0_excode),
    .memory_cp0_badvaddr(memory_cp0_badvaddr),
    .id_cp0_badvaddr(id_cp0_badvaddr),
    .id_cp0_we(id_cp0_we),
    .id_cp0_bd(id_cp0_bd),
    .id_cp0_addr(id_cp0_addr),
    .id_cp0_eret_flush(id_cp0_eret_flush),
    .id_rf_wsel(id_rf_wsel),
    .id_rd(id_rd),
    .id_rdata1(id_rdata1),
    .id_rdata2(id_rdata2),
    .id_ram_we(id_ram_we),
    .id_rf_nwe(id_rf_nwe),
    .id_is_ram(id_is_ram),
    .id_ram_wen(id_ram_wen),
    .id_ram_sign(id_ram_sign),
    .id_opcode(id_opcode),
    .id_func(id_func),
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
    .ex_hilo_out(ex_hilo_out),
    .ex_opcode(ex_opcode),
    .ex_func(ex_func),
    .ex_ram_wen(ex_ram_wen),
    .ex_ram_sign(ex_ram_sign),
    .ex_cp0_ex(ex_cp0_ex),
    .ex_cp0_excode(ex_cp0_excode),
    .ex_cp0_badvaddr(ex_cp0_badvaddr),
    .ex_cp0_we(ex_cp0_we),
    .ex_cp0_bd(ex_cp0_bd),
    .ex_cp0_addr(ex_cp0_addr),
    .ex_cp0_eret_flush(ex_cp0_eret_flush),
    .ex_cp0_tag(ex_cp0_tag)
);

memory u_memory(
    .ex_ram_wen(ex_ram_wen),
    .ex_ram_sign(ex_ram_sign),
    .ex_ram_addr(ex_alu_out[1:0]),
    .id_ram_we(id_ram_we),
    .id_ram_wen(id_ram_wen),
    .id_ram_addr(alu_out),
    .id_cp0_ex(id_cp0_ex),
    .memory_ex(ex_ex),
    .data_sram_wen(data_sram_wen),
    .data_sram_addr(data_sram_addr),
    .ram_in(data_sram_rdata),
    .ram_out(ram_out),
    .s_ram_in(id_rdata2),
    .s_ram_out(data_sram_wdata),
    .memory_cp0_excode(memory_cp0_excode),    
    .memory_cp0_ex(memory_cp0_ex),
    .memory_cp0_badvaddr(memory_cp0_badvaddr)
);

mem_wb u_mem_wb(
    .clk(clk),
    .resetn(resetn),
    .ex_pc(ex_pc),
    .ex_alu_out(ex_alu_out),
    .div_finish(div_finish),
    .int_div_stall(int_div_stall),
    .ram_out(ram_out),
    .ex_rdata1(ex_rdata1),
    .ex_rdata2(ex_rdata2),
    .ex_rf_wsel(ex_rf_wsel),
    .ex_rf_nwe(ex_rf_nwe),
    .ex_hilo_out(ex_hilo_out),
    .ex_rd(ex_rd),
    .ex_opcode(ex_opcode),
    .ex_func(ex_func),
    .int_flush(int_flush),
    .ex_cp0_ex(ex_cp0_ex),
    .ex_cp0_excode(ex_cp0_excode),
    .ex_cp0_badvaddr(ex_cp0_badvaddr),
    .ex_cp0_we(ex_cp0_we),
    .ex_cp0_bd(ex_cp0_bd),
    .ex_cp0_addr(ex_cp0_addr),
    .ex_cp0_tag(ex_cp0_tag),
    .ex_cp0_eret_flush(ex_cp0_eret_flush),
    .mem_pc(mem_pc),
    .mem_alu_out(mem_alu_out),
    .mem_ram_out(mem_ram_out),
    .mem_rdata1(mem_rdata1),
    .mem_rdata2(mem_rdata2),
    .mem_rf_wsel(mem_rf_wsel),
    .mem_rf_nwe(mem_rf_nwe),
    .mem_rd(mem_rd),
    .mem_hilo_out(mem_hilo_out),
    .mem_opcode(mem_opcode),
    .mem_func(mem_func),
    .mem_cp0_ex(mem_cp0_ex),
    .mem_cp0_excode(mem_cp0_excode),
    .mem_cp0_badvaddr(mem_cp0_badvaddr),
    .mem_cp0_we(mem_cp0_we),
    .mem_cp0_bd(mem_cp0_bd),
    .mem_cp0_addr(mem_cp0_addr),
    .mem_cp0_tag(mem_cp0_tag),
    .mem_cp0_eret_flush(mem_cp0_eret_flush)
);

rf_mux u_rf_mux(
    .pc(mem_pc),
    .mem_rf_nwe(mem_rf_nwe),
    .mem_cp0_ex(mem_cp0_ex),
    .int_flush(int_flush),
    .rf_wsel(mem_rf_wsel),
    .alu_in(mem_alu_out),
    .rs_in(mem_rdata1),
    .ram_in(mem_ram_out),
    .hilo_in(mem_hilo_out),
    .cp0_in(cp0_rdata),
    .rf_wdata(mux_rf_wdata),
    .rf_nwe(mux_rf_we)
);


cp0_reg u_cp0_reg(
    .clk(clk),
    .resetn(resetn),
    .div_finish(div_finish),
    .eret_flush(mem_cp0_eret_flush),
    .cp0_tag(mem_cp0_tag),
    .cp0_badvaddr(mem_cp0_badvaddr),
    .cp0_excode_t(mem_cp0_excode),
    .cp0_pc(mem_pc),
    .cp0_ex_t(mem_cp0_ex),
    .cp0_bd(mem_cp0_bd),
    .cp0_we(mem_cp0_we),
    .cp0_addr(mem_cp0_addr),
    .cp0_wdata(mem_rdata2),
    .cp0_int(ext_int),
    .cp0_rdata(cp0_rdata),
    .int_pc(int_pc),
    .int_flush(int_flush),
    .int_div_stall(int_div_stall)
);

assign data_sram_en    = 1'b1;

assign inst_sram_en    = 1'b1;
assign inst_sram_wen   = {4{1'b0}};
assign inst_sram_wdata = 32'b0;

assign debug_wb_pc = mem_pc;
assign debug_wb_rf_wdata = mux_rf_wdata;
assign debug_wb_rf_wen = {4{mux_rf_we}};
assign debug_wb_rf_wnum = mem_rd;

endmodule