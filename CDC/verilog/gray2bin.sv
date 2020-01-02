// from Cliff Cummings SNUG 2008 Boston CDC

module gray2bin
#(
  parameter SIZE = 4
)(
  input   logic  [SIZE-1:0]  gray,
  output  logic  [SIZE-1:0]  bin
);

always_comb
  for (int i=0; i < SIZE; i++)
    bin[i] = ^(gray>>i);

endmodule
