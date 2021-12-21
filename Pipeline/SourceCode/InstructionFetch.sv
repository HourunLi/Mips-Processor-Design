`ifndef INSTRUCTION_FETCH_INCLUDED
`define INSTRUCTION_FETCH_INCLUDED

`include "InstructionMemory.sv"
//`include "Definitions.sv"
`include "ProgramCounter.sv"
//`include "Multiplexer.sv"

typedef struct packed{
    int_t pcValue;
    instruction_t inst;
}pipe_IF_ID_reg_t;

`define reset_IF_ID_reg '{  \
    pcValue : `ZERO32,       \
    inst :    `BUBBLE_INST   \
}

module InstuctionFetch(
    input logic clock,
    input logic reset,
   
    input logic stallFromDecode, //the stall generated in ID stage that stalls the IF works 
    
    input int_t jumpValue,
    input logic jumpEnable, 
    
    output pipe_IF_ID_reg_t pipelineFetchRes
);

    //`stall represents whether the current stage needs to stall
    //It's subject to stll from decode stage
    logic stall;
    assign stall = stallFromDecode;
    
    instruction_t instruction;
    int_t pcValue;
    
    ProgramCounter PC(
        .reset(reset), 
        .clock(clock), 
        .stall(stall), 
        .jumpEnable(jumpEnable), 
        .jumpValue(jumpValue), 
        .pcValue(pcValue)
    );
        
    InstructionMemory IM(
        .pcValue(pcValue), 
        .instruction(instruction)
    );
        
    always_ff @(posedge clock) begin
        if(reset) begin
            pipelineFetchRes <= `reset_IF_ID_reg;
        end else begin
            if(!stall) begin
                pipelineFetchRes.inst <= instruction;
                pipelineFetchRes.pcValue <= pcValue;
            end else begin
                //if stall, the content of pipeline register result keeps stagnant
                pipelineFetchRes.inst <= pipelineFetchRes.inst;
                pipelineFetchRes.pcValue <= pipelineFetchRes.pcValue;          
            end
        end
    end
    
endmodule
`endif