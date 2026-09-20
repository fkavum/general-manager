@echo off
rem Generic launcher shared by every <project>-manager\tools\cmd\runner.
rem   run.cmd docker   - every service in Docker, attached
rem   run.cmd manual   - infra in Docker, the services built and run from source
rem The project describes itself in runner\project.cmd; nothing here is project
rem specific. Windows half of general-manager\bash\lib\run.sh.
if not defined GM_TOOLS_DIR (echo run.cmd must be invoked from a runner wrapper 1>&2 & exit /b 1)
set "GM_LIB=%~dp0"
if "%GM_LIB:~-1%"=="\" set "GM_LIB=%GM_LIB:~0,-1%"

set "MODE=%~1"
if /i not "%MODE%"=="docker" if /i not "%MODE%"=="manual" (echo usage: run.cmd ^<docker^|manual^> [options] 1>&2 & exit /b 1)
shift

set "BUILD=--build"
set "WITH_INFRA=1"
set "WATCH=0"
set "WITH= "
set "APP_ENV=.env.local"
set "INFRA_ENV_OVERRIDE="
set "DRY=0"

:args
if "%~1"=="" goto :argsdone
set "A=%~1"
if /i "%A%"=="--no-build"    (set "BUILD="            & shift & goto :args)
if /i "%A%"=="--no-infra"    (set "WITH_INFRA=0"      & shift & goto :args)
if /i "%A%"=="--watch"       (set "WATCH=1"           & shift & goto :args)
if /i "%A%"=="--dry-run"     (set "DRY=1"             & shift & goto :args)
if /i "%A%"=="--wezterm"     (set "GM_TERMINAL=wezterm" & shift & goto :args)
if /i "%A%"=="--wt"          (set "GM_TERMINAL=wt"    & shift & goto :args)
if /i "%A%"=="--no-terminal" (set "GM_TERMINAL=none"  & shift & goto :args)
if /i "%A:~0,7%"=="--with="       (set "WITH=%WITH%%A:~7% "        & shift & goto :args)
if /i "%A:~0,11%"=="--terminal="  (set "GM_TERMINAL=%A:~11%"       & shift & goto :args)
if /i "%A:~0,12%"=="--infra-env=" (set "INFRA_ENV_OVERRIDE=%A:~12%" & shift & goto :args)
if /i "%A:~0,10%"=="--app-env="   (set "APP_ENV=%A:~10%"           & shift & goto :args)
if /i "%A%"=="-h"     goto :usage
if /i "%A%"=="--help" goto :usage
echo unknown option: %A% 1>&2
exit /b 1
:usage
echo usage: run-%MODE%.cmd [options]
echo.
echo   docker: every service in Docker, attached, one service per pane.
echo   manual: infra in Docker, every service built and run from source.
echo   Panes come up together; each waits for the ports it needs.
echo.
echo   --no-infra        assume the shared infra is already running
echo   --with=a,b        also start these optional services
echo   --infra-env=F     infra env file ^(default .env.win^)
echo   --app-env=F       env file the app stacks use ^(default .env.local^)
echo   --no-build        skip 'docker compose --build'   ^(docker mode^)
echo   --watch           dotnet watch instead of dotnet run   ^(manual mode^)
echo   --terminal=X      auto ^| wezterm ^| wt ^| os ^| none
echo   --dry-run         print what each pane would run, launch nothing
exit /b 0
:argsdone

call "%GM_LIB%\tools.cmd" init || exit /b 1
call "%GM_TOOLS_DIR%\project.cmd" || exit /b 1
if not defined INFRA_DIR (echo project.cmd did not declare an infra stack 1>&2 & exit /b 1)
if "%SVC_COUNT%"=="0"    (echo project.cmd declared no services 1>&2 & exit /b 1)

call "%GM_LIB%\tools.cmd" pickenv "%INFRA_DIR%" "%INFRA_ENV_OVERRIDE%" INFRA_ENV_FILE || exit /b 1
call "%GM_LIB%\tools.cmd" resolvew "%INFRA_DIR%\%INFRA_ENV_FILE%"

