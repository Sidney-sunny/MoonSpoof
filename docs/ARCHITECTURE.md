# MoonSpoof System Architecture & Design Specification

This document details the internal design, algorithmic pipelines, data representations, and performance characteristics of MoonSpoof.

---

## 1. System Overview & Core Pipeline

MoonSpoof implements a modular pipeline adhering to Unicode Technical Standard #39 (Unicode Security Mechanisms):

```text
[ Raw Input String ]
        │
        ├──▶ [ Unicode Codepoint Scanner ]
        │         │
        │         ├──▶ Category Classification (General Category)
        │         ├──▶ Invisible / Bidi Control Interception
        │         └──▶ Codepoint Formatting (U+XXXX)
        │
        ├──▶ [ Script Analysis Engine ]
        │         │
        │         ├──▶ Script & Script_Extensions Lookup
        │         ├──▶ Mixed-Script Detection
        │         └──▶ Restriction Level Assessment (UTS #39 Section 5)
        │
        ├──▶ [ Confusable Skeleton Engine ]
        │         │
        │         ├──▶ Codepoint Decomposition (NFD equivalence)
        │         ├──▶ UTS #39 Confusable Mapping Lookup
        │         └──▶ Canonical Skeleton Assembly
        │
        └──▶ [ Security Risk & Diagnostic Engine ]
                  │
                  ├──▶ Rule Evaluation Engine
                  ├──▶ Risk Level Assignment (Safe / Low / Medium / High / Critical)
                  └──▶ Structured Diagnostic Report (DiagnosticReport)
```

---

## 2. Subsystem Layout

| Subsystem | Package Path | Primary Responsibility |
| :--- | :--- | :--- |
| **Unicode Core** | `Sidney-sunny/moonspoof/src/unicode` | Codepoint metadata, general categories, invisible char detection |
| **Script Classifier** | `Sidney-sunny/moonspoof/src/script` | Script identification and restriction level determination |
| **Confusable Engine** | `Sidney-sunny/moonspoof/src/confusable` | UTS #39 Confusable Skeleton transformation and comparison |
| **Security Diagnostic**| `Sidney-sunny/moonspoof/src/security` | Character-level explainability, rule evaluation, risk grading |
| **Batch Scanner** | `Sidney-sunny/moonspoof/src/batch` | O(N) collision grouping and bulk identifier auditing |

---

## 3. Algorithmic Design & Optimization

### 3.1 UTS #39 Confusable Skeleton Transformation

According to UTS #39 Section 4, determining whether two strings $S_1$ and $S_2$ are visually confusable requires mapping them to their canonical skeleton:

$$\text{skeleton}(S) = \text{NFD}\left( \bigcup_{c \in \text{NFD}(S)} \text{confusable\_map}(c) \right)$$

MoonSpoof stores compact codepoint mapping tables generated directly from Unicode 16.0.0. When scanning an identifier:
- Characters without confusable entries pass through untouched without redundant string cloning.
- Confusable characters (e.g. Cyrillic `а` U+0430, Greek `ο` U+03BF) map directly to their standardized targets (e.g. `a`, `o`).
- Identifiers $A$ and $B$ are confusable if and only if $\text{skeleton}(A) = \text{skeleton}(B)$.

### 3.2 High-Throughput O(N) Batch Collision Scanning

A naive collision scanner comparing $N$ usernames pairwise requires $O(N^2)$ comparisons, which becomes intractable for 10,000 to 100,000 names:

$$\text{Pairwise Comparisons} = \frac{N(N-1)}{2} \approx 5 \times 10^7 \quad (N = 10,000)$$

MoonSpoof employs **Hash-Indexed Skeleton Bucketing**:
1. For each input name $S_i$, compute $\text{sk}_i = \text{skeleton}(S_i)$ (or $\text{skeleton\_case\_folded}(S_i)$ when case-insensitive mode is enabled) in $O(L)$ time where $L$ is identifier length.
2. Store into hash bucket $\text{Buckets}[\text{sk}_i] \leftarrow \text{append}(S_i)$.
3. Collect all buckets with cardinality $\ge 2$.
4. Total execution time scales linearly at $O(N \cdot L)$ with memory overhead $O(N)$.
5. **Case-Insensitive Mode**: Supported natively via `find_confusable_groups_ignore_case`, grouping variants such as `PAYPAL`, `pаypal` (Cyrillic `а`), and `Paypal` into a single unified collision cluster under canonical folded signature `paypal`.

