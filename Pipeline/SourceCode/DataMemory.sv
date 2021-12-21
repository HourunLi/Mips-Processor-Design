`ifndef DATA_MEMORY_INCLUDED
`define DATA_MEMORY_INCLUDED

`include "Definitions.sv"
module DataMemory(
    input logic reset, 
    input logic clock,
    input int_t pcValue,
    
    input int_t address, 
    input read_type_t readType,

    input logic writeEnable, 
    input int_t writeValue, 
    input write_type_t writeType,
    
    output int_t readResult
);

    int_t dataMemory[`DM_WORDS-1:0];
    int_t addr;
    int_t originData;
    int_t writeData;
    byte_t extractByte;
    short_t extractHalfWord;
    assign addr = address[`INT_SIZE-1:2] & `DM_WORDS_MASK;
    assign originData = dataMemory[addr];
//    readResult <= 

//                endcase
    always_comb begin
        extractByte = 8'b0;
        extractHalfWord = 16'b0;
        casez(readType) 
            BYTE_SIGNED, BYTE_UNSIGNED:begin
                casez(address[1:0])
                    2'b00: extractByte = originData[`N_BYTE(0)];
                    2'b01: extractByte = originData[`N_BYTE(1)];
                    2'b10: extractByte = originData[`N_BYTE(2)];
                    2'b11: extractByte = originData[`N_BYTE(3)];
                endcase
                casez(readType)
                    BYTE_SIGNED   : readResult = {{24{extractByte[7]}}, extractByte};
                    BYTE_UNSIGNED : readResult = {24'b0, extractByte};
                endcase
            end
            HALF_WORD_SIGNED, HALF_WORD_UNSIGNED : begin
                casez(address[1])
                    1'b0: extractHalfWord = originData[`N_HALF_WORD(0)];
                    1'b1: extractHalfWord = originData[`N_HALF_WORD(1)];
                endcase
                casez(readType)
                    HALF_WORD_SIGNED:   readResult = {{16{extractHalfWord[15]}}, extractHalfWord};
                    HALF_WORD_UNSIGNED: readResult = {16'b0, extractHalfWord};
                endcase
            end
            ORIGIN_WORD: readResult = originData; 
        endcase
    end
    
    //write
    always_comb begin
      casez(writeType) 
            WRITE_NONE:  writeData = 0;
            WRITE_BYTE:
                casez(address[1:0])
                    2'b00:  writeData = {originData[`N_BYTE(3)], originData[`N_BYTE(2)], originData[`N_BYTE(1)], writeValue[`N_BYTE(0)]};
                    2'b01:  writeData = {originData[`N_BYTE(3)], originData[`N_BYTE(2)], writeValue[`N_BYTE(0)], originData[`N_BYTE(0)]};
                    2'b10:  writeData = {originData[`N_BYTE(3)], writeValue[`N_BYTE(0)], originData[`N_BYTE(1)], originData[`N_BYTE(0)]};
                    2'b11:  writeData = {writeValue[`N_BYTE(0)], originData[`N_BYTE(2)], originData[`N_BYTE(1)], originData[`N_BYTE(0)]};
                endcase
            WRITE_HALF_WORD:
                casez(address[1])
                    1'b0: writeData = {originData[`N_HALF_WORD(1)], writeValue[`N_HALF_WORD(0)]};
                    1'b1: writeData = {writeValue[`N_HALF_WORD(0)], originData[`N_HALF_WORD(0)]};
                endcase
            WRITE_WORD: writeData = writeValue;
        endcase
    end
 
    //write
    always_ff @(posedge clock) begin
        if(reset) begin
            for(integer i = 0; i < `DM_WORDS; i = i+1)
                dataMemory[i] <= 32'h00000000;  
        end
        if(writeEnable) begin
            dataMemory[addr] <= writeData;
            $display("@%h: *%h <= %h", pcValue, address&`MEMORY_MASK, writeData);
        end
    end
endmodule
`endif