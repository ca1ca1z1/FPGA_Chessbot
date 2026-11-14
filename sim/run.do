onerror {quit -code 1 -force}
onbreak {resume}
set chessbot_root [file normalize $env(CHESSBOT_ROOT)]
if {![file isdirectory work]} {vlib work}
vmap work work
vlog -vlog01compat +incdir+$chessbot_root/rtl {*}[glob $chessbot_root/rtl/*.v] {*}[glob $chessbot_root/sim/tb_*.v]
foreach bench {tb_button tb_game tb_video tb_pll tb_core tb_top} {
    vsim -t 1ps -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver work.$bench
    onfinish stop
    run -all
    if {[examine -radix unsigned /$bench/passed] != 1} {
        puts "FAILED: $bench"
        quit -code 1 -force
    }
    quit -sim
}
puts "ALL STAGE 1 TESTS PASSED"
quit -code 0 -force