where docker >nul 2>&1 || (echo error: docker is not on PATH 1>&2 & exit /b 1)
docker info >nul 2>&1 || (echo error: docker daemon is not running 1>&2 & exit /b 1)
if /i not "%MODE%"=="manual" goto :dotnetok
where dotnet >nul 2>&1 || (echo error: dotnet is not on PATH 1>&2 & exit /b 1)
:dotnetok

rem --- which services, and the preflight each mode needs ---------------------
set "PICKED= "
set "CHECKPORTS="
set "N=0"
:pick
set /a N+=1
if %N% GTR %SVC_COUNT% goto :picked
call set "_opt=%%SVC_%N%_OPTIONAL%%"
call set "_nm=%%SVC_%N%_NAME%%"
rem an optional service is only picked when --with= named it
if not "%_opt%"=="1" goto :pickon
call :selected "%_nm%"
if errorlevel 1 goto :pick
:pickon
set "PICKED=%PICKED%%N% "
call set "_prj=%%SVC_%N%_PROJECT%%"
call set "_dkr=%%SVC_%N%_DOCKER%%"
if /i "%MODE%"=="docker" goto :pickdocker
if "%_prj%"=="-"         goto :pickdocker
call "%GM_LIB%\tools.cmd" checkdir "%_prj%" || exit /b 1
call set "CHECKPORTS=%%CHECKPORTS%% %%SVC_%N%_PORTS:,= %%"
goto :pick
:pickdocker
call "%GM_LIB%\tools.cmd" checkdir "%_dkr%" || exit /b 1
goto :pick
:picked
if "%PICKED%"=="  " (echo no services selected 1>&2 & exit /b 1)
if not "%WITH_INFRA%"=="1" goto :infradirok
call "%GM_LIB%\tools.cmd" checkdir "%INFRA_DIR%" || exit /b 1
:infradirok

if "%DRY%"=="1" goto :nopreflight
if /i not "%MODE%"=="manual" goto :portsok
if not defined CHECKPORTS goto :portsok
call "%GM_LIB%\tools.cmd" portfree %CHECKPORTS% || exit /b 1
:portsok
if not defined GM_EXTERNAL_NETWORKS set "GM_EXTERNAL_NETWORKS=dokploy-network"
call "%GM_LIB%\tools.cmd" netcheck %GM_EXTERNAL_NETWORKS%
if "%WITH_INFRA%"=="1" call "%GM_LIB%\tools.cmd" bindpaths "%INFRA_DIR%\%INFRA_ENV_FILE%" "%INFRA_DIR%"
goto :preflightdone
:selected
rem exit 0 when --with= named this service, 1 otherwise
echo %WITH%| findstr /i /c:" %~1 " >nul
exit /b %ERRORLEVEL%
:preflightdone
:nopreflight

rem --- env.cmd: the tool's own variables only --------------------------------
set "ENV_CMD=%RUN_DIR%\env.cmd"
> "%ENV_CMD%" echo @echo off
>>"%ENV_CMD%" echo rem generated by %GM_TOOLS_DIR% - regenerated on every run
>>"%ENV_CMD%" echo set "TOOLS_DIR=%TOOLS_DIR%"
>>"%ENV_CMD%" echo set "MANAGER_DIR=%MANAGER_DIR%"
>>"%ENV_CMD%" echo set "RUN_DIR=%RUN_DIR%"
>>"%ENV_CMD%" echo set "GM_WAIT=%GM_WAIT%"
>>"%ENV_CMD%" echo set "GM_TAILER=%GM_TAILER%"
>>"%ENV_CMD%" echo set "GM_WAIT_TIMEOUT=%GM_WAIT_TIMEOUT%"
>>"%ENV_CMD%" echo set "PROJECT=%PROJECT%"
>>"%ENV_CMD%" echo set "INFRA_DIR=%INFRA_DIR%"
>>"%ENV_CMD%" echo set "INFRA_ENV_FILE=%INFRA_ENV_FILE%"
>>"%ENV_CMD%" echo set "APP_ENV=%APP_ENV%"

rem --- panes -----------------------------------------------------------------
rem No -p anywhere: each stack keeps the project name compose derives from its
rem own folder, so these panes drive the same containers as compose by hand.
del /q "%RUN_DIR%\%MODE%-*.cmd" 2>nul
set "PLIST="
set "PANEN=0"

