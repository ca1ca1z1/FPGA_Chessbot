param([string]$ModelSimBin = 'C:\intelFPGA_lite\18.1\modelsim_ase\win32aloem')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$env:CHESSBOT_ROOT = $root
$out = Join-Path $root 'build\sim'
New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $out
try {
    # Copy library mappings locally; never modify the installed modelsim.ini.
    if (-not (Test-Path -LiteralPath 'modelsim.ini')) {
        & (Join-Path $ModelSimBin 'vmap.exe') -c
        if ($LASTEXITCODE -ne 0) { throw 'ModelSim library setup failed' }
    }
    $doFile = (Join-Path $root 'sim\run.do').Replace('\','/')
    & (Join-Path $ModelSimBin 'vsim.exe') -c -l simulation.log -do "do {$doFile}"
    if ($LASTEXITCODE -ne 0) { throw 'Simulation failed; inspect build/sim/simulation.log' }
} finally { Pop-Location }
& (Join-Path $PSScriptRoot 'render_frames.ps1')
