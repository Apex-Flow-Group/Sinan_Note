@echo off
REM Google Play Build Script for Windows
REM Builds appbundle for Google Play flavor and saves to build\google folder

setlocal enabledelayedexpansion

echo 🚀 Starting Google Play Build...
echo.

REM Create output directory
if not exist "build\google" mkdir build\google

REM Build appbundle
echo 📦 Building appbundle for Google Play...
call flutter build appbundle --release --flavor googlePlay

if errorlevel 1 (
    echo ❌ Build failed!
    exit /b 1
)

REM Copy to google folder
echo 📁 Copying to build\google...
copy "build\app\outputs\bundle\googlePlayRelease\app-googlePlay-release.aab" "build\google\"

if errorlevel 1 (
    echo ❌ Copy failed!
    exit /b 1
)

REM Get file info
for %%A in ("build\google\app-googlePlay-release.aab") do set FILE_SIZE=%%~zA

echo.
echo ✅ Build Complete!
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 📍 Location: build\google\app-googlePlay-release.aab
echo 📊 Size: !FILE_SIZE! bytes
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pause
