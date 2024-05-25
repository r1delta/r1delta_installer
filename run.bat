@echo off
setlocal enabledelayedexpansion

if exist config.cmd (
    call config.cmd
    set "PATH=!LOVE_PATH!;%PATH%"

    where /q love.exe
    if ERRORLEVEL 1 (
        echo Could not find love.exe in PATH. Please check your config.cmd
        exit /b
    )
)

cd source
love.exe ./