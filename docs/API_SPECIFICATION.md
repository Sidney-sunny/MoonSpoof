# MoonSpoof API Specification

[Chinese](API_SPECIFICATION_zh.md)

This document defines the public API contracts, input/output types, invariants, and error behaviors for MoonSpoof.

---

## 1. Top-Level Public APIs

All public APIs are exposed at the root package level under module `Sidney-sunny/moonspoof`.

### 1.1 `skeleton`

Computes the stable application skeleton using pinned Unicode 16.0 NFD, default-ignorable removal and confusable mappings. Fullwidth folding and stabilization are application extensions; see [implementation scope](SPECIFICATION.md).

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
- **Note**: Includes exact string equality (`a == b`); callers must distinguish identical text from a differing-text collision. Two strings with `are_confusable(a, b) == true` may have completely different codepoint representations.

---

### 1.3 `are_confusable_ignore_case` & `skeleton_case_folded`

Compares stable application keys using full default C/F Unicode case folding.

```moonbit
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool
pub fn skeleton_case_folded(input : String) -> String
```

- **Parameters**:
  - `a : String`, `b : String` — Candidate identifiers to compare.
- **Returns**: `Bool` — `true` exactly when `skeleton_case_folded(a) == skeleton_case_folded(b)`. Sensitive matching is not ORed into this result.
- **Invariants**: Folding followed by skeleton transformation repeats to a stable key. This is a separate equivalence policy: sensitive `I` / `l` matches need not match under folding.

---

### 1.4 `analyze_scripts`

Analyzes the Unicode scripts present in an identifier and evaluates its restriction level as a scoped estimate, without full Script_Extensions or Identifier_Status prerequisites.

```moonbit
pub fn analyze_scripts(input : String) -> ScriptAnalysis
```

- **Parameters**: `input : String` — The identifier to analyze.
- **Returns**: `ScriptAnalysis`:
  - `primary_script : Script` — The first recognized non-Common/non-Inherited script, or Common if none.
  - `scripts : Array[Script]` — Distinct recognized scripts, excluding Common, Inherited and Unknown.
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
  - `skeleton : String` — Stable application skeleton.
  - `script_analysis : ScriptAnalysis` — Script composition metrics.
  - `risk_level : SecurityRiskLevel` — `Safe`, `Low`, `Medium`, `High`, or `Critical`.
  - `char_diagnostics : Array[CharDiagnostic]` — Detailed character-level breakdown.
  - `rules_triggered : Array[String]` — Identifiers of triggered security rules.

---

### 1.6 `validate_identifier` & `is_allowed_identifier`

Applies custom identifier checks; this is not full UTS #39 Identifier_Status or syntax validation. Default: no mixed scripts or ignorables, maximum128 codepoints. Permissive: mixed scripts allowed, ignorables rejected, maximum256 codepoints. Both reject C0/C1 controls and empty input. Unknown scripts and punctuation are not rejected solely for their category.

```moonbit
pub fn validate_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default()
) -> Result[Unit, String]

pub fn is_allowed_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default()
) -> Bool
```

- **Parameters**:
  - `input : String` — The candidate identifier string.
  - `profile? : IdentifierProfile` — Configurable validation criteria.
- **Returns**: `Result[Unit, String]` or `Bool` indicating compliance.

---

### 1.7 `find_confusable_groups`

Scans a collection of names and partitions them into confusable collision buckets using hash buckets, with cost proportional to computing each name's key rather than all pairwise comparisons.

```moonbit
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup]
```

- **Parameters**: `names : Array[String]` — List of candidate identifiers or usernames.
- **Returns**: `Array[ConfusableGroup]` — Groups with at least two entries, including identical duplicates. Groups and members follow first-seen input order:
  - `skeleton : String` — The shared skeleton key.
  - `members : Array[String]` — The conflicting candidate names.

---

### 1.8 `find_confusable_groups_ignore_case`

Scans a collection of names and partitions them into case-insensitive confusable collision buckets under UTS #39 Section 4 using `skeleton_case_folded`.

```moonbit
pub fn find_confusable_groups_ignore_case(names : Array[String]) -> Array[ConfusableGroup]
```

- **Parameters**: `names : Array[String]` — List of candidate identifiers or usernames.
- **Returns**: `Array[ConfusableGroup]` — All groups containing 2 or more mutually confusable names under case folding (e.g. `PAYPAL`, `pаypal`, `Paypal`).

---

## 2. Type Definitions

The additive full-script APIs `get_unicode_script`, `get_script_extensions`, `resolve_script_set`, and `is_mixed_script_resolved`, including `ScriptSet::All` versus an empty intersection, are specified in [Unicode property contracts](UNICODE_PROPERTIES.md). Legacy `ScriptAnalysis` and restriction estimates retain their existing behavior.

The same document specifies `get_identifier_status` and the opt-in `validate_identifier_status`, with typed first-failure evidence and the explicit literal-codepoint/canonical-closure boundary. Existing `IdentifierProfile` fields and defaults are unchanged.

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
