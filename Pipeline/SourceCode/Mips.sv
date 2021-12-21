`timescale 1ns / 1ps

`ifndef TOPLEVEL
`define TOPLEVEL

`include "InstructionFetch.sv"
`include "InstructionDecode.sv"
`include "Execution.sv"
`include "Memory.sv"
`include "WriteBack.sv"

//`include "Instruction.sv"
//`include "ControlUnit.sv" 
//`include "GeneralPurposeRegister.sv"
//`include "ProgramCounter.sv"
//`include "InstructionMemory.sv"
//`include "DataMemory.sv"
//`include "ArithmeticLogicUnit.sv"
//`include "Multiplexer.sv"
//`include "ForwardingUnit.sv"

module TopLevel(
    input logic clock,
    input logic reset
);
    //ProgramCounter
    int_t jumpValue;
    logic jumpEnable;
    
    //pipeline Intermediate result
    pipe_IF_ID_reg_t pipelineFetchRes;
    pipe_ID_EX_reg_t pipelineDecodeRes;
    pipe_EX_MEM_reg_t pipelineExeRes;
    pipe_MEM_WB_reg_t pipelineMemoryRes;
    
    forwarding_data_t resultFromID_EX;
    forwarding_data_t resultFromEX_MEM;
    forwarding_data_t resultFromMEM_WB;
    
    //read
    regs_t regReadId;
    register_data_t regReadData;
    
    //write
    reg_t regWriteId;
    int_t regWriteData;
    logic regWriteEnbale;
    
    logic stallFromDecode;
    logic stallFromEx;
    
    GeneralPruposeRegister GPR(
        .clock(clock),
        .reset(reset),
        .pcValue(pipelineMemoryRes.pcValue),
        .writeId(regWriteId),
        .writeData(regWriteData),
        .writeEnable(regWriteEnbale),
        
        .read_id(regReadId),
        //output
        .readData(regReadData)
    );
    
    InstuctionFetch Fetch(
        .clock(clock),
        .reset(reset),
        
        .stallFromDecode(stallFromDecode),
        .jumpValue(jumpValue),
        .jumpEnable(jumpEnable), 
        
        .pipelineFetchRes(pipelineFetchRes)
    );
  
    InstructionDecode Decode(
        .clock(clock),
        .reset(reset),
        .stallFromEx(stallFromEx),
        
        .readId(regReadId),
        .readData(regReadData),
    
        .resultFromEX_MEM(resultFromEX_MEM),
        .resultFromMEM_WB(resultFromMEM_WB),
        .resultFromID_EX(resultFromID_EX),
        .pipelineFetchRes(pipelineFetchRes),
        .pipelineDecodeRes(pipelineDecodeRes),
        
        .stallFromDecode(stallFromDecode),
        .jumpValue(jumpValue),
        .jumpEnable(jumpEnable)
    );
        
    Execution Execution(
        .clock(clock),
        .reset(reset),
        
        .pipelineDecodeRes(pipelineDecodeRes),
        .pipelineExeRes(pipelineExeRes),
        
        .resultFromMEM_WB(resultFromMEM_WB),
        .resultFromEX_MEM(resultFromEX_MEM),
        
        .stallFromEx(stallFromEx)
    );
           
    Memory Memory(
        .clock(clock),
        .reset(reset),

        .pipelineExeRes(pipelineExeRes),
        .pipelineMemoryRes(pipelineMemoryRes),
        
        .resultFromMEM_WB(resultFromMEM_WB)
    );
    
    WriteBack WriteBack(
        .clock(clock),
        .reset(reset),
        .pipelineMemoryRes(pipelineMemoryRes),
        .writeEnable(regWriteEnbale),
        .regDst(regWriteId),
        .writeValue(regWriteData)
    );
endmodule
`endif