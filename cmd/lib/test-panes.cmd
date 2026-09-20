@echo off
rem Exercise the pane launcher with dummy services - no docker, no dotnet.
rem Each pane writes a marker file, so this reports whether the panes actually
rem RAN, not just whether a window opened.
rem Windows half of general-manager\bash\lib\test-panes.sh.
if not defined GM_TOOLS_DIR (echo test-panes.cmd must be invoked from a runner wrapper 1>&2 & exit /b 1)
set "GM_LIB=%~dp0"
if "%GM_LIB:~-1%"=="\" set "GM_LIB=%GM_LIB:~0,-1%"

set "PANES=4"
set "HOLD=60"
set "TIMEOUT=30"
set "KEEP=0"
:args
if "%~1"=="" goto :argsdone
set "A=%~1"
if /i "%A%"=="--keep"        (set "KEEP=1"           & shift & goto :args)
if /i "%A%"=="--wezterm"     (set "GM_TERMINAL=wezterm" & shift & goto :args)
if /i "%A%"=="--wt"          (set "GM_TERMINAL=wt"   & shift & goto :args)
if /i "%A%"=="--no-terminal" (set "GM_TERMINAL=none" & shift & goto :args)
if /i "%A:~0,8%"=="--panes="    (set "PANES=%A:~8%"    & shift & goto :args)
if /i "%A:~0,7%"=="--hold="     (set "HOLD=%A:~7%"     & shift & goto :args)
if /i "%A:~0,10%"=="--timeout=" (set "TIMEOUT=%A:~10%" & shift & goto :args)
if /i "%A%"=="-h"     goto :usage
if /i "%A%"=="--help" goto :usage
echo unknown option: %A% 1>&2
exit /b 1
:usage
echo usage: test.cmd [--panes=N] [--hold=SEC] [--timeout=SEC] [--keep] [--wezterm^|--wt^|--no-terminal]
echo.
echo   Launches N dummy panes through the same code path the run-* scripts use,
echo   waits for every pane to check in, then closes them again.
exit /b 0
:argsdone

call "%GM_LIB%\tools.cmd" init || exit /b 1
set "MARKER_DIR=%RUN_DIR%\test-markers"
if exist "%MARKER_DIR%" rd /s /q "%MARKER_DIR%"
md "%MARKER_DIR%"

del /q "%RUN_DIR%\test-*.cmd" 2>nul
set "PLIST="
set "N=0"
:write
set /a N+=1
if %N% GTR %PANES% goto :written
set "F=%RUN_DIR%\test-%N%-p%N%.cmd"
> "%F%" echo @echo off
>>"%F%" echo title test pane %N% of %PANES%
>>"%F%" echo echo ----- test pane %N% of %PANES% -----
>>"%F%" echo echo pane %N% alive at %%TIME%%
>>"%F%" echo echo cwd: %%CD%%
>>"%F%" echo echo tools dir reached me: %GM_TOOLS_DIR%
>>"%F%" echo type nul ^> "%MARKER_DIR%\p%N%"
>>"%F%" echo echo holding for %HOLD% s...
>>"%F%" echo timeout /t %HOLD% /nobreak ^>nul
>>"%F%" echo echo.
>>"%F%" echo echo [test pane %N%] stopped - type r to re-run, exit to close the pane
>>"%F%" echo cmd /k doskey r=call "%F%"
set "PLIST=%PLIST% "%F%""
goto :write
:written

echo ==^> test mode - %PANES% panes - terminal: %GM_TERMINAL%
call "%GM_LIB%\tools.cmd" launch %PLIST% || exit /b 1
if /i "%GM_TERMINAL%"=="none" (rd /s /q "%MARKER_DIR%" & exit /b 0)

<nul set /p "===> waiting for %PANES% panes to check in"
set "WAITED=0"
:poll
set "GOT=0"
for %%f in ("%MARKER_DIR%\p*") do set /a GOT+=1
if %GOT% GEQ %PANES% goto :polled
if %WAITED% GEQ %TIMEOUT% goto :polled
<nul set /p "=."
timeout /t 1 /nobreak >nul
set /a WAITED+=1
goto :poll
:polled
echo.

set "RC=0"
if %GOT% GEQ %PANES% (
  echo PASS  %GOT%/%PANES% panes started and ran their command
) else (
  echo FAIL  only %GOT%/%PANES% panes checked in within %TIMEOUT%s
  echo       pane scripts are in %RUN_DIR% - run one by hand to see why
  set "RC=1"
)

if "%KEEP%"=="1" goto :keepopen
if not defined W1 goto :nowez
where wezterm >nul 2>&1 || goto :nowez
set "N=0"
:killloop
set /a N+=1
if %N% GTR %PANES% goto :killed
call wezterm cli kill-pane --pane-id %%W%N%%% >nul 2>&1
goto :killloop
:killed
echo ==^> closed the test panes
goto :done
:keepopen
echo ==^> left open - close the panes yourself when done
goto :done
:nowez
echo warn: separate windows were opened - close them yourself
:done
rd /s /q "%MARKER_DIR%" 2>nul
exit /b %RC%
