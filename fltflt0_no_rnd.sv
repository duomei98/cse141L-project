// behavioral model for float addition
// CSE141L Spr 2025    NO ROUND   NO SUB
// dummy DUT for float+float
module Top_level0(
  input        clk, reset,
               start,
  output logic done);
  logic       nil1,		    	      // zero detect addend 1
              nil2,		    	      // zero detect addend 2
			  nil3,                   // zero detect sum
              guard,	    	      // needed for subtraction
              round,
              sticky;
  logic[10:0] mant1,                   // mantissa of addend 1
              mant2;				   //  (w/ room for hidden bit)
  logic[11:0] mant3;	      	       // mantissa of sum, incl. overflow
  logic[ 5:0] exp1,			           // exponent of addend 1
              exp2,
              exp3;					   // exponent of sum
  logic       sign1,		           // sign of addend 1
              sign2,
              sign3;	               // sign of sum (or difference)

 logic              CLK;               // wires for all DataMem ports
 logic     [8-1:0]  DataAddress;	   // in your model you would connect these	
 logic              ReadMem;		   //  to other blocks/modules	
 logic              WriteMem;	   		
 logic       [7:0]  DataIn;			
 logic       [7:0]  DataOut;
 int          pgm;			

  data_mem data_mem1(.*);

  always @(posedge clk) begin	 :main
    if(reset) pgm++;
    else if(start) begin
		guard  = 1'b0;
		round  = 1'b0;
		sticky = 1'b0;
		sign1  = data_mem1.mem_core[ 9][7];			 // load operands from data_mem
		sign2  = data_mem1.mem_core[11][7];
		exp1   = data_mem1.mem_core[ 9][6:2];
		exp2   = data_mem1.mem_core[11][6:2];
		nil1   = !data_mem1.mem_core[ 9][6:2];	     // zero exp trap
		nil2   = !data_mem1.mem_core[11][6:2];		 // zero exp trap
		mant1 <= { 1'b1,                         // hidden-1 always, unless exp==0
			data_mem1.mem_core[9][1:0],   // mantissa[9:8]
			data_mem1.mem_core[8][7:0]
		};                              // 1 + 2 + 8 = 11 bits
		mant2 <= { 1'b1,
			data_mem1.mem_core[11][1:0],
			data_mem1.mem_core[10][7:0]
		};
		done   = 1'b0;
    end

	else if (!done) begin	  :nonreset
		$display("diff = %d",exp1-exp2);
		//$display("mant2 = %b", mant2);	
	  exp3  = exp1;                     // covers equal exponent case; override if exp2>exp1   
	  if(sign1==sign2) begin  :netadd   // perform addition
        sign3 = sign1;				    // won't need guard, but would for subtraction
	    //mant1 = {!nil1,mant1[9:0]};	    // prepend hidden bit
		//mant2 = {!nil2,mant2[9:0]}; //subnormal check do we need?
		if(exp1>exp2) begin
		  exp3 = exp1;				    // larger exponent always wins
		  for(int j=0; j<(exp1-exp2); j++) begin
//		    sticky = sticky|round;	    // move everything down 1 position
//			round  = mant2[0];

			mant2  = mant2>>1;
		  end
		end
		else if(exp2>exp1) begin             
          exp3 = exp2;
          for(int j=0; j<(exp2-exp1); j++) begin // right-shift mant1 by exp2-exp1
//		    sticky = sticky|round;
//			round  = mant1[0];
		    mant1  = mant1>>1;
		  end
		end
       	mant3 = mant1 + mant2;
       // $display("mant3 = %b = mant1 + mant2 = %b + %b",mant3,mant1,mant2);
		if(mant3[11]) begin	           // overflow case
//		  $display("overflow engaged");
          exp3++;					   // incr. exp & right-shift mant.
//		  sticky = sticky|round;
//		  round  = mant3[0];
		  mant3  = mant3>>1;
		end
//		if(mant3[0]||sticky)           // rounding
//		  mant3 = mant3 + round;

		nil3=!exp3;
	  end   :netadd

// you may ignore net subtraction, if you wish, and assume that
//  the two operand sign bits are equal
/*	  else begin  :netsub			   // perform subtraction
        if(exp1>exp2) begin
		  sign3 = sign1;
		  for(int j=0; j<(exp1-exp2); j++) begin
		    sticky = sticky|round;
			round  = guard;
			guard  = mant1[0];
		    mant1  = mant1>>1;
		  end
// subtract mants w/o adding 1 LSB (yet) -- conditional rounding
		  mant3 = mant1 + (~mant2) + !({guard,round,sticky});   // address GRS next
		  if(!mant3[10]) begin	          // need to left-shift to norm.
		    mant3 = {mant3,guard};
			guard = round;
			round = sticky;
		  end
		  if(mant3[0] || sticky || round)
		    mant3 = mant3 + guard;
		end
		else if(exp2>exp1) begin
		  sign3 = sign2;
		  for(int j=0; j<(exp1-exp2); j++) begin
		    sticky = sticky|round;
			round  = guard;
			guard  = mant1[0];
		    mant1  = mant1>>1;
		  end
		  mant3 = mant2 + (~mant1) + !({guard,round,sticky});	 // renorm shrunk mantissa
		  if(!mant3[10]) begin
		    mant3 = {mant3,guard};
			guard = round;
			round = sticky;
		  end
		  if(mant3[0] || sticky|| round)
		    mant3 = mant3 + guard;
		end
		else begin                         // equal exp. case
          exp3 = exp1;                     // provisionally
          if(mant1>mant2) begin
		    mant3 = mant1 + (~mant2) + 1;  // no RS (why?)
			for(int k = 0; k < 9; k++)     // perform normalization
			  if(!mant3[10]) begin
			    mant3 = mant3 << 1'b1;
				exp3--;
			  end
		  end
		  else if(mant2>mant1) begin
		    mant3 = mant2 + (~mant1) + 1;
			for(int k = 0; k < 9; k++)     // perform normalization
			  if(!mant3[10]) begin
			    mant3 = mant3 << 1'b1;
				exp3--;
			  end
		  end
		  else begin				       // zero result (A-A)
		    exp3  = 0;
		    mant3 = 0;
		  end
		end
      end :netsub		*/

// now store results into specified mem_core addresses so that the testbench
//  can read them
      data_mem1.mem_core[13][7]								=	   sign3; 
      data_mem1.mem_core[13][6:2]							    =	   exp3 ; 
      {data_mem1.mem_core[13][1:0],data_mem1.mem_core[12]}  =	   mant3[9:0]; 
	  done = 1'b1;															     
	end	 :nonreset
  end  :main
endmodule