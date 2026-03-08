@echo off
cd /d "%~dp0"
echo パスビューア起動中...
start http://localhost:8090/
python server.py
