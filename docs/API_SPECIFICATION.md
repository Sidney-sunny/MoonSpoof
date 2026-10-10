# MoonSpoof API Specification

This document defines the public API contracts, input/output types, invariants, and error behaviors for MoonSpoof.

---

## 1. Top-Level Public APIs

All public APIs are exposed at the root package level under module `Sidney-sunny/moonspoof`.

### 1.1 `skeleton`

Computes the UTS #39 Confusable Skeleton of a Unicode string.

```moonbit
pub fn skeleton(input : String) -> String
```

- **Parameters**: `input : String` — The raw Unicode input string.
- **Returns**: `String` — The normalized visual skeleton string.
- **Invariants**:
  - Deterministic and pure function.
  - An empty input string returns `""`.
  - Normal ASCII strings return an equivalent ASCII representation.

---

### 1.2 `are_confusable`

Determines whether two strings are visually confusable under UTS #39 skeleton equivalence.

```moonbit
pub fn are_confusable(a : String, b : String) -> Bool
```

- **Parameters**:
  - `a : String` — First identifier.
  - `b : String` — Second identifier.
- **Returns**: `Bool` — `true` if `skeleton(a) == skeleton(b)`, otherwise `false`.
- **Note**: Distinguishes between exact string equality (`a == b`) and visual spoofing. Two strings with `are_confusable(a, b) == true` may have completely different codepoint representations.

---

### 1.3 `are_confusable_ignore_case` & `skeleton_case_folded`

Performs case-insensitive confusable equivalence matching per UTS #39 Section 4.

```moonbit
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool
pub fn skeleton_case_folded(input : String) -> String
```

- **Parameters**:
  - `a : String`, `b : String` — Candidate identifiers to compare.
- **Returns**: `Bool` — `true` if `are_confusable(a, b)` or `skeleton_case_folded(a) == skeleton_case_folded(b)`.
- **Invariants**: Case folding is applied both pre- and post-skeleton transformation to ensure idempotency.

---

### 1.4 `analyze_scripts`

Analyzes the Unicode scripts present in an identifier and evaluates its restriction level according to UTS #39 Section 5.

```moonbit
pub fn analyze_scripts(input : String) -> ScriptAnalysis
```

- **Parameters**: `input : String` — The identifier to analyze.
- **Returns**: `ScriptAnalysis`:
  - `primary_script : Script` — The dominant script of the identifier.
  - `scripts : Array[Script]` — List of distinct non-Common scripts present.
  - `is_mixed : Bool` — `true` if more than one distinct script is detected.
  - `level : RestrictionLevel` — Evaluated restriction level (`SingleScript`, `HighlyRestrictive`, `ModeratelyRestrictive`, `MinimallyRestrictive`, `Unrestricted`).

---

### 1.5 `analyze_identifier`

Performs an in-depth character-by-character diagnostic audit and evaluates security risk rules.

```moonbit
pub fn analyze_identifier(input : String) -> DiagnosticReport
```

- **Parameters**: `input : String` — The identifier to audit.
- **Returns**: `DiagnosticReport`:
  - `original : String` — The original input string.
  - `skeleton : String` — Canonical UTS #39 skeleton.
  - `script_analysis : ScriptAnalysis` — Script composition metrics.
  - `risk_level : SecurityRiskLevel` — `Safe`, `Low`, `Medium`, `High`, or `Critical`.
  - `char_diagnostics : Array[CharDiagnostic]` — Detailed character-level breakdown.
  - `rules_triggered : Array[String]` — Identifiers of triggered security rules.

---

### 1.6 `validate_identifier` & `is_allowed_identifier`

Enforces UTS #39 Section 3 Identifier Security Profiles.

```moonbit
pub fn validate_identifier(
  input : String,
  profile~ : IdentifierProfile = IdentifierProfile::default()
) -> Result[Unit, String]

pub fn is_allowed_identifier(
  input : String,
  profile~ : IdentifierProfile = IdentifierProfile::default()
) -> Bool
```

- **Parameters**:
  - `input : String` — The candidate identifier string.
  - `profile~ : IdentifierProfile` — Configurable validation criteria.
- **Returns**: `Result[Unit, String]` or `Bool` indicating compliance.

---

### 1.7 `find_confusable_groups`

Scans a collection of names and partitions them into confusable collision buckets in $O(N)$ time.

```moonbit
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup]
```

- **Parameters**: `names : Array[String]` — List of candidate identifiers or usernames.
- **Returns**: `Array[ConfusableGroup]` — All groups containing 2 or more mutually confusable names:
  - `skeleton : String` — The shared skeleton key.
  - `members : Array[String]` — The conflicting candidate names.

---

## 2. Type Definitions

### 2.1 `SecurityRiskLevel`

```moonbit
pub(all) enum SecurityRiskLevel {
  Safe
  Low
  Medium
  High
  Critical
}
```

### 2.2 `Script`

```moonbit
pub(all) enum Script {
  Common
  Inherited
  Latin
  Cyrillic
  Greek
  Arabic
  Hebrew
  Han
  Hiragana
  Katakana
  Hangul
  Unknown
}
```

### 2.3 `RestrictionLevel`

```moonbit
pub(all) enum RestrictionLevel {
  SingleScript
  HighlyRestrictive
  ModeratelyRestrictive
  MinimallyRestrictive
  Unrestricted
}
```

### 2.4 `CharDiagnostic`

```moonbit
pub(all) struct CharDiagnostic {
  char : Char
  codepoint : Int
  codepoint_hex : String
  script : Script
  is_invisible : Bool
  is_bidi : Bool
  is_confusable : Bool
  confusable_target : String
}
```
