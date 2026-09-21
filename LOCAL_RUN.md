# LOCAL_RUN.md — local build record

**Scope:** this file documents a **local, non-public** build of this fork on one specific
machine. It is not an upstream artifact, it is not a support document for `microsoft/terminal`,
and nothing in it has been submitted upstream. See `AGENTS.md` for the upstream AI usage policy.

Everything below was observed on this machine. Paths are absolute on purpose — this is a
"how do I rebuild here" note, not a portable guide.

---

## 0. Status

| | |
|---|---|
| Fork | `Etsuya233/terminal` (parent `microsoft/terminal`) |
| Commit | `7c92ecd03` on `main` |
| Result | **build succeeds**, `0 Error(s)`, 248 warnings, 190 projects, 14m35s |
| Tracked files modified | **none** — all scaffolding is untracked |

Rebuild:

```cmd
cd C:\Users\Etsuya\Programming\wte\terminal
cmd /c build.cmd
```

---

## 1. Host baseline (before any changes)

- Windows 11, `10.0.26200.8875`. Single volume `C:`, **40.2 GB free** at the start.
- Present: git 2.45.1, gh 2.93.0, winget 1.29.290, PowerShell 7.6.0 (`C:\Program Files\PowerShell\7\pwsh.exe`)
- Visual Studio **2022 Community 17.11.35222.181** — present but **too old** (see §3.1)
- Windows SDK 10.0.22621.0 / 10.0.26100.0, MSVC 14.41.34120
- No .NET SDK (runtime 8.0.29 only), no standalone VS 2026 toolchain

## 2. Toolchain actually installed

### 2.1 Removing VS 2022

VS 2022 17.11 could not build this commit (§3.1), so it was uninstalled. That took free space
from 40.2 GB → 125.9 GB and **also removed the Windows SDK** (`C:\Program Files (x86)\Windows
Kits\10` disappeared), which the VS 2026 install then reinstalled.

### 2.2 Visual Studio 2026 Community

Pinned bootstrapper (downloaded via proxy, SHA256 verified):

```
URL    https://download.visualstudio.microsoft.com/download/pr/7437128c-6580-48ab-9c69-f7452be2ee7f/55e08bb27632a116042e7717c25335dca5a02cd5c33b14c40cae58ccd32fd72d/vs_Community.exe
SHA256 55e08bb27632a116042e7717c25335dca5a02cd5c33b14c40cae58ccd32fd72d
```

Note: `https://aka.ms/vs/18/release/vs_community.exe` is **dead** (redirects to Bing). Use the
`download.visualstudio.microsoft.com` URL above, or read the URL out of the winget manifest with
`winget show --id Microsoft.VisualStudio.Community -e`.

Installed by feeding the repo's own `.vsconfig` to the bootstrapper:

```powershell
Start-Process -FilePath 'C:\Users\Etsuya\Programming\wte\_setup\vs_Community.exe' `
  -ArgumentList '--config','C:\Users\Etsuya\Programming\wte\terminal\.vsconfig',
                '--quiet','--wait','--norestart','--includeRecommended' `
  -Verb RunAs -Wait -PassThru
```

- `--config` is a supported install-time switch (VS 2019 16.3+).
- Result: **51/51 `.vsconfig` components present, 0 missing.**
- Exit code **3010** (success, reboot recommended) — see §7.
- Installed: `18.10.12210.168` at `C:\Program Files\Microsoft Visual Studio\18\Community`
  (note the path segment is `18`, not `2026`).
- One UAC prompt covers the whole install: the bootstrapper's children inherit the elevation,
  so the remaining components install without a second prompt.

`.vsconfig` verification was done by looping every component id through
`vswhere -requires <id> -property installationPath`.

### 2.3 Supporting tools that came with it

| Tool | Version / path |
|---|---|
| Windows SDK | `10.0.26100.0` restored |
| vcpkg | `2026-07-27-98d7cb0cf1f4686a3e43aa5672b6230c1d56bce8` at `...\18\Community\VC\vcpkg` |
| vcpkg downloads root | `C:\Users\Etsuya\AppData\Local\vcpkg\downloads` (writable; the vcpkg root under `Program Files` is **not**) |
| .NET SDK | `10.0.401` |
| MSBuild | `...\18\Community\MSBuild\Current\Bin\MSBuild.exe` |

vcpkg hard-requires **CMake 4.4.0**; the pre-existing `C:\Program Files\CMake\bin\cmake.exe`
(3.31.0-rc1) is correctly rejected as too old.

Not independently verified: the README asks for Windows SDK `10.0.26100.8249`+. The VS-installed
component reports `Win11SDK_10.0.26100, version=10.0.26100.16` and
`Microsoft.Windows.SDK.BuildTools_10.0.26100.7705`, which are *component* versions, not the SDK
revision. The exact SDK revision was **not** independently confirmed; the build works regardless.

---

## 3. Obstacles hit (the useful part)

### 3.1 VS 2022 17.11 is not usable

