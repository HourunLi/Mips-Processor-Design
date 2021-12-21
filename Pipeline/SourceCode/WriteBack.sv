`ifndef WRITE_BACK_INCLUDED
`define WRITE_BACK_INCLUDED

`include "Memory.sv"
//`include "Definitions.sv"
module WriteBack(
    input logic reset,
    input logic clock,
    input pipe_MEM_WB_reg_t pipelineMemoryRes,
    output logic writeEnable,
    output reg_t regDst,
    output int_t writeValue
);
    
    always_comb begin
        writeValue  = pipelineMemoryRes.Result;
        writeEnable = pipelineMemoryRes.signals.RegWrite;
        regDst      = pipelineMemoryRes.writeId;
    end
    
    always_comb begin
        if (pipelineMemoryRes.inst.inst_code inside {SYSCALL})
            $finish;
    end
endmodule
`endif