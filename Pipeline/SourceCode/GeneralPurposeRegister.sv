`ifndef GENERAL_PURPOSE_REGISTER_INCLUDED
`define GENERAL_PURPOSE_REGISTER_INCLUDED

`include "Definitions.sv"

typedef struct packed{
    reg_t readId1, readId2;   
}regs_t;

typedef struct packed {
    int_t data1, data2;
} register_data_t;

`define BUBBLE_READ_DATA  '{  \
    data1 : `ZERO32,           \
    data2 : `ZERO32            \
 }
 
module GeneralPruposeRegister(
    input logic clock,
    input logic reset,
    input int_t pcValue,
    input reg_t writeId,
    input int_t writeData,
    input logic writeEnable,
    input regs_t read_id,
    output register_data_t readData
);

    int_t GengisterFile[31:0];
    assign readData.data1 = GengisterFile[read_id.readId1];
    assign readData.data2 = GengisterFile[read_id.readId2];
    
    //write first and then read
    //if both happen at the same time and in the same storage architechture
    always_ff @ (negedge clock) begin
        // Initialization
        if (reset)
            for (integer i = 0; i < 32; i++)
                GengisterFile[i] <= 0;
        // Write
//        $display("writeEnable")
        if (writeEnable && writeId != 0) begin
            GengisterFile[writeId] <= writeData;
            $display("@%h: $%2d <= %h", pcValue, writeId, writeData);
        end else if(writeEnable && writeId == 0)
            $display("@%h: $%2d <= %h", pcValue, writeId, writeData);
    end
endmodule
`endif