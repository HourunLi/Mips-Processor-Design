`timescale 1ns / 1ps
module InstructionMemory(clock, address, readResult);
    input clock; 
    input [31:0] address;
    output reg [31:0] readResult;
    reg [31:0] read;
    reg [31:0] memory[1023:0];
    initial begin
        $readmemh("E:\\vivado_project\\SingleCycle\\code.txt", memory);
    end
    wire [31:0] addr;
    assign addr = address[31:2] & 10'b1111111111;
    always @(posedge clock) begin
//        readResult.opCode <= memory[address[31:2]][31:26];
//        readResult.Rs <= memory[address[31:2]][25:21];
//        readResult.Rt <= memory[address[31:2]][20:16];
//        readResult.Rd <= memory[address[31:2]][15:11];
//        readResult.funcCode <= memory[address[31:2]][5:0];
//        readResult.immediate16 <= memory[address[31:2]][15:0];
//        readResult.immediate26 <= memory[address[31:2]][25:0];
        readResult <= memory[addr];
    end
endmodule
