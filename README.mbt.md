# MoonSpoof

Unicode Spoof and Homoglyph Detection for MoonBit, implementing selected Unicode Technical Standard #39 mechanisms.

## Key Features

- Unicode 16.0 NFD, full default folding, default-ignorable removal and stable confusable keys.
- Complete Unicode Script/Script_Extensions properties and resolved script sets, alongside legacy script diagnostics and restriction estimates.
- Optional literal Identifier_Status filtering with typed codepoint/index evidence, separate from existing profile defaults and application syntax.
- Opt-in decimal-system mixing detection with scalar conflict evidence.
- Multi-script restriction level classification (Single Script, Highly Restrictive, Moderately Restrictive).
- Detection of invisible zero-width formatting characters and bidirectional control codes.
- Stable hash-indexed batch collision grouping using the same keys as pair matching.

## Usage

```moonbit nocheck
///|
let authentic = "paypal"

///|
let candidate = "p\u0430ypal" // Cyrillic Small Letter A

///|
let is_confusable = @moonspoof.are_confusable(authentic, candidate)

///|
let skeleton = @moonspoof.skeleton(candidate)

///|
let report = @moonspoof.analyze_identifier(candidate)
```

Default profiles do not enforce Identifier_Status or decimal mixing checks, and bidi skeleton reordering is not implemented. See the [complete script API contracts](docs/UNICODE_PROPERTIES.md). Fullwidth folding and key stabilization are application extensions.

[Chinese](docs/README_zh.md)

For complete documentation, see the [Documentation](./docs/README_zh.md) and [API Specification](./docs/API_SPECIFICATION.md).
