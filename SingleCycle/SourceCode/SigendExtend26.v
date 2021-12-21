`timescale 1ns / 1ps
 
module SignExtend26(immediate, out);
    input [31:0] immediate;
    output [31:0] out;
	 
	assign out[25:0] = immediate[25:0];
	assign out[31:26] = immediate[25]? 6'b111111 : 6'b000000;
endmodule