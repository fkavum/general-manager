@echo off
rem ---------------------------------------------------------------------------
rem Shared launcher machinery for the per-project tools\cmd\runner folders.
rem Windows half of general-manager\bash\lib\tools.sh - same concepts, same
rem project.* declarations, same generated panes.
rem
rem Called as:  call "%GM_LIB%\tools.cmd" <subcommand> [args]
rem No setlocal on purpose: init/infra/wait/service must leave state behind.
rem ---------------------------------------------------------------------------
if /i "%~1"=="init"       goto :init
if /i "%~1"=="infra"      goto :infra
if /i "%~1"=="wait"       goto :waittarget
if /i "%~1"=="service"    goto :service
if /i "%~1"=="envget"     goto :envget
if /i "%~1"=="pickenv"    goto :pickenv
if /i "%~1"=="bindpaths"  goto :bindpaths
if /i "%~1"=="resolvew"   goto :resolvew
if /i "%~1"=="waitport"   goto :waitportof
if /i "%~1"=="checkdir"   goto :checkdir
if /i "%~1"=="netcheck"   goto :netcheck
if /i "%~1"=="portfree"   goto :portfree
if /i "%~1"=="killports"  goto :killports
if /i "%~1"=="launch"     goto :launch
echo tools.cmd: unknown subcommand "%~1" 1>&2
exit /b 1

rem ===========================================================================
:init
rem GM_TOOLS_DIR (the runner folder) and GM_MANAGER_DIR come from the wrapper.
set "TOOLS_DIR=%GM_TOOLS_DIR%"
set "MANAGER_DIR=%GM_MANAGER_DIR%"
set "GM_LIB_DIR=%~dp0"
if "%GM_LIB_DIR:~-1%"=="\" set "GM_LIB_DIR=%GM_LIB_DIR:~0,-1%"
set "RUN_DIR=%TOOLS_DIR%\.run"
set "GM_WAIT=%GM_LIB_DIR%\waitport.cmd"
set "GM_TAILER=%GM_LIB_DIR%\tailer.cmd"
if not defined GM_TERMINAL     set "GM_TERMINAL=auto"
if not defined GM_WAIT_TIMEOUT set "GM_WAIT_TIMEOUT=180"
set "SVC_COUNT=0"
set "WAIT_COUNT=0"
if not exist "%RUN_DIR%" md "%RUN_DIR%"
exit /b 0

rem === gm_infra:  infra dir=<folder> [label=<text>] ==========================
:infra
shift
set "INFRA_DIR="
set "INFRA_LABEL=infra"
:infraargs
if "%~1"=="" goto :infradone
for /f "tokens=1* delims==" %%a in ("%~1") do (
  if /i "%%a"=="dir"   set "INFRA_DIR=%%b"
  if /i "%%a"=="label" set "INFRA_LABEL=%%b"
)
shift
goto :infraargs
:infradone
if not defined INFRA_DIR (echo gm_infra: dir= is required 1>&2 & exit /b 1)
for %%I in ("%INFRA_DIR%") do set "INFRA_DIR=%%~fI"
exit /b 0

rem === gm_wait:  wait <name> key=<ENVKEY> default=<port> =====================
:waittarget
shift
set /a WAIT_COUNT+=1
set "_w=%WAIT_COUNT%"
set "WAIT_%_w%_NAME=%~1"
set "WAIT_%_w%_KEY="
set "WAIT_%_w%_DEFAULT="
shift
:waitargs
if "%~1"=="" goto :waitdone
for /f "tokens=1* delims==" %%a in ("%~1") do (
  if /i "%%a"=="key"     set "WAIT_%_w%_KEY=%%b"
  if /i "%%a"=="default" set "WAIT_%_w%_DEFAULT=%%b"
)
shift
goto :waitargs
:waitdone
call set "WAIT_%_w%_PORT=%%WAIT_%_w%_DEFAULT%%"
exit /b 0

