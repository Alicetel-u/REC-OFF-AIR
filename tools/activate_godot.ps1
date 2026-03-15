Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32G {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$procs = Get-Process -Name "godot" -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    if ($p.MainWindowHandle -ne 0) {
        [Win32G]::ShowWindow($p.MainWindowHandle, 9)
        [Win32G]::SetForegroundWindow($p.MainWindowHandle)
        Write-Output "Activated: $($p.MainWindowTitle)"
    }
}
