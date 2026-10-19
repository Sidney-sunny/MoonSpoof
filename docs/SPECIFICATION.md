# Unicode security implementation scope

[Chinese](SPECIFICATION_zh.md)

MoonSpoof implements selected Unicode security mechanisms using pinned Unicode 16.0.0 data. It does not claim full UTS #39 conformance. A matching skeleton or a risk signal does not establish malicious intent.

## Data and reproducibility

The reference is [UTS #39 revision 30](https://www.unicode.org/reports/tr39/tr39-30.html). `tools/data-generator/sources.json` records official URLs and SHA-256 hashes for nine files: confusables, Scripts, UnicodeData, CaseFolding, DerivedCoreProperties, NormalizationTest, ScriptExtensions, PropertyValueAliases, and IdentifierStatus. Regenerate with `python tools/data-generator/generate.py`, then run `moon info`, `moon fmt`, and `pnpm --dir playground run verify:unicode`.

| Mechanism | Implemented behavior | Boundary |
| --- | --- | --- |
| NFD | Recursive canonical decomposition, algorithmic Hangul, stable combining-class ordering | NFKC and NFKD are not provided |
| Confusable key | NFD, remove Default_Ignorable_Code_Point, map, NFD; repeat to stability | Application key, not the full bidiSkeleton procedure |
| Case-insensitive key | Full default C/F case folding, then skeleton; repeat to stability | No Turkic T or locale-specific casing; a separate equivalence policy |
| Legacy script analysis | Scripts.txt lookup, eleven named categories plus Unknown | Unchanged compatibility API; many scripts become Unknown |
| Complete script properties | Full Script and Script_Extensions lookups, canonical long names | Separate APIs; no change to legacy diagnostics |
| Resolved script sets | UTS #39 section 5.1 augmented-set intersection, CJK writing systems | All differs from an empty intersection; not an identifier policy |
| Identifier policy | Empty/length/control/ignorable/mixed-script checks | Custom policy, not Identifier_Status, XID, or syntax validation |
| Diagnostics | Codepoints, raw mapping targets, scripts, triggered rules, risk | A raw character target need not equal the final normalized key |
| Bidi | Detect Unicode bidi controls and overrides | No UBA reordering or bidi skeleton; demo uses browser rendering |
| Batch | Hash groups by the same key used in pair comparison | Duplicate identical entries also form collisions |

## Application extensions and compatibility

Fullwidth ASCII U+FF01–U+FF5E and U+3000 are folded to their ASCII counterparts. Repeating normalization/mapping until stability handles targets that normalize into another mapped codepoint, including Hangul. Both are explicit application extensions; stored keys should be versioned with the library and Unicode data version.

`are_confusable_ignore_case(a,b)` now means only equality of folded keys. It no longer ORs this result with case-sensitive equality. For example, `I` and `l` collide under the case-sensitive key but differ under the folded key. Pair comparison and batch grouping therefore use the same equivalence relation.

## Restriction estimates

`primary_script` is the first recognized non-Common/non-Inherited script, not a frequency-based dominant script. Unknown characters yield Unrestricted but are not included in the recognized `scripts` list.

| Estimate | Recognized script set |
| --- | --- |
| SingleScript | Zero or one recognized script, with no Unknown codepoints |
| HighlyRestrictive | More than one script, subset of Latin/Han/Hiragana/Katakana or Latin/Han/Hangul |
| ModeratelyRestrictive | Exactly Latin+Arabic or Latin+Hebrew |
| MinimallyRestrictive | Other combinations of the recognized named scripts, including Latin+Cyrillic and Latin+Greek |
| Unrestricted | Any Unknown script |

These estimates omit the full standard's Identifier_Status and Script_Extensions prerequisites. The default custom identifier policy rejects every recognized mixed-script combination, even CJK combinations assigned HighlyRestrictive; callers may choose the permissive policy. Unknown-script text and punctuation may pass this policy, so callers must enforce their own identifier syntax.

## Risk rules

| Rule | Trigger |
| --- | --- |
| RULE_INVISIBLE_OR_FORMAT_CHARACTER | Default_Ignorable_Code_Point |
| RULE_CONTROL_CHARACTER | C0 U+0000–001F or C1 U+007F–009F |
| RULE_BIDI_CONTROL_CHARACTER | A supported bidi control |
| RULE_BIDI_OVERRIDE_CHARACTER | LRO or RLO |
| RULE_BIDI_FILE_EXTENSION_SPOOF | LRO/RLO and any dot; heuristic, no extension parser |
| RULE_MIXED_SCRIPT_IDENTIFIER | More than one recognized script |
| RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD | Any pair among Latin, Cyrillic, Greek |
| RULE_CROSS_SCRIPT_CONFUSABLE_GLYPH | A raw mapped target uses a different recognized script, ignoring Common/Inherited/Unknown |

Controls, ignorables, and bidi controls yield Critical. A cross-script mapping or triad combined with mixed scripts yields High. A cross-script mapping alone or an unexpected mixed set yields Medium. Remaining changed keys yield Low; otherwise Safe. A HighlyRestrictive CJK mix is not escalated to Medium solely for mixing.

Mixed-number detection, Identifier_Status enforcement, and bidi skeleton reordering remain unimplemented. Complete Script_Extensions and resolved sets are available through [separate additive APIs](UNICODE_PROPERTIES.md). Legacy restriction estimates are intentionally unchanged: they omit Identifier_Status prerequisites and do not use resolved sets. Applications must not interpret them as a full standard classification. The low-level `get_general_category` helper is a coarse legacy classifier, not complete UCD General_Category data.

## Verification evidence

The property verifier independently expands checksum-verified official files across all 1,114,112 codepoints and checks Script, Script_Extensions, and the literal Identifier_Status property (3,342,336 assertions). Resolved-set regressions additionally cover the standard's CJK writing-system augmentation and shared-character constraints.


Normalization vectors are parsed directly from the checksum-verified official `NormalizationTest.txt`; a derived JSON cache cannot reduce the checked suite. Empty input, malformed rows, and invalid scalar values fail verification.

The verifier checks 19,965 official NFD vectors (99,825 assertions), all 6,355 confusable source rows against a reference pipeline, 1,557 C/F case-fold mappings, and key stability for 7,561 source codepoints. The reference pipeline reuses the NFD implementation after official NFD verification. This evidence does not establish full UTS #39 conformance or prove every possible string property. Unit tests additionally cover JSON controls, astral lengths, ordering, CJK restrictions, and worker lifecycle failures.