rem === gm_service: service name=… docker=… [project=…] container=… port=… ====
rem                 [ports=a,b] [profile=local] [optional=1] [env=…|-] [waits=a,b]
:service
shift
set /a SVC_COUNT+=1
set "_s=%SVC_COUNT%"
set "SVC_%_s%_NAME="
set "SVC_%_s%_DOCKER="
set "SVC_%_s%_PROJECT=-"
set "SVC_%_s%_CONTAINER="
set "SVC_%_s%_PORT="
set "SVC_%_s%_PORTS="
set "SVC_%_s%_PROFILE=local"
set "SVC_%_s%_OPTIONAL=0"
set "SVC_%_s%_ENV="
set "SVC_%_s%_WAITS="
:svcargs
if "%~1"=="" goto :svcdone
for /f "tokens=1* delims==" %%a in ("%~1") do set "SVC_%_s%_%%a=%%b"
shift
goto :svcargs
:svcdone
call set "_p=%%SVC_%_s%_PORT%%"
call set "_ps=%%SVC_%_s%_PORTS%%"
if not defined _ps call set "SVC_%_s%_PORTS=%_p%"
if not defined _p for /f "tokens=1 delims=," %%p in ("%_ps%") do set "SVC_%_s%_PORT=%%p"
call set "_d=%%SVC_%_s%_DOCKER%%"
if defined _d for %%I in ("%_d%") do set "SVC_%_s%_DOCKER=%%~fI"
call set "_j=%%SVC_%_s%_PROJECT%%"
if defined _j if not "%_j%"=="-" for %%I in ("%_j%") do set "SVC_%_s%_PROJECT=%%~fI"
set "_p=" & set "_ps=" & set "_d=" & set "_j="
exit /b 0

rem === envget <file> <key> <default> <outvar> ================================
:envget
set "__v="
if exist "%~2" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~2") do if /i "%%a"=="%~3" set "__v=%%b"
if not defined __v set "__v=%~4"
set "%~5=%__v%"
set "__v="
exit /b 0

rem === pickenv <dir> <explicit|""> <outvar> ==================================
:pickenv
if not "%~3"=="" (
  if not exist "%~2\%~3" (echo error: no such env file: %~2\%~3 1>&2 & exit /b 1)
  set "%~4=%~3"
  exit /b 0
)
if exist "%~2\.env.win" (set "%~4=.env.win" & exit /b 0)
if exist "%~2\.env.ubuntu" (set "%~4=.env.ubuntu" & exit /b 0)
echo error: no env file found in %~2 ^(looked for .env.win, .env.ubuntu^) 1>&2
echo        create one, or pass --infra-env=^<name^> - it is what compose reads 1>&2
exit /b 1

rem === bindpaths <env-file> <base-dir> =======================================
rem Every *_LOG_PATH / *_DATA_PATH / *_INIT_PATH is a host path the stack will
rem bind-mount. Create them now rather than let compose fail with a mount error.
:bindpaths
if not exist "%~2" exit /b 0
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~2") do call :bindone "%%a" "%%b" "%~3"
exit /b 0
:bindone
set "_k=%~1"
set "_v=%~2"
if not defined _v exit /b 0
echo %_k%| findstr /r /c:"_LOG_PATH$" /c:"_DATA_PATH$" /c:"_INIT_PATH$" >nul || exit /b 0
set "_path=%_v%"
echo %_v%| findstr /r /c:"^[A-Za-z]:" /c:"^\\\\" >nul || set "_path=%~3\%_v%"
if not exist "%_path%" md "%_path%" 2>nul
if not exist "%_path%" echo warn: could not create %_k%=%_v% ^(compose may fail to mount it^) 1>&2
set "_k=" & set "_v=" & set "_path="
exit /b 0

rem === resolvew <infra env file> : fill in every wait target's port ==========
:resolvew
set "_n=0"
:resolvewloop
set /a _n+=1
if %_n% GTR %WAIT_COUNT% goto :resolvewdone
call set "_key=%%WAIT_%_n%_KEY%%"
call set "_def=%%WAIT_%_n%_DEFAULT%%"
call :envget envget "%~2" "%_key%" "%_def%" _port
call set "WAIT_%_n%_PORT=%_port%"
goto :resolvewloop
:resolvewdone
set "_n=" & set "_key=" & set "_def=" & set "_port="
exit /b 0

