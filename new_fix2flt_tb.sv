// CSE141L   revised 2025.05.24
// testbench for fixed(8.8) to float(16) conversion
// bench computes theoretical result
// bench holds your DUT and my dummy DUT
// (ideally, all three should agree :) )
// keyword bit is same as logic, except it self-initializes
//  to 0 and cannot take on x or z value
module new_int2flt_tb();
  bit       clk       , 
            reset = '1,
            req;
  wire      ack,			 // your DUT's done flag
            ack0;			 // my dummy done flag
  bit  [15:0] int_in; 	     // incoming operand
  logic[15:0] int_out0;      // reconstructed integer from my reference
  logic[15:0] int_out;       // reconstructed integer from your floating point output
  logic[15:0] int_outM;      // reconstructed integer from mathetmical floating point conversion
  bit  [ 3:0] shift;         // for incoming data sizing
  logic[15:0] flt_out0,		 // my design final result
			  flt_out,		 // your design final result
              flt_outM;	     // mathematical final result
  int         scoreM,        // your DUT vs. theory 
              score0,	     // your DUT vs. mine
			  count = 0;     // number of trials

  TopLevel f1(				 // your DUT to generate right answer
    .clk  (clk),
	.start(req),
    .reset(reset),
    .done (ack));	         // your ack is the one that counts
  TopLevel0 f0(				 // reference DUT goes here
    .clk  (clk),			 // 
    .start(req),			 //  
	.reset(reset),			 //  
    .done (ack0));           

  always begin               // clock 
    #5ns clk = '1;			 
	#5ns clk = '0;
  end

  initial begin				 // test sequence
    $monitor("data_mem.core0, 1 = %b  %b %t",f0.data_mem1.mem_core[3],f1.data_mem1.mem_core[3],$time);

    /*
    $monitor("PC: %d, R1: %b, R2: %b, R3: %b, R4: %b, R5: %b, R6: %b, R7: %b, F: %b, done: %b", 
             f1.prog_ctr,
             f1.rf1.core[1], 
             f1.rf1.core[2], 
             f1.rf1.core[3],
             f1.rf1.core[4],  
             f1.rf1.core[5],  
             f1.rf1.core[6],  
             f1.rf1.core[7], 
             f1.flag_reg,
             f1.done); 
    */
    //#20ns reset = '0;
	disp2(int_in);			 // subroutine call
	int_in = 16'h0001;			 // minimum nonzero positive = 1/128
	disp2(int_in);
	int_in = 16'h0002; 		 // start w/ contrived tests   1/64
	disp2(int_in);
	int_in = 16'h0003;		 // 						  3/128
	disp2(int_in);
	int_in = 16'h000c;		 // 						  3/32
	disp2(int_in);
	int_in = 16'h0030;		 // 					  3/8
	disp2(int_in);
	int_in = 16'h1fff;       // qtr maximum positive   31 + 255/256
	disp2(int_in);
	int_in = 16'h3fff;      // half maximum positive  63 + 255/256
	disp2(int_in);
	int_in = 16'h7fff;      // maximum positive	 = 127 + 255/256
	disp2(int_in);
	int_in = 16'hffff;		 // minimum magnitude negative = -1/256
	disp2(int_in);
	int_in = 16'hfffe;		 // -1/128
	disp2(int_in);
	int_in = 16'hfffd; 		 // -3/256
	disp2(int_in);
	int_in = 16'hfff4;		 // -3/32
	disp2(int_in);
	int_in = 16'hffd0;		 // -3/8
	disp2(int_in);
	int_in = 16'hc000;      // qtr maximum magnitude negative
	disp2(int_in);
	int_in = 16'h4000;     // half maximum magnitude negative
	disp2(int_in);
	int_in = 16'h8000;     // maximum magnitude negative
	disp2(int_in);
	int_in = 16'h8001;     // near maximum magnitude negative
	disp2(int_in);
	forever begin			 // random tests
	  int_in = $random;
	  int_in[15] = int_in[15] && !int_in[14:0]; // zero out extreme neg
	  disp2(int_in);
	  if(count>100) begin
	  	#20ns $display("scores = %d %d out of %d",score0,scoreM,count); 
        $stop;
	  end
	end
  end

