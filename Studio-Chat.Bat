:: Script `.\Studio-Chat.Bat`

:: Initialization
@echo off
color 80
title Studio-Chat Launcher
cd /d %~dp0

:: Draw Banner and Begin
echo ========================================================================================================================
echo     Studio-Chat Batch Launcher
echo ========================================================================================================================
echo.
echo Batch Initialized.
timeout /t 1 /nobreak >nul

:: Launch Program
echo Running StudioChat..
timeout /t 1 /nobreak >nul
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
echo ..StudioChat Exited.
timeout /t 2 /nobreak >nul
goto Exit

:: Exit Launcher
:Exit
echo.
echo Exititing Batch.
echo.
timeout /t 5 /nobreak >nul