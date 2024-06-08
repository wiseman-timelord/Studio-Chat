@echo off

:: Initialization
mode con: cols=40 lines=20
title StudioChat
cd /d %~dp0
echo =============( StudioChat )=============
color 80
echo.
echo Batch Initialized...
timeout /t 2 /nobreak >nul
echo.

:: Artwork
cls
echo =============( StudioChat )=============
timeout /t 2 /nobreak >nul

:: Program
echo Running StudioChat...
timeout /t 1 /nobreak >nul
start pwsh -NoExit -File .\main1.ps1
start pwsh -NoExit -File .\main2.ps1
echo ...StudioChat Exited.
timeout /t 1 /nobreak >nul
goto Exit

:: Exit
:Exit
echo.
echo ...Exit Process Initiated.
echo.
timeout /t 5 /nobreak >nul