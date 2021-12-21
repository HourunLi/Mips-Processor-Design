`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/22 20:09:49
// Design Name: 
// Module Name: ProgramCounter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ProgramCounter(reset, clock, jumpEnable, jumpInput, offset, pcValue);
    input reset;
    input clock;
    input jumpEnable;
    input [31:0] jumpInput;
    input [31:0] offset;
    output reg [31:0] pcValue;
    wire [31:0] nextPC;
    wire over;
    
    adder add(.A(pcValue), .B(4), .flag(1'b0), .sum(nextPC), .over(over));
    always@(posedge clock) begin
        if(reset) begin
            pcValue <= 32'h00003000;
        end else begin
            #5;
            if(jumpEnable) pcValue <= jumpInput;
            else pcValue <= nextPC+offset;
        end
    end
endmodule
