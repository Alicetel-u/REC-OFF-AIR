@echo off
echo === push-all ===
echo.

:: 未コミットのファイルを確認
git status --short > tmp_status.txt
set /p STATUS_CHECK=<tmp_status.txt
del tmp_status.txt

git status --short
echo.

for /f %%i in ('git status --short ^| find /c /v ""') do set COUNT=%%i

if %COUNT% GTR 0 (
    echo [警告] 未コミットのファイルが %COUNT% 件あります！
    echo 上のリストを確認してください。
    echo.
    choice /M "このままpushしますか？"
    if errorlevel 2 (
        echo キャンセルしました。
        pause
        exit /b
    )
)

echo.
echo --- pushing all branches ---
for /f "delims=" %%b in ('git branch --format "%%(refname:short)"') do (
    echo pushing %%b...
    git push origin %%b
)
echo.
echo === done ===
pause
