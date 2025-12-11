@echo off
cd /d "%~dp0"
CALL C:\flutter\bin\flutter run -d windows
if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Build failed!
    echo ========================================
    pause
    exit /b 1
)
pause
