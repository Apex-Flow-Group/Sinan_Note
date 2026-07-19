@echo off
chcp 65001 >nul
title Sinan Note - Release Build

echo.
echo ══════════════════════════════════════
echo   Sinan Note - Release AAB Build
echo ══════════════════════════════════════
echo.

:: Clean previous builds
echo [1/3] Cleaning previous builds...
call flutter clean
echo.

:: Get dependencies
echo [2/3] Getting dependencies...
call flutter pub get
echo.

:: Build AAB with obfuscation
echo [3/3] Building with maximum protection...
call flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols --android-skip-build-dependency-validation

:: Check result
echo.
if %ERRORLEVEL% EQU 0 (
    echo ══════════════════════════════════════
    echo   BUILD SUCCESSFUL
    echo ══════════════════════════════════════
    echo.
    echo   AAB: build\app\outputs\bundle\release\app-release.aab
    echo   Symbols: build\app\outputs\symbols\
    echo.
    echo   Keep symbols folder for crash reports!
    echo ══════════════════════════════════════
) else (
    echo ══════════════════════════════════════
    echo   BUILD FAILED!
    echo ══════════════════════════════════════
)

echo.
pause
