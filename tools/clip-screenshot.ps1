Add-Type -AssemblyName System.Windows.Forms
$img = [System.Windows.Forms.Clipboard]::GetImage()
if ($img) {
    $tmp = [System.IO.Path]::Combine($env:TEMP, "claude_clip.png")
    $img.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $tmp
} else {
    Write-Error "クリップボードに画像がありません"
    exit 1
}
