# Google Play "Image de présentation" / feature graphic: 1024 x 500 PNG
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$iconPath = Join-Path $root 'assets\icons\splash-icon.png'
$outPath = Join-Path $root 'assets\images\play-feature-graphic-1024x500.png'

if (-not (Test-Path $iconPath)) {
    Write-Error "Missing: $iconPath"
    exit 1
}

$W = 1024
$H = 500
# AppTheme.splashBackgroundColor #F5F7FA
$bg = [System.Drawing.Color]::FromArgb(255, 245, 247, 250)

$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear($bg)

$icon = [System.Drawing.Image]::FromFile($iconPath)
# Marge confort + zone "safe" Play : icône pas trop grande
$padX = 140
$padY = 60
$maxW = $W - $padX
$maxH = $H - $padY
$scale = [Math]::Min($maxW / $icon.Width, $maxH / $icon.Height)
$iw = [int][Math]::Round($icon.Width * $scale)
$ih = [int][Math]::Round($icon.Height * $scale)
$ix = [int](($W - $iw) / 2)
$iy = [int](($H - $ih) / 2)
$g.DrawImage($icon, $ix, $iy, $iw, $ih)
$g.Dispose()
$icon.Dispose()

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$f = Get-Item $outPath
Write-Host "OK: $outPath ($($f.Length) bytes, $($W)x$H)"
