@echo off
rem tailer.cmd <glob-with-%DATE%> [lines]
rem Waits for the files to exist, lists what it found, then follows them.
rem Kept separate so a pane can be re-run after Ctrl-C.
setlocal enabledelayedexpansion
set "TPL=%~1"
set "LINES=%~2"
if not defined LINES set "LINES=200"

rem %DATE% in the pattern means today as YYYYMMDD (the app's log file naming)
for /f %%d in ('powershell -NoProfile -Command "(Get-Date).ToString(\"yyyyMMdd\")"') do set "TODAY=%%d"
set "PATTERN=!TPL:%%DATE%%=%TODAY%!"

:wait
dir /b "%PATTERN%" >nul 2>&1 && goto :found
<nul set /p "=no file matching %PATTERN% yet, waiting..."
powershell -NoProfile -Command "Start-Sleep -Seconds 3" >nul
echo.
goto :wait

:found
echo following:
for %%f in ("%PATTERN%") do echo   %%~ff
echo.
powershell -NoProfile -Command "Get-Content -Path '%PATTERN%' -Tail %LINES% -Wait"
endlocal
