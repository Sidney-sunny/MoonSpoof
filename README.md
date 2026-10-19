<p align="center">
  <img src="docs/assets/banner.png" alt="MoonSpoof: Unicode Spoof Detection for MoonBit" width="960" />
</p>

<p align="center">
  <img alt="Version 0.1.0" src="https://img.shields.io/badge/Version-0.1.0-334155?style=flat-square" />
  <img alt="Unicode 16.0" src="https://img.shields.io/badge/Unicode-16.0.0-334155?style=flat-square" />
  <img alt="UTS #39" src="https://img.shields.io/badge/Standard-UTS_%2339-334155?style=flat-square" />
  <img alt="Targets WASM JS Native" src="https://img.shields.io/badge/Targets-WASM_%7C_JS_%7C_Native-334155?style=flat-square" />
  <a href="LICENSE"><img alt="Apache 2.0" src="https://img.shields.io/badge/License-Apache_2.0-334155?style=flat-square" /></a>
  <img alt="MoonBit Hackathon 2026" src="https://img.shields.io/badge/MoonBit-2026_Hackathon-000000?style=flat-square" />
</p>

<p align="center">
  Unicode confusable keys, character evidence, and batch collision detection for MoonBit.
</p>

<p align="center">
  <a href="docs/README_zh.md"><strong>简体中文文档</strong></a> ·
  <a href="#quickstart">Quickstart</a> ·
  <a href="docs/API_SPECIFICATION.md">API Specification</a> ·
  <a href="docs/ARCHITECTURE.md">Architecture</a> ·
  <a href="docs/BENCHMARKS.md">Benchmarks</a> ·
  <a href="CHANGELOG.md">Changelog</a> ·
  <a href="ROADMAP.md">Roadmap</a> ·
  <a href="docs/SPECIFICATION.md">Implementation Scope</a>
</p>

---

## What the engine provides

| Confusable keys | Character evidence | Batch grouping |
| --- | --- | --- |
| Unicode 16.0 NFD and full default case folding | Codepoint, script, raw mapping target and risk rules | Hash buckets using the same keys as pair comparison |
| Default ignorables and application fullwidth folding | Bidi/control detection and configurable identifier policy | Stable first-seen order; duplicates retained |
| Pure MoonBit; JS, WASM and native targets | Limited script categories; explicit standards gaps | No pairwise comparison of every name |

MoonSpoof implements selected UTS #39 mechanisms, not full conformance. Risk signals do not establish malicious intent. See [scope and compatibility](docs/SPECIFICATION.md).

## Development direction

The project has passed preliminary review, as reported by the owner. A runnable account-registration reference integration now demonstrates decisions, versioned snapshots, and index migration through the public MoonBit API. Better script/identifier checks and reference comparisons remain planned. The [roadmap](ROADMAP.md) records milestone evidence and the proposed v0.2.0 release gates; a repository example does not establish external application adoption.

## Run the registration integration

```powershell
moon run cmd/registration
```

Load existing accounts, distinguish duplicate and confusable registration attempts, inspect rejected invisible characters, and rebuild an index after changing policies. The [bilingual integration guide](examples/registration/README.md) documents call sites, expected outcomes, snapshot validation, and production storage responsibilities. No frontend dependencies are required.

## Run the bilingual showcase

