// program counter
// our ISA only supports both relative jumps
module PC #(parameter D=12)(
  input start,
  		reset,					// synchronous reset
  		done,
		clk,
   		reljump_en,
		             // rel. jump enable
  input [D-1:0] offset,	// how far/where to jump
  output logic[D-1:0] prog_ctr
);

  always_ff @(posedge clk) begin
    if(reset)
	  prog_ctr <= '0;
    // loop on PC until reset signal
    else if (done)
        prog_ctr <= prog_ctr;
    else if (start || prog_ctr > 0) begin
      // if instruction is jump 0, ignore it
      if (reljump_en && (offset != 'b0))
        prog_ctr <= prog_ctr + offset;
        // no absolute addressing
  	  else
	  	prog_ctr <= prog_ctr + 1;
    end 
  end 

endmodule