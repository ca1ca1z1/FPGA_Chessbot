package require ::quartus::project
package require ::quartus::sta
project_open chess
create_timing_netlist
read_sdc
update_timing_netlist
report_clocks -file build/verify/clocks.txt
check_timing -file build/verify/check_timing.txt
report_ucp -file build/verify/unconstrained.txt
delete_timing_netlist
project_close
