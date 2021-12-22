`ifndef INSTRUCTION_MEMORY 
`define INSTRUCTION_MEMORY

`include "Definitions.sv"
`include "Instruction.sv"

`define INST_OP_HIGH 31
`define INST_OP_LOW  26

`define INST_RS_HIGH 25
`define INST_RS_LOW  21

`define INST_RT_HIGH 20
`define INST_RT_LOW  16

`define INST_RD_HIGH 15
`define INST_RD_LOW  11

`define INST_SHIFT_HIGH 10
`define INST_SHIFT_LOW 6

`define INST_FUNC_HIGH 5
`define INST_FUNC_LOW  0

`define INST_IMM_HIGH 15
`define INST_IMM_LOW  0
//for j only
`define INST_ADDR_HIGH 25
`define INST_ADDR_LOW  0

typedef logic[`REGBIT-1:0] reg_t;
typedef logic[`INST_IMM_HIGH:0] imm_t;
typedef logic[`INST_ADDR_HIGH:0] addr_t;
typedef logic [`SHIFT_BIT-1:0]  shift_t;

typedef struct packed{
    int_t binaryCode;
    instruction_code_t inst_code;
    reg_t Rs, Rt, Rd;
    shift_t shift_amount;
    imm_t immediate;
    addr_t absJmpVal;
}instruction_t;

`define BUBBLE_INST '{         \
    binaryCode   :   32'bz,     \
    inst_code    :   NOP,       \
    Rs           :  `REG_ZERO,  \
    Rt           :  `REG_ZERO,  \
    Rd           :  `REG_ZERO,  \
    shift_amount :  `SHIFT_ZERO,\
    immediate    :  `ZERO16,    \
    absJmpVal    :  `ZERO26     \
}


module InstructionMemory(
    input int_t pcValue, 
    output instruction_t instruction
);
    int_t memory[`IM_WORDS-1:0];
    initial begin
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\0dE.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\0eC.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\0eL.asm.txt", memory);
        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\0hJ.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\0vM.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\02H.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\08H.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\22H.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\28H.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\82H.asm.txt", memory);
//        $readmemh("E:\\VivadoProject\\Mips\\TestCode\\HexadecimalCode\\88H.asm.txt", memory);
        
        
    end
    
    int_t addr, binaryOpCode;
    assign addr = pcValue[`INT_SIZE-1:2] & `IM_WORDS_MASK;
    assign binaryOpCode = memory[addr];
    
    assign instruction.binaryCode   = binaryOpCode;
    assign instruction.inst_code    = instruction_code_t'(binaryOpCode);
    assign instruction.Rs           = binaryOpCode[`INST_RS_HIGH:`INST_RS_LOW];
    assign instruction.Rt           = binaryOpCode[`INST_RT_HIGH:`INST_RT_LOW];
    assign instruction.Rd           = binaryOpCode[`INST_RD_HIGH:`INST_RD_LOW];
    assign instruction.shift_amount = binaryOpCode[`INST_SHIFT_HIGH:`INST_SHIFT_LOW];
    assign instruction.immediate    = binaryOpCode[`INST_IMM_HIGH:`INST_IMM_LOW];
    assign instruction.absJmpVal    = binaryOpCode[`INST_ADDR_HIGH:`INST_ADDR_LOW]; 
endmodule
`endif