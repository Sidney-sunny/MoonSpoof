# MoonSpoof 0.2.0 release notes

[Chinese](RELEASE_0.2.0_zh.md)

Released 2026-10-30. Toolchain: `moonc 0.10.18+6c83a7f62`. Data: Unicode 16.0.0, nine checksum-pinned official files. Mooncakes and GitHub release verification is recorded in the [acceptance report](ACCEPTANCE.md).

## What this release delivers

Complete Script/Script_Extensions lookups and resolved script sets; an optional literal Identifier_Status filter with typed failures; complete decimal mixing checks covering 76 Nd families; a runnable registration integration with explicit decisions, versioned snapshots and controlled rebuilding; and reproducible ICU4J 76.1 comparisons with all observed differences pinned. See the [mechanism coverage matrix](REFERENCE_COMPARISON.md) for evidence and boundaries.

These mechanisms are new relative to the GitHub `v0.1.0` tag. The separately published Mooncakes `0.1.0` already contains many of the later script/status/number APIs and integration tests. Compared with that registry package, 0.2.0 primarily delivers the fixed 0.10.18 toolchain, retained distribution notices, release verification and measurements, and explicit library version identity. Do not treat both 0.1.0 artifacts as identical baselines.

`get_library_version() -> String` now returns `"0.2.0"`. Registration metadata reads that API instead of duplicating the version string. CI verifies the facade/module/showcase versions together. Two additional public regressions bring the MoonBit suite to 99 tests, including the 0.1.0-to-0.2.0 index migration.

## Compatibility and migration

| Area | Contract |
| --- | --- |
| Compiler | Use the exact 0.10.18 pin and recompile callers. Compatibility with older compilers is not claimed |
| Existing public API | Existing visibility and optional profile arguments are retained; `Int32` spelling in generated interfaces is the compiler's alias spelling for the same 32-bit integer type |
| Keys and Unicode | Unicode version, skeleton algorithm/data, sensitive/folded equivalence policies and default profiles remain unchanged |
| Stored reference indexes | Version metadata advances to 0.2.0. Direct restore of 0.1.0 metadata fails; rebuild from original names and switch only after success |
| Optional filters | Enabling Identifier_Status or decimal mixing requires a new application policy version and review of newly rejected accounts; neither filter becomes a default |

Run `moon run cmd/registration`. The [migration regression](../examples/registration/snapshot_test.mbt) verifies unchanged keys after rebuilding old metadata and preservation of the old snapshot. Applications remain responsible for concurrent writer coordination and atomic database enforcement. The reference store has no database or serialized snapshot adapter.

## Verification and distribution

The release requires WASM, JavaScript and native checks/builds/tests in CI, 19 generator tests, browser ABI/worker checks, 4,456,448 full-space property assertions, official NFD/mapping verification, and a 42-case ICU corpus. [Benchmarks](BENCHMARKS.md) publish inputs, runtime, compiler, hardware, repeated samples and reproducible commands; they make no competitor ranking.

Release archives are built from a clean committed tree, include source/engine/site payloads and retained license texts, and carry a release manifest plus SHA-256 checksums. Engine and site build metadata must match the release commit, compiler and version. Apache-2.0 covers original source; Unicode, Manrope, React and Vite retain [their upstream notices](../THIRD_PARTY_NOTICES.md).

The source ZIP also builds without `.git`, using its archived metadata. Such unversioned builds are marked dirty and cannot be repackaged as verified clean release inputs.

## Limits

No full UTS #39 conformance, canonical-equivalence closure for the literal status filter, bidi skeleton reordering, NFKC/NFKD, IDNA or locale-specific casing is claimed. Legacy restriction estimates remain scoped. The integration is a repository reference, not evidence of external production adoption.
