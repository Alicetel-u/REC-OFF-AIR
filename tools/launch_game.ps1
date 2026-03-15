$desktop = Join-Path $env:USERPROFILE "OneDrive\デスクトップ"
$candidates = @(
    (Join-Path $desktop "Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe"),
    (Join-Path $desktop "Godot_v4.6.1-stable_win64.exe"),
    (Join-Path $env:USERPROFILE "Desktop\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe")
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        Write-Host "Found: $c"
        Start-Process -FilePath $c -ArgumentList "--path","C:\repos\REC-OFF-AIR"
        exit 0
    }
}
# fallback: search where.exe
$found = where.exe godot 2>$null
if ($found) {
    Write-Host "Found via where: $found"
    Start-Process -FilePath $found -ArgumentList "--path","C:\repos\REC-OFF-AIR"
    exit 0
}
Write-Host "Godot not found. Candidates checked:"
foreach ($c in $candidates) { Write-Host "  $c" }
