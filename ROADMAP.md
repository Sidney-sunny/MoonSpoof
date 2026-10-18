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

All milestones below are planned and incomplete. Estimates are focused developer days, not calendar deadlines. Re-estimate after M1; no competition deadline has been supplied. Version numbers are proposals until their release gates pass.

| Order | Deliverable | Completion evidence | Estimate |
| --- | --- | --- | --- |
| M1 | Runnable account-registration example | Executable acceptance cases using the public library | 2–4 days |
| M2 | Script sets and an explicit identifier-status policy | Pinned data, reviewed API changes, multilingual regressions | 4–7 days |
| M3 | Mixed-number checks and reference comparisons | Reproducible results with explained differences | 3–5 days |
| M4 | Integration review and proposed v0.2.0 release | Completed gates, migration notes, verified release artifacts | 2–3 days |

## M1 — Complete one integration

Build a small runnable MoonBit registration example that imports the public API. Treat it as a reference integration until an actual application adopts it; do not describe a repository example as external usage.

Acceptance criteria:

- [ ] A fresh checkout can run one documented command to load existing names and evaluate registration candidates without starting the showcase.
- [ ] The example distinguishes accepted names, exact duplicates, confusable collisions, and policy failures. It returns the existing conflicting identifier and useful diagnostic evidence.
- [ ] Executable cases cover `paypal` / `p\u0430ypal`, a valid multilingual name, a default-ignorable character, and the documented `I` / `l` difference between sensitive and folded modes. Syntax validation and the choice of collision policy are explicit application decisions.
- [ ] The example records library/data versions and the selected key policy with stored keys, and demonstrates rebuilding the index after a version or policy change. Document the need for atomic collision enforcement in a concurrent production store; do not claim the in-memory example provides it.
- [ ] English and Chinese integration instructions identify the import, call site, expected decisions, and limitations. Tests exercise the integration through public APIs.

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

1. **Registration integration:** implement M1 as a bounded change; include public-API acceptance tests and bilingual instructions. This is the next coding priority after the roadmap.
2. **Script foundation:** start M2 with reviewed source metadata, reproducible tables, and the script-set API decision. Complete the remaining M2 work in later commits if needed; do not mark M2 done when only tables exist.

These describe future implementation work. The two documentation pushes that introduce this roadmap and align the product documentation do not complete M1 or M2.

## Scope control

- Keep the core a reusable MoonBit library. No account server, database framework, or new UI platform is required to demonstrate integration.
- Keep Unicode 16.0.0 pinned through this sequence. Plan a later Unicode upgrade as a separate data and compatibility review.
- Defer full bidi skeleton reordering, NFKC/NFKD, IDNA/domain validation, locale-specific casing, and any full-conformance claim. Revisit them only with an explicit use case and acceptance corpus.
- Fix correctness and integration blockers first. CI hardening and visual polish alone do not satisfy a product milestone.
- Update milestone checkboxes only with links to executable evidence; record external adoption only when it actually happens.
