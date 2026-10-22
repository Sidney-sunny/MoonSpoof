# Decimal number system checks

[Chinese](NUMBER_SYSTEMS_zh.md)

These opt-in APIs use checksum-pinned Unicode 16.0.0 UnicodeData.txt, already among the nine reviewed sources. Decimal values come from field 6, without a host-runtime Unicode database. Before writing any output, the generator validates ten complete digits per family: 760 digits in 76 systems.

## Public contracts

| API | Result |
| --- | --- |
| `get_decimal_zero(Int) -> Int?` | Zero codepoint of an Nd family; None for every other or invalid codepoint |
| `get_decimal_systems(String) -> Array[Int]` | Unique zero representatives in ascending codepoint order; a fresh array per call |
| `has_mixed_numbers(String) -> Bool` | True when more than one decimal family occurs |
| `validate_number_systems(String) -> Result[Unit, MixedNumberIssue]` | First digit whose family differs from the first decimal digit's family |

`MixedNumberIssue` has public fields `codepoint_index` (zero-based Unicode scalar index), `codepoint`, `codepoint_hex`, `first_decimal_zero`, and `decimal_zero`. A supplementary character counts as one scalar. Empty strings and strings without decimal digits pass this check and have no families.

```moonbit
@moonspoof.get_decimal_zero(0x0665) // Some(0x0660)
@moonspoof.get_decimal_systems("user1١") // [0x0030, 0x0660]
@moonspoof.has_mixed_numbers("١۲") // true
```

## Algorithm and limits

The mechanism follows the decimal-family comparison in [UTS #39 revision 30, section 5.3](https://www.unicode.org/reports/tr39/tr39-30.html#Mixed_Number_Detection): represent each decimal digit by its codepoint minus its decimal value, then compare the distinct representatives. Property fields are defined by [UAX #44 revision 34](https://www.unicode.org/reports/tr44/tr44-34.html#UnicodeData.txt).

The check uses raw input. ASCII, fullwidth and mathematical styles remain distinct even when application skeletons fold them together. Adjacent mathematical families have separate zero representatives. Arabic-Indic and Extended Arabic-Indic digits differ even though both have Script=Arabic.

Only General_Category=Nd participates. Superscripts, fractions, Roman numerals and numeric Han characters contribute no family. The standard's identifier procedure assumes non-decimal numbers are excluded separately; this API only reports decimal mixing and does not reject those characters. A passing result is neither grammar validation nor a guarantee of safety. Keep application syntax, optional Identifier_Status filtering and collision checks separate.

Default profiles, diagnostic risk scores, restriction estimates and stored skeleton keys are unchanged. This mechanism does not establish full UTS #39 conformance.

## Registration and migration

Run `moon run cmd/registration`. Its `number_checked_syntax` callback composes this check with status filtering and example syntax. `account12` passes; `user1١` is rejected at U+0661, scalar index 5. The executable uses an explicit application policy version.

When enabling checks on existing accounts, change `application_policy_version` and rebuild from original names. [Registration regressions](../examples/registration/numbers_test.mbt) verify rejection evidence, incompatible restore, rebuild review and preservation of the old index. Do not silently switch policies under old metadata. This remains a reference integration, not external adoption.

## Verification

Run `moon test` and `moon test --target js` for [public regressions](../moonspoof_numbers_test.mbt). They cover single/mixed families, same-script families, supplementary characters, Unicode 16 additions, excluded numeric types, scalar indices, sorted unique results and unchanged defaults.

`pnpm --dir playground run verify:unicode` independently reads the checksum-verified UnicodeData source and compares `get_decimal_zero` through `spoof_decimal_zero` for all 1,114,112 codepoints, including absent and surrogate values. The ABI uses -1 for None. Combined with Script, Script_Extensions and Identifier_Status, the property suite runs 4,456,448 assertions. This is direct source verification; the [pinned ICU comparison](REFERENCE_COMPARISON.md) separately verifies representatives and mixing on the committed corpus.
