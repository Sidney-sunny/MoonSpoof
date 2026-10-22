# ICU reference comparisons and mechanism coverage

[Chinese](REFERENCE_COMPARISON_zh.md)

Verified 2026-10-22 against ICU4J 76.1.0.0 with Unicode 16.0.0.0, matching MoonSpoof's pinned Unicode 16.0.0 data. This is scoped comparison evidence, not full UTS #39 conformance, a performance comparison, or production adoption.

## Run the comparison

Requires the pinned MoonBit compiler, Node 22 and JDK 21 (`java` and `javac` on PATH). From the repository root:

```powershell
pnpm --dir playground run verify:icu
```

The command rebuilds the JavaScript engine, downloads the optional ICU jar to ignored `_build/icu-reference`, verifies SHA-256 before caching or executing it, compiles the standalone oracle, and compares the committed corpus. Existing cache contents are verified on every run; a mismatched cache fails without replacing it. Downloads time out after 60 seconds. No Java or ICU dependency enters the MoonBit library or browser bundle.

The [reference manifest](../tools/icu-reference/manifest.json) pins the Maven artifact, ICU version and Unicode version. Its SHA-256 is `732cdf18121b1642899da1f5e37e52cc7f48e3ec07fa737105d4603976781b33`, checked against the [published checksum](https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/76.1/icu4j-76.1.jar.sha256). See the [official ICU 76 release](https://unicode-org.github.io/icu/download/76.html) and [versioned SpoofChecker source](https://github.com/unicode-org/icu/blob/release-76-1/icu4j/main/core/src/main/java/com/ibm/icu/text/SpoofChecker.java).

## Compared operations and results

The [42-case corpus](../tools/icu-reference/corpus.json) covers canonical normalization, confusables, folding, ignored/control characters, bidi order, CJK, shared scripts, supplementary/new scripts, literal status, decimal families, and 512-repeat long inputs. Corpus SHA-256: `b4325b674bf29e693acec6d1ffacd02a54e2c7bc5192cbf787ec97602a7ea49a`.

| Comparison | Evidence |
| --- | --- |
| NFD against `Normalizer2.getNFDInstance` | 42 exact comparisons |
| Application keys against ICU plus documented width/stability/folding operations | 84 exact comparisons; this adapted oracle is distinct from raw ICU behavior |
| Decimal representatives and mixing against `SpoofChecker.MIXED_NUMBERS` / `CheckResult.numerics` | 84 exact comparisons |
| Script, Script_Extensions, literal Identifier_Status and decimal zero against ICU properties | 500 assertions; unique codepoints within each case, not full-space ICU verification |
| Raw skeleton, skeleton after default case folding, and LTR bidi skeleton against application keys | 126 comparisons: 114 equal, 12 explicitly reviewed differences |

The raw operations are `getSkeleton(text)`, `getSkeleton(UCharacter.foldCase(text, true))`, and `getBidiSkeleton(LEFT_TO_RIGHT, text)`. The folded operation is an explicit reference policy, not a claim that ICU's ordinary skeleton is case-insensitive. The Java runtime version and corpus hash are included in `_build/icu-reference/report.json` alongside every difference. Runtime ICU and Unicode versions must match the manifest and library source manifest.

## Every observed difference

| Corpus case | Fields differing | Explanation |
| --- | --- | --- |
| `fullwidth` | All three | Width folding is an application extension: raw ICU retains fullwidth digit U+FF11; the folded reference also retains U+FF42 |
| `ideographic-space` | All three | Application folds U+3000 to U+0020; raw ICU retains U+3000 |
| `hangul-prototype` | All three | U+321D maps to a decomposed prototype ending U+11AB in one ICU pass; application stabilization maps that Jamo again to U+1102 |
| `mathematical-digits` | Folded only | A mapping produces `OO`; repeated application folding yields stable `oo` |
| `bidi-control` | LTR bidi only | ICU reorders `abc` + RLO + `.txt` to skeleton `abctxt.`; application key remains `abc.txt` |
| `arabic-order` | LTR bidi only | ICU applies bidi ordering to the Arabic/digit sequence; application keys do not reorder |

Each differing field pins both exact outputs and a reason in the corpus. New, changed or stale differences fail verification; reasons are not blanket exemptions. Default-ignorable removal agrees with ICU and is not counted as an application-only difference. [Harness tests](../tools/icu-reference/reference.test.mjs) verify these gates plus manifest, artifact and cache failures without downloading ICU.

## Mechanism coverage matrix

| Mechanism | Implemented and checked | Remaining boundary |
| --- | --- | --- |
| NFD | 19,965 official vectors / 99,825 assertions; ICU corpus | No NFKC/NFKD |
| Confusable keys | Official mappings, key stability, ICU raw/adapted corpus | Width/closure extensions; no bidi reordering |
| Full default folding | All 1,557 C/F mappings; stable folded keys; ICU corpus | No locale/Turkic policy |
| Complete Script / Script_Extensions | Full-space official property checks; ICU corpus | Legacy enum and restriction estimates remain scoped |
| Resolved script sets | Multilingual augmentation/intersection regressions | ICU comparison checks properties, not ICU's private resolved-set method |
| Literal Identifier_Status | Full-space official checks; ICU corpus | Optional raw filter; no canonical-equivalence closure or full General Security Profile |
| Decimal mixing | 76 complete Nd families; full-space lookup checks; ICU numeric corpus | Optional; non-decimal numeric characters need separate syntax policy |
| Bidi controls | Rejection/diagnostic regressions; explicit ICU bidi differences | No bidiSkeleton implementation |
| Pair/batch integration | [Adversarial public regressions](../moonspoof_adversarial_test.mbt), both key policies, long combining sequences, scalar evidence | Repository reference integration; no external adoption claim |

The full-space official suite has 4,456,448 property assertions; it remains independent of the smaller ICU corpus. Run `pnpm --dir playground run verify:unicode` separately. [Scope](SPECIFICATION.md) describes legacy estimates and risk rules; [roadmap](../ROADMAP.md) retains the M4 integration, measurement, compatibility and release gates. A dedicated CI job runs the pinned ICU comparison alongside the existing three-target suite.
