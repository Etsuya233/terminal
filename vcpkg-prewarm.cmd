@echo off
rem Mirror the exact vcpkg command MSBuild emits (note the doubled backslash before each closing quote).
set "VCPKG=C:\Program Files\Microsoft Visual Studio\18\Community\VC\vcpkg\vcpkg.exe"
"%VCPKG%" install  --x-wait-for-lock --triplet "x64-windows-static" --vcpkg-root "C:\Program Files\Microsoft Visual Studio\18\Community\VC\vcpkg\\" "--x-manifest-root=C:\Users\Etsuya\Programming\wte\terminal\\" "--x-install-root=C:\Users\Etsuya\Programming\wte\terminal\\obj\x64\vcpkg\\" --x-feature=terminal
echo VCPKG_PREWARM_EXIT=%errorlevel%
