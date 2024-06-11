@echo off

:: Initialization
mode con: cols=30 lines=10
title StudioChat Launcher
cd /d %~dp0
echo ========( StudioChat )========
color 80
echo.
echo Batch Initialized.
echo.
timeout /t 2 /nobreak >nul

:: Launch Program
echo Running StudioChat..
timeout /t 1 /nobreak >nul
start pwsh -NoExit -File .\engine_window.ps1
timeout /t 1 /nobreak >nul
start pwsh -NoExit -File .\chat_window.ps1
timeout /t 1 /nobreak >nul
echo ..StudioChat Executed.
goto Exit

:: Exit Launcher
:Exit
echo.
echo Exititing Batch.
echo.
timeout /t 5 /nobreak >nul