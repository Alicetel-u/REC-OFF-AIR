Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$procs = Get-Process | Where-Object { $_.MainWindowTitle -like '*Path Viewer*' -or $_.MainWindowTitle -like '*localhost*' -or $_.MainWindowTitle -like '*Chrome*' -or $_.MainWindowTitle -like '*Edge*' }
foreach ($p in $procs) {
    if ($p.MainWindowHandle -ne 0) {
        [Win32]::ShowWindow($p.MainWindowHandle, 9)
        [Win32]::SetForegroundWindow($p.MainWindowHandle)
        Write-Output "Activated: $($p.MainWindowTitle)"
    }
}
