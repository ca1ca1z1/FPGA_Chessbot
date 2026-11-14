package require ::quartus::project
package require ::quartus::sta
project_open FPGA_Chessbot
create_timing_netlist
read_sdc
update_timing_netlist
file mkdir ../build/timing
report_clocks -file ../build/timing/clocks.txt
check_timing -file ../build/timing/check_timing.txt
report_ucp -file ../build/timing/unconstrained.txt
set failures 0
foreach corner [get_available_operating_conditions] {
    set_operating_conditions $corner
    update_timing_netlist
    foreach kind {setup hold recovery removal} {
        set paths [get_timing_paths -$kind -npaths 1]
        if {[get_collection_size $paths] > 0} {
            foreach_in_collection path $paths {
                set slack [get_path_info -slack $path]
                puts "TIMING $corner $kind slack=$slack ns"
                if {$slack < 0} {incr failures}
            }
        }
        report_timing -$kind -npaths 5 -detail full_path -file "../build/timing/${corner}_${kind}.txt"
    }
}
delete_timing_netlist
project_close
if {$failures > 0} {error "$failures timing checks failed"}
puts "TIMING SLACK CHECKS PASSED; inspect check_timing.txt and unconstrained.txt too."
