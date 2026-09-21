@echo off
rem Local build entry point.
rem   build.cmd                 -> clean build (bcz dbg -> /t:Clean;Build)
rem   build.cmd no_clean dbg    -> incremental build
rem   build.cmd rel             -> clean Release build
rem Any arguments are forwarded straight to tools\bcz.cmd.
set "PATH=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin;%PATH%"

rem Inject the missing %(Lib.TargetMachine) for x64 (Windows Store app-type props omit it).
rem MSBuild picks this up as a property from the environment; bcz passes it through to msbuild.
set "ForceImportAfterCppProps=C:\Users\Etsuya\Programming\wte\_setup\x64-lib-targetmachine.props"

set "BCZ_ARGS=%*"
if "%BCZ_ARGS%"=="" set "BCZ_ARGS=dbg"

call "%~dp0tools\razzle.cmd"
if not defined MSBUILD (
    echo FATAL: razzle did not set MSBUILD
    exit /b 1
)
echo ==============================================
echo BUILD START %DATE% %TIME%
echo MSBUILD=%MSBUILD%
echo PLATFORM=%PLATFORM%  BCZ ARGS: %BCZ_ARGS%
echo ForceImportAfterCppProps=%ForceImportAfterCppProps%
echo ==============================================

call "%~dp0tools\bcz.cmd" %BCZ_ARGS%
set BCZ_EXIT=%errorlevel%
echo ==============================================
echo BUILD END %DATE% %TIME%  BCZ_EXIT=%BCZ_EXIT%
echo ==============================================
exit /b %BCZ_EXIT%
