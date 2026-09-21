@echo off
rem Fastest CLI inner loop: no razzle, no nuget restore.
rem razzle runs two nuget restores and bcz runs a third; neither is needed once
rem packages/ is populated. Env is set explicitly instead.
rem   build-fast.cmd            -> incremental solution build
rem   build-fast.cmd Clean      -> clean first
set "VSROOT=C:\Program Files\Microsoft Visual Studio\18\Community"
set "PATH=%VSROOT%\MSBuild\Current\Bin;%PATH%"
set "ForceImportAfterCppProps=C:\Users\Etsuya\Programming\wte\_setup\x64-lib-targetmachine.props"
set "MSBUILD=%VSROOT%\MSBuild\Current\Bin\MSBuild.exe"
set "OPENCON=C:\Users\Etsuya\Programming\wte\terminal"
set "ARCH=x64"
set "PLATFORM=x64"

set "TARGET=Build"
if /i "%~1"=="Clean" set "TARGET=Clean;Build"

"%MSBUILD%" "%OPENCON%\OpenConsole.slnx" /t:"%TARGET%" /m /p:Configuration=Debug /p:GenerateAppxPackageOnBuild=false /p:Platform=x64 /p:AppxBundle=false
exit /b %errorlevel%
