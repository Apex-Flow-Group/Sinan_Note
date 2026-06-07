@echo off
setlocal EnableDelayedExpansion

echo.
echo ==========================================
echo      Sinan Note -- Windows Builder
echo ==========================================
echo.

:: 1. Flutter analyze
echo [1/3] Analyzing code...
call flutter analyze lib/ --no-pub > analyze_out.tmp 2>&1
type analyze_out.tmp | findstr /i "No issues found" >nul 2>&1
if errorlevel 1 (
    type analyze_out.tmp
    del analyze_out.tmp >nul 2>&1
    echo.
    echo [FAILED] flutter analyze found issues. Fix them before building.
    pause
    exit /b 1
)
del analyze_out.tmp >nul 2>&1
echo [OK] No issues found.
echo.

:: 2. Flutter build windows
echo [2/3] Building Windows release...
call flutter build windows --release > build_out.tmp 2>&1
type build_out.tmp | findstr /i "built error failed"
del build_out.tmp >nul 2>&1

if not exist "build\windows\x64\runner\Release\sinan_note.exe" (
    echo [FAILED] Build failed -- sinan_note.exe not found.
    pause
    exit /b 1
)
echo [OK] sinan_note.exe built successfully.
echo.

:: 3. Inno Setup
echo [3/3] Building installer...

set ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%ISCC%" (
    echo [FAILED] Inno Setup not found.
    echo          Install from: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

if not exist "installer" mkdir installer

"%ISCC%" "%~dp0windows\sinan_note_setup.iss" > inno_out.tmp 2>&1
type inno_out.tmp | findstr /i "Successful SinanNote_Setup Error"
type inno_out.tmp | findstr /i "Successful" >nul 2>&1
if errorlevel 1 (
    del inno_out.tmp >nul 2>&1
    echo [FAILED] Inno Setup compilation failed.
    pause
    exit /b 1
)
del inno_out.tmp >nul 2>&1

:: Find installer file
set INSTALLER=
for %%f in (installer\SinanNote_Setup_*.exe) do set INSTALLER=%%f

if not defined INSTALLER (
    echo [FAILED] Installer not found in installer\
    pause
    exit /b 1
)

echo.
echo ==========================================
echo            BUILD COMPLETE
echo ==========================================
echo.
echo   Installer: %INSTALLER%
for %%f in (%INSTALLER%) do echo   Size:      %%~zf bytes
echo.

explorer installer
endlocal