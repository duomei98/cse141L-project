// lookup table
// deep 
// 9 bits wide; as deep as you wish
module instr_ROM #(parameter D=12)(
  input       [D-1:0] prog_ctr,    // prog_ctr	  address pointer
  output logic[8:0] mach_code);

  logic[8:0] core[2**D];
  initial begin					    // load the program
    // $readmemb("prog3.txt",core);
    // $readmemb("prog2.txt",core);
     $readmemb("prog1.txt",core);
  end 

  always_comb  mach_code = core[prog_ctr];

endmodule
