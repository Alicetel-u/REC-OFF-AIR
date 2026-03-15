Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$tmp = [System.IO.Path]::Combine($env:TEMP, "claude_clip.png")
$data = [System.Windows.Forms.Clipboard]::GetDataObject()

if (-not $data) {
    Write-Error "クリップボードにデータがありません"
    exit 1
}

$img = $null

# 方法1: GetImage()
$img = [System.Windows.Forms.Clipboard]::GetImage()

# 方法2: PNG ストリームから読む
if (-not $img -and $data.GetDataPresent("PNG")) {
    $stream = $data.GetData("PNG")
    if ($stream) {
        $img = [System.Drawing.Image]::FromStream($stream)
    }
}

# 方法3: Bitmap形式
if (-not $img -and $data.GetDataPresent("System.Drawing.Bitmap")) {
    $img = $data.GetData("System.Drawing.Bitmap")
}

if ($img) {
    $img.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $tmp
} else {
    Write-Error "クリップボードから画像を取得できません (formats: $($data.GetFormats() -join ', '))"
    exit 1
}
