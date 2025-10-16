// 8-bit wide, 256-word (byte) deep memory array
module dat_mem (
  input[7:0] dat_in,
  input      clk, reset,
  input      wr_en,	          // write enable
  input[7:0] addr,		      // address pointer
  output logic[7:0] dat_out);

  logic[7:0] mem_core[256];       // 2-dim array  8 wide  256 deep
  wire[7:0] addr_unsigned = {4'b0000,addr[3:0]};

  // preload memory from a file
  initial begin
    $readmemb("prog1_dm.txt", mem_core);  
  end

// reads are combinational; no enable or clock required
  assign dat_out = mem_core[addr_unsigned];

// writes are sequential (clocked) -- occur on stores or pushes 
  always_ff @(posedge clk) begin
    if(wr_en)				  // wr_en usually = 0; = 1 		
      mem_core[addr_unsigned] <= dat_in;
    if (reset) begin
      mem_core[0] <= 'b00000000;
      mem_core[1] <= 'b00000001;
    end
  end 

endmodule