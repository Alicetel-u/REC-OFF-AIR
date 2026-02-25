$ErrorActionPreference = "Stop"

$GODOT    = "C:\Users\RST-9\Desktop\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe"
$PROJECT  = Split-Path -Parent $MyInvocation.MyCommand.Path
$TPZ_URL  = "https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz"
$TPZ_PATH = "$env:APPDATA\Godot\export_templates\templates.tpz"
$TMPL_DIR = "$env:APPDATA\Godot\export_templates\4.6.1.stable"
$BUILD    = "$PROJECT\build"

# Resolve actual username for Godot path
$GODOT = "$env:USERPROFILE\Desktop\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe"

Write-Host "[deploy] Project: $PROJECT"
Write-Host "[deploy] Godot  : $GODOT"

# Step 1-2: Install export templates
if (-not (Test-Path "$TMPL_DIR\windows_release_x86_64.exe")) {
    New-Item -ItemType Directory -Force -Path $TMPL_DIR | Out-Null

    if (-not (Test-Path $TPZ_PATH)) {
        Write-Host "[1/4] Downloading export templates (~500MB)..."
        Invoke-WebRequest -Uri $TPZ_URL -OutFile $TPZ_PATH -UseBasicParsing
        Write-Host "      Download complete."
    } else {
        Write-Host "[1/4] TPZ already downloaded, skipping."
    }

    Write-Host "[2/4] Extracting templates..."
    $tmp    = "$env:TEMP\godot_tpz_extract"
    $tpzZip = "$env:TEMP\godot_templates.zip"
    if (Test-Path $tmp)    { Remove-Item $tmp    -Recurse -Force }
    if (Test-Path $tpzZip) { Remove-Item $tpzZip -Force }
    Copy-Item $TPZ_PATH $tpzZip
    Expand-Archive -Path $tpzZip -DestinationPath $tmp -Force
    Remove-Item $tpzZip -Force

    $inner = Join-Path $tmp "templates"
    $src   = if (Test-Path $inner) { $inner } else { $tmp }
    Copy-Item "$src\*" -Destination $TMPL_DIR -Recurse -Force
    Remove-Item $tmp -Recurse -Force
    Write-Host "      Templates installed."
} else {
    Write-Host "[1-2/4] Templates already installed, skipping."
}

# Step 3: Export
Write-Host "[3/4] Exporting game..."
New-Item -ItemType Directory -Force -Path $BUILD | Out-Null

& $GODOT --headless --path $PROJECT --export-release "Windows Desktop" "$BUILD\GhostStreamer.exe"

if (-not (Test-Path "$BUILD\GhostStreamer.exe")) {
    Write-Host "ERROR: Export failed." -ForegroundColor Red
    exit 1
}
Write-Host "      Export complete: $BUILD\GhostStreamer.exe"

# Step 4: ZIP
Write-Host "[4/4] Creating ZIP..."
$zip = "$PROJECT\GhostStreamer_build.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path "$BUILD\*" -DestinationPath $zip

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "  EXE : $BUILD\GhostStreamer.exe"
Write-Host "  ZIP : $zip"
