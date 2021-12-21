`timescale 1ns / 1ps
module DataMemory(reset, address, readEnable, writeEnable, writeInput, readResult, clock);
    input reset, writeEnable, readEnable, clock;
    input [31:0] writeInput;
    input [31:0] address;
    output reg[31:0] readResult;
    reg [31:0] data[1023:0];
    wire [31:0] addr;
    assign addr = address[31:2] & 10'b1111111111;
    integer i;
    always @(reset) begin
        for(i = 0; i < 1024; i = i+1)
            data[i] <= 32'h00000000;  
    end
    
    always @(posedge clock) begin
        #2.5;
        if(writeEnable)begin 
            data[addr] <= writeInput;
        end
    end
    
    always @(posedge clock) begin   
        #2.5;
        if(readEnable) begin
            readResult <= data[addr];
        end else
            readResult <= 0;
    end
    
endmodule
