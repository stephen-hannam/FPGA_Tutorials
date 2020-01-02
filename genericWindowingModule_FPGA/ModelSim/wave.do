onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /generic_window_tb/clk
add wave -noupdate /generic_window_tb/rst_n
add wave -noupdate /generic_window_tb/rst_good
add wave -noupdate /generic_window_tb/screen_done
add wave -noupdate /generic_window_tb/data_in
add wave -noupdate /generic_window_tb/data_out
add wave -noupdate -radix unsigned /generic_window_tb/x
add wave -noupdate -radix unsigned /generic_window_tb/y
add wave -noupdate /generic_window_tb/pixel
add wave -noupdate /generic_window_tb/control_sigs
add wave -noupdate -radix unsigned /generic_window_tb/pixel_count
add wave -noupdate -divider DUT
add wave -noupdate /generic_window_tb/DUT/clk
add wave -noupdate /generic_window_tb/DUT/rst_n
add wave -noupdate /generic_window_tb/DUT/data_in
add wave -noupdate /generic_window_tb/DUT/data_out
add wave -noupdate /generic_window_tb/DUT/screen_done
add wave -noupdate -radix unsigned /generic_window_tb/DUT/x
add wave -noupdate -radix unsigned /generic_window_tb/DUT/y
add wave -noupdate /generic_window_tb/DUT/data_out_w
add wave -noupdate /generic_window_tb/DUT/data_in_w
add wave -noupdate /generic_window_tb/DUT/data_out_g
add wave -noupdate /generic_window_tb/DUT/wr_en
add wave -noupdate /generic_window_tb/DUT/fifo_in_n
add wave -noupdate /generic_window_tb/DUT/fifo_out_n
add wave -noupdate /generic_window_tb/DUT/count_state
add wave -noupdate -radix unsigned /generic_window_tb/DUT/col_count
add wave -noupdate -radix unsigned /generic_window_tb/DUT/row_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3071724335 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 226
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
WaveRestoreZoom {0 ps} {3225752250 ps}
