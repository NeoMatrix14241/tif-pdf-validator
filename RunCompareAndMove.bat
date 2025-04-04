@echo off
title Pang hanap ni kyle ng hindi ma-OCR ni abbyy
setlocal EnableDelayedExpansion
cls

echo GitHub Copilot File Comparison and Move Tool
echo Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): %date:~10,4%-%date:~4,2%-%date:~7,2% %time:~0,8%
echo Current User's Login: %USERNAME%
echo ================================================

:INPUT_PATH
echo.
echo Input/Archive Path
echo -----------------
echo This should be the path to either:
echo  1. Your Input folder with TIF files
echo  2. Your Archive folder with TIF files
echo Example: D:\DOE\for ocr\INPUT or D:\DOE\for ocr\ARCHIVE
echo.
set /p "inputPath=Please enter the INPUT/ARCHIVE path (where your TIF files are): "
if "!inputPath!"=="" (
    echo Input/Archive path cannot be empty!
    goto INPUT_PATH
)
if not exist "!inputPath!" (
    echo Warning: Input/Archive path does not exist!
    choice /C YN /M "Do you want to try again"
    if !errorlevel!==1 goto INPUT_PATH
)

:OUTPUT_PATH
echo.
echo Output Path
echo -----------
echo This should be the path where your PDF files are located
echo Example: D:\DOE\for ocr\OUTPUT
echo.
set /p "outputPath=Please enter the OUTPUT path (where your PDF files are): "
if "!outputPath!"=="" (
    echo Output path cannot be empty!
    goto OUTPUT_PATH
)
if not exist "!outputPath!" (
    echo Warning: Output path does not exist!
    choice /C YN /M "Do you want to try again"
    if !errorlevel!==1 goto OUTPUT_PATH
)

:MOVE_PATH
echo.
echo Move Path
echo ---------
echo This is where unmatched TIF files will be moved to
echo The log file will also be saved in this location
echo Example: D:\DOE\for ocr\UNMATCHED
echo.
set /p "movePath=Please enter the path where unmatched files should be MOVED to: "
if "!movePath!"=="" (
    echo Move path cannot be empty!
    goto MOVE_PATH
)

echo.
echo Please review your selections:
echo ================================================
echo Input/Archive Path: !inputPath!
echo Output Path:       !outputPath!
echo Move Path:         !movePath!
echo Log File will be saved in the Move Path
echo ================================================
echo.

choice /C YN /M "Are these paths correct"
if !errorlevel!==2 goto INPUT_PATH

:OPTIONS
echo.
echo Please select operation mode:
echo [1] Move unmatched files
echo [2] Copy unmatched files (keeps original files)
echo [3] Preview only (no changes will be made)
echo.
choice /C 123 /M "Select operation mode (1-3)"
set OPTIONS=
set OPERATION=
if !errorlevel!==1 (
    set "OPERATION=Move files"
    set "OPTIONS="
)
if !errorlevel!==2 (
    set "OPERATION=Copy files"
    set "OPTIONS=-CopyOnly"
)
if !errorlevel!==3 (
    set "OPERATION=Preview only"
    set "OPTIONS=-WhatIf"
)

echo.
choice /C YN /M "Do you want to enable detailed logging"
if !errorlevel!==1 set OPTIONS=!OPTIONS! -DetailedLog

echo.
echo Configuration Summary:
echo ================================================
echo Operation Mode:     !OPERATION!
echo Detailed Logging:   !OPTIONS:~-10!
echo Log File Location:  !movePath!
echo ================================================
echo.
choice /C YN /M "Do you want to proceed with these settings"
if !errorlevel!==2 goto OPTIONS

echo.
echo Starting file comparison and !OPERATION! process...
echo ================================================
echo Log file will be created in: !movePath!
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0CompareAndMove.ps1" -inputPath "!inputPath!" -outputPath "!outputPath!" -movePath "!movePath!" !OPTIONS!

if !errorlevel! neq 0 (
    echo.
    echo Error occurred during execution
    pause
    exit /b 1
)

echo.
echo Script completed successfully!
echo A detailed log file has been created in: !movePath!
echo Log filename: FileComparisonLog_[DateTime].log
echo.
pause
