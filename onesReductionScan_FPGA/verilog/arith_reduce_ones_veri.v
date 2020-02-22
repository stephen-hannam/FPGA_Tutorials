module arith_reduce_ones_veri
  #(
    parameter INPUT_WIDTH = 4,
    parameter IW = INPUT_WIDTH - 1,
    parameter BW = $clog2(INPUT_WIDTH),
    parameter CW = (BW+1)*INPUT_WIDTH - 1
  )(
    input       [IW:0]  arr_in,
    output reg  [BW:0]  cnt_out = 0,
    output reg  [CW:0]  cum_cnt_out = 0
  );

  integer i;

  always @(arr_in) begin

    // PLO: diff btw verilog and VHDL => continuous vs procedural, or signal
    // vs variable
    cnt_out = 0;
    cum_cnt_out = 0;

    // procedural loop vs generative loop
    for(i = 0; i < INPUT_WIDTH; i = i + 1) begin
      cnt_out = cnt_out + arr_in[i];
      if (arr_in[i] == 1'b1) begin
        if (i == 0) begin
          cum_cnt_out[i*(BW+1) +: (BW+1)] = 1;
        end else begin
          cum_cnt_out[i*(BW+1) +: (BW+1)] = cum_cnt_out[(i-1)*(BW+1) +: (BW+1)] + 1;
        end
      end
    end

  end

endmodule
