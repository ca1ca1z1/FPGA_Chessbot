create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
# The external reset is asynchronous. Keep inter-stage and downstream paths timed.
set_false_path -from [get_ports {KEY[0]}] -to [get_registers {*reset_control*|sync_ff[*]}]
# LEDs are human-readable outputs, including the asynchronous switch lookup.
# This exception must be revisited if switches feed clocked game logic later.
set_false_path -to [get_ports {LEDR[*]}]
