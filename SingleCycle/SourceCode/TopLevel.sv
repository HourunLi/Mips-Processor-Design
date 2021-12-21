`timescale 1ns / 1ps
//typedef struct {
//    logic [5:0] opCode, funcCode;
//    logic [4:0] Rs, Rt, Rd;
//    logic [15:0] immediate16;
//    logic [25:0] immediate26;
//} ins;
module TopLevel(reset, clock);
    input reset;
    input clock;
    wire [31:0] pc, instruction;
    wire [31:0] Rdata1, Rdata2;
    wire [5:0] opCode, funcCode;
    wire [4:0] Rs, Rt, Rd;
    wire [31:0] immediate16, extImmediate16, shiftImm16;
    wire [31:0] immediate26, extImmediate26, shiftImm26;
    wire [31:0] ALURes, DMRes;
    wire RegWrite, MemRead, MemWrite, jumpEnable;
    wire [1:0] RegDst, ALUSrc, MemtoReg, Branch;
    wire [2:0] opALU;
    
    reg[4:0] wreg;
    reg[31:0] wdata, ALUB;
    reg[31:0] offset, jumpInput;
    
    assign opCode = instruction[31:26];
    assign Rs = instruction[25:21];
    assign Rt = instruction[20:16];
    assign Rd = instruction[15:11];
    assign funcCode = instruction[5:0];
    assign immediate16 = instruction[15:0];
    assign immediate26 = instruction[25:0];
    
    ALU ALU(.A(Rdata1),.B(ALUB),.Op(opALU),.C(ALURes),.Over()); //no latency  ready after #2
    ProgramCounter PC(.reset(reset), .clock(clock), .jumpEnable(jumpEnable), .jumpInput(jumpInput), .offset(offset), .pcValue(pc)); //change at first sight
    InstructionMemory INST(.clock(clock), .address(pc), .readResult(instruction));  //#0;
    ControllerUnit CU(.opCode(opCode), .funcCode(funcCode), .RegDst(RegDst), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg), .Branch(Branch),
     .opALU(opALU), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .jumpEnable(jumpEnable)); // #1
    GeneralRegister GR(.readAdd1(Rs), .readAdd2(Rt), .writeAdd(wreg), .read1(Rdata1), .read2(Rdata2), .write(wdata), .writeEnable(RegWrite), .clock(clock));  //#2 for read, #3 for write
    DataMemory DM(.reset(reset), .address(ALURes), .readEnable(MemRead), .writeEnable(MemWrite), .writeInput(Rdata2), .readResult(DMRes), .clock(clock)); //read after #2.5, write after #2.5
    SignExtend16 SE16(.immediate(immediate16), .out(extImmediate16));
    SignExtend26 SE26(.immediate(immediate26), .out(extImmediate26));
    Shift shift16(.in(extImmediate16), .out(shiftImm16));
    Shift shift26(.in(extImmediate26), .out(shiftImm26));
    
    always @(posedge clock) begin
        #0.3;
        if(RegDst == 2'b10)
            wreg <= 5'b11111;  //针对jal
        else if(RegDst == 2'b01) //R
                wreg <= Rd;
        else if(!RegDst)
                wreg <= Rt;
    end
    
    always @(posedge clock) begin
        #1.7;
        if(ALUSrc == 2'b00)
            ALUB <= Rdata2;
        else if(ALUSrc == 2'b01)
            ALUB <= immediate16;
        else if(ALUSrc == 2'b10)
            ALUB <= extImmediate16;
    end
    
    always @(posedge clock) begin  
        #2.7;
        if(MemtoReg == 2'b10)
//            wdata <= ProgramCounter.nextPC + 4;  //这里可能有问题
            wdata <= pc + 4;  //这里可能有问题
        else if(MemtoReg == 2'b01) 
            wdata <= DMRes;
        else if(!MemtoReg)
            wdata <= ALURes;
   end
   
   always @(posedge clock) begin 
        #3.5;
//        $display("Branch:%d  ALUres:%d  shiftImm16$h", Branch, ALURes, shiftImm16);
        if(Branch == 2'b11) begin
            offset <= 0;
            jumpInput <= shiftImm26;
        end else if(Branch == 2'b10) begin
            offset <= 0;
            jumpInput <= Rdata1;
        end else if(Branch == 2'b01) begin
            jumpInput <= 0;
            if(ALURes == 0) 
                offset <= shiftImm16;
            else
                offset <= 0;
//            $display("rs:%h    rt:%h  ALURes:%h ", rs, rt, ALURes);
        end else begin
            jumpInput <= 0;
            offset <= 0;
        end
    end
endmodule
