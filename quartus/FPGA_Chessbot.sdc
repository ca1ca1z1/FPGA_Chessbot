create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_pll_clocks
derive_clock_uncertainty
# Forwarded 25.2 MHz DAC clock. RGB and control launch on falling edges.
set pixel_source [get_pins -hierarchical {*divclk*}]
if {[get_collection_size $pixel_source] != 1} {error "Expected exactly one PLL output clock source"}
create_generated_clock -name VGA_PIXEL_OUT -source $pixel_source -divide_by 1 [get_ports {VGA_CLK}]
# ADV7123 3.3 V: setup 0.2 ns, hold 1.5 ns (Rev D, timing table).
# Budgets below add margin for PCB skew; hardware verification is still required.
set_output_delay -clock VGA_PIXEL_OUT -max 2.0 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_BLANK_N VGA_SYNC_N VGA_HS VGA_VS}]
set_output_delay -clock VGA_PIXEL_OUT -min -2.5 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_BLANK_N VGA_SYNC_N VGA_HS VGA_VS}]
# Human inputs are asynchronous. Only first-stage key synchronizers are excepted.
set_false_path -from [get_ports {KEY[*]}] -to [get_registers {*|sync_meta}]
# SW[9] only drives the asynchronous reset synchronizer; SW[8:0] are unused.
set_false_path -from [get_ports {SW[*]}]
# Reset release and the synchronizer's inter-stage path remain timed.
# LEDs are asynchronous human-readable diagnostics, not a synchronous interface.
set_false_path -to [get_ports {LEDR[*]}]
