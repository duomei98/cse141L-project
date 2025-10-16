// control decoder
// we use both funct and op; 15 instructions
// mcodebits is 4 bits to support <15 instructions
module Control #(parameter opwidth = 3, functwidth = 2, mcodebits = 4)(
  input [opwidth-1:0] 	 opcode,    
  input [functwidth-1:0] funct, 
  output logic RegDst, Branch, Jump,
     MemtoReg, MemWrite, ALUSrc, RegWrite, flag_en,
  output logic[mcodebits-1:0] ALUOp); // for 15 ALU operations

always_comb begin
// defaults
// We only use RegDst for move instructions. Default to rd
  RegDst 	=   'b0;    // 1: not in place  just leave 0
  Branch 	=   'b0;    // 1: conditional branch 
  Jump		= 	'b0;	// 1: unconditional jump
  MemWrite  =	'b0;    // 1: store to memory
  ALUSrc 	=	'b0;    // 1: immediate  0: second reg file output
  RegWrite  =	'b1;    // 0: for store or no op  1: most other operations 
  MemtoReg  =	'b0;    // 1: load -- route memory instead of ALU to reg_file data in 
  flag_en	=	'b0; 	// 1: update flag
  ALUOp	    =   'b1111; // nop? 

  // decode from opcode
  case(opcode)    
  // 000 or 001: r-type
  'b000:  begin	
    // signals same as default; only change ALUOp
    case(funct)
      // add
      'b00: begin
        ALUOp   = 'b0000;		// store carry out
        flag_en = 'b1;			
      // sub
      end 
      'b01: begin
        ALUOp   = 'b0001;		// store carry out
        flag_en = 'b1;			
      end 
      // not
      'b10: ALUOp = 'b0010;
      // cmp
      'b11: begin
        ALUOp   = 'b0011;
        flag_en = 'b1;
        RegWrite  =	'b0;		// we write to flag instead
      end 
    endcase 
  end 
  'b001:  begin
    case(funct)
      // movl: left operant is dest (write in place, same as default)
      'b00: ALUOp = 'b0100;
      // movr: right operant is dest
      'b01: begin
        RegDst 	  = 'b1;
        ALUOp     = 'b0101;
      end 
      // shift with shift_in
      /* this is technically not an r-type instruction 
      but we put it here because we're out of room;;;
      */
      'b10: begin
        ALUOp = 'b0110;
        flag_en = 'b1;
        // imm encodes whether to shift left or right
        ALUSrc = 'b1;		
      end 
      // add with carry in
      'b11: begin
        ALUOp 	= 'b0111;
        flag_en = 'b1;	
      end 
    endcase 
  end 
  // i-type: ALUSrc = 1; imm is second operand  
  // 010: ld from mem
  'b010:  begin
    ALUSrc    	  = 'b1;   
    MemtoReg 	  = 'b1;	// load data from memory to reg
  end 
  // 011: str to mem
  'b011: begin 
    ALUSrc 		  = 'b1;	
    MemWrite 	  = 'b1;	// write to memory
    RegWrite	  = 'b0;	// 0 for store
  end 
  // 100: addi
  'b100: begin
    ALUSrc 		  = 'b1;
    flag_en		  = 'b1; 		// store carry out
    ALUOp 		  = 'b1000;

  end
  // 101: shift by imm
  'b101: begin
    ALUSrc 		  = 'b1;		
    flag_en		  = 'b1; 		// store shift out
    ALUOp 		  = 'b1001;
  end 
    
  // j-type
  // 110: jump
  'b110: begin
    Jump 		  = 'b1;		// enable Jump
    RegWrite 	  = 'b0; 		// don't write to register
  end 
  // 111: beq 
  'b111:  begin	
    Branch 		  = 'b1;		// enable Branch
    RegWrite 	  = 'b0; 		// don't write to register
  end 
  default: begin
	ALUOp		  = 'b1111;		// no op: loads & stores, branches
  end
endcase

end
	
endmodule