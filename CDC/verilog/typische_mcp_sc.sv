//`timescale 1ns/1ps

// online resource said this would be good for both fast to slow and slow to
// fast but that clearly can't be the case, and tb reveals it

module typische_mcp_sc
#(
  parameter WIDTH = 8
)(
  input                   clk_a,
  input                   rst_n_a,
  input                   clk_b,
  input                   cntl_a,
  input       [WIDTH-1:0] data_a,
  output reg  [WIDTH-1:0] data_b,
  output reg              cntl_b
);

  localparam SLEN = 3;

  reg r_cntl_a = 0;
  reg [WIDTH-1:0] r_data_a = 0;

  (* ASYNC_REG = "TRUE" *)
  reg [0:SLEN-1] sync;

  wire mux_sel, sync_reset;
  wire [WIDTH-1:0] mux_out_b;

  (* ASYNC_REG = "TRUE" *)
  reg [WIDTH-1:0] r_data_b = 0;

  assign mux_sel    = ^sync;
  assign mux_out_b  = (mux_sel) ? r_data_a : r_data_b;
  assign sync_reset = ((&sync[0:SLEN-2]) & ~sync[SLEN-1]) ? 0 : 1;

  genvar i;

  always @(posedge clk_b) begin
    data_b   <= mux_out_b;
    r_data_b <= mux_out_b;
    cntl_b   <= mux_sel;
    sync[0]  <= r_cntl_a;
  end

  for (i = 1; i < SLEN; i = i + 1) begin
    always @(posedge clk_b) begin
      sync[i]  <= sync[i-1] & sync_reset;
    end
  end

  for (i = 0; i < SLEN; i = i + 1) begin
    initial begin
      sync[i] <= 0;
    end
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