`README.md` requires **VS 2026 (v18.6+)**. `tools/razzle.cmd` picks the latest VS in
`[17.0,19.0)`, and `src/common.build.pre.props` only falls back to the `v143` toolset when
`$(VisualStudioVersion) < 18.0`. With only 17.11 present the build would have silently used the
old toolset against a codebase written for `v145`. Installing VS 2026 was the correct fix.

### 3.2 `razzle.cmd` → "Could not find MSBuild on your machine"

Two independent causes, both in `tools/razzle.cmd`:

**(a) the `vswhere` package was never restored.** razzle locates MSBuild through a `vswhere.exe`
found under `packages\vswhere*`, but razzle only restores `OpenConsole.slnx` and
`dep\nuget\packages.config`. The `vswhere` package is declared in a *third* file,
`.nuget\packages.config` (vswhere 2.6.7), which razzle never touches. Fix:

```cmd
dep\nuget\nuget.exe restore .nuget\packages.config
```

**(b) razzle's own `for /f` call still failed** even after the package existed. The lookup at the
`-requires Microsoft.Component.MSBuild -version "[17.0,19.0)" -find MSBuild\**\Bin\MSBuild.exe`
step reported `The system cannot find the path specified.` and returned nothing, while the
**identical command run directly** resolves fine. This is a cmd quoting quirk in the nested
`for /f` backquote context (note razzle also picks up the odd flat dir `packages\vswhere\2.6.7\`
alongside `packages\vswhere.2.6.7\`).

**Workaround used:** razzle honours `msbuild.exe` already on `PATH` and skips the whole vswhere
path (the repo documents this as GH#1313). `build.cmd` therefore prepends the MSBuild bin dir:

```cmd
set "PATH=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin;%PATH%"
```

Note `MSBUILD` **cannot** be preset — `:FIND_MSBUILD` does `set MSBUILD=` first. `VSWHERE` can be
preset instead if the PATH route is ever undesirable.

### 3.3 vcpkg could not download CMake (HTTP 504)

First build died at the vcpkg step:

```
error : curl operation failed with response code 504.
error : Reached maximum number of attempts, won't retry download from
        https://github.com/Kitware/CMake/releases/download/v4.4.0/cmake-4.4.0-windows-x86_64.zip
```

Diagnosis: the GitHub **release asset** returned 504 both direct (`--noproxy '*'`) and through
Clash (which was already set as the system proxy *and* via `HTTP(S)_PROXY`). The 504 body is a
92-byte generic gateway-timeout page. The `cmake.org` mirror
(`https://cmake.org/files/v4.4/...`) served the same file fine (HTTP 206). Beware: the system
proxy is configured, so a naive "direct" `curl` still goes through Clash — use `--noproxy '*'`
to actually test direct.

Resolution: **transient.** `vcpkg.exe fetch cmake` succeeded on its own retry
("Attempt 1 of 3, retrying download"), caching CMake 4.4.0 and 7-Zip under
`%LOCALAPPDATA%\vcpkg\downloads\tools\`. No workaround was needed beyond retrying.

Handy: pre-warm vcpkg outside of MSBuild so dependency failures don't surface 7 minutes into a
build. See `vcpkg-prewarm.cmd`. Two gotchas in that script: it must mirror MSBuild's exact
argument quoting (the trailing `\\"` doubling), and `^` line-continuations do not survive this
checkout's LF-only line endings.

### 3.4 `LNK1112` — the real bug: `%(Lib.TargetMachine)` missing for x64

Second build failed on `Microsoft.Terminal.Settings.Model.Lib`:

```
warning LNK4068: /MACHINE not specified; defaulting to X86
fatal error LNK1112: module machine type 'x64' conflicts with target machine type 'x86'
  [...\src\cascadia\TerminalSettingsModel\Microsoft.Terminal.Settings.ModelLib.vcxproj]
```

The `Lib` invocation had **no `/MACHINE`** flag, so `lib.exe` defaulted to X86 while the object
files were x64.

Root cause, found by diffing the two platform property sheets under
`...\MSBuild\Microsoft\VC\v180\`:

| File | sets `TargetMachine` for |
|---|---|
| `Platforms\x64\Platform.Common.props` (lines 23–31) | Link, **Lib**, ImpLib |
| `Application Type\Windows Store\10.0\Platforms\x64\Platform.Common.props` (lines 25–30) | Link, ImpLib — **Lib is omitted** |

`Microsoft.Cpp.Default.props:130` computes
`_RelativePlatformFolder = $(_RelativeApplicationTypeRevisionFolder)Platforms\$(Platform)\`.
When a Windows Store *Application Type* is active, that resolves to the second file — the one
without `Lib`. `Microsoft.Terminal.Settings.ModelLib` is a static library with
`<OpenConsoleUniversalApp>true</OpenConsoleUniversalApp>` (a Windows Store app type), so it gets
the incomplete sheet, and with no `%(Lib.TargetMachine)` `lib.exe` falls back to X86.

This is a genuine gap in the repo's own workaround, `src/common.build.pre.props:178–183`:

```xml
<!-- Work around the Windows Store platform not specifying a TargetMachine for static libraries -->
<ItemDefinitionGroup Condition="'$(Platform)'=='Win32'">
  <Lib>
    <TargetMachine>MachineX86</TargetMachine>
  </Lib>
</ItemDefinitionGroup>
```

The comment describes exactly this problem, but the condition only covers `Win32` — **the x64
case is uncovered.**

**Fix applied (non-invasive, no repo files touched).** `Microsoft.Cpp.props:120` imports the
platform props and line **130** imports `$(ForceImportAfterCppProps)`, so that hook runs *after*
the platform sheets. Injected file
`C:\Users\Etsuya\Programming\wte\_setup\x64-lib-targetmachine.props`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemDefinitionGroup Condition="'$(Platform)' == 'x64'">
    <Lib>
      <TargetMachine Condition="'%(Lib.TargetMachine)' == ''">MachineX64</TargetMachine>
    </Lib>
  </ItemDefinitionGroup>
</Project>
```

It is wired in via an **environment variable** (`build.cmd` sets
`ForceImportAfterCppProps=<path>`). MSBuild treats environment variables as properties, so
`tools\bcz.cmd` needs no modification — this is why the fix required zero repo edits. The guard
`Condition="'%(Lib.TargetMachine)' == ''"` matches the VS sheets' own pattern and cannot clobber
an intentional value (e.g. the repo's `MachineX86` for Win32).

The upstream-correct fix would be widening the condition in `src/common.build.pre.props` to
cover x64, but that means editing a tracked file, so it was deliberately not done here.

---

## 4. Files added by this local setup

Untracked, inside the repo:

| File | Purpose |
|---|---|
| `build.cmd` | Sets `ForceImportAfterCppProps`, runs razzle, then `bcz dbg` |
| `vcpkg-prewarm.cmd` | Standalone `vcpkg install` for x64-windows-static, to pre-warm deps |

Outside the repo, in `C:\Users\Etsuya\Programming\wte\_setup\`:

| File | Purpose |
|---|---|
| `x64-lib-targetmachine.props` | The `ForceImportAfterCppProps` payload (§3.4) |
| `vs_Community.exe` | VS 2026 bootstrapper |
| `install-vs.ps1` | Elevated VS install wrapper |
| `vs-install.log` | Install transcript incl. exit code |

`build.cmd` references the props file by absolute path, so moving `_setup\` breaks the build
unless `build.cmd` is updated too.

---

## 5. Reproduce

```cmd
rem 1. toolchain (once, elevated)
C:\Users\Etsuya\Programming\wte\_setup\install-vs.ps1

rem 2. vswhere package + MSBuild on PATH are handled inside build.cmd
rem 3. pre-warm vcpkg deps (optional, makes failures cheaper to debug)
cd C:\Users\Etsuya\Programming\wte\terminal
cmd /c vcpkg-prewarm.cmd

rem 4. full clean build
cmd /c build.cmd
```

What `bcz dbg` actually runs (echoed by bcz into the log):

```
MSBuild.exe OpenConsole.slnx /t:"Clean;Build" /m
  /p:Configuration=Debug /p:GenerateAppxPackageOnBuild=false
  /p:Platform=x64 /p:AppxBundle=false
```

## 6. Verification

```
0 Error(s), 248 Warning(s), 190 projects, Time Elapsed 00:14:35
```

Artifacts, all verified `PE32+ ... x86-64`:

| Binary | Size |
|---|---|
| `bin\x64\Debug\OpenConsole.exe` | 9,374,720 |
| `bin\x64\Debug\wt.exe` | 1,176,576 |
| `src\cascadia\CascadiaPackage\bin\x64\Debug\WindowsTerminal.exe` | 4,908,032 |

The package loose layout is complete (`AppxManifest.xml`, `CascadiaPackage.build.appxrecipe`,
all `.dll` / `.winmd` / `.pri`). Disk after build: **77.9 GB free** (`bin` 5.9 GB + `obj` 20 GB).

## 7. Caveats

- VS install returned **3010** (reboot recommended). The build succeeded **without rebooting**;
  treat a reboot as optional cleanup, not a prerequisite.
- **No `.msix` is produced.** `bcz` passes `/p:GenerateAppxPackageOnBuild=false`, and on Debug it
  also adds `/p:AppxBundle=false`. Build Release to get a package.
- 248 warnings are expected noise on this tree, including a benign `CS1668` about a missing
  `atlmfc\lib\x64` search path (the ATL libraries are not installed; nothing failed on it).
- Deploying/running the built Terminal (`Add-AppxPackage`, loose-layout registration) needs
  **Developer Mode enabled** and elevation. Not done — out of scope for a build-only run.
- `WindowsTerminal.exe` **cannot** be launched directly from `bin\`; it requires package
  registration (see upstream `doc/building.md`).
