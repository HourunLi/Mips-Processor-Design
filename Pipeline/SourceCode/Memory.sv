`ifndef MEMORY_INCLUDED
`define MEMORY_INCLUDED

`include "Execution.sv"
//`include "Multiplexer.sv"
`include "DataMemory.sv"
//`include "Definitions.sv"
typedef struct packed{
    int_t pcValue;
    control_signals_t signals;
    instruction_t inst;
    regs_t readId;
    reg_t writeId;
    int_t Result;
    logic dataReady;
    logic bubble;
}pipe_MEM_WB_reg_t;

`define reset_MEM_WB_reg '{         \
    pcValue    :  `ZERO32,          \
    signals    :  `BUBBLE_SIGNALS,  \
    inst       :  `BUBBLE_INST,     \
    readId     :  `reset_regs_t,    \
    writeId    :  `REG_ZERO,        \
    Result     :  `ZERO32,          \
    dataReady  :  `ENABLE,          \
    bubble     :  `ENABLE           \
}

module Memory(
    input logic clock,
    input logic reset,
    
    input pipe_EX_MEM_reg_t pipelineExeRes,
    output pipe_MEM_WB_reg_t pipelineMemoryRes,
    
    output forwarding_data_t resultFromMEM_WB
);
    
    int_t DMContent;
    
    DataMemory DM(
        .reset(reset), 
        .clock(clock),
        .address(pipelineExeRes.ALUResult), 
        .pcValue(pipelineExeRes.pcValue),
        .writeEnable(pipelineExeRes.signals.MemWrite), 
        .writeValue(pipelineExeRes.readData.data2), 
        .readResult(DMContent),
        .readType(pipelineExeRes.signals.readType),
        .writeType(pipelineExeRes.signals.writeType)
    );
    
    always_comb begin
        if(pipelineMemoryRes.signals.RegWrite) begin
            resultFromMEM_WB.regDest        = pipelineMemoryRes.writeId;
            resultFromMEM_WB.dataReady      = pipelineMemoryRes.dataReady;
            resultFromMEM_WB.forwardingData = pipelineMemoryRes.Result;
        end else begin
            resultFromMEM_WB.regDest        = `REG_ZERO;
            resultFromMEM_WB.dataReady      = `ENABLE;
            resultFromMEM_WB.forwardingData = `ZERO32;
        end
    end
    
    always_ff @(posedge clock) begin
        if(reset) begin
            pipelineMemoryRes                  <= `reset_MEM_WB_reg;
        end else begin 
            pipelineMemoryRes.pcValue          <= pipelineExeRes.pcValue;
            pipelineMemoryRes.signals          <= pipelineExeRes.signals;
            pipelineMemoryRes.inst             <= pipelineExeRes.inst;
            pipelineMemoryRes.readId           <= pipelineExeRes.readId ;
            pipelineMemoryRes.writeId          <= pipelineExeRes.writeId;
            pipelineMemoryRes.dataReady        <= `ENABLE;
            pipelineMemoryRes.bubble           <= pipelineExeRes.bubble;
            if(pipelineExeRes.bubble) begin
                pipelineMemoryRes.Result       <= `ZERO32;
            end else begin
                pipelineMemoryRes.Result       <= selectMemRes(pipelineExeRes.signals, pipelineExeRes.ALUResult, DMContent, pipelineExeRes.MDUResult, pipelineExeRes.pcValue);
            end
        end
    end
   
endmodule
`endif