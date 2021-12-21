`timescale 1ns / 1ps
module GeneralRegister(readAdd1, readAdd2, writeAdd, read1, read2, write, writeEnable, clock);
    input [4:0] readAdd1, readAdd2, writeAdd;
    input [31:0] write;
    input writeEnable, clock;
    output reg [31:0] read1, read2;
    reg [31:0] GPR[31:0];
    
    integer i;
    initial begin
        GPR[0] <= 32'h00000000;GPR[1] <= 32'h00000000;   GPR[2] <= 32'h00000000;GPR[3] <= 32'h00000000;
        GPR[4] <= 32'h00000000;GPR[5] <= 32'h00000000;   GPR[6] <= 32'h00000000;GPR[7] <= 32'h00000000;
        GPR[8] <= 32'h00000000;GPR[9] <= 32'h00000000;   GPR[10] <= 32'h00000000;GPR[11] <= 32'h00000000;
        GPR[12] <= 32'h00000000;GPR[13] <= 32'h00000000; GPR[14] <= 32'h00000000;GPR[15] <= 32'h00000000;
        GPR[16] <= 32'h00000000;GPR[17] <= 32'h00000000; GPR[18] <= 32'h00000000;GPR[19] <= 32'h00000000;
        GPR[20] <= 32'h00000000;GPR[21] <= 32'h00000000; GPR[22] <= 32'h00000000;GPR[23] <= 32'h00000000;
        GPR[24] <= 32'h00000000;GPR[25] <= 32'h00000000; GPR[26] <= 32'h00000000;GPR[27] <= 32'h00000000;
        GPR[28] <= 32'h00000000;GPR[29] <= 32'h00000000; GPR[30] <= 32'h00000000;GPR[31] <= 32'h00000000;
    end
    
    always @(posedge clock) begin
        #1.5;
        read1 <= GPR[readAdd1];
        read2 <= GPR[readAdd2];
    end
    
    always@(posedge clock) begin
        #3;
        if(writeEnable) 
            GPR[writeAdd] <= write;
    end
endmodule
