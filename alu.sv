// combinational -- no clock
// sample -- change as desired
module alu(
  input[3:0] alu_cmd,     	// 16 ALU instructions
  
  // inA: rd (r4-r7), inB: rs (r0-r3)
  input[7:0] inA, 
  input[7:0] inB, 	 		// default inB value; unsigned
  input f_in,				// flag (shift or carry) in
    
  output logic[7:0] rslt,
  // flag written to R1
  output logic out
);
  
  wire signed [7:0] inB_signed = inB;  // signed version just for addi

  always_comb begin 
    rslt 	  = 'b0; 		// default result to 0
    out  	  = 'b0;    
    case(alu_cmd)
      // add: automatically makes carry-out
      'b0000: {out,rslt} = inA + inB;

      // sub: automatically makes carry-out
      'b0001: {out,rslt} = inA - inB;

      // bitwise not of 8-bit number
      'b0010: rslt = ~inB;	 // A = ~B

      // cmp: 1 if two values are equal, 0 if not
      'b0011: out = (inA == inB);

      // movl: move from r0–r3 to r4–r7
      'b0100: rslt = inB;
      
      // movr: move from r4–r7 to r0–r3
      'b0101: rslt = inA;
      
      // shc: logical shift left or right 1 with shift_in
      'b0110: begin
        // immed = XXXX 1110: shift right
        if (inB[3] == 1) begin
          out     = inA[0];		// LSB shifted out
          rslt    = {f_in, inA[7:1]};
        // immed = XXXX 0010: shift left
        end 
        else begin
          out 	  = inA[7];		// MSB shifted out
          rslt 	  = {inA[6:0],f_in};
        end 
      end 
      
      // add with carry_in
      'b0111: {out,rslt} = inA + inB + f_in;
      
      // addi: add immediate, automatically makes carry-out
      'b1000: {out,rslt} = inA + inB_signed;

      // sh: logical shift by imm; flags MSB / LBS of shift out
      'b1001: begin
        // imm is negative
        if (inB[7] == 'b1) begin
          out  = inA[7];
          // shift left by |imm|
          rslt = inA << (~inB_signed + 1);   
        end 
        // imm is positive
        else begin			
          out  = inA[0];
          // shift right by |imm|
          rslt 	  = inA >> inB;		
        end 
      end 
      // nop: for ld, str, jump, beq
      default: rslt = 8'b0;
    endcase
  end
   
endmodule