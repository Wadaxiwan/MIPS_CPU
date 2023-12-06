`define EXT_Z     3'b001
`define EXT_S     3'b010
`define EXT_B     3'b011
`define EXT_J     3'b100
`define EXT_L     3'b101
`define EXT_I     3'b110

module sext(
    input  [2:0]        op,
    input  [25:0]      din,
    output [31:0]      ext
);

assign ext = ( {32{op == `EXT_L}} & {din[15:0], {16{1'b0}}} )|
             ( {32{op == `EXT_S}} & {{16{din[15]}}, din[15:0]} ) |
             ( {32{op == `EXT_Z}} & {{16{1'b0}}, din[15:0]} ) |
             ( {32{op == `EXT_I}} & {{27{1'b0}}, din[10:6]} ) |
             ( {32{op == `EXT_B}} & {{14{din[15]}}, din[15:0], {2{1'b0}}} ) |
             ( {32{op == `EXT_J}} & {{4{1'b0}}, din[25:0], {2{1'b0}}} );


endmodule