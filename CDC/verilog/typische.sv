//`timescale 1ns/1ps

module typische
#(
  parameter integer WIDTH = 8
)(
  input                   clk_a,
  input                   rst_n_a,
  input                   clk_b,
  input                   cntl_a,
  input       [WIDTH-1:0] data_a,
  output reg  [WIDTH-1:0] data_b,
  output reg              cntl_b
);

  reg r_cntl_a = 0;
  reg [WIDTH-1:0] r_data_a = 0;

  (* ASYNC_REG = "TRUE" *)
  reg [2:0] sync = 0;

  wire mux_sel;
  wire [WIDTH-1:0] mux_out_b;

  (* ASYNC_REG = "TRUE" *)
  reg [WIDTH-1:0] r_data_b = 0;

  assign mux_sel   = sync[1] ^ sync[2];
  assign mux_out_b = (mux_sel) ? r_data_a : r_data_b;

  always @(posedge clk_b) begin
    data_b                      <= mux_out_b;
    cntl_b                      <= mux_sel;
    {sync[2], sync[1], sync[0]} <= {sync[1], sync[0], r_cntl_a};
  end

  always @(posedge clk_a) begin
    if (~rst_n_a) begin
      r_data_a  <= 0;
      r_cntl_a  <= 0;
    end else begin
      r_data_a  <= data_a;
      r_cntl_a  <= cntl_a;
    end
  end

endmodule
