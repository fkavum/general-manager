@echo off
rem Golden test for what run.cmd GENERATES - not for what it launches.
rem Windows half of general-manager\bash\lib\test-generate.sh; the test itself is
rem test-generate.ps1, because batch cannot diff text and this lib already leans
rem on PowerShell for waitport, tailer and the port checks.
rem
rem   test-generate.cmd            check; exits 1 on any diff
rem   test-generate.cmd --update   rewrite the goldens - then READ the diff
rem   test-generate.cmd --keep     leave the temp fixture behind for inspection
rem
rem The goldens live in testdata\golden\ and are NOT the shell half's: both
rem halves are tested the same way, but batch and shell panes look different.
setlocal
set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "PSARGS="
:args
if "%~1"=="" goto :argsdone
if /i "%~1"=="--update" (set "PSARGS=%PSARGS% -Update" & shift & goto :args)
if /i "%~1"=="--keep"   (set "PSARGS=%PSARGS% -Keep"   & shift & goto :args)
if /i "%~1"=="--help"   (set "PSARGS=%PSARGS% -Help"   & shift & goto :args)
if /i "%~1"=="-h"       (set "PSARGS=%PSARGS% -Help"   & shift & goto :args)
echo unknown option: %~1 ^(try --help^) 1>&2
exit /b 1
:argsdone

powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%\test-generate.ps1"%PSARGS%
exit /b %ERRORLEVEL%
