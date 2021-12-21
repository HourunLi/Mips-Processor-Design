`timescale 1ns / 1ns
module ALU(A,B,Op,C,Over);
	input signed [31:0] A;
	input signed [31:0] B;
	input [2:0] Op;
    output reg [31:0] C;
    output reg Over;
    
    wire [1:0]Over_;
	wire [31:0] B_;
	wire [31:0] C1, C2;
    adder add(
        .A(A),
        .B(B),
        .flag(1'b0),
        .sum(C1),
        .over(Over_[0]));
        
     adder sub(
        .A(A),
        .B(~B),
        .flag(1'b1),
        .sum(C2),
        .over(Over_[1]));    
               
    always@(*)
        
		begin //use begin to guarantee serial excution
//		$display("rdata1:%h  rdata2:%h  opALU:%d", A, B, Op);
            case(Op)
                3'b000: begin//add
                    C <= C1;
                    Over <= Over_[0];
				end 3'b001: begin  // addu 	
                    C <= C1;
                    Over <= 0;
				end 3'b010: begin//sub
                    C <= C2;
                    Over <= Over_[1];        
                end 3'b011: begin //subu
                    C <= C2;
                    Over <= 0;                         		
                end 3'b100: begin  //lui
                    C <= {B[15:0], 16'h0000};
                    Over <= 0; 
                end 3'b101: begin    //ori
                    C <= A|B[15:0];
                    Over <= 0; 
                end default: begin
                    C <= 0;
                    Over <= 0;
                end
            endcase
        end
endmodule