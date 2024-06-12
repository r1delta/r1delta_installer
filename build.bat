@echo off
REM **************** R1DELTA INSTALLER BUILDER ****************
REM This batch script builds the r1delta_installer executable
REM file. Love2D, 7-Zip and ResourceHacker are required, their 
REM paths should be added to "config.cmd". You can find an 
REM example config.cmd in "config.cmd.example".
REM **************** R1DELTA INSTALLER BUILDER ****************

@echo off
setlocal enabledelayedexpansion

echo **************** R1DELTA INSTALLER BUILDER ****************

REM Load config.cmd
if exist config.cmd (
    call config.cmd
    set "PATH=!LOVE_PATH!;!7ZIP_PATH!;!RESH_PATH!;%PATH%"

    where /q love.exe
    if ERRORLEVEL 1 (
        echo Could not find love.exe in PATH. Please check your config.cmd
        exit /b
    )

    where /q 7z.exe
    if ERRORLEVEL 1 (
        echo Could not find 7z.exe in PATH. Please check your config.cmd
        exit /b
    )

    where /q ResourceHacker.exe
    if ERRORLEVEL 1 (
        echo Could not find ResourceHacker.exe in PATH. Please check your config.cmd
        exit /b
    )
) else (
    echo config.cmd file not found. 
    exit /b  
)

echo Cleaning up folders...
if exist "build/" ( rmdir /S /Q "build/"  )
if exist "intermediate/" ( rmdir /S /Q "intermediate/" )

mkdir build
mkdir intermediate

echo Copying intermediate Love2D files...
copy /V /Y "%LOVE_PATH%\love.exe" /B "intermediate\" > nul
copy /V /Y "%LOVE_PATH%\love.dll" /B "intermediate\" > nul
copy /V /Y "%LOVE_PATH%\lua51.dll" /B "intermediate\" > nul   
rem copy /V /Y "%LOVE_PATH%\OpenAL32.dll" /B "intermediate\" > nul   
copy /V /Y "%LOVE_PATH%\SDL2.dll" /B "intermediate\" > nul   

cd source
echo Zipping up Lua files...
7z.exe a ..\intermediate\build.zip * >nul
move ..\intermediate\build.zip ..\intermediate\build.love >nul
cd ..

echo Building executable...
cd intermediate
copy /b love.exe + build.love r1delta_installer.exe >nul

ResourceHacker.exe -open r1delta_installer.exe -save r1delta_installer.exe -action addoverwrite -res ..\r1delta_installer_patch.res -mask ,,, >nul
 
echo Building 7-Zip archive...
rem 7z.exe a -y r1delta_installer.7z r1delta_installer.exe love.dll lua51.dll OpenAL32.dll SDL2.dll >nul
7z.exe a -y r1delta_installer.7z r1delta_installer.exe love.dll lua51.dll SDL2.dll >nul

echo Building 7-Zip SFX archive...
copy /V /Y "!7ZIP_PATH!\7zS2.sfx" /B "7zS2.sfx" >nul
copy /b 7zS2.sfx + "..\config.txt" + r1delta_installer.7z "..\build\r1delta_installer.exe" >nul  
cd ..

echo Patching 7-Zip SFX archive...
cd build
ResourceHacker.exe -open r1delta_installer.exe -save r1delta_installer.exe -action addoverwrite -res ..\r1delta_installer_patch.res -mask ,,, >nul

echo **************** R1DELTA INSTALLER BUILDER ****************