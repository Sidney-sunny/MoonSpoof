# UTS #39 Unicode Security Specification & Compliance Matrix

This document outlines the scope of Unicode Technical Standard #39 (UTS #39) compliance implemented in MoonSpoof, referencing Unicode Character Database (UCD) 16.0.0.

---

## 1. Specification References & Pinned Data Versions

| Standard / Dataset | Official Specification | Pinned Version | Upstream Resource |
| :--- | :--- | :--- | :--- |
| **UTS #39** | Unicode Security Mechanisms | Revision 30 / 16.0.0 | [unicode.org/reports/tr39/](https://www.unicode.org/reports/tr39/) |
| **Confusables** | Visual Confusable Mapping Data | 16.0.0 | [confusables.txt](https://www.unicode.org/Public/security/16.0.0/confusables.txt) |
| **UCD Scripts** | Unicode Script Property Data | 16.0.0 | [Scripts.txt](https://www.unicode.org/Public/16.0.0/ucd/Scripts.txt) |
| **UCD ScriptExtensions** | Script_Extensions (scx) | 16.0.0 | [ScriptExtensions.txt](https://www.unicode.org/Public/16.0.0/ucd/ScriptExtensions.txt) |

---

## 2. Standard Compliance Coverage

### 2.1 UTS #39 Section 4: Confusable Detection

- **Supported**: Full single-codepoint confusable mapping transformation (`skeleton(S)`).
- **Supported**: Automatic stripping of default ignorable and invisible format characters (ZWSP U+200B, ZWNJ U+200C, ZWJ U+200D) to empty string in `skeleton`.
- **Supported**: Identification of cross-script homoglyphic substitution (e.g. Cyrillic `а` / Greek `ο` replacing Latin `a` / `o`).
- **Supported**: Fullwidth ASCII (U+FF01–U+FF5E) and Ideographic Space (U+3000) canonicalization to standard ASCII.
- **Invariants**: Normalization differences and confusable equivalence are strictly evaluated.

### 2.2 UTS #39 Section 5: Mixed-Script Detection & Restriction Levels

- **Single Script**: Identifiers composed exclusively of a single script (plus `Common` and `Inherited` characters).
- **Highly Restrictive**:
  - `Latin` + `Han` / `Hiragana` / `Katakana` (Japanese standard)
  - `Latin` + `Han` (Chinese standard)
  - `Latin` + `Hangul` (Korean standard)
- **Moderately Restrictive**: Identifiers mixing `Latin` with `Cyrillic` or `Greek`.
- **Minimally Restrictive / Unrestricted**: Arbitrary script mixtures.

---

## 3. Security Rule Definitions

MoonSpoof evaluates security risks using explicit, machine-readable rule identifiers:

| Rule Identifier | Trigger Condition | Severity Level |
| :--- | :--- | :--- |
| `RULE_INVISIBLE_OR_FORMAT_CHARACTER` | Contains zero-width space (U+200B), joiners (U+200C/D), or soft hyphens | **Critical** |
| `RULE_BIDI_CONTROL_CHARACTER` | Contains LRM, RLM, or bidirectional overrides (U+202A–202E, U+2066–2069) | **Critical** |
| `RULE_BIDI_OVERRIDE_CHARACTER` | Contains Right-to-Left Override (U+202E) or Left-to-Right Override (U+202D) | **Critical** |
| `RULE_BIDI_FILE_EXTENSION_SPOOF` | Bidi override paired with deceptive executable/document extension (.exe, .pdf, .scr) | **Critical** |
| `RULE_CROSS_SCRIPT_CONFUSABLE_GLYPH` | Contains non-Latin glyphs masquerading as Latin characters | **High** |
| `RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD` | Identifier mixes Latin, Cyrillic, or Greek alphabets vulnerable to homoglyphs | **High** |
| `RULE_MIXED_SCRIPT_IDENTIFIER` | Contains conflicting characters from two or more unrelated scripts | **Medium** |
