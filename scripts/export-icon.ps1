# Export the approved artwork; no redraw or image API call.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'branding/qinglong-icon.png'))
function Export-Icon([string]$RelativePath, [int]$Size, [double]$Scale = 1) {
    $path = Join-Path $projectRoot $RelativePath
    [System.IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $edge = [int][Math]::Round($Size * $Scale)
        $offset = [int][Math]::Round(($Size - $edge) / 2)
        $graphics.DrawImage($source, $offset, $offset, $edge, $edge)
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}
try {
    Export-Icon 'assets/images/ql.png' 512
    Export-Icon 'assets/images/ql_white.png' 512
    Export-Icon 'assets/images/ql_splash.png' 512
    foreach ($entry in @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}.GetEnumerator()) {
        Export-Icon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png" $entry.Value
    }
    # Include the source's slight off-center placement within the 66/108 safe circle.
    Export-Icon 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png' 432 0.68
} finally { $source.Dispose() }
