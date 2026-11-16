param([string]$ModelSimBin='C:\intelFPGA_lite\18.1\modelsim_ase\win32aloem',
      [string]$QuartusBin='C:\intelFPGA_lite\18.1\quartus\bin64')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path "$root\build\verify" | Out-Null
Push-Location "$root\build\verify"
try {
    if (-not (Test-Path modelsim.ini)) { & "$ModelSimBin\vmap.exe" -c }
    if (-not (Test-Path work)) { & "$ModelSimBin\vlib.exe" work }
    & "$ModelSimBin\vlog.exe" -vlog01compat "$root\rtl\reset_sync.v" "$root\rtl\chess_board.v" "$root\rtl\chess.v" "$root\sim\tb_chess.v" "$root\sim\tb_chess_board.v" "$root\sim\tb_v101.v"
    if ($LASTEXITCODE -ne 0) { throw 'Verilog compilation failed' }
    $commands='onerror {quit -code 1 -force}; onbreak {resume}; vsim work.tb_v101; onfinish stop; run -all; if {[examine -radix unsigned /tb_v101/passed] != 1} {quit -code 1 -force}; quit -code 0 -force'
    & "$ModelSimBin\vsim.exe" -c -l simulation.log -do $commands
    if ($LASTEXITCODE -ne 0) { throw 'Reset/top-level tests failed' }
    # Existing standalone board test: also check the moved board and final reset.
    $commands='onerror {quit -code 1 -force}; vsim work.tb_chess_board; run 120 ns; if {[examine -radix unsigned /tb_chess_board/board_under_test/board_squares(12)] != 0 || [examine -radix unsigned /tb_chess_board/board_under_test/board_squares(28)] != 1} {quit -code 1 -force}; run 100 ns; if {[examine -radix unsigned /tb_chess_board/board_under_test/board_squares(12)] != 1 || [examine -radix unsigned /tb_chess_board/board_under_test/board_squares(28)] != 0} {quit -code 1 -force}; puts {PASS board move and reset}; quit -code 0 -force'
    & "$ModelSimBin\vsim.exe" -c -l board.log -do $commands
    if ($LASTEXITCODE -ne 0) { throw 'Board move/reset test failed' }
} finally { Pop-Location }
Push-Location $root
try {
    & "$QuartusBin\quartus_sh.exe" --flow compile chess
    if ($LASTEXITCODE -ne 0) { throw 'Quartus compilation failed' }
    & "$QuartusBin\quartus_sta.exe" -t scripts/check_timing.tcl
    if ($LASTEXITCODE -ne 0) { throw 'Timing report generation failed' }
    if (Get-ChildItem output_files -Filter '*.rpt' | Select-String 'Critical Warning') { throw 'Critical Quartus warnings remain' }
    $summary=Get-Content -Raw output_files/chess.sta.summary
    if ($summary -match 'Slack\s*:\s*-' -or $summary -notmatch 'Type\s*:.*Setup') { throw 'Timing failed or no setup paths checked' }
    $ucp=Get-Content -Raw build/verify/unconstrained.txt
    $rows=[regex]::Matches($ucp,'(?m)^;\s*(?:Illegal Clocks|Unconstrained[^;]+)\s*;\s*(\d+)\s*;\s*(\d+)\s*;')
    if($rows.Count -ne 6) { throw 'Unexpected unconstrained-path report' }
    foreach($row in $rows) { if([int]$row.Groups[1].Value -ne 0 -or [int]$row.Groups[2].Value -ne 0) { throw 'Unconstrained paths remain' } }
    Write-Host 'PASS v1.0.1 simulation, compilation and timing checks'
} finally { Pop-Location }
