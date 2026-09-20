@echo off
rem One pane per service, each following that service's logs. Read-only: nothing
rem is started, stopped or rebuilt. Sources come from runner\logs.conf.
rem Windows half of general-manager\bash\lib\logs.sh.
if not defined GM_TOOLS_DIR (echo logs.cmd must be invoked from a runner wrapper 1>&2 & exit /b 1)
set "GM_LIB=%~dp0"
if "%GM_LIB:~-1%"=="\" set "GM_LIB=%GM_LIB:~0,-1%"

set "MODE=auto"
set "SERVICES="
set "WITH_INFRA=0"
set "LINES_CLI="
set "DRY=0"
:args
if "%~1"=="" goto :argsdone
set "A=%~1"
if /i "%A%"=="--docker"      (set "MODE=docker"      & shift & goto :args)
if /i "%A%"=="--manual"      (set "MODE=manual"      & shift & goto :args)
if /i "%A%"=="--with-infra"  (set "WITH_INFRA=1"     & shift & goto :args)
if /i "%A%"=="--dry-run"     (set "DRY=1"            & shift & goto :args)
if /i "%A%"=="--wezterm"     (set "GM_TERMINAL=wezterm" & shift & goto :args)
if /i "%A%"=="--wt"          (set "GM_TERMINAL=wt"   & shift & goto :args)
if /i "%A%"=="--no-terminal" (set "GM_TERMINAL=none" & shift & goto :args)
if /i "%A:~0,11%"=="--services=" (set "SERVICES=%A:~11:,= %" & shift & goto :args)
if /i "%A:~0,8%"=="--lines="     (set "LINES_CLI=%A:~8%"     & shift & goto :args)
if /i "%A:~0,11%"=="--terminal=" (set "GM_TERMINAL=%A:~11%"  & shift & goto :args)
if /i "%A%"=="-h"     goto :usage
if /i "%A%"=="--help" goto :usage
echo unknown option: %A% 1>&2
exit /b 1
:usage
echo usage: logs.cmd [--docker^|--manual] [--services=a,b] [--with-infra] [--lines=N]
echo.
echo   Opens one pane per service, each following that service's logs.
echo   It only reads - nothing is started, stopped or rebuilt.
echo   Sources live in runner\logs.conf ^(override in logs.local.conf^).
exit /b 0
:argsdone

call "%GM_LIB%\tools.cmd" init || exit /b 1
call "%GM_TOOLS_DIR%\project.cmd" || exit /b 1

set "LOG_LINES=200"
call :readconf "%GM_TOOLS_DIR%\logs.conf"
call :readconf "%GM_TOOLS_DIR%\logs.local.conf"
rem logs.conf is read after the arguments, so a flag has to win over it
if defined LINES_CLI set "LOG_LINES=%LINES_CLI%"

if /i not "%MODE%"=="auto" goto :modeset
set "MODE=manual"
set "N=0"
:detect
set /a N+=1
if %N% GTR %SVC_COUNT% goto :detected
call set "_c=%%SVC_%N%_CONTAINER%%"
if defined _c docker ps --format "{{.Names}}" | findstr /x /c:"%_c%" >nul && set "MODE=docker"
goto :detect
:detected
echo ==^> mode: %MODE% ^(detected^)
goto :modedone
:modeset
echo ==^> mode: %MODE%
:modedone

if not defined SERVICES call :allservices
if "%WITH_INFRA%"=="1" call :addwaits

del /q "%RUN_DIR%\logs-*.cmd" 2>nul
> "%RUN_DIR%\env.cmd" echo @echo off
>>"%RUN_DIR%\env.cmd" echo set "GM_TAILER=%GM_TAILER%"
>>"%RUN_DIR%\env.cmd" echo set "LOG_LINES=%LOG_LINES%"

set "PLIST="
set "PANEN=0"
for %%s in (%SERVICES%) do call :pane %%s
if "%PANEN%"=="0" (
  echo error: nothing to follow in %MODE% mode - every selected service was skipped. 1>&2
  echo   Add the shared database with --with-infra, or follow containers with --docker. 1>&2
  exit /b 1
)
echo ==^> following %PANEN% service^(s^) - %LOG_LINES% lines of history
if "%DRY%"=="1" (echo ==^> dry run - scripts written to %RUN_DIR%, nothing launched & exit /b 0)
call "%GM_LIB%\tools.cmd" launch %PLIST%
exit /b %ERRORLEVEL%

:readconf
if not exist "%~1" exit /b 0
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~1") do if not "%%~b"=="" set "%%a=%%b"
exit /b 0

:allservices
set "N=0"
:allloop
set /a N+=1
if %N% GTR %SVC_COUNT% exit /b 0
call set "SERVICES=%%SERVICES%% %%SVC_%N%_NAME%%"
goto :allloop

:addwaits
rem one pane per readiness target (mysql, redis, ...) rather than a single
rem "infra", because an infra stack can be more than one container
if "%WAIT_COUNT%"=="0" (set "SERVICES=%SERVICES% infra" & exit /b 0)
set "N=0"
:waitloop
set /a N+=1
if %N% GTR %WAIT_COUNT% exit /b 0
call set "SERVICES=%%SERVICES%% %%WAIT_%N%_NAME%%"
goto :waitloop

:pane
set "SVC=%~1"
set "KEY=%MODE%_%SVC%"
set "KEY=%KEY:-=_%"
call set "SRC=%%%KEY%%%"
if not defined SRC (
  echo warn: %SVC%: no log source for %MODE% mode ^(%KEY% is empty in logs.conf^) - skipped 1>&2
  exit /b 0
)
set /a PANEN+=1
set "PANE=%RUN_DIR%\logs-%PANEN%-%SVC%.cmd"
> "%PANE%" echo @echo off
>>"%PANE%" echo call "%RUN_DIR%\env.cmd"
>>"%PANE%" echo title %SVC% logs
set "PFX=%SRC:~0,7%"
if /i "%PFX%"=="docker:" goto :panedocker
>>"%PANE%" echo echo ----- %SVC% logs - %SRC% -----
>>"%PANE%" echo call "%%GM_TAILER%%" "%SRC%" %%LOG_LINES%%
goto :panetail
:panedocker
set "CONTAINER=%SRC:~7%"
>>"%PANE%" echo echo ----- %SVC% logs - %CONTAINER% -----
>>"%PANE%" echo docker logs -f --tail %%LOG_LINES%% %CONTAINER%
:panetail
>>"%PANE%" echo echo.
>>"%PANE%" echo echo [%SVC%] stopped - type r to re-run, exit to close the pane
>>"%PANE%" echo cmd /k doskey r=call "%PANE%"
set "PLIST=%PLIST% "%PANE%""
exit /b 0
