# Acceptance audit

[Chinese](ACCEPTANCE_zh.md)

Checked 2026-10-30 with `moonc v0.10.18+6c83a7f62` and `moon 0.1.20261028`. This repository report records engineering evidence against the owner's nine requirements; it is not a submission form or official acceptance.

## Result against the nine requirements

Requirements 1–8 have implementation and verification evidence. Requirement 9 is repaired in current source and the prepared archive, but the existing Mooncakes 0.1.0 artifact lacks the newly retained third-party notices. A new version is required before claiming the complete distributed package meets all nine requirements. No new registry version was published in this audit.

| Requirement | Status | Reproducible evidence |
| --- | --- | --- |
| 1. Primarily MoonBit; compiler at least 0.10.16 | Pass at requested 0.10.18 | [.moon-version](../.moon-version) pins `0.10.18+6c83a7f62`; [version gate](../tools/verify-toolchain.py) checks the actual compiler. Core algorithms, facade and integration are MoonBit, with 41 tracked source/test files |
| 2. Public GitHub, clear history | Pass | [Repository](https://github.com/Sidney-sunny/MoonSpoof), [commits](https://github.com/Sidney-sunny/MoonSpoof/commits/main/); uploads verify `Sidney-sunny` authentication, author and committer |
| 3. Clear structure and core behavior | Pass within stated scope | [Implementation scope](SPECIFICATION.md), [API](API_SPECIFICATION.md), 97 MoonBit tests; no full UTS #39 claim |
| 4. README, installation, usage and examples | Pass | [README](../README.md), [Chinese guide](README_zh.md); `moon add Sidney-sunny/moonspoof` and the public import exercised in a separate module |
| 5. CI checks, builds and tests | Pass once the matching CI run succeeds | [Workflow](../.github/workflows/ci.yml) explicitly verifies the compiler and runs check/build/test for WASM, JS and native; [Actions](https://github.com/Sidney-sunny/MoonSpoof/actions) additionally verify generators, ABI/build, Unicode, ICU and registry installation |
| 6. Runnable example | Pass | `moon run cmd/registration`, `moon run cmd/main`; [integration guide](../examples/registration/README.md). Clean tracked-source export of `3051c64` ran the integration and 97 tests |
| 7. Core-path tests | Pass | 97 MoonBit, 19 generator, 14 ABI/worker and 7 reference-harness tests; 4,456,448 full-space property assertions, official NFD/mapping checks and [ICU coverage](REFERENCE_COMPARISON.md) |
| 8. Published to mooncakes.io | Pass for 0.1.0 | [Public package](https://mooncakes.io/modules/Sidney-sunny/moonspoof) lists non-yanked 0.1.0, published 2026-10-23; [clean consumer](../tools/verify-registry-consumer.py) runs its keys/properties/policies on WASM and JS under 0.10.18 |
| 9. OSI license and upstream terms | Source/archive repaired; registry artifact pending | [Apache-2.0](../LICENSE) is [OSI approved](https://opensource.org/license/apache-2-0); [upstream notices](../THIRD_PARTY_NOTICES.md), license texts and generated attribution are retained. Site output carries license copies. Existing registry 0.1.0 cannot be overwritten |

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
uv run --no-project python tools/verify-registry-consumer.py
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground run check
pnpm --dir playground run verify:unicode
pnpm --dir playground run verify:icu
moon info
moon fmt
```

Linux/CI can use `python3` for the standard-library scripts. ICU needs `java` and `javac` on PATH; the audit used process-local JDK 21.0.10.0.10. Ubuntu CI verifies native; this report does not claim a local Windows native build. Regeneration plus `moon info` / `moon fmt` must reproduce committed tables and interfaces.

The consumer uses a new temporary module, a fixed registry dependency and no local override. It may reuse the package manager's download cache. Installing registry 0.1.0 does not install this audit's source/compiler-pin or notice changes.

## Remaining distribution action

Publish a reviewed new version with the compiler-compatible source and upstream notices. `moon package --list` verified inclusion of `LICENSE`, `THIRD_PARTY_NOTICES.md` and both retained license texts. Publication validation of unchanged 0.1.0 reports a duplicate-version conflict; it was not replaced. Tokens, saved credentials and private material stay outside the archive and Git history. The saved Mooncakes account was changed to `Sidney-sunny` using its account-specific environment key.

The [roadmap](../ROADMAP.md) separately retains measurements, compatibility review and proposed v0.2.0 release gates. Those goals do not change the nine supplied requirements. No external adoption or upcoming release is certified here.
