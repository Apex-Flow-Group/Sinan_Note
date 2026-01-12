@echo off
setlocal enabledelayedexpansion

echo.
echo ==========================================
echo    Sinan Note - APK Installer
echo    Copyright © 2025 Apex Flow Group
echo ==========================================
echo.

where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  ADB not in PATH
    echo Please add Android SDK platform-tools to your PATH
    exit /b 1
)

echo 📱 SELECT FLAVOR TO INSTALL:
echo.
echo   1) Google Play (No P2P Transfer^)
echo   2) F-Droid (Full Features^)
echo.
set /p FLAVOR_CHOICE="Enter choice (1-2): "

if "%FLAVOR_CHOICE%"=="1" (
    set FLAVOR=googlePlay
    set FLAVOR_NAME=Google Play
) else if "%FLAVOR_CHOICE%"=="2" (
    set FLAVOR=fDroid
    set FLAVOR_NAME=F-Droid
) else (
    echo ❌ Invalid choice!
    exit /b 1
)

set APK_FILE=build\app\outputs\flutter-apk\app-%FLAVOR%-release.apk

if not exist "!APK_FILE!" (
    echo.
    echo ❌ APK not found: !APK_FILE!
    echo.
    echo Build it first:
    echo   build_android.bat %FLAVOR_CHOICE%
    echo.
    exit /b 1
)

echo.
echo 📱 Installing %FLAVOR_NAME% APK...
echo.

adb install -r "!APK_FILE!"

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo ✅ %FLAVOR_NAME% installed successfully!
    echo ==========================================
    echo.
) else (
    echo.
    echo ==========================================
    echo ❌ Installation failed!
    echo Make sure:
    echo - Device is connected
    echo - USB debugging is enabled
    echo - ADB drivers are installed
    echo ==========================================
    exit /b 1
)
