`ifndef FORWARDING_UNIT_INCLUDED
`define FORWARDING_UNIT_INCLUDED

`include "ControlUnit.sv"
`include "Definitions.sv"

typedef struct packed{
    reg_t regDest;
    logic dataReady;
    int_t forwardingData;
}forwarding_data_t;

typedef forwarding_data_t forwarding_datas_t[3];

`define HOLLOW_FORWARDING '{   \
    regDest        : `REG_ZERO, \
    dataReady      : `ENABLE,   \
    forwardingData : `ZERO32    \
}

module ForwardingUnit(
    input logic clock,
    input logic reset,
    input forwarding_datas_t forwardingDatas,
    input reg_t regId,
    input int_t oldRegData,
    input jump_condition_t jmpCondition,
    output int_t newRegData,
    output logic stall
);
    
    logic currStall;
    always_comb begin
        currStall = 0;
        newRegData = oldRegData;
        if(regId != `REG_ZERO) begin
//            $display("condition : %d\n", jmpCondition);
            for(integer i = 0; i < 3; i++) begin
                //only jmp inst considers the ID result
                if(i == 0 && jmpCondition == FALSE) begin
//                    $display("i == 0 && jmpCondition == FALSE\n");
                    continue;
                end
                if(forwardingDatas[i].regDest == regId)begin
                    if(forwardingDatas[i].dataReady)
                        newRegData = forwardingDatas[i].forwardingData;
                    else begin
//                        $display("need stall, i : %d, reg : %d\n", i,  regId);
                        currStall = 1;
                    end
                    break;
                end
            end
        end
        stall = currStall;
    end

endmodule
`endif