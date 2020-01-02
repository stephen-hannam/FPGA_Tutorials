// from Cliff Cummings SNUG 2008 Boston CDC: gray code counter style #1

module graycntr_1
#(
  parameter SIZE = 5
)(
  input   logic             clk,
  input   logic             inc,
  input   logic             rst_n,
  output  logic [SIZE-1:0]  gray
);

  logic [SIZE-1:0] gnext, bnext, bin;

  genvar i;

  always_ff @(posedge clk or negedge rst_n)
    if (~rst_n)
      gray <= '0;
    else
      gray <= gnext;

  always_comb begin
    for (i = 0; i < SIZE; i = i + 1)
      bin[i] = ^(gray>>i);

    bnext = bin + inc;
    gnext = (bnext>>1) ^ bnext;
  end
endmodule
