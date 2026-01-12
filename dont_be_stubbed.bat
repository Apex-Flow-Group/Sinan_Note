@echo off
REM Sinan Note - Golden Release Archiver (Windows)
REM Copyright (C) 2025 Apex Flow Group

echo 🎯 Creating Golden Release Archive...

REM Get current date in YYYY-MM-DD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set DATE_STAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%

REM Create archive
powershell Compress-Archive -Path * -DestinationPath "Sinan_Note_Golden_v2_%DATE_STAMP%.zip" -Force -Exclude *.git*,build,*.dart_tool,*.zip,.vscode,*.apk,*.aab

echo ✅ Archive created: Sinan_Note_Golden_v2_%DATE_STAMP%.zip
echo 📦 Ready for distribution!
pause
