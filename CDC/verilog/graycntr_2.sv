// from Cliff Cummings SNUG 2008 Boston CDC: gray code counter style #2

module graycntr_2
#(
  parameter SIZE = 5
)(
  input   logic             clk,
  input   logic             rst_n,
  input   logic             full,
  input   logic             inc,
  output  logic [SIZE-1:0]  gray
);

  logic [SIZE-1:0] gnext, bnext, bin;

  always_ff @(posedge clk or negedge rst_n)
    if (!wrst_n)
      {bin, gray} <= '0;
    else
      {bin, gray} <= {bnext, gnext};

  assign bnext = !full ? bin + inc : bin;
  assign gnext = (bnext>>1) ^ bnext;
endmodule