rem === waitport <token> <outvar> : a wait name or another service's name =====
:waitportof
set "%~3="
set "_n=0"
:wpw
set /a _n+=1
if %_n% GTR %WAIT_COUNT% goto :wps
call set "_nm=%%WAIT_%_n%_NAME%%"
if /i "%_nm%"=="%~2" (call set "%~3=%%WAIT_%_n%_PORT%%" & goto :wpdone)
goto :wpw
:wps
set "_n=0"
:wpsl
set /a _n+=1
if %_n% GTR %SVC_COUNT% goto :wpdone
call set "_nm=%%SVC_%_n%_NAME%%"
if /i "%_nm%"=="%~2" (call set "%~3=%%SVC_%_n%_PORT%%" & goto :wpdone)
goto :wpsl
:wpdone
set "_n=" & set "_nm="
exit /b 0

rem === checkdir <dir> <what> =================================================
:checkdir
if exist "%~2" exit /b 0
echo error: not found: %~2 1>&2
echo   Repos are resolved relative to the manager folder ^(%MANAGER_DIR%^). 1>&2
echo   If your checkout differs, set the matching *_REPO variable first. 1>&2
exit /b 1

rem === netcheck <name>… : create external networks nobody else will =========
:netcheck
shift
:netloop
if "%~1"=="" exit /b 0
docker network inspect %~1 >nul 2>&1 || (
  echo ==^> creating missing external network: %~1
  docker network create %~1 >nul
)
shift
goto :netloop

rem === portfree <port>… : manual mode binds these on the host ===============
:portfree
shift
set "_busy="
:pfloop
if "%~1"=="" goto :pfdone
powershell -NoProfile -Command "try{$c=New-Object Net.Sockets.TcpClient;$c.Connect('127.0.0.1',%~1);$c.Close();exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 goto :pfnext
rem goto dispatch, not a block: %_busy% inside ( ) would expand before it runs
set "_holder="
for /f "usebackq delims=" %%c in (`docker ps --filter "publish=%~1" --format "{{.Names}}"`) do set "_holder=%%c"
call :pfmark "%~1"
:pfnext
shift
goto :pfloop

:pfmark
if defined _holder set "_busy=%_busy% %~1 (docker container %_holder%)"
if not defined _holder set "_busy=%_busy% %~1"
exit /b 0

:pfdone
if not defined _busy exit /b 0
echo error: ports needed by the local builds are already taken:%_busy% 1>&2
echo   Stop the docker stack first:  %TOOLS_DIR%\stop.cmd 1>&2
set "_busy="
exit /b 1

