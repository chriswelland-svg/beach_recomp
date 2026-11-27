@echo off
setlocal EnableExtensions
title Beach Spikers - optimise for this PC
rem Builds a game module tuned to how the game really runs on this PC
rem (profile-guided optimisation, PGO). Put this file next to "Beach Spikers.exe".
rem
rem   1. Builds a "measuring" version of the game module (10-25 minutes).
rem   2. Starts the game. PLAY NORMALLY for 5-10 minutes: menus, a few full
rem      matches, replays. It runs SLOWLY while it measures - that is expected.
rem      Then close the game window normally (not with Task Manager).
rem   3. Builds the optimised module from those measurements (10-25 minutes)
rem      and makes the launcher use it. The previous module is kept as
rem      g<disc>_recomp.before-pgo.dll next to it.

set "PKG=%~dp0"
set "TC=%PKG%Toolchain"
set "UD=%LOCALAPPDATA%\moderngekko"
set "MODULES=%UD%\StaticRecompModules"
set "OUT=%MODULES%\build"

if not exist "%PKG%moderngekko-port.exe" goto :wrong_folder
set "REGION="
for %%R in (GBSE8P GBSP8P GBSJ8P) do if not defined REGION if exist "%UD%\games\%%R\sys\main.dol" set "REGION=%%R"
if not defined REGION goto :no_game

rem pgo-run looks up clang and llvm-profdata by name: put the bundled ones first.
set "PATH=%TC%\mingw\bin;%TC%\cmake\bin;%TC%\bin;%TC%\python;%PATH%"

echo Optimising Beach Spikers (%REGION%) for this PC.
echo When the game window opens: play normally for 5-10 minutes, then close it.
echo.
"%PKG%moderngekko-port.exe" pgo-run "%UD%\games\%REGION%" --output "%OUT%" --opt-level 2 --no-lto --compiler "%TC%\mingw\bin\clang.exe" --ninja "%TC%\bin\ninja.exe" --python "%TC%\python\python.exe" --cmake "%TC%\cmake\bin\cmake.exe" --llvm-profdata "%TC%\mingw\bin\llvm-profdata.exe" -- --user-dir "%UD%"
if errorlevel 1 goto :failed

set "ACTIVE="
set /p ACTIVE=<"%OUT%\%REGION%\active-module.txt"
if not defined ACTIVE goto :failed
if not exist "%ACTIVE%" goto :failed
set "TARGET=%MODULES%\g%REGION%_recomp.dll"
set "BACKUP=%MODULES%\g%REGION%_recomp.before-pgo.dll"
if exist "%TARGET%" if not exist "%BACKUP%" copy /y "%TARGET%" "%BACKUP%" >nul
copy /y "%ACTIVE%" "%TARGET%" >nul
if errorlevel 1 goto :failed
echo.
echo Done. Start "Beach Spikers.exe" as usual - it now uses the optimised module.
echo To undo: delete %TARGET%
echo and rename %BACKUP% to g%REGION%_recomp.dll
pause
exit /b 0

:wrong_folder
echo Put this file in the same folder as "Beach Spikers.exe".
pause
exit /b 1

:no_game
echo No extracted game found in %UD%\games.
echo Start "Beach Spikers.exe" once, pick your disc and let it build first.
pause
exit /b 1

:failed
echo.
echo The optimisation did not finish. Your current module was not changed.
echo Please send the text above this line.
pause
exit /b 1
