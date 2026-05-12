Add-Type -AssemblyName System.Drawing

$topCrop    = 125
$bottomCrop = 145
$srcDir     = "$PSScriptRoot\raw"
$outDir     = "$PSScriptRoot\cropped"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Get-ChildItem $srcDir -Filter "*.png" | ForEach-Object {
    $img    = [System.Drawing.Image]::FromFile($_.FullName)
    $newH   = $img.Height - $topCrop - $bottomCrop
    $srcRect = [System.Drawing.Rectangle]::new(0, $topCrop, $img.Width, $newH)
    $dstRect = [System.Drawing.Rectangle]::new(0, 0,        $img.Width, $newH)
    $bmp    = New-Object System.Drawing.Bitmap($img.Width, $newH)
    $g      = [System.Drawing.Graphics]::FromImage($bmp)
    $g.DrawImage($img, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $img.Dispose()
    $out = Join-Path $outDir $_.Name
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Done: $($_.Name)  ->  $($img.Width) x $newH"
}

Write-Host "`nAll done! Output: $outDir"