rem === killports <port>… =====================================================
rem After the docker stacks are down, a forgotten run-manual.cmd can still be
rem holding the service ports. Only ports this project declares are touched,
rem only when no container publishes them (compose owns those), and the process
rem is asked to exit before it is forced.
:killports
shift
:kploop
if "%~1"=="" exit /b 0
set "_owner="
for /f "usebackq delims=" %%c in (`docker ps --filter "publish=%~1" --format "{{.Names}}"`) do set "_owner=%%c"
if defined _owner goto :kpnext
set "_pid="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "try{(Get-NetTCPConnection -LocalPort %~1 -State Listen -ErrorAction Stop | Select-Object -First 1 -ExpandProperty OwningProcess)}catch{}"`) do set "_pid=%%p"
if not defined _pid goto :kpnext
set "_pname="
for /f "usebackq delims=" %%n in (`powershell -NoProfile -Command "try{(Get-Process -Id %_pid% -ErrorAction Stop).ProcessName}catch{}"`) do set "_pname=%%n"
echo ==^> port %~1 held by pid %_pid% ^(%_pname%^) - stopping it
taskkill /pid %_pid% >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Seconds 2" >nul
tasklist /fi "pid eq %_pid%" 2>nul | findstr /c:"%_pid%" >nul && call :kpforce %_pid%
:kpnext
shift
goto :kploop

:kpforce
echo warn: pid %~1 did not exit - forcing 1>&2
taskkill /f /t /pid %~1 >nul 2>&1
exit /b 0

rem ===========================================================================
rem launch <pane1.cmd> <pane2.cmd> …   WezTerm -> Windows Terminal -> windows
rem ===========================================================================
:launch
shift
set "PCOUNT=0"
:collect
if "%~1"=="" goto :collected
set /a PCOUNT+=1
call set "P%PCOUNT%=%~1"
call set "T%PCOUNT%=%~n1"
shift
goto :collect
:collected
if "%PCOUNT%"=="0" (echo launch: no pane scripts given 1>&2 & exit /b 1)

if /i "%GM_TERMINAL%"=="none"    goto :launch_none
if /i "%GM_TERMINAL%"=="wezterm" goto :launch_wez
if /i "%GM_TERMINAL%"=="wt"      goto :launch_wt
if /i "%GM_TERMINAL%"=="os"      goto :launch_start
where wezterm >nul 2>&1 && goto :launch_wez
where wt      >nul 2>&1 && goto :launch_wt
goto :launch_start

:launch_wez
where wezterm >nul 2>&1 || (echo wezterm is not on PATH 1>&2 & exit /b 1)
wezterm cli list >nul 2>&1 || (start "" wezterm start & call :sleep 3)
for /f "usebackq delims=" %%i in (`wezterm cli spawn --new-window -- cmd /c "%P1%"`) do set "W1=%%i"
set "N=1"
:wezloop
set /a N+=1
if %N% GTR %PCOUNT% goto :wezdone
call set "PFILE=%%P%N%%%"
rem goto dispatch, not nested if-blocks: a parenthesised block would expand
rem %PREV% before the block ever runs
if %N%==2 (set "TARGET=%W1%" & set "DIR=--right"  & goto :wezsplit)
if %N%==3 (set "TARGET=%W1%" & set "DIR=--bottom" & goto :wezsplit)
if %N%==4 (set "TARGET=%W2%" & set "DIR=--bottom" & goto :wezsplit)
set /a PREV=%N%-1
call set "TARGET=%%W%PREV%%%"
set "DIR=--bottom"
:wezsplit
for /f "usebackq delims=" %%i in (`wezterm cli split-pane --pane-id %TARGET% %DIR% --percent 50 -- cmd /c "%PFILE%"`) do set "W%N%=%%i"
goto :wezloop
:wezdone
echo ==^> launched %PCOUNT% panes in WezTerm
exit /b 0

:launch_wt
where wt >nul 2>&1 || (echo Windows Terminal ^(wt^) is not on PATH 1>&2 & exit /b 1)
set "WTCMD=-w -1 new-tab --title "%T1%" cmd /c "%P1%""
if %PCOUNT% GEQ 2 set "WTCMD=%WTCMD% ; split-pane -V --title "%T2%" cmd /c "%P2%""
if %PCOUNT% GEQ 3 set "WTCMD=%WTCMD% ; move-focus left ; split-pane -H --title "%T3%" cmd /c "%P3%""
if %PCOUNT% GEQ 4 set "WTCMD=%WTCMD% ; move-focus right ; split-pane -H --title "%T4%" cmd /c "%P4%""
set "N=4"
:wtloop
set /a N+=1
if %N% GTR %PCOUNT% goto :wtdone
call set "PFILE=%%P%N%%%"
call set "PTITLE=%%T%N%%%"
call set "WTCMD=%%WTCMD%% ; split-pane --title "%PTITLE%" cmd /c "%PFILE%""
goto :wtloop
:wtdone
wt %WTCMD%
echo ==^> launched %PCOUNT% panes in Windows Terminal
exit /b 0

:launch_start
set "N=0"
:startloop
set /a N+=1
if %N% GTR %PCOUNT% goto :startdone
call set "PFILE=%%P%N%%%"
call set "PTITLE=%%T%N%%%"
start "%PTITLE%" cmd /c "%PFILE%"
call :sleep 1
goto :startloop
:startdone
echo ==^> opened %PCOUNT% console windows, one per service
exit /b 0

:launch_none
echo.
echo ==^> run each of these in its own terminal, in this order:
set "N=0"
:noneloop
set /a N+=1
if %N% GTR %PCOUNT% goto :nonedone
call echo     %%P%N%%%
goto :noneloop
:nonedone
echo.
exit /b 0

:sleep
powershell -NoProfile -Command "Start-Sleep -Seconds %~1" >nul 2>&1
exit /b 0
