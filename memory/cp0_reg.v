`define cp0_int   5'h00 // interrupt
`define EX_ADEL  5'h04 // address error exception (load or instruction fetch)
`define EX_ADES  5'h05 // address error exception (store)
`define EX_SYS   5'h08 // syscall exception
`define EX_BP    5'h09 // breakpoint exception
`define EX_RI    5'h0a // reserved instruction exception
`define EX_OV    5'h0c // coprocessor unusable exception
`define CR_INDEX      5'h01 // TLB index
`define CR_ENTRYLO0   5'h02 // TLB entry low 0
`define CR_ENTRYLO1   5'h03 // TLB entry low 1
`define CR_BADVADDR   5'h04 // bad virtual address
`define CR_COUNT      5'h05 // timer count
`define CR_ENTRYHI    5'h06 // TLB entry high
`define CR_COMPARE    5'h07 // timer compare
`define CR_STATUS     5'h08 // status register
`define CR_CAUSE      5'h09 // cause register
`define CR_EPC        5'h0a // exception program counter
`define CR_CONFIG     5'h0b // configuration register
`define CR_CONFIG1    5'h0c // configuration register 1


module cp0_reg(
    input                         clk,
    input                      resetn,
    input                  eret_flush,
    input   [31:0]       cp0_badvaddr,  // bad virtual address
    input   [31:0]             cp0_pc,  // pc of this instruction
    input   [4:0]          cp0_excode,  // exception code
    input                      cp0_ex,  // this instruction has exception
    input                      cp0_bd,  // this instruction is branch delay slot
    input                      cp0_we,
    input   [4:0]            cp0_addr,
    input   [31:0]          cp0_wdata,
    input   [5:0]             cp0_int,
    output  [31:0]          cp0_rdata,
    output  [31:0]             int_pc,
    output                  int_flush
);

wire [31:0]  status_rdata;
wire [31:0]  cause_rdata;
wire [31:0]  epc_rdata;
wire [31:0]  badvaddr_rdata;
wire [31:0]  count_rdata;
wire [31:0]  compare_rdata;


wire         mtc0_we;   // can write when cp0_we == 1 and cp0_ex == 0


assign int_flush = eret_flush | cp0_ex;  // flush when eret or exception (can be seen as the same in MIPS)
assign int_pc = {32{eret_flush}} & epc_rdata |
                {32{cp0_ex}} & 32'hBFC00380;

// @Breif: mtc0 inst write enable
assign mtc0_we = cp0_we && ~cp0_ex;



assign cp0_rdata = ({32{cp0_addr == `CR_COMPARE}} & status_rdata) |
                   ({32{cp0_addr == `CR_CAUSE}} & cause_rdata) |
                   ({32{cp0_addr == `CR_EPC}} & epc_rdata) |
                   ({32{cp0_addr == `CR_BADVADDR}} & badvaddr_rdata) |
                   ({32{cp0_addr == `CR_COUNT}} & count_rdata) |
                   ({32{cp0_addr == `CR_STATUS}} & status_rdata) ;

/* Reg */

// @Warning: badvaddr should be virtual address 
reg [31:0]  badvaddr;   // r8 s0   read only

// @Warning: count will be update once every 2 clk 
reg         tick;
reg [31:0]  count;      // r9 s0   read/write

// @Breif: when compare == count, timer interrupt will be trigger
// @Warning: when compare == count, cause_ti will be set to 1
// @Warning: when update compare from software, cause_ti will be set to 0
reg [31:0]  compare;    // r11 s0  read/write

// @Breif: Interrupt mask / enable / exception level / global interrupt enable
wire        status_bev; // r12 s0  read only always 1
reg [7:0]   status_im;  // r12 s0  read/write interrupt mask 1:enable 0:disable
reg         status_exl; // r12 s0  read/write exception level 1:exception 0:normal
// @Warning: status_exl == 1: all interrupt disable and EPC cause_bd can not be update
reg         status_ie;  // r12 s0  read/write interrupt enable 1:enable 0:disable

// @Berif: Delay slot / timer interrupt / interrupt pending / interrupt code
reg         cause_bd;   // r13 s0  read only  1:branch delay slot 0:normal
reg         cause_ti;   // r13 s0  read only  1:timer interrupt to be handle 0:no timer interrupt
reg [7:0]   cause_ip;   // r13 s0  read only(7:2) read/write(1:0)  1: interrupt to be handle 0:no interrupt
reg [4:0]   cause_excode;  // r13 s0  read only interrupt code

// @Breif: Exception program counter
// @Warning: when exception pc is in branch delay slot, EPC will be set to the address of the branch instruction
// @Warning: when status_exl == 1, EPC can not be update
reg [31:0]  epc;        // r14 s0  read/write



/*  Status  */
assign status = {{9{1'b0}}, status_bev, {6{1'b0}}, status_im, {6{1'b0}}, status_exl, status_ie};


// status bev
assign status_bev = 1'b1;

// status im
always @(posedge clk) begin
    if (~resetn) begin
        status_im <= 8'h0;
    end else if (mtc0_we && cp0_addr == `CR_STATUS) begin
        status_im <= cp0_wdata[15:8];
    end
end

// status exl
// @Warning: this will be use in previlege check
always @(posedge clk) begin
    if (~resetn) begin
        status_exl <= 1'b0;
    end
    else if (cp0_ex) begin
        status_exl <= 1'b1;
    end
    else if (eret_flush) begin
        status_exl <= 1'b0;
    end
    else if (mtc0_we && cp0_addr == `CR_STATUS) begin
        status_exl <= cp0_wdata[1];
    end
end


// status ie
always @(posedge clk) begin
    if(~resetn) begin
        status_ie <= 1'b0;
    end else if(mtc0_we && cp0_addr == `CR_STATUS) begin
        status_ie <= cp0_wdata[0];
    end
end


/*  Cause  */
assign cause = {cause_bd, cause_ti, {14{1'b0}}, cause_ip, 1'b0, cause_excode, {2{1'b0}}};

// cause bd
// @Warning: this only be update when status_exl == 0
always @(posedge clk) begin
    if(~resetn) begin
        cause_bd <= 1'b0;
    end else if(~status_exl && cp0_bd) begin
        cause_bd <= 1'b1;
    end 
end


// cause ti
always @(posedge clk) begin
    if(~resetn) begin
        cause_ti <= 1'b0;
    end else if(mtc0_we && cp0_addr == `CR_COMPARE) begin   // more priority than compare == count
        cause_ti <= 1'b0;
    end else if(count == compare) begin
        cause_ti <= 1'b1;
    end
end

// cause ip7 - ip2
always @(posedge clk) begin
    if(~resetn) begin
        cause_ip[7:2] <= 6'b0;
    end else begin
        cause_ip[7] <= cp0_int[5] | cause_ti;
        cause_ip[6:2] <= cp0_int[4:0];
    end
end

// cause ip1 - ip0
always @(posedge clk) begin
    if(~resetn) begin
        cause_ip[1:0] <= 2'b0;
    end else if(mtc0_we && cp0_addr == `CR_CAUSE) begin
        cause_ip[1:0] <= cp0_wdata[9:8];
    end
end


// cause exccode
always @(posedge clk) begin
    if(~resetn) begin
        cause_excode <= 5'b0;
    end else if(cp0_ex) begin
        cause_excode <= cp0_excode;
    end
end



/*  EPC  */

assign epc_rdata = epc;

always @(posedge clk) begin
    if(~resetn) begin
        epc <= 32'h0;
    end else if(cp0_ex && ~status_exl) begin
        epc <= cp0_bd ? cp0_pc - 3'h4 : cp0_pc;
    end else if (mtc0_we && cp0_addr == `CR_EPC) begin
        epc <= cp0_wdata;
    end
end



/*  BadVaddr  */

assign badvaddr_rdata = badvaddr;

always @(posedge clk) begin
    if (~resetn) begin
        badvaddr <= 32'h0;
    end else if(cp0_ex && (cp0_excode == `EX_ADEL || cp0_excode == `EX_ADES)) begin
        badvaddr <= cp0_badvaddr;
    end
end

/* Count  */

assign count_rdata = count;

always @(posedge clk) begin
    if(~resetn) begin
        tick <= 1'b0
    end else begin
        tick <= ~tick;
    end

    if(~resetn) begin
        count <= 32'h0;
    end else if (mtc0_we && cp0_addr == `CR_COUNT) begin
        count <= cp0_wdata;
    end else if (tick) begin
        count <= count + 1'b1;
    end
end


/* Compare */
assign compare_rdata = compare;

always @(posedge clk) begin
    if(~resetn) begin
        compare <= 32'h0;
    end else if (mtc0_we && cp0_addr == `CR_COMPARE) begin
        compare <= cp0_wdata;
    end
end


endmodule