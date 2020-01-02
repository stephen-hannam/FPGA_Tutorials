onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider DUT_cntl
add wave -noupdate /typische_tb/tx_locked
add wave -noupdate /typische_tb/rx_locked
add wave -noupdate /typische_tb/rst_good
add wave -noupdate /typische_tb/rx_done
add wave -noupdate /typische_tb/tx_done
add wave -noupdate /typische_tb/passed
add wave -noupdate -radix hexadecimal /typische_tb/stim_data
add wave -noupdate -radix hexadecimal /typische_tb/bytes_tx_out
add wave -noupdate -radix hexadecimal /typische_tb/cmp_bytes
add wave -noupdate -radix unsigned /typische_tb/final_count
add wave -noupdate /typische_tb/ii
add wave -noupdate /typische_tb/jj
add wave -noupdate -divider DUT_port
add wave -noupdate /typische_tb/DUT/clk_a
add wave -noupdate /typische_tb/DUT/rst_n_a
add wave -noupdate /typische_tb/DUT/clk_b
add wave -noupdate /typische_tb/DUT/cntl_a
add wave -noupdate -radix hexadecimal /typische_tb/DUT/data_a
add wave -noupdate /typische_tb/DUT/cntl_b
add wave -noupdate -radix hexadecimal /typische_tb/DUT/data_b
add wave -noupdate -divider DUT_internal
add wave -noupdate /typische_tb/DUT/r_cntl_a
add wave -noupdate /typische_tb/DUT/sync
add wave -noupdate /typische_tb/DUT/sync_reset
add wave -noupdate /typische_tb/DUT/mux_sel
add wave -noupdate -radix hexadecimal /typische_tb/DUT/r_data_a
add wave -noupdate -radix hexadecimal /typische_tb/DUT/mux_out_b
add wave -noupdate -radix hexadecimal /typische_tb/DUT/r_data_b
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {46280 ps} 0}
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
WaveRestoreZoom {0 ps} {66276 ps}
