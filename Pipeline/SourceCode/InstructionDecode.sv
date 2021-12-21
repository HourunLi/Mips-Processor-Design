`ifndef INSTRUCTION_DECODE_INCLUDED
`define INSTRUCTION_DECODE_INCLUDED

`include "InstructionFetch.sv"
//`include "ControlUnit.sv"
//`include "InstructionMemory.sv"
`include "GeneralPurposeRegister.sv"
`include "ForwardingUnit.sv"
//`include "Definitions.sv"

`define reset_regs_t '{  \
    readId1 : `REG_ZERO,  \
    readId2 : `REG_ZERO   \
}

//regs_t is the encapsulation of reg_t
//reg_t is the specific index number of register.
//while reg_id_t is the general type of register.(rs or rd or rt)
typedef struct packed{ 
    int_t pcValue; 
    control_signals_t signals; 
    instruction_t inst; 
    regs_t readId;
    reg_t writeId;
    register_data_t readData;  // the data read from register file 
    logic dataReady;
    logic bubble; 
}pipe_ID_EX_reg_t; 

`define reset_ID_EX_reg '{       \
    pcValue   : `ZERO32,          \
    signals   : `BUBBLE_SIGNALS,  \
    inst      : `BUBBLE_INST,     \
    readId    : `reset_regs_t,    \
    writeId   : `REG_ZERO,        \
    readData  : `BUBBLE_READ_DATA,\
    dataReady : `ENABLE,          \
    bubble    : `ENABLE           \
}

