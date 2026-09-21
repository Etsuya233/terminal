# AGENTS.md

> **Local fork — not upstream content.** This checkout is a personal fork of
> `microsoft/terminal`, built locally on this machine.

Before building, running, or debugging anything here, read **[`LOCAL_RUN.md`](./LOCAL_RUN.md)**.
It records the exact toolchain, the obstacles hit during the first build, and the non-invasive
workarounds applied — in particular the fact that a build here depends on local scaffolding
(`build.cmd`, `vcpkg-prewarm.cmd`, and a `ForceImportAfterCppProps` payload that lives outside
the repo). Skipping it will very likely produce a confusing failure.

Branches:

- `dev/ety` — this fork's development branch. Do work here.
- `main` — tracks upstream `microsoft/terminal`; keep it clean for rebases.
