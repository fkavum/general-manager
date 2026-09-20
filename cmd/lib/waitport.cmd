@echo off
rem waitport.cmd <label> <host> <port> [timeout-seconds]
rem Blocks until the TCP port accepts a connection. exit 1 on timeout, so the
rem caller can decide whether that is fatal.
setlocal
set "LABEL=%~1"
set "HOST=%~2"
set "PORT=%~3"
set "TMO=%~4"
if not defined TMO set "TMO=%GM_WAIT_TIMEOUT%"
if not defined TMO set "TMO=180"

<nul set /p "===> waiting for %LABEL% (%HOST%:%PORT%) ..."
powershell -NoProfile -Command ^
  "$t=%TMO%; while($t -gt 0){ try{ $c=New-Object Net.Sockets.TcpClient; $c.Connect('%HOST%',%PORT%); $c.Close(); exit 0 } catch { Start-Sleep -Seconds 1; $t-- } }; exit 1"
if errorlevel 1 (
  echo.
  echo warn: %LABEL% ^(%HOST%:%PORT%^) did not come up within %TMO%s - continuing anyway
  endlocal & exit /b 1
)
echo  up
endlocal & exit /b 0
