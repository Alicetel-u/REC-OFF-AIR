$projectDir = $PSScriptRoot
$godot = Join-Path $projectDir "Godot_v4.6.1-stable_win64_console.exe"

if (-not (Test-Path $godot)) {
    Write-Host "[ERROR] Godot not found: $godot"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Launching Godot..."
Start-Process -FilePath $godot -ArgumentList "--path `"$projectDir`" --editor"
