@echo off
cd /d "%~dp0"
echo ==============================
echo  REC-OFF-AIR Dev Tools Server
echo ==============================
echo.
echo  Dashboard:       http://localhost:8090/
echo  Path Viewer:     http://localhost:8090/path-viewer/
echo  Dialogue Editor: http://localhost:8090/dialogue-editor/
echo.
start http://localhost:8090/
python server.py
pause
