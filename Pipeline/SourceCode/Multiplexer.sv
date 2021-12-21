`ifndef MULTIPLEXER_INCLUDED
`define MULTIPLEXER_INCLUDED

`include "ControlUnit.sv" 
//`include "Execution.sv"

function int_t selectALUDMUOperand(
    ALU_DMU_source_t src,
    register_data_t regdata,
    instruction_t inst
);
    case(src)
        READ_DATA_1 :
            return regdata.data1;
        READ_DATA_2 :
            return regdata.data2;
        IMM_UNSIGNED :
            return {16'h0, inst.immediate};
        IMM_SIGNED :
            return {{16{inst.immediate[15]}}, inst.immediate};
        SHIFT_AMOUNT :
            return {27'h0, inst.shift_amount};
    endcase
endfunction

function int_t selectJumpInput(
    jump_dest_source_t jmpDest,
    register_data_t readData,
    instruction_t inst
);
    case (jmpDest)
        JUMP_REG_READ:
            return readData.data1;
        JUMP_ABSOLUTE_ADDR:
            return {6'b0, inst.absJmpVal};
        JUMP_RELATIVE_ADDR:
            return {{16{inst.immediate[15]}}, inst.immediate};   //signed extend
        default:
            return 'bx;
    endcase
endfunction

function int_t selectMemRes(
    control_signals_t signals,
    int_t ALUResult,
    int_t DMContent,
    int_t MDUResult,
    int_t pcValue
);
    case(signals.MemtoReg)
        ALU_RES   : return  ALUResult;
        DM_RES    : return  DMContent;
        DMU_RES   : return  MDUResult;
        PC_PLUS_8 : return  pcValue+8;
        default   : return  'bx;
    endcase
endfunction

function reg_t selectRegId(
    reg_id_t regId,
    instruction_t inst
);
    case(regId)
        REG_RA   : return 31;
        REG_RD   : return inst.Rd;
        REG_RT   : return inst.Rt;
        REG_RS   : return inst.Rs;
        REG_ZERO : return 0;
    endcase
endfunction
`endif