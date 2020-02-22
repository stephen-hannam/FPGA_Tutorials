onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider DUT_cntl
add wave -noupdate -group sim_cntl /typische_tb/clk_tb
add wave -noupdate -group sim_cntl -radix unsigned /typische_tb/a_cnt
add wave -noupdate -group sim_cntl -radix unsigned /typische_tb/b_cnt
add wave -noupdate -group sim_cntl /typische_tb/b_locked
add wave -noupdate -group sim_cntl /typische_tb/a_locked
add wave -noupdate -group sim_cntl /typische_tb/rst_good
add wave -noupdate -group sim_cntl /typische_tb/passed
add wave -noupdate -group sim_cntl -radix hexadecimal /typische_tb/stim_data
add wave -noupdate -group sim_cntl -radix hexadecimal /typische_tb/bytes_tx_out
add wave -noupdate -group sim_cntl -radix hexadecimal /typische_tb/cmp_bytes
add wave -noupdate -group sim_cntl -radix unsigned /typische_tb/final_count
add wave -noupdate -group sim_cntl /typische_tb/a_done
add wave -noupdate -group sim_cntl /typische_tb/b_done
add wave -noupdate -divider DUT_port
add wave -noupdate -radix binary /typische_tb/DUT/clk_a
add wave -noupdate -radix binary /typische_tb/DUT/rst_n_a
add wave -noupdate -radix binary /typische_tb/DUT/clk_b
add wave -noupdate -radix binary /typische_tb/DUT/cntl_a
add wave -noupdate -radix hexadecimal /typische_tb/DUT/data_a
add wave -noupdate /typische_tb/DUT/cntl_b
add wave -noupdate -radix hexadecimal /typische_tb/DUT/data_b
add wave -noupdate -divider DUT_internal
add wave -noupdate -radix binary /typische_tb/DUT/sync
add wave -noupdate -expand /typische_tb/DUT/r_gray_cntrs_b
add wave -noupdate /typische_tb/DUT/gray_cntr_a
add wave -noupdate -radix hexadecimal /typische_tb/DUT/r_data_a
add wave -noupdate -radix hexadecimal /typische_tb/DUT/mux_out_b
add wave -noupdate -radix hexadecimal /typische_tb/DUT/r_data_b
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28733 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 186
configure wave -valuecolwidth 148
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {105062 ps}
