@echo off
cd /d "C:\repos\REC-OFF-AIR"
del game_crash_log.txt 2>nul
del game_stdout.txt 2>nul
"C:\repos\REC-OFF-AIR\godot.exe" --verbose > "C:\repos\REC-OFF-AIR\game_stdout.txt" 2>&1
