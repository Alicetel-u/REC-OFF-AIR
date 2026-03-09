@echo off
cd /d "%~dp0"
set GODOT_PATH="%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.1-stable_win64.exe"
%GODOT_PATH% -e
