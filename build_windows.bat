@echo off
cd /d "%~dp0"

echo [Status] Cleaning previous build...
CALL C:\flutter\bin\flutter clean

echo [Status] Getting dependencies...
CALL C:\flutter\bin\flutter pub get

echo [Status] Building Windows Release...
CALL C:\flutter\bin\flutter build windows --release --verbose

if %errorlevel% neq 0 (
    echo.
    echo [Error] Build Failed with error code %errorlevel%
    color 4
) else (
    echo.
    echo [Success] Build Completed Successfully!
    color 2
)

pause
