// from Cliff Cummings SNUG 2008 Boston CDC

module bin2gray
#(
  SIZE = 4
)(
  input   logic [SIZE-1:0]  bin,
  output  logic [SIZE-1:0]  gray
);

  assign gray = (bin>>1) ^ bin;

endmodule
