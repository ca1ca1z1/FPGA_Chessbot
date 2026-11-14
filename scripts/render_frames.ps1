param([string]$FrameDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\sim'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
foreach ($name in @('initial','selected','moved')) {
    $bytes = [IO.File]::ReadAllBytes((Join-Path $FrameDirectory "$name.ppm"))
    $header = [Text.Encoding]::ASCII.GetBytes("P6`n640 480`n255`n")
    if ($bytes.Length -ne $header.Length + 640*480*3) { throw "Invalid frame size: $name" }
    for ($i=0; $i -lt $header.Length; $i++) {
        if ($bytes[$i] -ne $header[$i]) { throw "Invalid PPM header: $name" }
    }
    $bitmap = New-Object Drawing.Bitmap 640,480,([Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $data = $bitmap.LockBits([Drawing.Rectangle]::new(0,0,640,480),
            [Drawing.Imaging.ImageLockMode]::WriteOnly,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
        try {
            $pixels = New-Object byte[] (640*480*3)
            for ($i=0; $i -lt $pixels.Length; $i+=3) {
                $pixels[$i]=$bytes[$header.Length+$i+2]
                $pixels[$i+1]=$bytes[$header.Length+$i+1]
                $pixels[$i+2]=$bytes[$header.Length+$i]
            }
            [Runtime.InteropServices.Marshal]::Copy($pixels,0,$data.Scan0,$pixels.Length)
        } finally { $bitmap.UnlockBits($data) }
        $bitmap.Save((Join-Path $FrameDirectory "$name.png"),[Drawing.Imaging.ImageFormat]::Png)
    } finally { $bitmap.Dispose() }
}
Write-Host 'Rendered initial.png, selected.png and moved.png from simulated VGA outputs.'
