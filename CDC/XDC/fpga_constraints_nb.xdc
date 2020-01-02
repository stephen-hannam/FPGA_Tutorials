
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

##Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_pad]
create_clock -period 10.000 -name clk_pad -waveform {0.000 5.000} -add [get_ports clk_pad]

##Resets
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports rst_n]

##Buttons
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {switch[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {switch[1]}]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {switch[2]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {switch[3]}]

##LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {led_b[0]}]
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {led_r[0]}]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {led_g[0]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {led_b[1]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {led_r[1]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {led_g[1]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {led_b[2]}]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {led_r[2]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {led_g[2]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {led_b[3]}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {led_r[3]}]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {led_g[3]}]

## PMOD connections
##JA	#################
##B18

##JB	#################
##E15
##E16
##D15
##C15

##J17
##J18
##K15
##J15

##JC	#################
##U12
##V12
##V10
##U11

##U14
##V14
##T13
##U13

################# JD	#################
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports pmod_cs]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports pmod_mosi]
##F4
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports pmod_sclk]

set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports pmod_dc]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports pmod_res]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports pmod_vbat]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports pmod_vdd]

set_false_path -from [get_clocks -of_objects [get_pins PM_PLL/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins PM_PLL/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins PM_PLL/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins PM_PLL/inst/mmcm_adv_inst/CLKOUT1]]
