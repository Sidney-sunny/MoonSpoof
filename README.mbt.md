# MoonSpoof

Unicode Spoof and Homoglyph Detection for MoonBit, adhering to Unicode Technical Standard #39 (UTS #39).

## Key Features

- UTS #39 Confusable Skeleton calculation and equivalence checking.
- Unicode Script and Script_Extensions analysis.
- Multi-script restriction level classification (Single Script, Highly Restrictive, Moderately Restrictive).
- Detection of invisible zero-width formatting characters and bidirectional control codes.
- High-throughput O(N) batch username collision scanning.

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

For complete documentation, see the [Documentation](./docs/README_zh.md) and [API Specification](./docs/API_SPECIFICATION.md).