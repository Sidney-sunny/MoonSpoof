# Third-party notices

[Chinese](docs/THIRD_PARTY_NOTICES_zh.md)

MoonSpoof's original source is distributed under [Apache-2.0](LICENSE). Upstream data and fonts retain their own licenses; the module's Apache declaration does not replace those terms.

| Component | Use | License and retained notice |
| --- | --- | --- |
| Unicode 16.0.0 UCD and security data | Generated confusable, script, normalization, case-fold, ignorable, status and decimal tables | [Unicode License v3](licenses/UNICODE-3.0.txt); source files identify © 2024 Unicode, Inc. |
| Manrope font via `@fontsource/manrope` | Browser showcase fonts | [SIL Open Font License 1.1](licenses/Manrope-OFL-1.1.txt), Copyright 2019 The Manrope Project Authors |
| React, react-dom and scheduler | Browser UI runtime | [MIT license](licenses/React-MIT.txt), Copyright Meta Platforms, Inc. and affiliates; shared notice retained for these runtime packages |
| Vite modulepreload helper | Runtime helper injected in the production browser bundle | [Vite license and notices](licenses/Vite-LICENSE.txt) retained with site output |
| ICU4J 76.1 | Optional verification oracle, downloaded separately; not bundled with the library or showcase | [Versioned upstream license and notices](https://github.com/unicode-org/icu/blob/release-76-1/LICENSE); retain these if redistributing ICU |

The Unicode license was retrieved from [the official license file](https://www.unicode.org/license.txt); its SHA-256 is `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96`. The current permission notice includes Copyright © 1991–2026 Unicode, Inc.; generated data retains the 2024 source attribution. [Reviewed source URLs and hashes](tools/data-generator/sources.json) identify every data input. Generated tables are transformed data, with attribution emitted by the generator.

The package archive includes this document and the license texts. The showcase ships the Unicode, Manrope, React and Vite notices under `licenses/` in its public output. Keep these notices when distributing generated source, engine artifacts or site bundles. Other installed dependencies retain their package notices; no upstream source is relicensed by this document.