module InstructionDecode(
    input logic clock,
    input logic reset,
    input logic stallFromEx,  //the stall generated in EX stage stalls both ID and IF stages
    
    //register
    output regs_t readId, //the regid for GPR to read
    input register_data_t readData,   //the data read from GPR
    
    //stage result and forwarding result
    input forwarding_data_t resultFromEX_MEM,
    input forwarding_data_t resultFromMEM_WB,
    output forwarding_data_t resultFromID_EX,
    input pipe_IF_ID_reg_t pipelineFetchRes,
    output pipe_ID_EX_reg_t pipelineDecodeRes,
    
    output logic stallFromDecode, //the stall generated in ID stage that stalls the IF works 
    output int_t jumpValue,
    output logic jumpEnable
);
    
    //control signals
    control_signals_t  signals;
    
    ControlUnit CU(
        .instruction(pipelineFetchRes.inst),
        .Signals(signals)
    );
    
    //ouput the readID for GPR in MIPS
    reg_t writeId;
    assign readId.readId1 = selectRegId(signals.Read1ID, pipelineFetchRes.inst);
    assign readId.readId2 = selectRegId(signals.Read2ID, pipelineFetchRes.inst);
    assign writeId        = selectRegId(signals.RegDst,  pipelineFetchRes.inst);
    //stall
    logic stall;
    logic hazard[2];
    // the newset reg data, updated by forwarding unit
    register_data_t    regData;
    // the data to be forwarded
    forwarding_datas_t forwarding_datas;
    
    assign forwarding_datas = '{
        resultFromID_EX,
        resultFromEX_MEM,
        resultFromMEM_WB
    };
    
    ForwardingUnit FU0(
        .clock(clock),
        .reset(reset),
        
        .forwardingDatas(forwarding_datas),
        .regId(readId.readId1),          //the destination register of forwarding data
        .oldRegData(readData.data1), //the data read from GPR
        .jmpCondition(signals.jmpCondition),
        .newRegData(regData.data1),  //updated by forwarded data
        .stall(hazard[0])            //output 
    );
    
    ForwardingUnit FU1(
        .clock(clock),
        .reset(reset),
       
        .forwardingDatas(forwarding_datas),
        .regId(readId.readId2),          //the destination register of forwarding data
        .oldRegData(readData.data2), //the data read from GPR
        .jmpCondition(signals.jmpCondition),
        .newRegData(regData.data2),  //updated by forwarded data
        .stall(hazard[1])            //output 
    );
    
    //hazard is the potential stall generated in ID stage caused by conditional jump
    assign stall = hazard[0] || hazard[1] || stallFromEx;  // the stall generated in decode stage
    assign stallFromDecode = stall;
   
    int_t jumpInput;
    always_comb begin
        jumpEnable = 0;
        if(!stall) begin
            casez(signals.jmpCondition)
                FALSE                           : jumpEnable = 0;
                TRUE                            : jumpEnable = 1;
                BRANCH_IF_EQUAL                 : jumpEnable = (regData.data1 == regData.data2);
                BRANCH_IF_NOT_EQUAL             : jumpEnable = (regData.data1 != regData.data2);
                BRANCH_IF_LESS_EQUAL_TO_ZERO    : jumpEnable = ($signed(regData.data1) <= 0);
                BRANCH_IF_GREATE_EQUAL_TO_ZERO  : jumpEnable = ($signed(regData.data1) >= 0);
                BRANCH_IF_GREATE_THAN_ZERO      : jumpEnable = ($signed(regData.data1) > 0);
                BRANCH_IF_LESS_THAN_ZERO        : jumpEnable = ($signed(regData.data1) < 0);
            endcase
        end
        jumpInput = selectJumpInput(
            signals.jmpDest,
            regData,
            pipelineFetchRes.inst
        );
        jumpValue = 0;
        case(signals.jmpDest)
            JUMP_REG_READ      : jumpValue = jumpInput;
            JUMP_ABSOLUTE_ADDR : jumpValue = {4'b0, jumpInput[25:0], 2'b0};
            JUMP_RELATIVE_ADDR : jumpValue = pipelineFetchRes.pcValue + 4 + {jumpInput[29:0], 2'b0};
        endcase
    end
    
    always_comb begin
        if(pipelineDecodeRes.signals.RegWrite) begin
            resultFromID_EX.regDest        = pipelineDecodeRes.writeId;
            resultFromID_EX.dataReady      = pipelineDecodeRes.dataReady;
            resultFromID_EX.forwardingData = 'bx;
        end else begin
            resultFromID_EX.regDest        = `REG_ZERO;
            resultFromID_EX.dataReady      = `ENABLE;
            resultFromID_EX.forwardingData = `ZERO32;   
        end
    end
    
    always_ff @(posedge clock) begin
        if(reset) begin
            pipelineDecodeRes           <= `reset_ID_EX_reg;
        end else if(!stall) begin
            pipelineDecodeRes.pcValue   <= pipelineFetchRes.pcValue;
            pipelineDecodeRes.signals   <= signals;
            pipelineDecodeRes.inst      <= pipelineFetchRes.inst;
            pipelineDecodeRes.readId    <= readId;
            pipelineDecodeRes.writeId   <= writeId;
            pipelineDecodeRes.readData  <= regData;
            pipelineDecodeRes.dataReady <=`DIS_ABLE;
            pipelineDecodeRes.bubble    <=`DIS_ABLE;
        end else if(stallFromEx) begin     //stall because of ex stage rather than itself satge
            pipelineDecodeRes.pcValue  <= pipelineDecodeRes.pcValue;
            pipelineDecodeRes.signals  <= pipelineDecodeRes.signals;
            pipelineDecodeRes.inst     <= pipelineDecodeRes.inst;
            pipelineDecodeRes.readId   <= pipelineDecodeRes.readId ;
            pipelineDecodeRes.writeId  <= pipelineDecodeRes.writeId;
            pipelineDecodeRes.readData <= pipelineDecodeRes.readData;   
            pipelineDecodeRes.dataReady <= pipelineDecodeRes.dataReady;   
            pipelineDecodeRes.bubble   <=`DIS_ABLE;        
        end else begin //bubble       stall because of the hazards in itself stage
            pipelineDecodeRes          <= `reset_ID_EX_reg;
        end
    end
endmodule
`endif