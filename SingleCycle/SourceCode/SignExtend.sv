`timescale 1ns / 1ps
 
module SignExtend16(immediate, out);
    input [15:0] immediate;
    output [31:0] out;
	 
	assign out[15:0] = immediate;
	assign out[31:16] = immediate[15]? 16'hffff : 16'h0000;
endmodule