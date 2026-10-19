# Complete Unicode script properties

[Chinese](UNICODE_PROPERTIES_zh.md)

These additive APIs use Unicode 16.0.0 data. They complement the legacy `Script` enum and `analyze_scripts`; they do not change skeletons, stored keys, default profiles, risk rules, or restriction estimates.

## Property lookups

```moonbit
@moonspoof.get_unicode_script(0x0905) // "Devanagari"
@moonspoof.get_script_extensions(0x30FC) // ["Hiragana", "Katakana"]
```

`get_unicode_script(Int) -> String` returns the canonical long Script property name. The generated table covers every explicitly assigned range; omitted codepoints return `"Unknown"`, including unassigned, surrogate, private-use, and invalid inputs outside 0..0x10FFFF. All 170 explicitly assigned script values are represented without expanding the legacy enum.

`get_script_extensions(Int) -> Array[String]` returns canonical long names in lexical order, resolving aliases from the pinned PropertyValueAliases file. Missing entries inherit the single Script value, as defined by [UAX #24 revision 37](https://www.unicode.org/reports/tr24/tr24-37.html). Each call returns a fresh array.

## Resolved script sets

```moonbit
@moonspoof.resolve_script_set("ねガ") // Scripts(["Jpan"])
@moonspoof.resolve_script_set("中文가") // Scripts(["Kore"])
@moonspoof.is_mixed_script_resolved("aー") // true
```

`resolve_script_set(String) -> ScriptSet` implements the augmented-set intersection in [UTS #39 revision 30, section 5.1](https://www.unicode.org/reports/tr39/tr39-30.html#Mixed_Script_Detection). The returned type has two variants:

| Variant | Meaning |
| --- | --- |
| `All` | No character constrains the script; includes empty strings and only Common/Inherited characters without specific extension sets |
| `Scripts(names)` | Intersection of the characters' augmented script sets, in lexical order; an empty array means mixed-script |

The augmentation retains canonical long names and adds the writing-system identifiers `Hanb`, `Jpan`, and `Kore`. Han adds all three; Hiragana/Katakana add Jpan; Hangul adds Kore; Bopomofo adds Hanb. A set containing Common or Inherited imposes no constraint. Unknown remains an explicit property value and is not treated as All.

`is_mixed_script_resolved(String) -> Bool` is true only for `Scripts([])`. For example, `ねガ` resolves to Jpan, while `aー` has an empty intersection because the prolonged-sound mark has a specific Hiragana/Katakana extension set.

## Compatibility and limits

The legacy APIs remain unchanged. They expose eleven named categories plus Unknown and use scoped restriction estimates. They can disagree with resolved-set detection: `aー` is not mixed under the legacy Script-only check, while `ねガ` is mixed under that check but resolves to a single Japanese writing system. Explicitly choose the API matching the application's policy.

Resolved sets alone do not validate identifier syntax, restrict Identifier_Status, detect mixed-number systems, establish a restriction level, or prove an identifier safe. Unassigned characters can have the singleton set Unknown. Empty strings resolve to All but still fail ordinary identifier validation. No input normalization or bidi reordering is applied by these property APIs.

## Verification

Run `pnpm --dir playground run verify:unicode` after regeneration. The verifier reads checksum-verified official files independently, expands the full 0..0x10FFFF code space, and compares Script, Script_Extensions, and the literal Identifier_Status property: 1,114,112 codepoints and 3,342,336 property assertions. This includes default values and surrogate codepoints and supplements the existing normalization/mapping checks.

[Public regression tests](../moonspoof_scripts_test.mbt) cover Japanese, Korean, Han/Bopomofo, Devanagari, Thai, shared/inherited characters, Unknown, and unchanged legacy behavior. The browser ABI additionally exposes `spoof_unicode_script(cp)`, `spoof_script_extensions(cp)` (JSON array), and `spoof_identifier_status_allowed(cp)` (boolean) for reference verification.
