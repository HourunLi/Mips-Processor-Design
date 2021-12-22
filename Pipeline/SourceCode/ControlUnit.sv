`ifndef CONTROL_UNIT_INCLUDED
`define CONTROL_UNIT_INCLUDED

`include "Definitions.sv"
`include "ArithmeticLogicUnit.sv"
//`include "Instruction.sv"
`include "InstructionMemory.sv"
`include "MultiplicationDivisionUnit.sv"

typedef enum logic [2:0] {
    ALU_RES,
    DMU_RES,
    DM_RES,
    PC_PLUS_8 //PC+8
}memery_to_reg_t;

typedef enum logic [2:0] {
    READ_DATA_1,
    READ_DATA_2,
    IMM_UNSIGNED,
    IMM_SIGNED,
    SHIFT_AMOUNT
} ALU_DMU_source_t;

typedef enum logic [2:0] {
    FALSE,
    TRUE,
    BRANCH_IF_EQUAL,
    BRANCH_IF_NOT_EQUAL,
    BRANCH_IF_LESS_EQUAL_TO_ZERO,
    BRANCH_IF_GREATE_EQUAL_TO_ZERO,
    BRANCH_IF_GREATE_THAN_ZERO,
    BRANCH_IF_LESS_THAN_ZERO
}jump_condition_t;

//regs_t is the encapsulation of reg_t
//reg_t is the specific index number of register.
//while reg_id_t is the general type of register.(rs or rd or rt)
typedef enum logic [2:0] {
    REG_RA,  //GR[31],for return addr jal
    REG_RD,
    REG_RT,
    REG_RS,
    REG_ZERO
} reg_id_t;

typedef enum logic [1:0] {
    JUMP_REG_READ,
    JUMP_ABSOLUTE_ADDR,  //absolute addr is 26 bits unsigned 
    JUMP_RELATIVE_ADDR   //relative addr is 16 bits signed 
} jump_dest_source_t;

typedef enum logic[2:0] {
    NONE_EXTEND,
    BYTE_SIGNED,
    BYTE_UNSIGNED,
    HALF_WORD_SIGNED,
    HALF_WORD_UNSIGNED,
    ORIGIN_WORD
}read_type_t;

typedef enum logic[1:0] {
    WRITE_NONE,
    WRITE_BYTE,
    WRITE_HALF_WORD,
    WRITE_WORD
}write_type_t;

typedef struct packed{
    logic                RegWrite;   //result whether needs to be written into register
    read_type_t          readType;   // read type such as byeteSigned, Half_word_signed, for lw, lb...
    logic                MemWrite;   // result whether needs to be written into data memory
    write_type_t         writeType;  // read type such as byeteS, Half_word, for sb, sw...
    alu_operation_t      ALUOPCode;  //alu operation code
    mdu_operation_t      DMUOPCode;  //dmu operation code
    logic                mduStart;   //dmu start working sign
    memery_to_reg_t      MemtoReg;   // the data type to be written into register
    reg_id_t             RegDst;     // register destionation
    reg_id_t             Read1ID;    
    reg_id_t             Read2ID;    
    ALU_DMU_source_t     ALUDMUOperand1;
    ALU_DMU_source_t     ALUDMUOperand2;
    jump_condition_t     jmpCondition; //jump condition, such as beq, bne and so on
    jump_dest_source_t   jmpDest;      //the source of jump addr, such as from register or absolute addr...
}control_signals_t;

`define BUBBLE_SIGNALS  '{                 \
    RegWrite        : `DIS_ABLE,            \
    readType        :  NONE_EXTEND,         \
    MemWrite        : `DIS_ABLE,            \
    writeType       :  WRITE_NONE,          \
    ALUOPCode       :  ALU_ADD,             \
    DMUOPCode       :  MDU_START_SIGNED_MUL,\
    mduStart        : `DIS_ABLE,            \
    MemtoReg        :  ALU_RES,             \
    RegDst          :  REG_ZERO,            \
    Read1ID         :  REG_ZERO,            \
    Read2ID         :  REG_ZERO,            \
    ALUDMUOperand1  :  READ_DATA_1,         \
    ALUDMUOperand2  :  READ_DATA_2,         \
    jmpCondition    :  FALSE,               \
    jmpDest         :  JUMP_ABSOLUTE_ADDR   \
}


