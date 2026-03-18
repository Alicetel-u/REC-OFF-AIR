param(
    [int]$TimeoutSec = 120,
    [int]$DelayBeforeF11 = 10
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

$godotDir = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.6.1-stable_win64.exe"
if (-not (Test-Path "$godotDir\Godot_v4.6.1-stable_win64_console.exe")) {
    $godotDir = "$env:USERPROFILE\OneDrive\$([char]0x30C7)$([char]0x30B9)$([char]0x30AF)$([char]0x30C8)$([char]0x30C3)$([char]0x30D7)\Godot_v4.6.1-stable_win64.exe"
}
$godotExe = "$godotDir\Godot_v4.6.1-stable_win64_console.exe"
$projectDir = "C:\repos\REC-OFF-AIR"
$logFile = "$projectDir\game_autotest.txt"

Get-Process -Name "Godot_v4.6.1-stable_win64_console" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

Write-Host "[AutoTest] Launching game..."
$proc = Start-Process -FilePath $godotExe -ArgumentList "--verbose","--path",$projectDir -RedirectStandardOutput $logFile -RedirectStandardError "$projectDir\game_autotest_err.txt" -PassThru -WorkingDirectory $projectDir

Write-Host "[AutoTest] Waiting ${DelayBeforeF11}s before sending F11..."
Start-Sleep -Seconds $DelayBeforeF11

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class AutoTestWin {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

# ウィンドウタイトルで探す（複数候補）
$hwnd = [AutoTestWin]::FindWindow([NullString]::Value, "REC:OFF:AIR (DEBUG)")
if ($hwnd -eq [IntPtr]::Zero) {
    $hwnd = [AutoTestWin]::FindWindow([NullString]::Value, "Ghost Streamer (DEBUG)")
}
if ($hwnd -eq [IntPtr]::Zero) {
    Write-Host "[AutoTest] ERROR: Game window not found"
    if (-not $proc.HasExited) { $proc | Stop-Process -Force -ErrorAction SilentlyContinue }
    exit 1
}
[AutoTestWin]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 500

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{F11}")
Write-Host "[AutoTest] F11 sent - autotest started"

$startTime = Get-Date
$completed = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSec) {
    if ($proc.HasExited) {
        Write-Host "[AutoTest] Game process exited (code: $($proc.ExitCode))"
        $completed = $true
        break
    }
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
        if ($content -and $content.Contains("all chapters done")) {
            Write-Host "[AutoTest] All chapters completed!"
            $completed = $true
            Start-Sleep -Seconds 3
            break
        }
    }
    Start-Sleep -Seconds 2
}

if (-not $completed) {
    Write-Host "[AutoTest] Timeout (${TimeoutSec}s)"
}

if (-not $proc.HasExited) {
    $proc | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "========================================="
Write-Host "  AutoTest Result Report"
Write-Host "========================================="

if (Test-Path $logFile) {
    $log = Get-Content $logFile -Encoding UTF8 -ErrorAction SilentlyContinue

    $autoLines = $log | Where-Object { $_ -match "\[AutoTest\]" }
    if ($autoLines.Count -gt 0) {
        Write-Host ""
        Write-Host "--- AutoTest Log ---"
        $autoLines | ForEach-Object { Write-Host $_ }
    }

    $errors = $log | Where-Object { $_ -match "SCRIPT ERROR|ERROR:" } | Where-Object { $_ -notmatch "Loading|Orphan|Leaked|resource" }
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "--- Errors ($($errors.Count)) ---"
        $errors | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host ""
        Write-Host "Errors: None"
    }

    $warns = $log | Where-Object { $_ -match "WARNING:" } | Where-Object { $_ -notmatch "sfx not found" }
    if ($warns.Count -gt 0) {
        Write-Host ""
        Write-Host "--- Warnings ($($warns.Count)) ---"
        $warns | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    }
} else {
    Write-Host "Log file not found: $logFile"
}

Write-Host ""
Write-Host "========================================="
