`timescale 1ns / 1ps

module ControllerUnit(opCode, funcCode, RegDst, ALUSrc, MemtoReg, Branch, opALU, RegWrite, MemRead, MemWrite, jumpEnable);
    input [5:0] opCode, funcCode;
    output reg RegWrite, MemRead, MemWrite, jumpEnable;
    output reg [1:0] RegDst, ALUSrc, MemtoReg, Branch;
    output reg [2:0] opALU;
    
    always @(opCode or funcCode) begin
        if(opCode == 6'b000000 && funcCode == 6'b001100)
            $finish;
        else if(opCode == 6'b000011) //jal
            RegDst <=2'b10;
        else if(opCode == 6'b000000) //R
            RegDst <=2'b01;
        else  //ÆäËû
            RegDst <= 2'b00;
        
        if(opCode == 6'b000000 || opCode == 6'b000100) //R or Beq
            ALUSrc <= 2'b00;
        else if(opCode == 6'b001111 || opCode == 6'b001101) //lui or ori
            ALUSrc <= 2'b01;    
        else
            ALUSrc <= 2'b10; 
        
        if(opCode == 6'b000011)  //jal
            MemtoReg <= 2'b10;   
        else if(opCode == 6'b100011) //LW
            MemtoReg <= 2'b01;
        else
            MemtoReg <= 2'b00;
            
        if(opCode == 6'b000000 && funcCode == 6'b001000)begin  //jr
            Branch <= 2'b10;
            jumpEnable <=1;
        end else if(opCode[5:1] == 5'b00001) begin   //jal or j 
            Branch <= 2'b11;
            jumpEnable <=1;
        end else if(opCode == 6'b000100) begin  //beq
            Branch <= 2'b01;
            jumpEnable <=0;
        end else begin
            Branch <= 2'b00;
            jumpEnable <=0;
        end
            
        if(opCode == 6'b101011 || opCode == 6'b000100 || opCode == 6'b000010 || (opCode == 6'b000000 && funcCode == 6'b001000)) //sw or beq or j or jr
            RegWrite <= 0;
        else
            RegWrite <= 1;
            
        if(opCode == 6'b100011) //lw
            MemRead <=1;
        else
            MemRead <= 0;
            
        if(opCode == 6'b101011) //sw
            MemWrite <=1;
        else
            MemWrite <= 0;
            
        if(opCode == 6'b001101)  
            opALU <= 3'b101;   //ori
        else if(opCode == 6'b001111) //lui
            opALU <= 3'b100;
        else if(opCode == 6'b000100) //beq
            opALU <= 3'b010;
        else if(opCode == 6'b000000) begin
            if(funcCode == 6'b100001)  //addu
                opALU <= 3'b001;
            else if(funcCode == 6'b100011)  //subu
                opALU <= 3'b011;
            else if(funcCode == 6'b100010) //sub
                opALU <= 3'b010;
            else    
                opALU <= 3'b000;
        end else
            opALU <= 3'b000;  
    end
endmodule
