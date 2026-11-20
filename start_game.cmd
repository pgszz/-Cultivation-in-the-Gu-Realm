@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start_game.ps1" %*
if errorlevel 1 (
    echo.
    echo Game startup failed. See the error and log path above.
    pause
    exit /b 1
)
