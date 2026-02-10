@echo off
setlocal enabledelayedexpansion

echo.
echo ==========================================
echo    Sinan Note - Android Builder
echo    Copyright © 2025 Apex Flow Group
echo ==========================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  Flutter not in PATH
    echo Please add Flutter to your PATH or run from Flutter directory
    exit /b 1
)

for /f "tokens=1" %%i in ('flutter --version') do set FLUTTER_VERSION=%%i
echo ✅ Flutter: %FLUTTER_VERSION%
echo.

if "%1"=="" (
    echo 📱 SELECT BUILD FLAVOR:
    echo.
    echo   1) Google Play (No P2P Transfer^)
    echo   2) F-Droid (Full Features^)
    echo   3) Both (Sequential^)
    echo.
    set /p CHOICE="Enter choice (1-3): "
) else (
    set CHOICE=%1
)

if "%CHOICE%"=="1" (
    echo 🎯 Building Google Play flavor...
    echo.
    call :build_flavor googlePlay "Google Play"
) else if "%CHOICE%"=="2" (
    echo 🎯 Building F-Droid flavor...
    echo.
    call :build_flavor fDroid "F-Droid"
) else if "%CHOICE%"=="3" (
    echo 🎯 Building both flavors (sequential^)...
    echo.
    
    echo ════════════════════════════════════════════════════════════════
    echo Building Google Play...
    echo ════════════════════════════════════════════════════════════════
    call :build_flavor googlePlay "Google Play"
    
    echo.
    echo ════════════════════════════════════════════════════════════════
    echo Building F-Droid...
    echo ════════════════════════════════════════════════════════════════
    call :build_flavor fDroid "F-Droid"
    
    echo.
    echo ==========================================
    echo ✅ Both builds completed successfully!
    echo ==========================================
    echo.
    echo 📁 APK Locations:
    echo   • Google Play: build\app\outputs\flutter-apk\app-googlePlay-release.apk
    echo   • F-Droid:     build\app\outputs\flutter-apk\app-fDroid-release.apk
) else (
    echo ❌ Invalid choice!
    exit /b 1
)

echo.
exit /b 0

:build_flavor
setlocal
set FLAVOR=%1
set FLAVOR_NAME=%2

echo 🧹 Cleaning...
call flutter clean

echo.
echo 📦 Getting packages...
call flutter pub get

echo.
echo 🔨 Building %FLAVOR_NAME% APK...
call flutter build apk --flavor %FLAVOR% --release -t lib/main.dart

if %errorlevel% equ 0 (
    echo.
    echo ✅ %FLAVOR_NAME% build completed!
    echo.
    
    set APK_PATH=build\app\outputs\flutter-apk\app-%FLAVOR%-release.apk
    if exist "!APK_PATH!" (
        for %%A in ("!APK_PATH!") do set SIZE=%%~zA
        echo 📁 Location: !APK_PATH!
        echo 💾 Size: !SIZE! bytes
    )
) else (
    echo.
    echo ❌ %FLAVOR_NAME% build failed!
    exit /b 1
)

endlocal
exit /b 0
