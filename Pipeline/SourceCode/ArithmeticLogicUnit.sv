`ifndef ARITHMETIC_LOGIC_UNIT_INCLUDED
`define ARITHMETIC_LOGIC_UNIT_INCLUDED

`include "Definitions.sv"
`include "Adder.sv"
typedef enum logic[3:0] {
    ALU_ADD,
    ALU_ADDU,
    
    ALU_SUB,
    ALU_SUBU,
    
    ALU_SHIFT_R_ARITHMETIC,
    ALU_SHIFT_R_LOGIC,
    ALU_SHIFT_L,
    
    ALU_LESS_THAN_UNSIGNED,
    ALU_LESS_THAN_SIGNED,
    
    ALU_LUI,
    ALU_OR,
    ALU_AND,
    ALU_XOR,
    ALU_NOR
}alu_operation_t;

`define ADD_FLAG 1'b0
`define SUB_FLAG 1'b1

module ArithmeticLogicUnit(
    input int_t operand1,
    input int_t operand2,
    input alu_operation_t opCode,
    output int_t result,
    output logic Over
);
   
	int_t addRes, subRes;
	logic addOverFlag, subOverFlag;
    adder add(
        .A(operand1),
        .B(operand2),
        .flag(`ADD_FLAG),
        .sum(addRes),
        .over(addOverFlag));
        
     adder sub(
        .A(operand1),
        .B(~operand2),
        .flag(`SUB_FLAG),
        .sum(subRes),
        .over(subOverFlag));    
    logic[4:0] shiftAmount; 
    assign shiftAmount = operand1[4:0];
    always@(*)
		begin //use begin to guarantee serial excution
//		$display("rdata1:%h  rdata2:%h  opALU:%d", A, B, Op);
            case(opCode)
                ALU_ADD: begin
                    result <= addRes;
                    Over <= addOverFlag;
				end ALU_ADDU: begin   	
                    result <= addRes;
                    Over <= 0;
				end ALU_SUB: begin
                    result <= subRes;
                    Over <= subOverFlag;        
                end ALU_SUBU: begin 
                    result <= subRes;
                    Over <= 0;                         		
                end ALU_LUI: begin  
                    result <= {operand2[`HALF_INT_SIZE-1:0], `ZERO16};
                    Over <= 0; 
                end ALU_OR: begin   
                    result <= operand1|operand2;
                    Over <= 0; 
                end ALU_AND: begin
                    result <= operand1 & operand2;
                    Over <= 0;
                end ALU_XOR: begin
                    result <= operand1 ^ operand2;
                    Over <= 0;
                end ALU_NOR: begin
                    result <= ~(operand1 | operand2);
                    Over <= 0;
                end ALU_SHIFT_R_ARITHMETIC: begin
                    result <= $signed(operand2) >>> shiftAmount;
                    Over <= 0;
                end ALU_SHIFT_R_LOGIC: begin
                    result <= operand2 >> shiftAmount;
                    Over <= 0;
                end ALU_SHIFT_L : begin
                    result <= operand2 << shiftAmount;
                    Over <= 0;
                end ALU_LESS_THAN_UNSIGNED: begin
                    result <= {31'b0, operand1 < operand2};
                    Over <= 0;
                end ALU_LESS_THAN_SIGNED: begin
                    result = {31'b0, $signed(operand1) < $signed(operand2)};
                    Over <= 0;
                end default: begin
                    result <= 0;
                    Over <= 0;
                end
            endcase
        end
endmodule
`endif