if not "%WITH_INFRA%"=="1" goto :noinfrapane
set "TITLE=infra -"
set "N=0"
:infratitle
set /a N+=1
if %N% GTR %WAIT_COUNT% goto :infratitledone
call set "TITLE=%%TITLE%% %%WAIT_%N%_NAME%% %%WAIT_%N%_PORT%%"
goto :infratitle
:infratitledone
call :panestart infra "%TITLE%"
>>"%PANE%" echo cd /d "%INFRA_DIR%"
>>"%PANE%" echo docker compose --env-file "%INFRA_ENV_FILE%" up
call :paneend infra
:noinfrapane

set "DOTNET_CMD=dotnet run"
if "%WATCH%"=="1" set "DOTNET_CMD=dotnet watch"

for %%i in (%PICKED%) do call :service_pane %%i
goto :launch

:service_pane
set "I=%~1"
call set "SNAME=%%SVC_%I%_NAME%%"
call set "SPORTS=%%SVC_%I%_PORTS%%"
call set "SPROJ=%%SVC_%I%_PROJECT%%"
call set "SDOCK=%%SVC_%I%_DOCKER%%"
call set "SPROF=%%SVC_%I%_PROFILE%%"
call set "SENV=%%SVC_%I%_ENV%%"
call set "SWAITS=%%SVC_%I%_WAITS%%"
if not defined SENV set "SENV=%APP_ENV%"

set "MODESTR=docker"
set "ISDOCKER=1"
if /i not "%MODE%"=="docker" if not "%SPROJ%"=="-" (set "ISDOCKER=0" & set "MODESTR=--env=%SPROF%")
call :panestart "%SNAME%" "%SNAME% - :%SPORTS% (%MODESTR%)"

rem each service waits only for what it declared, so all panes can start at once
for %%d in (%SWAITS:,= %) do call :waitline "%%d"

if "%ISDOCKER%"=="1" goto :pane_docker
>>"%PANE%" echo cd /d "%SPROJ%"
>>"%PANE%" echo %DOTNET_CMD% --launch-profile %SPROF%
goto :pane_tail
:pane_docker
>>"%PANE%" echo cd /d "%SDOCK%"
if "%SENV%"=="-" (>>"%PANE%" echo docker compose up %BUILD%) else (>>"%PANE%" echo docker compose --env-file "%SENV%" up %BUILD%)
:pane_tail
call :paneend "%SNAME%"
exit /b 0

:waitline
call "%GM_LIB%\tools.cmd" waitport "%~1" _wp
if not defined _wp (echo error: waits=%~1 is neither a wait target nor a service 1>&2 & exit /b 1)
>>"%PANE%" echo call "%%GM_WAIT%%" %~1 127.0.0.1 %_wp%
set "_wp="
exit /b 0

:panestart
set /a PANEN+=1
set "PANE=%RUN_DIR%\%MODE%-%PANEN%-%~1.cmd"
> "%PANE%" echo @echo off
>>"%PANE%" echo rem generated by %GM_TOOLS_DIR% - regenerated on every run
>>"%PANE%" echo call "%RUN_DIR%\env.cmd"
>>"%PANE%" echo title %~2
>>"%PANE%" echo echo ----- %~2 -----
exit /b 0

:paneend
rem Ctrl-C must not take the pane with it: cmd /k keeps an interactive prompt and
rem the doskey macro 'r' re-runs this pane. Batch asks "Terminate batch job
rem (Y/N)?" on Ctrl-C - answer N to land here.
>>"%PANE%" echo echo.
>>"%PANE%" echo echo [%~1] stopped ^(%%ERRORLEVEL%%^) - type r to re-run, exit to close the pane
>>"%PANE%" echo cmd /k doskey r=call "%PANE%"
set "PLIST=%PLIST% "%PANE%""
exit /b 0

:launch
echo ==^> %MODE% mode - %PROJECT% - %PANEN% panes
if "%DRY%"=="1" (
  echo ==^> dry run - scripts written to %RUN_DIR%, nothing launched
  exit /b 0
)
call "%GM_LIB%\tools.cmd" launch %PLIST%
exit /b %ERRORLEVEL%