[Open the live demo](https://sidney-sunny.github.io/MoonSpoof/). GitHub Actions builds and publishes the current `main` branch to Pages after the engine and frontend checks pass.

```powershell
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground dev
```

Open the URL printed by Vite. Chinese is the default; EN / 中文 switches the entire interface. The browser runs freshly compiled MoonBit JavaScript in a worker and keeps inputs on the device. Compare identifiers, inspect character evidence, scan lists, and examine bidi rendering. The competitor matrix cites official ICU and confusable_homoglyphs APIs and makes no performance ranking.

```powershell
moon run cmd/main
```

---

## Quickstart

### 1. Add Dependency

Add the module with `moon add Sidney-sunny/moonspoof`, then import it in your package's `moon.pkg`:

```moonbit
import {
  "Sidney-sunny/moonspoof" @moonspoof,
}
```

### 2. Basic Confusable Comparison

```moonbit
let authentic = "paypal"
let spoofed = "p\u0430ypal" // Cyrillic Small Letter A (U+0430)

// Check if two identifiers share an identical visual skeleton
let confusable : Bool = @moonspoof.are_confusable(authentic, spoofed)
// confusable == true

// Generate the normalized application skeleton
let sk : String = @moonspoof.skeleton(spoofed)
// sk == "paypal"
```

### 3. Detailed Character Diagnostics & Risk Evaluation

```moonbit
let report = @moonspoof.analyze_identifier("admin\u200B")

// Check overall risk level: Safe, Low, Medium, High, Critical
println(report.risk_level) // Critical

// Inspect triggered security rules
println(report.rules_triggered) // ["RULE_INVISIBLE_OR_FORMAT_CHARACTER"]
```

### 4. High-Throughput Batch Collision Scanning

```moonbit
let registered_users = ["admin", "adm\u0456n", "alice", "bob", "al\u0456ce"]
let collisions = @moonspoof.find_confusable_groups(registered_users)

// Case-insensitive clustering using full default folded keys
let mixed_users = ["PAYPAL", "p\u0430ypal", "Paypal", "stripe"]
let folded_collisions = @moonspoof.find_confusable_groups_ignore_case(mixed_users)

// Each group aggregates conflicting homoglyphic accounts
for group in collisions {
  println("Skeleton: \{group.skeleton}, Members: \{group.members}")
}
```

### 5. Identifier Profiles & Case-Insensitive Matching

```moonbit
// Case-insensitive matching using the folded application key
let is_conf = @moonspoof.are_confusable_ignore_case("PAYPAL", "P\u0430yPal") // true

// Custom identifier policy validation
let check = @moonspoof.validate_identifier("p\u0430ypal") // Err("Identifier contains disallowed mixed scripts")
let allowed = @moonspoof.is_allowed_identifier("valid_user") // true

// Restriction level querying (UTS #39 Section 5)
let level = @moonspoof.get_restriction_level("p\u0430ypal") // MinimallyRestrictive
```

---

## Security boundary

The legacy diagnostics expose eleven script categories plus Unknown. Additive [complete script and Script_Extensions APIs](docs/UNICODE_PROPERTIES.md) provide Unicode-backed lookups and resolved sets. Default policies do not enforce Identifier_Status; mixed-number checks and bidi skeleton reordering remain unimplemented. Identifier policies are configurable application checks, not full Unicode identifier syntax validation. Fullwidth folding and repeated normalization to stable keys are application extensions.

Sensitive and folded keys are separate policies: `I` / `l` can match in the sensitive mode while differing in folded mode. Stored keys should carry a library/data version and be recomputed after changing versions. [API contracts](docs/API_SPECIFICATION.md) describe the corrected behavior.

---

## Documentation & Architecture Guides

| Topic | Reference |
| :--- | :--- |
| Chinese Documentation / 中文说明书 | [README_zh.md](docs/README_zh.md) |
| System Architecture & Pipeline | [ARCHITECTURE.md](docs/ARCHITECTURE.md) / [中文版](docs/ARCHITECTURE_zh.md) |
| API Contracts & Data Types | [API_SPECIFICATION.md](docs/API_SPECIFICATION.md) / [中文版](docs/API_SPECIFICATION_zh.md) |
| Performance & Benchmarks | [BENCHMARKS.md](docs/BENCHMARKS.md) / [中文版](docs/BENCHMARKS_zh.md) |
| Unicode Script Property APIs | [UNICODE_PROPERTIES.md](docs/UNICODE_PROPERTIES.md) / [中文版](docs/UNICODE_PROPERTIES_zh.md) |
| Unicode Security Scope | [SPECIFICATION.md](docs/SPECIFICATION.md) / [中文版](docs/SPECIFICATION_zh.md) |
| Release History | [CHANGELOG.md](CHANGELOG.md) / [中文版](docs/CHANGELOG_zh.md) |
| Development Roadmap | [ROADMAP.md](ROADMAP.md) / [中文版](docs/ROADMAP_zh.md) |
| Account Registration Integration | [Example](examples/registration/README.md) / [中文版](examples/registration/README_zh.md) |
| Brand Identity & Visual System | [BRANDING.md](docs/BRANDING.md) / [中文版](docs/BRANDING_zh.md) |

---

<details>
<summary><strong>Building and Testing from Source</strong></summary>

Requires MoonBit CLI toolchain (`moon`). CI, Pages, and the Copilot setup install the compiler version recorded in [`.moon-version`](.moon-version), currently `0.10.14+7d59c7ec9`. Use the same version for regeneration and formatting; toolchain upgrades require reviewing generated source and interface changes together.

```powershell
# Check project compilation
moon check

# Execute unit and property tests
moon test
moon test --target js
moon test --target native
pnpm --dir playground run check

# Run CLI demonstration
moon run cmd/main
```

Unicode tables are generated from nine checksum-recorded sources. To reproduce official NFD and mapping checks, run `python tools/data-generator/generate.py`, `moon info`, `moon fmt`, then `pnpm --dir playground run verify:unicode`. Node checks always rebuild the engine first. The library has no third-party runtime dependencies.

</details>

---

## License

Licensed under the [Apache License, Version 2.0](./LICENSE).