module ControlUnit(
    input instruction_t instruction,
    output control_signals_t Signals
);
    
    always_comb begin
        //default
        Signals.RegWrite       = `DIS_ABLE;
        Signals.readType       = NONE_EXTEND;
        Signals.MemWrite       = `DIS_ABLE;
        Signals.writeType      = WRITE_NONE;
        Signals.ALUOPCode      = ALU_ADD;
        Signals.DMUOPCode      = MDU_START_SIGNED_MUL;
        Signals.mduStart       = `DIS_ABLE;
        Signals.MemtoReg       = ALU_RES;
        Signals.RegDst         = REG_RT;
        Signals.Read1ID        = REG_RS;
        Signals.Read2ID        = REG_RT;
        Signals.ALUDMUOperand1 = READ_DATA_1;
        Signals.ALUDMUOperand2 = READ_DATA_2;
        Signals.jmpCondition   = FALSE;
        Signals.jmpDest        = JUMP_REG_READ;
        casez(instruction.inst_code)
            NOP, SYSCALL:begin
//                $display("%h, NOP, SYSCALL\n", instruction.binaryCode);
                Signals.RegDst = REG_ZERO;
                Signals.Read1ID = REG_ZERO;
                Signals.Read2ID = REG_ZERO;
            end
           //absolute addr jump
            JAL,J: begin
                //for memry_to_reg
                Signals.jmpCondition = TRUE;
                Signals.jmpDest = JUMP_ABSOLUTE_ADDR;
                Signals.RegDst = REG_ZERO;
                Signals.Read1ID = REG_ZERO;
                Signals.Read2ID = REG_ZERO;
                if (instruction.inst_code inside {JAL}) begin
                    Signals.RegDst = REG_RA;
                    Signals.RegWrite = `ENABLE;
//                    $display("%h, JAL\n", instruction.binaryCode);
                    Signals.MemtoReg = PC_PLUS_8;
                end
            end
            JR, JALR: begin
                Signals.jmpCondition = TRUE;
                Signals.jmpDest = JUMP_REG_READ;
                Signals.RegDst = REG_ZERO;
//              default:  Signals.Read1ID      = REG_RS;
                Signals.Read2ID = REG_ZERO;
                if(instruction.inst_code inside {JALR}) begin
                    Signals.RegDst = REG_RD;
                    Signals.RegWrite = `ENABLE;
//                    $display("%h, JALR\n", instruction.binaryCode);
                    Signals.MemtoReg = PC_PLUS_8;
                end
            end
            //R instruction
            ADD, ADDU, SUB, SUBU,
            SLL, SRL, SRA, SLLV,
            SRLV, SRAV, AND, OR, 
            XOR, NOR, SLT, SLTU: begin
                Signals.RegDst = REG_RD;
                Signals.RegWrite = `ENABLE;
