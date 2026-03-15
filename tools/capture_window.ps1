Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinAPI {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
    public delegate bool EnumCallback(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumCallback cb, IntPtr lParam);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
$found = [IntPtr]::Zero
[WinAPI]::EnumWindows({
    param($hWnd, $lParam)
    if (-not [WinAPI]::IsWindowVisible($hWnd)) { return $true }
    $sb = New-Object System.Text.StringBuilder 256
    [WinAPI]::GetWindowText($hWnd, $sb, 256) | Out-Null
    $title = $sb.ToString()
    if ($title -like "*Ghost Streamer*" -or $title -like "*REC-OFF-AIR*") {
        $script:found = $hWnd
        return $false
    }
    return $true
}, [IntPtr]::Zero) | Out-Null

if ($found -eq [IntPtr]::Zero) {
    Write-Host "Game window not found"
    exit 1
}

[WinAPI]::SetForegroundWindow($found) | Out-Null
Start-Sleep -Milliseconds 300

$r = New-Object WinAPI+RECT
[WinAPI]::GetWindowRect($found, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$h = $r.Bottom - $r.Top
Write-Host "Window: ${w}x${h} at ($($r.Left),$($r.Top))"

$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size $w, $h))
$g.Dispose()
$bmp.Save("C:\repos\REC-OFF-AIR\screenshot_win.png")
$bmp.Dispose()
Write-Host "Saved screenshot_win.png"
