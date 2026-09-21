@echo off
rem Build ONLY the project in %1 (default: current dir), incrementally - the fast inner loop.
rem   build-one.cmd src\cascadia\TerminalApp
set "PATH=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin;%PATH%"
set "ForceImportAfterCppProps=C:\Users\Etsuya\Programming\wte\_setup\x64-lib-targetmachine.props"

if not "%~1"=="" (
    cd /d "%~1" || exit /b 1
)
echo Project dir: %CD%

call "%~dp0tools\razzle.cmd"
if not defined MSBUILD exit /b 1
call "%~dp0tools\bx.cmd"
exit /b %errorlevel%
