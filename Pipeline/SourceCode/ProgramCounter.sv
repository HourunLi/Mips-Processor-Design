`ifndef PROGRAM_COUNTER_INCLUDED
`define PROGRAM_COUNTER_INCLUDED

`include "Definitions.sv"

module ProgramCounter(
    input logic reset, 
    input logic clock, 
    input logic jumpEnable, 
    input int_t jumpValue, 
    input logic stall, 
    output int_t pcValue
);

    int_t nextPC;
   
    always_comb begin
        if (jumpEnable)
            nextPC = jumpValue;
        else
            nextPC = pcValue + 4;
    end
    
    always_ff @(posedge clock) begin
        if(reset) begin
            pcValue <= `PC_INIT-4;
        end else begin
            if(!stall) begin
                pcValue <= nextPC;
            end else begin
                pcValue <= pcValue;
            end
        end
    end
endmodule
`endif