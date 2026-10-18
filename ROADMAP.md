# MoonSpoof roadmap

[Chinese](docs/ROADMAP_zh.md)

Planning updated: 2026-10-18. The project has passed preliminary review, as reported by the owner. This is a development plan, not evidence of final acceptance or production adoption.

## Goal

Make MoonSpoof a usable MoonBit library for detecting confusable account and package identifiers. Start with one complete account-registration integration, then improve the Unicode mechanisms that determine its results. The browser showcase supports inspection; library correctness and integration determine progress.

## Current baseline

- Released: [v0.1.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.1.0), with MoonBit APIs, a JavaScript engine artifact, and a bilingual showcase.
- Implemented: Unicode 16.0.0 NFD, full default case folding, application skeletons, character diagnostics, configurable policies, and batch collision grouping.
- Existing verification: 19,965 official NFD vectors / 99,825 assertions, confusable and case-fold mappings, and key-stability checks. See [scope and evidence](docs/SPECIFICATION.md).
- Reproducibility: six checksum-pinned Unicode sources, validated atomic downloads, direct verification against the official normalization source, and a pinned MoonBit compiler.
- Open gaps: eleven named script categories, no full Script_Extensions or Identifier_Status, no mixed-number detection or bidi skeleton reordering. A real application integration has not yet been documented.

## Milestone order

M1 is implemented as a reference integration; M2–M4 remain planned and incomplete. Estimates for remaining work are focused developer days, not calendar deadlines, and have not yet been revised from the initial plan. No competition deadline has been supplied. Version numbers are proposals until their release gates pass.

| Order | Deliverable | Completion evidence | Estimate |
| --- | --- | --- | --- |
| M1 — complete | Runnable account-registration example | [Guide](examples/registration/README.md), executable and acceptance tests | Delivered 2026-10-18 |
| M2 | Script sets and an explicit identifier-status policy | Pinned data, reviewed API changes, multilingual regressions | 4–7 days |
| M3 | Mixed-number checks and reference comparisons | Reproducible results with explained differences | 3–5 days |
| M4 | Integration review and proposed v0.2.0 release | Completed gates, migration notes, verified release artifacts | 2–3 days |

## M1 — Complete one integration

Implemented in [the registration example](examples/registration/README.md), importing the public API. Run `moon run cmd/registration` from the repository root. This remains a reference integration until an actual application adopts it; do not describe a repository example as external usage.

Acceptance criteria:

- [x] One documented command loads existing names and evaluates registration candidates without the showcase: [executable](cmd/registration/main.mbt). Verified from a clean source export; CI runs all three compiler targets.
- [x] Accepted names, exact duplicates, collisions, and policy failures return explicit decisions and evidence: [store](examples/registration/registry.mbt).
- [x] Public-API cases cover `paypal` / `p\u0430ypal`, multilingual names, default ignorables, the `I` / `l` policy difference, and independent syntax/profile decisions: [registration tests](examples/registration/registry_test.mbt).
- [x] Stored keys carry versions and policy metadata; restore validates keys and rebuild rechecks original names without publishing a partial index: [migration implementation](examples/registration/snapshot.mbt) and [tests](examples/registration/snapshot_test.mbt). The guide documents production atomicity requirements.
- [x] [English](examples/registration/README.md) and [Chinese](examples/registration/README_zh.md) instructions identify imports, call sites, expected decisions, and limitations. Fifteen acceptance tests exercise the public API integration.

## M2 — Improve script and identifier decisions

Address the script-analysis limits before adding more heuristic risk scores. Keep current application behavior documented while introducing more precise Unicode-backed checks.

Acceptance criteria:

- [ ] Pin the Unicode 16.0.0 Script_Extensions and Identifier_Status sources in the reviewed manifest, with official URLs, checksums, offline validation tests, and reproducible generation.
- [ ] Design and review a representation for complete script sets and Script_Extensions resolution. Record compatibility with the existing public script categories before updating generated interfaces.
- [ ] Add an explicit opt-in Identifier_Status policy with actionable rejection evidence. Keep it separate from application syntax validation and the existing default policy unless a breaking change is documented.
- [ ] Add multilingual regression cases for shared/inherited characters, CJK combinations, previously Unknown scripts, and restricted identifiers. Revisit restriction estimates against the pinned specification and record remaining gaps.
- [ ] Update API contracts, scope, migration notes, and tests together. Existing stored-key behavior must remain stable or carry an explicit migration requirement.

## M3 — Check numeric mixing and reference behavior

Use the same pinned Unicode version for reference comparisons. Differences caused by MoonSpoof's application extensions must remain visible rather than being counted as unexplained passes or failures.

Acceptance criteria:

- [ ] Implement mixed-number detection from complete pinned numeric-property data, with tests for a single decimal system, mixed systems, and characters outside the intended check.
- [ ] Add a reproducible comparison harness against a pinned ICU build with compatible Unicode data. Record the ICU/data versions, compared APIs, corpus, and command; keep this optional reference dependency outside the library runtime.
- [ ] Separate standard mechanisms from fullwidth folding, default-ignorable handling, stable application keys, and case-fold policy. Explain every observed difference in the committed comparison corpus.
- [ ] Expand adversarial and multilingual regressions around combining marks, supplementary characters, controls, and long inputs. Retain pair/batch equivalence and key-stability checks.
- [ ] Publish a coverage matrix of implemented mechanisms, tested behavior, and deferred work. Passing comparisons must not be presented as full UTS #39 conformance.

## M4 — Review integration and release

The proposed v0.2.0 release requires M1–M3 and the gates below. If scope changes, revise this plan and release notes before assigning the version.

Acceptance criteria:

- [ ] Run the M1 integration from a fresh checkout and document the result. If an external or owner-operated application is available, record its actual call site and feedback with permission; otherwise explicitly retain “reference integration only” as the adoption status.
- [ ] Pass MoonBit tests for WASM, JavaScript, and native in CI; pass generator tests, official Unicode verification, browser ABI/worker checks, and the production build. Run `moon info` and `moon fmt`, reviewing interface and generated-data changes.
- [ ] Publish reproducible measurements for key generation and batch grouping with corpus, input size, runtime, toolchain, and hardware details. Make competitor performance claims only when equivalent controlled measurements exist.
- [ ] Review API/data compatibility, index rebuilding, bilingual installation instructions, changelogs, and scope. Verify the MoonBit package registry publication state separately from GitHub release assets before advertising either installation path.
- [ ] Verify commit, tag, and authenticated push identities as `Sidney-sunny`; publish the reviewed tag, release notes, artifacts, and checksums after all gates pass.

## Next two implementation rounds

1. **Script foundation:** start M2 with reviewed source metadata, reproducible tables, and the script-set API decision. Preserve the existing facade and document compatibility before changing behavior.
2. **Identifier decisions:** continue M2 with opt-in Identifier_Status checks, multilingual regressions, and updated restriction estimates and contracts. Do not mark M2 done when only tables exist.

These describe future implementation work. M1's reference integration does not complete M2 or establish external application adoption.

## Scope control

- Keep the core a reusable MoonBit library. No account server, database framework, or new UI platform is required to demonstrate integration.
- Keep Unicode 16.0.0 pinned through this sequence. Plan a later Unicode upgrade as a separate data and compatibility review.
- Defer full bidi skeleton reordering, NFKC/NFKD, IDNA/domain validation, locale-specific casing, and any full-conformance claim. Revisit them only with an explicit use case and acceptance corpus.
- Fix correctness and integration blockers first. CI hardening and visual polish alone do not satisfy a product milestone.
- Update milestone checkboxes only with links to executable evidence; record external adoption only when it actually happens.
