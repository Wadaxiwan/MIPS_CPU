
`define RAM_SIGN   2'b01
`define RAM_UNSIGN 2'b10

module memory(
    input  [1:0]            ex_ram_addr,
    input  [3:0]             ex_ram_wen,
    input  [1:0]            ex_ram_sign,
    input  [31:0]           id_ram_addr,
    input  [3:0]             id_ram_wen,
    input                     id_ram_we,
    input                     memory_ex,
    input                     id_cp0_ex,
    output [3:0]          data_sram_wen,
    output [31:0]        data_sram_addr,
    input  [31:0]                ram_in,
    output [31:0]               ram_out,
    input  [31:0]              s_ram_in,
    output [31:0]             s_ram_out,
    output [4:0]      memory_cp0_excode,    
    output                memory_cp0_ex,        
    output [31:0]   memory_cp0_badvaddr  
);

wire [31:0]  format_ram_in;

wire [5:0] ex_ram_addr_bias = ex_ram_addr << 3;

// read from ram (load)
assign format_ram_in = ram_in >> ex_ram_addr_bias ;

assign ram_out = ({32{ex_ram_wen == 4'b1111}} & format_ram_in) |
                 ({32{ex_ram_wen == 4'b0001 & ex_ram_sign == `RAM_SIGN}} & {{24{format_ram_in[7]}},format_ram_in[7:0]}) |
                 ({32{ex_ram_wen == 4'b0001 & ex_ram_sign == `RAM_UNSIGN}} & {{24{1'b0}}, format_ram_in[7:0]}) |
                 ({32{ex_ram_wen == 4'b0011 & ex_ram_sign == `RAM_SIGN}} & {{16{format_ram_in[15]}}, format_ram_in[15:0]}) |
                 ({32{ex_ram_wen == 4'b0011 & ex_ram_sign == `RAM_UNSIGN}} & {{16{1'b0}}, format_ram_in[15:0]}) ;


// write into ram (store)
assign data_sram_wen = ({4{!(memory_cp0_ex | memory_ex) && id_ram_we}}) & (id_ram_wen << id_ram_addr[1:0]);  // prevent cp0 exception

assign data_sram_addr  = memory_cp0_ex ? 32'h0 : ((id_ram_addr[31:28] >= 4'h8 && id_ram_addr[31:28] < 4'hC) ? {3'b0, id_ram_addr[28:0]}: id_ram_addr);

assign s_ram_out = ({32{id_ram_wen == 4'b1111}} & s_ram_in) |
                   ({32{id_ram_wen == 4'b0001}} & {4{s_ram_in[7:0]}}) |
                   ({32{id_ram_wen == 4'b0011}} & {2{s_ram_in[15:0]}}) ;

assign memory_cp0_ex = (id_ram_wen == 4'b0011 && id_ram_addr[0] != 1'b0) |
                       (id_ram_wen == 4'b1111 && id_ram_addr[1:0] != 2'b00) |
                       id_cp0_ex;

assign memory_cp0_excode = id_ram_we ? `EX_ADES : `EX_ADEL;

assign memory_cp0_badvaddr = (memory_cp0_ex | memory_ex) ? id_ram_addr : 32'h0;

endmodule


/* Deprecated */  
// assign format_ram_in = ({32{ex_ram_addr == 2'b00}} & ram_in) |
//                        ({32{ex_ram_addr == 2'b01}} & {{8{1'b0}}, ram_in[31:8]}) |
//                        ({32{ex_ram_addr == 2'b10}} & {{16{1'b0}}, ram_in[31:16]}) |
//                        ({32{ex_ram_addr == 2'b11}} & {{24{1'b0}}, ram_in[31:24]}) ; 


// assign data_sram_wen = ({4{id_ram_we}}) & 
//                        (({4{id_ram_addr == 2'b00}} & id_ram_wen) |
//                        ({4{id_ram_addr == 2'b01}} & {{id_ram_wen[2:0], {1{1'b0}}}}) |
//                        ({4{id_ram_addr == 2'b10}} & {{id_ram_wen[1:0], {2{1'b0}}}}) |
//                        ({4{id_ram_addr == 2'b11}} & {{id_ram_wen[0], {3{1'b0}}}})) ;

// assign s_ram_out = ({32{id_ram_wen == 4'b1111}} & s_ram_in) |
//                    ({32{id_ram_wen == 4'b0001}} & 
//                     (({{32{id_ram_addr == 2'b00}}, s_ram_in[7:0]}) |
//                      ({{32{id_ram_addr == 2'b01}}, s_ram_in[7:0], {8{1'b0}}}) |
//                      ({{32{id_ram_addr == 2'b10}}, s_ram_in[7:0], {16{1'b0}}}) |
//                      ({{32{id_ram_addr == 2'b11}}, s_ram_in[7:0], {24{1'b0}}}))
//                    ) |
//                    ({32{id_ram_wen == 4'b0011}} & 
//                     (({{32{id_ram_addr == 2'b00}}, s_ram_in[15:0]}) |
//                      ({{32{id_ram_addr == 2'b10}}, s_ram_in[15:0], {16{1'b0}}}))
//                    ); 
