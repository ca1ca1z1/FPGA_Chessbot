param([string]$QuartusBin = 'C:\intelFPGA_lite\18.1\quartus\bin64')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location (Join-Path $root 'quartus')
try {
    & (Join-Path $QuartusBin 'quartus_sh.exe') --flow compile FPGA_Chessbot
    if ($LASTEXITCODE -ne 0) { throw 'Quartus compilation failed' }
    & (Join-Path $QuartusBin 'quartus_sta.exe') -t ../scripts/check_timing.tcl
    if ($LASTEXITCODE -ne 0) { throw 'Timing verification failed' }
    $reports = Get-ChildItem -LiteralPath 'output_files' -Filter '*.rpt'
    if ($reports | Select-String -Pattern 'Critical Warning') {
        throw 'Quartus reported a critical warning; review the generated reports'
    }
    # Include minimum-pulse-width checks from the normal multicorner STA run.
    $summary = Get-Content -Raw -LiteralPath 'output_files\FPGA_Chessbot.sta.summary'
    if ($summary -match 'Slack\s*:\s*-') { throw 'Negative slack in STA summary' }
    $ucp = Get-Content -Raw -LiteralPath '..\build\timing\unconstrained.txt'
    $rows = [regex]::Matches($ucp, '(?m)^;\s*(?:Illegal Clocks|Unconstrained[^;]+)\s*;\s*(\d+)\s*;\s*(\d+)\s*;')
    if ($rows.Count -ne 6) { throw 'Unrecognized unconstrained-path report format' }
    foreach ($row in $rows) {
        if ([int]$row.Groups[1].Value -ne 0 -or [int]$row.Groups[2].Value -ne 0) {
            throw 'Unexpected unconstrained path or illegal clock'
        }
    }
    $checks = Get-Content -Raw -LiteralPath '..\build\timing\check_timing.txt'
    $expected = @{ virtual_clock=1; no_input_delay=5; no_output_delay=11 }
    $rows = [regex]::Matches($checks, '(?m)^;\s*(\w+)\s*;\s*(\d+)\s*;')
    if ($rows.Count -lt 20) { throw 'Unrecognized check_timing report format' }
    foreach ($row in $rows) {
        $name=$row.Groups[1].Value
        $allowed=0
        if ($expected.ContainsKey($name)) { $allowed=$expected[$name] }
        if ([int]$row.Groups[2].Value -ne $allowed) { throw "Unexpected timing diagnostic: $name" }
    }
    Write-Host 'BUILD VERIFIED: no critical warnings, no negative slack, no unconstrained paths.'
} finally { Pop-Location }
