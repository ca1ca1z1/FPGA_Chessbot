create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
# The external reset is asynchronous. Keep inter-stage and downstream paths timed.
set_false_path -from [get_ports {KEY[0]}] -to [get_registers {*reset_control*|sync_ff[*]}]
# KEY[3:1] are asynchronous push buttons; each one enters through a two-stage synchronizer.
set_false_path -from [get_ports {KEY[1] KEY[2] KEY[3]}] -to [get_registers {*_button|sync_ff[*]}]
# LEDs and 7-segment displays are human-readable outputs.
set_false_path -to [get_ports {LEDR[*]}]
set_false_path -to [get_ports {HEX*}]
