Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('{PRTSC}')
Start-Sleep -Milliseconds 800
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $img.Save('C:\repos\REC-OFF-AIR\screenshot_prol3.png')
    Write-Host "Saved: $($img.Width)x$($img.Height)"
} else {
    Write-Host "No image in clipboard"
}
