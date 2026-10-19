# Changelog

[Chinese](docs/CHANGELOG_zh.md)

## Unreleased

### Added

- Explicit Identifier_Status lookup and optional literal-codepoint filtering with typed first-failure evidence. Registration examples demonstrate opting in with a new application policy version and reviewing newly rejected accounts during migration. Canonical-equivalence closure and full General Security Profile conformance are not claimed.
- Additive full-script lookups and UTS #39 augmented/resolved script sets, including shared-character constraints and Japanese/Korean/Han-Bopomofo writing systems; exhaustive official-property verification across all 1,114,112 codepoints.
- Pinned ScriptExtensions, PropertyValueAliases, and IdentifierStatus sources, strict property parsing, and complete low-level Unicode property tables. Existing script categories and default identifier policies are unchanged.
- Public-API account-registration reference store with explicit syntax/profile choices, sensitive or folded keys, and separate accepted, duplicate, collision, and rejected decisions with character evidence.
- Versioned snapshots with validated restoration and all-or-nothing index rebuilding from original names. Stale metadata, forged keys, duplicate accounts, and newly introduced migration conflicts fail explicitly.
- A runnable `moon run cmd/registration` walkthrough, 17 integration acceptance tests, bilingual integration instructions, and CI execution for WASM, JavaScript, and native. The integration imports the public library API.

### Documentation

- Added a bilingual post-review roadmap with incomplete milestones, executable acceptance criteria, and proposed v0.2.0 release gates. The next implementation priority is a public-API account-registration reference integration.
- Updated product positioning and README navigation for library integrators, distinguishing planned work and reference examples from actual application adoption.

### Fixed

- Official NFD verification now reads its vectors directly from the checksum-verified source, rejects empty or malformed suites, and no longer depends on a derived JSON cache that could silently reduce coverage.
- New Unicode downloads are checksum-checked before atomic cache publication; interrupted or invalid downloads no longer leave a bad cache that blocks subsequent retries.
- Unicode regeneration now requires the complete, reviewed source manifest before downloading or generating files, validates the pinned version, URLs, and checksum fields, and never rewrites the manifest from cached data. Added offline regression checks to CI.
- CI, Pages, and Copilot setup now install the shared compiler version from `.moon-version`, preventing unreviewed formatter and interface changes when the latest toolchain changes.

## [0.1.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.1.0) - 2026-10-12

First public release of MoonSpoof, a pure MoonBit Unicode confusable and identifier-risk engine with a bilingual browser showcase.

### Added

- Pinned Unicode 16.0.0 data for confusable mappings, scripts, canonical decomposition, full default case folding, and default ignorables; six official source files recorded with SHA-256 checksums.
- Stable application skeletons with NFD normalization, algorithmic Hangul decomposition, default-ignorable removal, and fullwidth ASCII/ideographic-space folding.
- Case-sensitive and case-insensitive pair comparison and hash-based batch collision groups, preserving first-seen order and duplicate entries.
- Character evidence, mixed-script restriction estimates, configurable identifier profiles, and risk rules for invisible characters, controls, bidi overrides, and file-extension spoof heuristics.
- Public MoonBit APIs, a CLI demonstration, JavaScript browser bindings, and WASM, JavaScript, and native compiler-target support.
- A Chinese/English React showcase with pair comparison, character diagnostics, batch scanning, bidi rendering, a worker-based engine, and GitHub Pages deployment.
- Unit, regression, whitebox, property, browser ABI, and worker-lifecycle tests; official Unicode normalization/mapping verification and reproducible benchmark tools.
- Bilingual API, architecture, implementation-scope, benchmark, and branding documentation.

### Corrected during pre-release development

- Replaced partial normalization and casing with Unicode-backed NFD and full default C/F folding.
- Made case-insensitive comparison depend exclusively on folded-key equality, matching case-insensitive batch grouping. For example, `I` and `l` collide in sensitive mode but differ in folded mode; the two policies are separate equivalence relations.
- Stabilized mapping/normalization output, including Hangul and mapping targets that normalize into another mapped codepoint.
- Corrected diagnostic JSON control escaping, astral-codepoint handling, CJK restriction estimates, batch ordering, and worker failure handling.
- Made generated Unicode source-manifest ordering portable across platforms.

### Scope and compatibility

- MoonSpoof implements selected UTS #39 mechanisms and does not claim full conformance. A matching key or risk signal does not establish malicious intent.
- Script analysis exposes eleven named categories plus Unknown. Script_Extensions, Identifier_Status, mixed-number detection, NFKC/NFKD, and bidi skeleton reordering are outside this release.
- Identifier profiles are application policies; callers must enforce their own identifier syntax. File-extension spoof detection is a heuristic.
- Fullwidth folding and normalization to stable keys are application extensions. Store the library and Unicode data versions with persisted keys, and recompute keys when upgrading.

See the [implementation scope](docs/SPECIFICATION.md), [API contracts](docs/API_SPECIFICATION.md), and [live showcase](https://sidney-sunny.github.io/MoonSpoof/).
