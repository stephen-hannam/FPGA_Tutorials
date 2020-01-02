`timescale 1ns/1ps
`include "utils.vh"
`define BASE_MEM_PATH ./

module typische_tb();

  parameter MW            = 8;
  parameter NUM_RX_WORDS  = 4;
  parameter NUM_TX_WORDS  = 4;
  parameter DATA_FILE     = `MAKE_PATH(`BASE_MEM_PATH,deadbeef.dat);
  parameter CMP_FILE      = `MAKE_PATH(`BASE_MEM_PATH,deadbeef_cmp.dat);
  parameter END_CYCLES    = 5;
  parameter T             = 5;

  /* TB CLK MGMT */
  parameter T_TB = 0.001;
  parameter C_A  = 2103;
  parameter C_B  = 1103;

  reg clk_tb = 0, clk_a = 0, clk_b = 0, b_locked = 0, a_locked = 0;
  reg [`M(C_A):0] a_cnt = 0;
  reg [`M(C_B):0] b_cnt = 0;

  reg rst_good = 0, a_done = 0, b_done = 0, passed = 0;
  reg [MW-1:0] stim_data [NUM_RX_WORDS];
  reg [MW-1:0] bytes_tx_out [NUM_TX_WORDS], cmp_bytes[NUM_TX_WORDS];
  reg [`M(END_CYCLES):0] final_count = 0;

  /* internal loop vars */
  integer ii = 0, jj = 0;

  /* INPUT regs into DUT */
  reg rst_n_a = 1;
  reg cntl_a = 0;
  reg [MW-1:0] data_a = 0;

  wire cntl_b;
  wire [MW-1:0] data_b;

  typische_mcp_mgc // mcp_mgc = multi-cycle path & minimal gray counters
  #(
    .WIDTH(MW)
  )
  DUT
  (
    .clk_a(clk_a),
    .rst_n_a(rst_n_a),
    .clk_b(clk_b),
    .cntl_a(cntl_a),
    .data_a(data_a),
    .data_b(data_b),
    .cntl_b(cntl_b)
  );

  //typische_mcp_sc // mcp_sc = multi-cycle path & sync chain
  //#(
  //  .WIDTH(MW)
  //)
  //DUT
  //(
  //  .clk_a(clk_a),
  //  .rst_n_a(rst_n_a),
  //  .clk_b(clk_b),
  //  .cntl_a(cntl_a),
  //  .data_a(data_a),
  //  .data_b(data_b),
  //  .cntl_b(cntl_b)
  //);


  always  #(T_TB)   clk_tb = ~clk_tb;

  always @(posedge clk_tb) begin
    if (a_locked) begin
      if (a_cnt < C_A) begin
        a_cnt <= a_cnt + 1;
      end else begin
        a_cnt <= 0;
        clk_a = ~clk_a;
      end
    end
    if (b_locked) begin
      if (b_cnt < C_B) begin
        b_cnt <= b_cnt + 1;
      end else begin
        b_cnt <= 0;
        clk_b = ~clk_b;
      end
    end
  end

  initial begin
        passed   = 1;
        b_locked = 0;
        a_locked = 0;
#(0.7)  b_locked = 1;
#(0.5)  a_locked = 1;
        a_done   = 0;
        b_done   = 0;
  	    rst_good = 0;
        rst_n_a  = 0;
#(2*T)  rst_n_a  = 1;
#(2*T)  rst_good = 1;
  end

  initial begin
    $readmemh(DATA_FILE, stim_data);
    $readmemh(CMP_FILE, cmp_bytes);
  end

  /* apply stim to DUT */
  always@(posedge rst_good)
  	$display("<< Starting the Simulation >> @ ", $time);

  always@(posedge clk_a) begin
  	if (rst_good) begin
      cntl_a  <= 0;
  		if (ii < NUM_RX_WORDS) begin
        ii     <= ii + 1;
        cntl_a <= 1;
  		  data_a <= stim_data[ii];
  			//$display("%d: %h",ii,stim_data[ii], $time);
      end else begin
        a_done <= 1;
      end
  	end
  end

  always @(posedge clk_b) begin
    if (rst_good) begin
      if (jj > NUM_TX_WORDS) begin
        $display("bytes_tx_out buffer overrun");
      end else if (cntl_b) begin
        jj  <= jj + 1;
        bytes_tx_out[jj]  <= data_b;
      end else if (jj == NUM_TX_WORDS) begin
        b_done  <= 1;
      end

      if (b_done) begin
        if (final_count < END_CYCLES) begin
          final_count <= final_count + 1;
        end else begin
          $display("beat number: %d: %s  == %s",-1,"tx data","expected data");
          $display("%s","----------------------------------------------------------");
          for (ii = 0; ii < NUM_TX_WORDS; ii = ii + 1) begin
            if (bytes_tx_out[ii] == cmp_bytes[ii]) begin
              $display("beat number: %d: %h == %h",ii,bytes_tx_out[ii],cmp_bytes[ii]);
            end else begin
              $display("beat number: %d: %h != %h",ii,bytes_tx_out[ii],cmp_bytes[ii]);
              passed = 0;
            end
          end
          $display("finished");
          if (~passed) begin
            $display("unit test failed");
          end else begin
            $display("unit test passed");
          end
          $stop;
        end
      end

    end
  end

endmodule
