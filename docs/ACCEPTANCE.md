# Acceptance audit

[Chinese](ACCEPTANCE_zh.md)

Checked 2026-10-30 with `moonc v0.10.18+6c83a7f62` and `moon 0.1.20261028`. This repository report records engineering evidence against the owner's nine requirements; it is not a submission form or official acceptance.

## Result against the nine requirements

All nine requirements now have engineering verification evidence for 0.2.0. Mooncakes 0.2.0 is published and independently installed on WASM/JS with its upstream notices verified; the [GitHub release](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.2.0) and annotated tag point to `a30e36f969c221efc443bc9f1788f021dd7f6891`. Downloaded release assets independently passed manifest/checksum verification. The earlier 0.1.0 notice gap is resolved by the new version, without overwriting 0.1.0. This does not establish official acceptance.

| Requirement | Status | Reproducible evidence |
| --- | --- | --- |
| 1. Primarily MoonBit; compiler at least 0.10.16 | Pass at requested 0.10.18 | [.moon-version](../.moon-version) pins `0.10.18+6c83a7f62`; [version gate](../tools/verify-toolchain.py) checks the actual compiler. Core algorithms, facade and integration are MoonBit, with 43 tracked source/test files |
| 2. Public GitHub, clear history | Pass | [Repository](https://github.com/Sidney-sunny/MoonSpoof), [commits](https://github.com/Sidney-sunny/MoonSpoof/commits/main/); uploads verify `Sidney-sunny` authentication, author and committer |
| 3. Clear structure and core behavior | Pass within stated scope | [Implementation scope](SPECIFICATION.md), [API](API_SPECIFICATION.md), 99 MoonBit tests; no full UTS #39 claim |
| 4. README, installation, usage and examples | Pass | [README](../README.md), [Chinese guide](README_zh.md); `moon add Sidney-sunny/moonspoof` and the public import exercised in a separate module |
| 5. CI checks, builds and tests | Pass | [Release-commit CI](https://github.com/Sidney-sunny/MoonSpoof/actions/runs/41044994373) passed compiler checks and check/build/test for WASM, JS and native, plus generators, ABI/build, Unicode, ICU and registry installation |
| 6. Runnable example | Pass | `moon run cmd/registration`, `moon run cmd/main`; [integration guide](../examples/registration/README.md). Final release source ZIP ran the registration integration and engine build without .git |
| 7. Core-path tests | Pass | 99 MoonBit, 19 generator, 15 packaging, 14 ABI/worker and 7 reference-harness tests; 4,456,448 full-space property assertions, official NFD/mapping checks and [ICU coverage](REFERENCE_COMPARISON.md) |
| 8. Published to mooncakes.io | Pass for 0.2.0 | [Public package](https://mooncakes.io/modules/Sidney-sunny/moonspoof) lists non-yanked 0.2.0, published 2026-10-30; [clean consumer](../tools/verify-registry-consumer.py) checks exact library version, keys/properties/policies and notices on WASM and JS |
| 9. OSI license and upstream terms | Pass for 0.2.0 distribution | [Apache-2.0](../LICENSE) is [OSI approved](https://opensource.org/license/apache-2-0); [upstream notices](../THIRD_PARTY_NOTICES.md), license texts and generated attribution are retained. Downloaded registry and release artifacts include the notices; site output also carries React/Vite runtime notices |

## Reproduce the checks

Use the pinned compiler. CI's official installer uses `MOONBIT_INSTALL_VERSION`; the version gate rejects another compiler build.

```powershell
moon version --all
uv run --no-project python tools/verify-toolchain.py
moon check
moon build --target wasm
moon test
moon test --target js
moon run cmd/registration
uv run --no-project python tools/verify-registry-consumer.py --version 0.2.0
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground run check
pnpm --dir playground run verify:unicode
pnpm --dir playground run verify:icu
moon info
moon fmt
```

Linux/CI can use `python3` for the standard-library scripts. ICU needs `java` and `javac` on PATH; the audit used process-local JDK 21.0.10.0.10. Ubuntu CI verifies native; this report does not claim a local Windows native build. Regeneration plus `moon info` / `moon fmt` must reproduce committed tables and interfaces.

The consumer uses a new temporary module, a fixed registry dependency and no local override. It may reuse the package manager's download cache. Installing registry 0.1.0 does not install this audit's source/compiler-pin or notice changes.

## Verified distribution

Published 0.2.0 with compiler-compatible source, exact version identity and retained Unicode/Manrope/React/Vite notices. The verified registry checksum is `c24722e4a5ab5ab62998da011bdf7510479340458546a52561b1c84c70451543`. Source/engine/site ZIPs, RELEASE_MANIFEST.json and SHA256SUMS were downloaded from GitHub and checked with `tools/package-release.py --verify`. Commit, tag, push and release identities were checked as Sidney; the Mooncakes saved account is `Sidney-sunny`. Tokens and private material remain outside the archive and history.

The [roadmap](../ROADMAP.md) records completed M1–M4 gates and [release notes](RELEASE_0.2.0.md) explain compatibility and remaining standards limits. No external adoption or official acceptance is certified here.
