@echo off
cd /d "%~dp0"

echo ========================================
echo   Apex Note - Run Release
echo ========================================
echo.

if exist "build\windows\x64\runner\Release\apex_note.exe" (
    echo Starting Apex Note...
    echo.
    start "" "build\windows\x64\runner\Release\apex_note.exe"
    
    if errorlevel 1 (
        echo.
        echo ========================================
        echo [ERROR] Failed to start
        echo ========================================
        echo.
        pause
    )
) else (
    echo ========================================
    echo [ERROR] Executable not found!
    echo ========================================
    echo.
    echo Please build first:
    echo   build_windows.bat
    echo.
    echo Or run in dev mode:
    echo   quick_run.bat
    echo.
    pause
)
