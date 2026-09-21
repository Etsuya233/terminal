@echo off
rem Set up env, then clean-build the whole solution (x64 Debug).
set "PATH=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin;%PATH%"

rem Inject the missing %(Lib.TargetMachine) for x64 (Windows Store app-type props omit it).
rem MSBuild picks this up as a property from the environment; bcz passes it through to msbuild.
set "ForceImportAfterCppProps=C:\Users\Etsuya\Programming\wte\_setup\x64-lib-targetmachine.props"

call "%~dp0tools\razzle.cmd"
if not defined MSBUILD (
    echo FATAL: razzle did not set MSBUILD
    exit /b 1
)
echo ==============================================
echo BUILD START %DATE% %TIME%
echo MSBUILD=%MSBUILD%
echo PLATFORM=%PLATFORM% CONFIG=Debug
echo ForceImportAfterCppProps=%ForceImportAfterCppProps%
echo ==============================================

call "%~dp0tools\bcz.cmd" dbg
set BCZ_EXIT=%errorlevel%
echo ==============================================
echo BUILD END %DATE% %TIME%  BCZ_EXIT=%BCZ_EXIT%
echo ==============================================
exit /b %BCZ_EXIT%
