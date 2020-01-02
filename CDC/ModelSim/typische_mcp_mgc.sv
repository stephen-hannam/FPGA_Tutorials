//`timescale 1ns/1ps

// online resource said this would be good for both fast to slow and slow to
// fast but that clearly can't be the case, and tb reveals it

module typische_mcp_mgc // mcp_mgc = multi-cycle path & minimal gray counters
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

  localparam SLEN = 2; // sync chain length
  localparam GLEN = 2; // gray counter width/length

  genvar i,j;

  reg [WIDTH-1:0] r_data_a = 0;

  (* ASYNC_REG = "TRUE" *)
  reg [GLEN-1:0] r_gray_cntrs_b[0:SLEN-1];

  reg [GLEN-1:0] gray_cntr_a = 0;

  (* ASYNC_REG = "TRUE" *)
  reg [WIDTH-1:0] r_data_b = 0;

  wire [WIDTH-1:0] mux_out_b;
  wire sync;

  assign sync       = (r_gray_cntrs_b[0] != r_gray_cntrs_b[1]);

  assign mux_out_b  = (sync) ? r_data_a : r_data_b;

  always @(posedge clk_b) begin
    data_b            <= mux_out_b;
    r_data_b          <= mux_out_b;
    cntl_b            <= sync;
    r_gray_cntrs_b[0] <= gray_cntr_a;
  end

  for (i = 1; i < SLEN; i = i + 1) begin
    always @(posedge clk_b) begin
      r_gray_cntrs_b[i]  <= r_gray_cntrs_b[i-1];
    end
  end

  for (i = 0; i < SLEN; i = i + 1) begin
    initial begin
      r_gray_cntrs_b[i] <= 0;
    end
  end

  always @(posedge clk_a) begin
    if (~rst_n_a) begin
      r_data_a    <= 0;
      gray_cntr_a <= 0;
    end else begin
      r_data_a  <= data_a;
      case (gray_cntr_a)
        2'b00 : if (cntl_a) gray_cntr_a <= 2'b01;
        2'b01 : if (cntl_a) gray_cntr_a <= 2'b11;
        2'b11 : if (cntl_a) gray_cntr_a <= 2'b10;
        2'b10 : if (cntl_a) gray_cntr_a <= 2'b00;
      endcase
    end
  end

endmodule