//                $display("%h, R instruction\n", instruction.binaryCode);
                Signals.MemtoReg = ALU_RES;
                casez(instruction.inst_code)
                    SLL : Signals.Read1ID = REG_ZERO;
                    SRL : Signals.Read1ID = REG_ZERO;
                    SRA : Signals.Read1ID = REG_ZERO;
                    default: Signals.Read1ID = REG_RS;
                endcase
                Signals.Read2ID = REG_RT;
                casez(instruction.inst_code)
                    SLL : Signals.ALUDMUOperand1 = SHIFT_AMOUNT;
                    SRL : Signals.ALUDMUOperand1 = SHIFT_AMOUNT;
                    SRA : Signals.ALUDMUOperand1 = SHIFT_AMOUNT;
                    default: Signals.ALUDMUOperand1 = READ_DATA_1;
                endcase
                casez(instruction.inst_code)
                    ADD : Signals.ALUOPCode = ALU_ADD;
                    ADDU: Signals.ALUOPCode = ALU_ADDU;
                    SUB : Signals.ALUOPCode = ALU_SUB;
                    SUBU: Signals.ALUOPCode = ALU_SUBU;
                    SLL : Signals.ALUOPCode = ALU_SHIFT_L;
                    SRL : Signals.ALUOPCode = ALU_SHIFT_R_LOGIC;
                    SRA : Signals.ALUOPCode = ALU_SHIFT_R_ARITHMETIC;
                    SLLV: Signals.ALUOPCode = ALU_SHIFT_L;
                    SRLV: Signals.ALUOPCode = ALU_SHIFT_R_LOGIC;
                    SRAV: Signals.ALUOPCode = ALU_SHIFT_R_ARITHMETIC;
                    AND : Signals.ALUOPCode = ALU_AND;
                    OR  : Signals.ALUOPCode = ALU_OR;
                    XOR : Signals.ALUOPCode = ALU_XOR;
                    NOR : Signals.ALUOPCode = ALU_NOR;
                    SLT : Signals.ALUOPCode = ALU_LESS_THAN_SIGNED;
                    SLTU: Signals.ALUOPCode = ALU_LESS_THAN_UNSIGNED;
                endcase
            end 
            //memory access instruction
            LB, LBU, LH, LHU, LW, SB, SH, SW: begin
                Signals.ALUDMUOperand2 = IMM_SIGNED;
                casez(instruction.inst_code)
                    LB, LBU, LH, LHU, LW:begin
                        Signals.RegWrite = `ENABLE;
//                        $display("%h, LB, LBU, LH, LHU, LW\n",instruction.binaryCode);
                        Signals.MemtoReg = DM_RES;
//                        Signals.Read2ID = REG_ZERO;
                        casez(instruction.inst_code) 
                            LB:  Signals.readType = BYTE_SIGNED;
                            LBU: Signals.readType = BYTE_UNSIGNED;
                            LH:  Signals.readType = HALF_WORD_SIGNED;
                            LHU: Signals.readType = HALF_WORD_UNSIGNED;
                            LW:  Signals.readType = ORIGIN_WORD;
                        endcase
                    end
                    SB, SH, SW:begin
                        Signals.MemWrite = `ENABLE;
                        Signals.RegDst = REG_ZERO;
                        casez(instruction.inst_code)
                            SB: Signals.writeType = WRITE_BYTE;
                            SH: Signals.writeType = WRITE_HALF_WORD;
                            SW: Signals.writeType = WRITE_WORD;
                        endcase
                    end
                endcase
            end
            ADDI, ADDIU, ANDI, ORI, 
            XORI, SLTI, SLTIU :begin
                Signals.RegWrite = `ENABLE;
//                $display("%h, ADDI, ADDIU, ANDI, ORI, XORI, SLTI, SLTIU\n", instruction.binaryCode);
                Signals.RegDst = REG_RT;
                Signals.MemtoReg = ALU_RES;
                //default : Signals.Read2ID = REG_RS;
                Signals.Read2ID = REG_ZERO;
                // default Signals.ALUDMUOperand1
                casez (instruction.inst_code)
                    ADDI:  Signals.ALUDMUOperand2 = IMM_SIGNED;
                    ADDIU: Signals.ALUDMUOperand2 = IMM_SIGNED;
                    ANDI:  Signals.ALUDMUOperand2 = IMM_UNSIGNED;
                    ORI:   Signals.ALUDMUOperand2 = IMM_UNSIGNED;
                    XORI:  Signals.ALUDMUOperand2 = IMM_UNSIGNED;
                    SLTI:  Signals.ALUDMUOperand2 = IMM_SIGNED;
                    SLTIU: Signals.ALUDMUOperand2 = IMM_SIGNED;
                endcase
                casez(instruction.inst_code)
                    ADDI :  Signals.ALUOPCode = ALU_ADD;
                    ADDIU:  Signals.ALUOPCode = ALU_ADDU;
                    ANDI :  Signals.ALUOPCode = ALU_AND; 
                    ORI  :  Signals.ALUOPCode = ALU_OR;
                    XORI :  Signals.ALUOPCode = ALU_XOR;
                    SLTI :  Signals.ALUOPCode = ALU_LESS_THAN_SIGNED;
                    SLTIU:  Signals.ALUOPCode = ALU_LESS_THAN_UNSIGNED;
                endcase                    
            end
            //���д��޸�
            LUI : begin
                Signals.RegWrite = `ENABLE;
