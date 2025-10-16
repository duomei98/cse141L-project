// test bench for float to fix 8.8
// CSE141L	 version w/o rounding required
//TODO: renorm everything to fix * 2**8   that way int_out can be type int again
module flt2fix_tb_noround();
  bit   clk = '0, 
        reset='1,
        req;
  wire  ack0,					 // from my dummy DUT
        ack;					 // from your DUT
  bit[15:0] flt_in = '0;
  logic sign;
  logic signed[5:0] exp;		 // de-biased exponent in
  logic[10:0] mant;              // significand in
  real int_equiv;                // computed value of integer 
  real mant2;					 // real equiv. of mant.
  real int_out;			         // two's comp. result
  real scaled;
  logic signed [15:0] math;
  int  score0, score1, 
       count;                   
  Top_level0 f2(.clk(clk),		 // my dummy DUT goes here
    .reset (reset),
    .start (req  ),
    .done  (ack0));				 
  TopLevel f3(.clk(clk),			 // your DUT goes here
    .reset (reset),
    .start (req  ),
    .done  (ack) );				 
  always begin
    #5ns clk = 1;
	#5ns clk = 0;
  end
  initial begin
    
    $monitor("PC: %d, R1: %b, R2: %b, R3: %b, R4: %b, R5: %b, R6: %b, R7: %b, F: %b, done: %b", 
             f3.prog_ctr,
             f3.rf1.core[1], 
             f3.rf1.core[2], 
             f3.rf1.core[3],
             f3.rf1.core[4],  
             f3.rf1.core[5],  
             f3.rf1.core[6],  
             f3.rf1.core[7],
             f3.flag_reg,
             f3.done); 
//    $monitor(flt_in,,,int_out);
    //#20ns reset = '0;
	flt_in = '0;
    disp;	                       // task call
	flt_in = 16'b0_01111_0000000000;	  // 00000001.00000000
    disp;
    flt_in = 16'b0_01111_1000000000;      // 00000001.10000000
    disp;
	flt_in = 16'b0_01111_0100000000;	  // 00000001.01000000

    disp;
    flt_in = 16'b0_01111_1100000000;	  // 00000001.11000000
	disp;
    flt_in = 16'b0_10000_0000000000;	  // 00000010.00000000
    disp;
    flt_in = 16'b0_10000_1000000000;	  // 00000011.00000000
    disp;
    flt_in = 16'b0_10000_1100000000;	  // 00000011.10000000
    disp;
    flt_in = 16'b0_10000_1110000000;	  // 00000011.11000000
    disp;
    flt_in = 16'b0_10000_0001000000;      // 00000010.00100000
    disp;
    flt_in = 16'b0_10000_0101000000;
    disp;
    flt_in = 16'b0_10000_0111000000;
    disp;
	flt_in = 16'b0_10010_1100000000;
	disp;
	flt_in = 16'b0_10010_1110000000;
	disp;
	flt_in = 16'b0_11000_1100000000;
	disp;
	flt_in = 16'b0_11001_1100000000;
	disp;
	flt_in = 16'b0_11101_1110000000;
	disp;
	flt_in = 16'b0_11110_1110000000;
	disp;
	flt_in = 16'h8000;
    disp;	                       // task call
	flt_in = 16'b1_01111_0000000000;
    disp;
//    flt_in = 16'b1_01111_1000000000;
//	disp;
	flt_in = 16'b1_01111_0100000000;
    disp;
//    flt_in = 16'b1_01111_1100000000;
//	disp;
    flt_in = 16'b1_10000_0000000000;
    disp;
    flt_in = 16'b1_10000_1000000000;
    disp;
//    flt_in = 16'b1_10000_1100000000;
//    disp;
//    flt_in = 16'b1_10000_1110000000;
//    disp;
    flt_in = 16'b1_10000_0001000000;
    disp;
    flt_in = 16'b1_10000_0001000000;
//    flt_in = 16'b1_10000_0101000000;
//    disp;
//    flt_in = 16'b1_10000_0111000000;
//    disp;
	flt_in = 16'b1_10010_1100000000;
	disp;
	flt_in = 16'b1_10010_1110000000;
	disp;
	flt_in = 16'b1_11000_1100000000;
	disp;
	flt_in = 16'b1_11001_1100000000;
	disp;
	flt_in = 16'b1_11101_1110000000;
	disp;
	flt_in = 16'b1_11110_1110000000;
	disp;

	#20ns $display("correct %d out of total %d",score0,count); 
		  $display("correct %d out of total %d",score1,count);
	$stop; 
  end
  task disp();
    reset = 1;
	#10ns;
	reset = 0;

    {f2.data_mem1.mem_core[5],f2.data_mem1.mem_core[4]} = flt_in;	 // inject flt_in to dat_mem
    {f3.data_mem1.mem_core[5],f3.data_mem1.mem_core[4]} = flt_in;	 //    same for your DUT
    #10ns req = '1;
    #10ns req = '0;
    sign      = flt_in[15];
    exp       = flt_in[14:10]-15;	     // remove exponent bias, adj to 8.8 fix      
    mant[10]  = |flt_in[14:10];	         // restore hidden bit
    mant[9:0] = flt_in[ 9: 0];	         // parse mantissa fraction
    mant2     = mant/1024.0;	         // equiv. floating point value of mant.
	wait(ack);
    if(exp>=8) begin	//>14
      if(sign) int_out = -128;         // max neg. trap     was -32768   
      else     int_out =  127.99609375;		 // max pos. trap			 32767
    end
    else begin
	int_equiv = mant2 * 2**exp;
	int_out   = sign? -int_equiv : int_equiv;
    end
    scaled = int_out * 256.0;          // e.g. 1.25 → 320.0
    math        = int'(scaled);             // truncate toward zero into signed 16-bit

    #20ns $display("%f * 2**%d = %f = %d",mant2,exp,int_equiv,int_out);
        $display("original binary = %b_%b_%b",flt_in[15],flt_in[14:10],flt_in[9:0]);
        $display("from MAT = %b = %d", math[15:0], math[15:0]);
    #20ns $display("from dum = %b = %d",{f2.data_mem1.mem_core[7],f2.data_mem1.mem_core[6]},
        {f2.data_mem1.mem_core[7],f2.data_mem1.mem_core[6]});
    $display("from DUT = %b = %d",{f3.data_mem1.mem_core[7],f3.data_mem1.mem_core[6]},
             {f3.data_mem1.mem_core[7],f3.data_mem1.mem_core[6]});
    count++;
    if({f3.data_mem1.mem_core[7],f3.data_mem1.mem_core[6]} == {f2.data_mem1.mem_core[7],f2.data_mem1.mem_core[6]}) score0++;
    if(math == {f3.data_mem1.mem_core[7],f3.data_mem1.mem_core[6]}) score1++;
	$display("                ct = %d, score0 = %d, score1 =  %d",count,score0,score1);
  endtask
endmodule