task automatic disp2(input logic [15:0] int_in);
	// locals
	logic        sign;
	real         v, mag;
	logic[15:0]  exp_unb, exp_biased, mant;
	logic [15:0] half;
	logic [15:0] float_M;

	sign = int_in[15];
	half = int_in;
	if (sign) half = ~int_in + 1;
	exp_unb = 1;

	if (!int_in) float_M = 0;
	else begin
	  while ((half & 16'h8000) == 0) begin
	  	half <<= 1;
	  	exp_unb++;
	  end
	  half <<= 1;

	  float_M = sign<<15;

	  exp_biased = 8 - exp_unb;
	  exp_biased = exp_biased + 15;
	  exp_biased <<= 10;

	  float_M = float_M + exp_biased;
	  half = half & 16'hFFC0;
	  half >>= 6;

	  float_M = float_M + half;
	end

	$display("This test case %b \n", int_in);
	reset = 1;
	#10ns;
	reset = 0;

	f1.data_mem1.mem_core[1] = int_in[15:8];   // load operands into your memory
	f1.data_mem1.mem_core[0] = int_in[ 7:0];
	f0.data_mem1.mem_core[1] = int_in[15:8];   // load operands into my memory
	f0.data_mem1.mem_core[0] = int_in[ 7:0];
    //flt_out_M[15]     = sgn_M;                 // sign is a passthrough
	#10ns req = 1;
	#10ns req = 0;
	wait(ack);
	wait(ack0);
	#10ns;
  	flt_out  = {f1.data_mem1.mem_core[3],f1.data_mem1.mem_core[2]};	 // results from your memory
    flt_out0 = {f0.data_mem1.mem_core[3],f0.data_mem1.mem_core[2]};	 // results from my dummy DUT
    $display("what's feeding the case %b",int_in);
	// exp_M  = '0;                           // initial point -- override as needed		   
	// mant_M = '0;
	/*if(!int_in[14:0]) begin                     // trap 0 or max neg 
      if(sgn_M) exp_M = 'd22;
      mant_M = '0;
    end 
    else begin 
      if(sgn_M) int_in = ~int_in+1;         // negatives
    casez(int_in[14:0])					// normalization
	  15'b1??_????_????_????: begin
	    exp_M  = 21;
	    mant_M = int_in[14:4];
		if(int_in[4]||(|int_in[2:0])) mant_M = mant_M+int_in[3];
        if(mant_M[11]) begin
		  exp_M++;
		  mant_M = mant_M>>1;
		end
	  end
	  15'b01?_????_????_????: begin
	    exp_M  = 20;
	    mant_M = int_in[13:3];
		if(int_in[3]||(|int_in[1:0])) mant_M = mant_M+int_in[2];
        if(mant_M[11]) begin
		  exp_M++;
		  mant_M = mant_M>>1;
		end
	  end
	  15'b001_????_????_????: begin
	    exp_M  = 19;
	    mant_M = int_in[12:2];
		if(int_in[2]||(int_in[0]))    mant_M = mant_M+int_in[1];
        if(mant_M[11]) begin
		  exp_M++;
		  mant_M = mant_M>>1;
		end
	  end
	  15'b000_1???_????_????: begin
	    exp_M  = 18;
		mant_M = int_in[11:1];
        if(int_in[1])                 mant_M = mant_M+int_in[0];
        if(mant_M[11]) begin
		  exp_M++;
		  mant_M = mant_M>>1;
		end
	  end
	  15'b000_01??_????_????: begin
	    exp_M  = 17;
		mant_M = int_in[10:0];
	  end
	  15'b000_001?_????_????: begin
	    exp_M  = 16;
		mant_M = {int_in[9:0],1'b0};
      end
	  15'b000_0001_????_????: begin
		exp_M  = 15;
		mant_M = {int_in[8:0],2'b0};
      end
	  15'b000_0000_1???_????: begin
		exp_M  = 14;
		mant_M = {int_in[7:0],3'b0};
      end
	  15'b000_0000_01??_????: begin
		exp_M  = 13;
		mant_M = {int_in[6:0],4'b0};
      end
	  15'b000_0000_001?_????: begin
		exp_M  = 12;
		mant_M = {int_in[5:0],5'b0};
      end
	  15'b000_0000_0001_????: begin
		exp_M  = 11;
		mant_M = {int_in[4:0],6'b0};
      end
	  15'b000_0000_0000_1???: begin
		exp_M  = 10;
		mant_M = {int_in[3:0],7'b0};
      end
	  15'b000_0000_0000_01??: begin
		exp_M  = 09;
		mant_M = {int_in[2:0],8'b0};
      end
	  15'b000_0000_0000_001?: begin
		exp_M  = 08;
		mant_M = {int_in[1:0],9'b0};
      end
	  15'b000_0000_0000_0001: begin
        exp_M  = 07;
		mant_M = 11'b100_0000_0000;
	  end
    endcase
	end*/
	flt_outM = float_M;

	$display("IN=0x%h,  DUT=0x%h, REF=0x%h, MATH=0x%h",
			int_in, flt_out, flt_out0, flt_outM);
	// Compare DUT vs. reference DUT
    if (flt_out === flt_out0) 
      score0++;
    else 
      $display("Mismatch DUT vs REF: DUT=0x%h REF=0x%h", flt_out, flt_out0);

    // Compare DUT vs. math model
    if (flt_out === flt_outM) 
      scoreM++;
    else 
      $display("Mismatch DUT vs MATH: DUT=0x%h MATH=0x%h", flt_out, flt_outM);

    count++;
    $display("Scores so far: vs REF=%0d, vs MATH=%0d, tests=%0d",
			score0, scoreM, count);
  endtask
endmodule