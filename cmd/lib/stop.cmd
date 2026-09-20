@echo off
rem 'docker compose down' for every stack this project's runner can start.
rem Local dotnet processes live in their own panes - close those.
rem Windows half of general-manager\bash\lib\stop.sh.
if not defined GM_TOOLS_DIR (echo stop.cmd must be invoked from a runner wrapper 1>&2 & exit /b 1)
set "GM_LIB=%~dp0"
if "%GM_LIB:~-1%"=="\" set "GM_LIB=%GM_LIB:~0,-1%"

set "STOP_INFRA=0"
set "KILL_PORTS=1"
set "VOLUMES="
set "APP_ENV=.env.local"
set "INFRA_ENV_OVERRIDE="
set "WITH= "
:args
if "%~1"=="" goto :argsdone
set "A=%~1"
if /i "%A%"=="--stop-infra" (set "STOP_INFRA=1" & shift & goto :args)
if /i "%A%"=="--keep-infra" (set "STOP_INFRA=0" & shift & goto :args)
if /i "%A%"=="--keep-ports" (set "KILL_PORTS=0" & shift & goto :args)
if /i "%A%"=="--volumes"    (set "VOLUMES=--volumes" & shift & goto :args)
if /i "%A:~0,7%"=="--with="       (set "WITH=%WITH%%A:~7% "         & shift & goto :args)
if /i "%A:~0,10%"=="--app-env="   (set "APP_ENV=%A:~10%"            & shift & goto :args)
if /i "%A:~0,12%"=="--infra-env=" (set "INFRA_ENV_OVERRIDE=%A:~12%" & shift & goto :args)
if /i "%A%"=="-h"     goto :usage
if /i "%A%"=="--help" goto :usage
echo unknown option: %A% 1>&2
exit /b 1
:usage
echo usage: stop.cmd [--stop-infra] [--keep-ports] [--volumes] [--with=a,b] [--app-env=F] [--infra-env=F]
echo.
echo   Runs 'docker compose down' in each service folder - the same command you
echo   would run by hand there. The shared database is LEFT RUNNING by default;
echo   the other projects use the same instance.
echo.
echo   Afterwards it checks the ports this project declares and stops anything
echo   still listening - typically a run-manual.cmd you forgot about.
echo   --keep-ports leaves those alone.
exit /b 0
:argsdone

call "%GM_LIB%\tools.cmd" init || exit /b 1
call "%GM_TOOLS_DIR%\project.cmd" || exit /b 1
where docker >nul 2>&1 || (echo error: docker is not on PATH 1>&2 & exit /b 1)

rem services first, infra last - the apps depend on it
set "N=%SVC_COUNT%"
:loop
if %N% LSS 1 goto :infra
call set "_opt=%%SVC_%N%_OPTIONAL%%"
call set "_nm=%%SVC_%N%_NAME%%"
if not "%_opt%"=="1" goto :takeit
echo %WITH%| findstr /i /c:" %_nm% " >nul
if errorlevel 1 goto :next
:takeit
call set "_dkr=%%SVC_%N%_DOCKER%%"
call set "_env=%%SVC_%N%_ENV%%"
if not defined _env set "_env=%APP_ENV%"
call :down "%_nm%" "%_dkr%" "%_env%"
:next
set /a N-=1
goto :loop

:infra
if "%STOP_INFRA%"=="0" (
  echo ==^> left running: %INFRA_LABEL% ^(shared - pass --stop-infra to take it down^)
  goto :ports
)
echo warn: %INFRA_LABEL% is shared with the other projects - taking it down affects them too 1>&2
call "%GM_LIB%\tools.cmd" pickenv "%INFRA_DIR%" "%INFRA_ENV_OVERRIDE%" INFRA_ENV_FILE || exit /b 1
call :down infra "%INFRA_DIR%" "%INFRA_ENV_FILE%"

rem --- leftovers from a manual run -------------------------------------------
:ports
if not "%KILL_PORTS%"=="1" exit /b 0
set "PORTS="
set "N=0"
:portloop
set /a N+=1
if %N% GTR %SVC_COUNT% goto :portsgo
call set "PORTS=%%PORTS%% %%SVC_%N%_PORTS:,= %%"
goto :portloop
:portsgo
if not defined PORTS exit /b 0
call "%GM_LIB%\tools.cmd" killports %PORTS%
exit /b 0

:down
if not exist "%~2" (echo warn: skipping %~1 - %~2 not found & exit /b 0)
echo ==^> docker compose down: %~1
pushd "%~2"
if "%~3"=="-" (docker compose down %VOLUMES%) else (docker compose --env-file "%~3" down %VOLUMES%)
popd
exit /b 0