//                $display("%h, LUI\n", instruction.binaryCode);
                Signals.RegDst = REG_RT;
                Signals.MemtoReg = ALU_RES;
                Signals.Read1ID = REG_ZERO;
                Signals.Read2ID = REG_ZERO;
                Signals.ALUDMUOperand2 = IMM_UNSIGNED;
                Signals.ALUOPCode = ALU_LUI;
            end
            //conditional jump
            BEQ, BNE, BLEZ, 
            BGTZ, BGEZ, BLTZ : begin
                casez(instruction.inst_code) 
                    BEQ  : Signals.Read2ID = REG_RT;
                    BNE  : Signals.Read2ID = REG_RT;
                    default : Signals.Read2ID = REG_ZERO;
                endcase
                casez(instruction.inst_code) 
                    BEQ  : Signals.jmpCondition = BRANCH_IF_EQUAL;
                    BNE  : Signals.jmpCondition = BRANCH_IF_NOT_EQUAL;
                    BLEZ : Signals.jmpCondition = BRANCH_IF_LESS_EQUAL_TO_ZERO;
                    BGEZ : Signals.jmpCondition = BRANCH_IF_GREATE_EQUAL_TO_ZERO;
                    BLTZ : Signals.jmpCondition = BRANCH_IF_LESS_THAN_ZERO;
                    BGTZ : Signals.jmpCondition = BRANCH_IF_GREATE_THAN_ZERO;
                endcase
                Signals.jmpDest = JUMP_RELATIVE_ADDR;
                Signals.RegDst = REG_ZERO;
            end
            MULT, MULTU, DIV, DIVU :begin
                //Signals.RegWrite = `DIS_ABLE;
                Signals.RegDst = REG_ZERO;
                Signals.mduStart = `ENABLE;
                casez(instruction.inst_code) 
                    MULT:  Signals.DMUOPCode = MDU_START_SIGNED_MUL;
                    MULTU: Signals.DMUOPCode = MDU_START_UNSIGNED_MUL;
                    DIV:   Signals.DMUOPCode = MDU_START_SIGNED_DIV;
                    DIVU:  Signals.DMUOPCode = MDU_START_UNSIGNED_DIV;
                endcase
            end
            MFHI, MFLO : begin
                Signals.RegWrite = `ENABLE;
//                $display("%h, MFHI, MFLO\n",instruction.binaryCode);
                Signals.MemtoReg = DMU_RES;
                Signals.RegDst = REG_RD;
                casez(instruction.inst_code) 
                    MFHI:  Signals.DMUOPCode = MDU_READ_HI;
                    MFLO:  Signals.DMUOPCode = MDU_READ_LO;
                endcase
            end
            MTHI, MTLO : begin
                Signals.jmpCondition   = FALSE;
                Signals.Read2ID = REG_ZERO;
                casez(instruction.inst_code) 
                    MTHI:  Signals.DMUOPCode = MDU_WRITE_HI;
                    MTLO:  Signals.DMUOPCode = MDU_WRITE_LO;
                endcase
            end
        endcase
    end
endmodule
`endif