---

## 4. WebAssembly Architecture & Foreign Function Interface (FFI)

MoonSpoof provides zero-overhead interoperability across multiple runtimes:
- **Core Logic in MoonBit**: All Unicode properties, skeleton computation, script parsing, profile validation, and risk modeling compile into pure WebAssembly and native binaries.
- **Web FFI Export Bindings (`src/bindings/web`)**:
  - `spoof_skeleton(s : String) -> String`: Computes canonical UTS #39 skeleton.
  - `spoof_skeleton_case_folded(s : String) -> String`: Computes case-folded canonical skeleton.
  - `spoof_compare(a : String, b : String, ignore_case : Bool) -> String`: Compares two identifiers for confusable equivalence under strict or case-folded mode.
  - `spoof_analyze(s : String) -> String`: Returns complete character-level diagnostic report as structured JSON.
  - `spoof_batch_scan(raw_input : String) -> String`: Performs O(N) batch collision clustering across delimited identifier pools.
  - `spoof_batch_scan_with_options(raw_input : String, ignore_case : Bool) -> String`: High-throughput collision scanning with case-insensitive clustering toggle.
  - `spoof_validate_profile(s : String, is_permissive : Bool) -> String`: Evaluates UTS #39 Section 3 IdentifierProfile.
  - `spoof_get_restriction_info(s : String) -> String`: Returns JSON script analysis with restriction level and scripts array.
- **Zero Network Egress**: The entire Unicode database runs completely client-side in the browser or embedded runtime without telemetry or external network calls.

---

## 5. Command-Line Interface (`cmd/main`)

The MoonSpoof executable provides a turnkey demonstration and testing CLI:
- Run directly via the MoonBit toolchain:
  ```bash
  moon run cmd/main
  ```
- Evaluates five standardized inspection routines:
  1. Confusable equivalence matching across Latin, Cyrillic, Greek, fullwidth, and invisible codepoints.
  2. Case-insensitive confusable validation under UTS #39 Section 4.
  3. Structured diagnostic reports with character-level scripts, hex codepoints, and security rules.
  4. UTS #39 Section 3 IdentifierProfile enforcement (Strict vs. Permissive).
  5. High-throughput $O(N)$ batch collision scanning across candidate identifier pools.

---

## 6. Mixed-Script Restriction Levels (UTS #39 Section 5)

MoonSpoof implements full UTS #39 Section 5 Restriction Level categorization:
- **SingleScript**: All characters belong to a single recommended script (e.g. Latin-only, Han-only).
- **HighlyRestrictive**: Allowed multi-script combinations including Japanese (`Latin + Han + Hiragana + Katakana`) and Korean (`Latin + Han + Hangul`).
- **ModeratelyRestrictive**: Single non-Latin recommended script paired with Latin (`Latin + Cyrillic`, `Latin + Greek`, `Latin + Arabic`, `Latin + Hebrew`).
- **MinimallyRestrictive**: Arbitrary combinations where all scripts belong to the Unicode Recommended Identifier Scripts set (e.g. `Cyrillic + Greek`).
- **Unrestricted**: Identifiers containing `Unknown` scripts, unassigned ranges, or disallowed characters.
- **Triad Attack Rule (`RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD`)**: Flags cross-script mixing between Latin, Cyrillic, and Greek alphabets where deceptive visual homoglyphs are prevalent.

---

## 7. Bidirectional Text & Trojan Source Defense (CVE-2021-42574)

MoonSpoof incorporates specialized defense mechanisms against bidirectional text attacks:
- **Directional Override Detection**: Explicitly tracks Right-to-Left Override (`RLO` U+202E) and Left-to-Right Override (`LRO` U+202D), triggering `RULE_BIDI_OVERRIDE_CHARACTER`.
- **File Extension Boundary Defense**: Identifiers combining a bidirectional override with filename delimiter dots (`.`) trigger `RULE_BIDI_FILE_EXTENSION_SPOOF` to prevent GUI visual disguise of dangerous executables (e.g. `.exe`, `.scr`, `.bat`).
- **Interactive Split Workbench (Zone D)**: The WebAssembly playground provides dual-pane inspection contrasting visual GUI appearance against physical in-memory byte streams.
