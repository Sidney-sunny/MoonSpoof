# MoonSpoof roadmap

[Chinese](docs/ROADMAP_zh.md)

Planning updated: 2026-10-22. The project has passed preliminary review, as reported by the owner. This is a development plan, not evidence of final acceptance or production adoption.

## Goal

Make MoonSpoof a usable MoonBit library for detecting confusable account and package identifiers. Start with one complete account-registration integration, then improve the Unicode mechanisms that determine its results. The browser showcase supports inspection; library correctness and integration determine progress.

## Current baseline

- Released: [v0.1.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.1.0), with MoonBit APIs, a JavaScript engine artifact, and a bilingual showcase.
- Implemented: Unicode 16.0.0 NFD, full default case folding, application skeletons, character diagnostics, configurable policies, and batch collision grouping.
- Existing verification: 19,965 official NFD vectors / 99,825 assertions, confusable and case-fold mappings, key-stability checks, and 4,456,448 script/status/decimal property assertions across the full code space. See [scope and evidence](docs/SPECIFICATION.md).
- Reproducibility: nine checksum-pinned Unicode sources, validated atomic downloads, direct verification against the official normalization source, and a pinned MoonBit compiler.
- Open gaps: legacy diagnostics retain eleven named script categories; separate full-script, resolved-set and opt-in literal Identifier_Status APIs now exist. Opt-in decimal mixing checks are also implemented. Canonical-equivalence closure and bidi skeleton reordering remain pending. A real application integration has not yet been documented.

## Milestone order

M1 is implemented as a reference integration; M2/M3 are complete within the explicit scopes below. M4 remains incomplete. Estimates for remaining work are focused developer days, not calendar deadlines, and have not yet been revised from the initial plan. No competition deadline has been supplied. Version numbers are proposals until their release gates pass.

| Order | Deliverable | Completion evidence | Estimate |
| --- | --- | --- | --- |
| M1 — complete | Runnable account-registration example | [Guide](examples/registration/README.md), executable and acceptance tests | Delivered 2026-10-18 |
| M2 — complete within stated scope | Script sets and an explicit identifier-status filter | [API contracts](docs/UNICODE_PROPERTIES.md), [status regressions](moonspoof_status_test.mbt), [migration tests](examples/registration/status_test.mbt) | Delivered 2026-10-19 |
| M3 — complete within stated scope | Mixed-number checks and reference comparisons | [Pinned ICU comparison and coverage matrix](docs/REFERENCE_COMPARISON.md), adversarial regressions | Delivered 2026-10-22 |
| M4 | Integration review and proposed v0.2.0 release | Completed gates, migration notes, verified release artifacts | 2–3 days |

## M1 — Complete one integration

Implemented in [the registration example](examples/registration/README.md), importing the public API. Run `moon run cmd/registration` from the repository root. This remains a reference integration until an actual application adopts it; do not describe a repository example as external usage.

Acceptance criteria:

- [x] One documented command loads existing names and evaluates registration candidates without the showcase: [executable](cmd/registration/main.mbt). Verified from a clean source export; CI runs all three compiler targets.
- [x] Accepted names, exact duplicates, collisions, and policy failures return explicit decisions and evidence: [store](examples/registration/registry.mbt).
- [x] Public-API cases cover `paypal` / `p\u0430ypal`, multilingual names, default ignorables, the `I` / `l` policy difference, and independent syntax/profile decisions: [registration tests](examples/registration/registry_test.mbt).
- [x] Stored keys carry versions and policy metadata; restore validates keys and rebuild rechecks original names without publishing a partial index: [migration implementation](examples/registration/snapshot.mbt) and [tests](examples/registration/snapshot_test.mbt). The guide documents production atomicity requirements.
- [x] [English](examples/registration/README.md) and [Chinese](examples/registration/README_zh.md) instructions identify imports, call sites, expected decisions, and limitations. Nineteen acceptance tests exercise the public API integration, including optional status/numeric filtering and migration.

## M2 — Improve script and identifier decisions

Address the script-analysis limits before adding more heuristic risk scores. Keep current application behavior documented while introducing more precise Unicode-backed checks.

Completed within this scope: complete properties, resolved script sets, and an opt-in literal-codepoint status filter. The filter is not the full UTS #39 General Security Profile: canonical-equivalence closure remains deferred. Legacy restriction estimates retain their documented gaps and behavior.

Acceptance criteria:

