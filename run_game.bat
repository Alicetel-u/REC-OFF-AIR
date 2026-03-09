@echo off
cd /d "%~dp0"
set GODOT_PATH="%USERPROFILE%\OneDrive\デスクトップ\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe"
del game_crash_log.txt 2>nul
del game_stdout.txt 2>nul
%GODOT_PATH% --verbose > game_stdout.txt 2>&1
