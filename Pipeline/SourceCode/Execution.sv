`ifndef EXECUTION_INCLUDED
`define EXECUTION_INCLUDED

//`include "Definitions.sv"
`include "InstructionDecode.sv"
`include "Multiplexer.sv"
`include "ArithmeticLogicUnit.sv"
//`include "ForwardingUnit.sv"
//`include "GeneralPurposeRegister.sv"

typedef struct packed{
    int_t pcValue;
    control_signals_t signals;
    instruction_t inst;
    regs_t readId;
    reg_t writeId;
    int_t ALUResult;
    int_t MDUResult;
    logic over;               
    register_data_t readData;
    logic dataReady;            //the data is ready for forwarding
    logic bubble;
}pipe_EX_MEM_reg_t;

`define reset_EX_MEM_reg '{        \
    pcValue    :  `ZERO32,          \
    signals    :  `BUBBLE_SIGNALS,  \
    inst       :  `BUBBLE_INST,     \
    readId     :  `reset_regs_t,    \
    writeId    :  `REG_ZERO,        \
    ALUResult  :  `ZERO32,          \
    MDUResult  :  `ZERO32,          \
    over       :  `DIS_ABLE,        \
    readData   :  `BUBBLE_READ_DATA,\
    bubble     :  `ENABLE,          \
    dataReady  :  `ENABLE           \
}

module Execution(
    input logic clock,
    input logic reset,

    input pipe_ID_EX_reg_t pipelineDecodeRes,
    output pipe_EX_MEM_reg_t pipelineExeRes,
    
    // forwarding data
    input forwarding_data_t resultFromMEM_WB,
    output forwarding_data_t resultFromEX_MEM,
    
    output logic stallFromEx
);

    int_t operand1;
    int_t operand2;
    // the newset reg data, updated by forwarding unit
    register_data_t regData;
    
    logic stall;
    logic hazard[2];
    forwarding_datas_t forwardingDatas;
    
    assign forwardingDatas = '{
        `HOLLOW_FORWARDING,  //hollow forwarding data from ID stage
        resultFromEX_MEM,    //forwarding data from EXE stage
        resultFromMEM_WB     //forwarding data from MEM stage
    };

    ForwardingUnit FU0(
        .clock(clock),
        .reset(reset),
        .forwardingDatas(forwardingDatas),
        .regId(pipelineDecodeRes.readId.readId1),
        .oldRegData(pipelineDecodeRes.readData.data1),
        .jmpCondition(pipelineDecodeRes.signals.jmpCondition),
        .newRegData(regData.data1),
        .stall(hazard[0])
    );
    
    ForwardingUnit FU1(
        .clock(clock),
        .reset(reset),
        .forwardingDatas(forwardingDatas),
        .regId(pipelineDecodeRes.readId.readId2),
        .oldRegData(pipelineDecodeRes.readData.data2),
        .jmpCondition(pipelineDecodeRes.signals.jmpCondition),
        .newRegData(regData.data2),
        .stall(hazard[1])
    );
    
    assign operand1 = selectALUDMUOperand(
        pipelineDecodeRes.signals.ALUDMUOperand1,
        regData,
        pipelineDecodeRes.inst
    );
        
    assign operand2 = selectALUDMUOperand(
        pipelineDecodeRes.signals.ALUDMUOperand2,
        regData,
        pipelineDecodeRes.inst
    );
    
    int_t ALUResult;
    int_t MDUResult;
    logic over;
    logic mduBusy;
    ArithmeticLogicUnit ALU( 
        .operand1(operand1),
        .operand2(operand2),
        .opCode(pipelineDecodeRes.signals.ALUOPCode),
        .result(ALUResult),
        .Over(over)
    );
    
    MultiplicationDivisionUnit MDU(
        .reset(reset),
        .clock(clock),

        .operand1(operand1),
        .operand2(operand2),
        .operation(pipelineDecodeRes.signals.DMUOPCode),
 
        .start(pipelineDecodeRes.signals.mduStart && !stall),
        
        .busy(mduBusy),
        .dataRead(MDUResult)
    );
    logic readSign;
    assign readSign =  pipelineDecodeRes.signals.DMUOPCode == MDU_READ_HI || pipelineDecodeRes.signals.DMUOPCode == MDU_READ_LO;
    assign stall = hazard[0] || hazard[1] || (mduBusy&&(pipelineDecodeRes.signals.mduStart||readSign));
    assign stallFromEx = stall;
    
    always_comb begin
        if(pipelineExeRes.signals.RegWrite) begin
            resultFromEX_MEM.regDest        = pipelineExeRes.writeId;
            resultFromEX_MEM.dataReady      = pipelineExeRes.dataReady;
            if(pipelineExeRes.signals.MemtoReg == DM_RES)
                resultFromEX_MEM.forwardingData = 'bx;
            else if(pipelineExeRes.signals.MemtoReg == ALU_RES)
                resultFromEX_MEM.forwardingData = pipelineExeRes.ALUResult;
            else if(pipelineExeRes.signals.MemtoReg == DMU_RES)
                // !whether need to tackle the situation where data is not ready???????
                resultFromEX_MEM.forwardingData = pipelineExeRes.MDUResult;
            else
                resultFromEX_MEM.forwardingData = pipelineExeRes.pcValue + 8;
        end else begin
            resultFromEX_MEM.regDest        = `REG_ZERO;
            resultFromEX_MEM.dataReady      = `ENABLE;
            resultFromEX_MEM.forwardingData = `ZERO32;
        end
    end
    
    
    always_ff @(posedge clock) begin
        if(reset) begin
            pipelineExeRes <= `reset_EX_MEM_reg;
        end else if(stall) begin
            pipelineExeRes <= `reset_EX_MEM_reg;
        end else if(pipelineDecodeRes.bubble) begin
            //passBublle;
            pipelineExeRes.bubble        <=  pipelineDecodeRes.bubble;
            pipelineExeRes.pcValue       <=  pipelineDecodeRes.pcValue;
            pipelineExeRes.signals       <=  pipelineDecodeRes.signals;
            pipelineExeRes.inst          <=  pipelineDecodeRes.inst;
            pipelineExeRes.readId        <=  pipelineDecodeRes.readId ;
            pipelineExeRes.writeId       <=  pipelineDecodeRes.writeId;
            pipelineExeRes.ALUResult     <=  `ZERO32;
            pipelineExeRes.MDUResult     <=  `ZERO32;
            pipelineExeRes.over          <=  `DIS_ABLE;
            pipelineExeRes.readData      <=  regData;
        end else begin
            pipelineExeRes.pcValue       <=  pipelineDecodeRes.pcValue;
            pipelineExeRes.signals       <=  pipelineDecodeRes.signals;
            pipelineExeRes.inst          <=  pipelineDecodeRes.inst;
            pipelineExeRes.readId        <=  pipelineDecodeRes.readId ;
            pipelineExeRes.writeId       <=  pipelineDecodeRes.writeId;
            pipelineExeRes.ALUResult     <=  ALUResult;
            pipelineExeRes.MDUResult     <=  MDUResult;
            pipelineExeRes.over          <=  over;
            pipelineExeRes.readData      <=  regData;
            pipelineExeRes.bubble        <=  `DIS_ABLE;
            if(pipelineDecodeRes.signals.MemtoReg == DM_RES)
                pipelineExeRes.dataReady <=  `DIS_ABLE;
            else // DMU_RES, ALU_RES
                pipelineExeRes.dataReady <=  `ENABLE;
            
        end
    end
endmodule
`endif