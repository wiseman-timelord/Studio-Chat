:: Script `.\Studio-Chat.Bat`

:: Initialization
@echo off

:: Initialization
title StudioChat Launcher
cd /d %~dp0
echo ========================================================================================================================
echo     Studio-Chat
echo ========================================================================================================================
color 80
echo.
echo Batch Initialized.
echo.
timeout /t 2 /nobreak >nul

:: Launch Program
echo Running StudioChat..
timeout /t 1 /nobreak >nul

:: Try running with pwsh
pwsh -NoExit -File .\launch_engine.ps1
if %errorlevel% neq 0 (
    echo Missing File: pwsh.exe
    timeout /t 2 /nobreak >nul
    :: Try running with powershell
    powershell -NoExit -File .\launch_engine.ps1
    if %errorlevel% neq 0 (
        echo Missing File: powershell.exe
        timeout /t 2 /nobreak >nul
        echo Pwsh and Powershell Not Found!
        timeout /t 3 /nobreak >nul
        goto :Exit
    )
)

echo ..StudioChat Executed.
goto Exit

:: Exit Launcher
:Exit
echo.
echo Exititing Batch.
echo.
timeout /t 5 /nobreak >nul