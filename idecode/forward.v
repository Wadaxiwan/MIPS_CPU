`define BEQ       5'b10110
`define BNE       5'b10111
`define BGEZ      5'b11000 
`define BGTZ      5'b11001 
`define BLEZ      5'b11010 
`define BLTZ      5'b11011
`define SLTU      5'b11100 
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


module forward(
    input                          clk,
    input                       resetn,
    input  [31:0]                   pc, 
    input  [31:0]                ex_pc,
    input  [31:0]                  imm, 
    input  [4:0]                alu_op,
    input  [2:0]                npc_op,
    input  [31:0]               rdata1,
    input  [31:0]               rdata2,
    input  [31:0]            id_rdata1,
    input  [31:0]              alu_out,
    input  [31:0]              ram_out,
    input  [63:0]             hilo_out,
    input  [31:0]            ex_rdata1,
    input  [31:0]           ex_alu_out,
    input  [63:0]          ex_hilo_out,
    input  [2:0]            ex_rf_wsel,
    input  [2:0]            id_rf_wsel,
    input             id_ex_hazard_mem,
    input          id_ex_rs_hazard_reg,
    input         id_mem_rs_hazard_mem,
    input         id_mem_rs_hazard_reg,
    input          id_ex_rt_hazard_reg,
    input         id_mem_rt_hazard_mem,
    input         id_mem_rt_hazard_reg,
    // input                   id_is_movz,
    // input                   ex_is_movz,
    output reg [31:0]       out_rdata1,
    output reg [31:0]       out_rdata2,
    output [31:0]                 dest,
    output                         jmp  // �Ƿ���ת
);

wire [31:0] pc4;

initial
begin
    out_rdata1 = 32'h0;
    out_rdata2 = 32'h0;
end

// ���ݲ�ͬ�Ķ������ͣ�ѡ��ͬ�Ķ������ݣ���� CPU_Pipeline_Design.pdf
always @(*) begin
    if (resetn == 1'b0 || id_ex_hazard_mem) begin  // ��ǰָ����ǰһ��ָ����ڼ���ʹ��ð��ʱ����ͣһ������
        out_rdata1 = 32'h0;
    end
    else if(id_ex_rs_hazard_reg) begin   // ID �� EX �εļĴ���ʹ�ô���ð��ʱ
        if(id_rf_wsel == `WB_HI) begin
            out_rdata1 = hilo_out[63:32];  // ��ǰָ��Ϊ mfhi ָ��ʱ��ʹ�� HILO �ε� hilo_out ����
        end
        else if(id_rf_wsel == `WB_LO) begin
            out_rdata1 = hilo_out[31:0];   // ��ǰָ��Ϊ mflo ָ��ʱ��ʹ�� HILO �ε� hilo_out ����
        end
        else begin
            out_rdata1 = alu_out;       // ��ǰָ�Ϊ mfhi �� mflo ָ��ʱ��ʹ�� alu �� alu_out ����
        end
    end
    else if(id_mem_rs_hazard_mem) begin // ID �� MEM �ε� RAM ʹ�ô���ð��ʱ
        out_rdata1 = ram_out;            // ʹ�� MEM �ε� ram_out ����
    end
    else if(id_mem_rs_hazard_reg) begin  // ID �� MEM �εļĴ���ʹ�ô���ð��ʱ
        if (ex_rf_wsel == `WB_PC8) begin                          
            out_rdata1 = ex_pc + 32'h8;          // ��ǰָ��Ϊ jalr ָ��ʱ��ʹ�� EX �ε� pc ���� + 8
        end else if (ex_rf_wsel == `WB_HI) begin
            out_rdata1 = ex_hilo_out[63:32];
        end else if (ex_rf_wsel == `WB_LO) begin
            out_rdata1 = ex_hilo_out[31:0];
        end else begin
            out_rdata1 = ex_alu_out;       // ��ǰָ�Ϊ jalr ָ��ʱ��ʹ�� EX �ε� alu_out ����
        end
    end
    else begin
        out_rdata1 = rdata1;            // ��ǰָ�����ð��ʱ��ʹ�� ID �ε� rdata1 ����
    end
end

always @(*) begin
    if (resetn == 1'b0 || id_ex_hazard_mem) begin
        out_rdata2 = 32'h0;
    end
    else if(id_ex_rt_hazard_reg) begin
        if(id_rf_wsel == `WB_HI) begin
            out_rdata2 = hilo_out[63:32];
        end
        else if(id_rf_wsel == `WB_LO) begin
            out_rdata2 = hilo_out[31:0];
        end
        else begin
            out_rdata2 = alu_out;
        end
    end
    else if(id_mem_rt_hazard_mem) begin
        out_rdata2 = ram_out;
    end
    else if(id_mem_rt_hazard_reg) begin
        if (ex_rf_wsel == `WB_PC8) begin
            out_rdata2 = ex_pc + 32'h8;
        end else if (ex_rf_wsel == `WB_HI) begin
            out_rdata2 = ex_hilo_out[63:32];
        end else if (ex_rf_wsel == `WB_LO) begin
            out_rdata2 = ex_hilo_out[31:0];
        end else begin
            out_rdata2 = ex_alu_out;
        end
    end 
    else begin
        out_rdata2 = rdata2;
    end
end


assign pc4 = pc + 32'h4;

assign jmp = ({alu_op == `BEQ} & out_rdata1 == out_rdata2) |
             ({alu_op == `BNE} & out_rdata1 != out_rdata2) |
             ({alu_op == `BGEZ} & $signed(out_rdata1) >= $signed(32'b0)) |
             ({alu_op == `BGTZ} & $signed(out_rdata1) > $signed(32'b0)) |
             ({alu_op == `BLEZ} & $signed(out_rdata1) <= $signed(32'b0)) |
             ({alu_op == `BLTZ} & $signed(out_rdata1) < $signed(32'b0)) |
             ({npc_op == `NPC_J}) |
             ({npc_op == `NPC_JR}) ;

assign dest = ({32{alu_op == `BEQ}} & (pc4 + imm)) |
             ({32{alu_op == `BNE}} &  (pc4 + imm)) |
             ({32{alu_op == `BGEZ}} & (pc4 + imm)) |
             ({32{alu_op == `BGTZ}} & (pc4 + imm)) |
             ({32{alu_op == `BLEZ}} & (pc4 + imm)) |
             ({32{alu_op == `BLTZ}} & (pc4 + imm)) |
             ({32{npc_op == `NPC_J}} & ({pc4[31:28], imm[27:0]})) |
             ({32{npc_op == `NPC_JR}} & out_rdata1) ;

endmodule


    //   out_rdata1 = {32{id_ex_rs_hazard_reg & id_rf_wsel == `WB_ALU}} & alu_out |  // ʹ�� EX �ε� alu_in ����
    //                  {32{id_mem_rs_hazard_mem & ex_rf_wsel == `WB_RAM}} & ram_out |  // ʹ�� MEM �ε� ram_in ����
    //                  {32{id_mem_rs_hazard_reg & ex_rf_wsel == `WB_ALU}} & ex_alu_out |  // ʹ�� EX �ε� alu_out ����
    //                  {32{id_mem_rs_hazard_reg & ex_rf_wsel == `WB_PC8}} & (ex_pc + 32'h8);