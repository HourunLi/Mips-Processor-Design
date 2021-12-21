`timescale 1ns / 1ps
module DataMemory(reset, clock, address, writeEnable, writeInput, readResult);
    input reset, clock, writeEnable;
    input [31:0] writeInput;
    input [31:0] address;
    output reg[31:0] readResult;
    reg [31:0] data[1023:0];
    
    integer i;
    always @(posedge clock) begin
        if(reset)
            for(i = 0; i < 1024; i = i+1)
                data[i] <= 32'h00000000;
        else begin
            if(writeEnable)
                data[address[31:2]] <= writeInput;
            else
                readResult <= data[address[31:2]];
        end
    end
endmodule