- [x] Pinned ScriptExtensions, PropertyValueAliases and IdentifierStatus in the [reviewed manifest](tools/data-generator/sources.json), with strict parsing, offline tests and reproducible generation.
- [x] Added full property names and explicit All/intersection sets; [API and compatibility contracts](docs/UNICODE_PROPERTIES.md) preserve the legacy enum, estimates and default policies. [Regression tests](moonspoof_scripts_test.mbt) cover resolved sets.
- [x] Added an explicit opt-in Identifier_Status filter with typed first-failure evidence: [implementation](src/security/identifier_status.mbt) and [tests](moonspoof_status_test.mbt). It remains independent of application syntax and existing default profiles.
- [x] Added [script regressions](moonspoof_scripts_test.mbt) for shared/inherited characters, CJK combinations and previously Unknown scripts, plus [restricted-name regressions](moonspoof_status_test.mbt). The [scope review](docs/SPECIFICATION.md) records why legacy restriction estimates remain unchanged and incomplete.
- [x] Updated [API contracts](docs/UNICODE_PROPERTIES.md), scope and bilingual integration instructions together. Existing keys remain unchanged; [migration tests](examples/registration/status_test.mbt) require an explicit application policy version and review when enabling the filter.

## M3 — Check numeric mixing and reference behavior

Use the same pinned Unicode version for reference comparisons. Differences caused by MoonSpoof's application extensions must remain visible rather than being counted as unexplained passes or failures.

Completed with a 42-case ICU4J 76.1 / Unicode 16 corpus, exact per-field difference baselines and the coverage matrix below. This is scoped comparison evidence; canonical closure, bidi skeleton implementation, full conformance and external adoption remain outside this milestone.

Acceptance criteria:

- [x] Implemented [decimal mixing APIs](docs/NUMBER_SYSTEMS.md) from the pinned UnicodeData source, with [public regressions](moonspoof_numbers_test.mbt) for single/mixed systems and excluded numeric types, full-code-space property verification, and [registration migration tests](examples/registration/numbers_test.mbt).
- [x] Added a checksum-pinned ICU4J 76.1 oracle with runtime Unicode-version checks, [corpus](tools/icu-reference/corpus.json), [command and API scope](docs/REFERENCE_COMPARISON.md), and a dedicated CI job. Java/ICU remain optional verification dependencies outside the library runtime.
- [x] Recorded all 12 field differences with exact outputs and reasons in the corpus; [review](docs/REFERENCE_COMPARISON.md) distinguishes fullwidth folding, stable keys, folded policy and deferred bidi behavior. Default-ignorable removal agrees with ICU. [Harness tests](tools/icu-reference/reference.test.mjs) reject new, changed or stale differences.
- [x] Added [public adversarial regressions](moonspoof_adversarial_test.mbt) for long combining inputs, supplementary/control evidence, stable keys and pair/batch equivalence under both policies; multilingual cases also run through the ICU corpus.
- [x] Published a bilingual [coverage matrix](docs/REFERENCE_COMPARISON.md) separating implementation, official-source tests, sampled ICU comparisons and deferred work, without a full-conformance claim.

## M4 — Review integration and release

The proposed v0.2.0 release requires M1–M3 and the gates below. If scope changes, revise this plan and release notes before assigning the version.

Acceptance criteria:

- [ ] Run the M1 integration from a fresh checkout and document the result. If an external or owner-operated application is available, record its actual call site and feedback with permission; otherwise explicitly retain “reference integration only” as the adoption status.
- [ ] Pass MoonBit tests for WASM, JavaScript, and native in CI; pass generator tests, official Unicode verification, browser ABI/worker checks, and the production build. Run `moon info` and `moon fmt`, reviewing interface and generated-data changes.
- [ ] Publish reproducible measurements for key generation and batch grouping with corpus, input size, runtime, toolchain, and hardware details. Make competitor performance claims only when equivalent controlled measurements exist.
- [ ] Review API/data compatibility, index rebuilding, bilingual installation instructions, changelogs, and scope. Verify the MoonBit package registry publication state separately from GitHub release assets before advertising either installation path.
- [ ] Verify commit, tag, and authenticated push identities as `Sidney-sunny`; publish the reviewed tag, release notes, artifacts, and checksums after all gates pass.

## Next two implementation rounds

1. **Integration review:** start M4 from a fresh checkout, run the registration integration and review API/data compatibility, index rebuilding and bilingual installation guidance. Keep adoption status explicit.
2. **Measurements and release review:** publish reproducible key/batch measurements and verify package-registry state, release notes and artifact gates before assigning v0.2.0.

These describe future implementation work. M1–M3 evidence does not complete M4 or establish external application adoption.

## Scope control

- Keep the core a reusable MoonBit library. No account server, database framework, or new UI platform is required to demonstrate integration.
- Keep Unicode 16.0.0 pinned through this sequence. Plan a later Unicode upgrade as a separate data and compatibility review.
- Defer canonical-equivalence closure for identifier status, full bidi skeleton reordering, NFKC/NFKD, IDNA/domain validation, locale-specific casing, and any full-conformance claim. Revisit them only with an explicit use case and acceptance corpus.
- Fix correctness and integration blockers first. CI hardening and visual polish alone do not satisfy a product milestone.
- Update milestone checkboxes only with links to executable evidence; record external adoption only when it actually happens.
