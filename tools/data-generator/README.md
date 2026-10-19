# MoonSpoof Unicode data generator

[Chinese](README_zh.md)

Python standard library only; no package installation is required. From the repository root:

```powershell
python -m unittest discover -s tools/data-generator -p 'test_*.py'
python tools/data-generator/generate.py
moon info
moon fmt
pnpm --dir playground run verify:unicode
```

The generator requires the reviewed `sources.json` manifest before downloading files. It rejects missing or extra source entries, a changed Unicode version or URL, and invalid SHA-256 fields before network access. It then downloads missing Unicode 16.0.0 files, verifies all nine recorded checksums before writing source, and emits sorted confusable/script/normalization tables. The manifest is read-only during regeneration; a missing manifest must be restored from version control, not recreated from cached files. Existing downloads are reused. Requests time out after 60 seconds. Raw `.txt` downloads are ignored; generated MoonBit tables and `sources.json` are tracked.

The verifier reads normalization vectors directly from the checksum-verified `NormalizationTest.txt`. Empty suites, malformed columns, and invalid Unicode scalar values are rejected. The old `normalization-vectors.json` cache is no longer generated or consumed.

| Official file | Purpose |
| --- | --- |
| confusables.txt | Single-codepoint confusable mappings |
| Scripts.txt | Full Script ranges and the compatibility enum |
| UnicodeData.txt | Canonical decomposition and combining classes |
| CaseFolding.txt | Full default C/F folding |
| DerivedCoreProperties.txt | Default_Ignorable_Code_Point ranges |
| NormalizationTest.txt | Official NFD verification vectors |
| ScriptExtensions.txt | Explicit shared-script sets; absent entries inherit Script |
| PropertyValueAliases.txt | Canonical long names for script aliases |
| IdentifierStatus.txt | Allowed ranges; absent entries are Restricted |

New downloads must match the pinned checksum before they are published to the cache. Publication uses an atomic replacement from a temporary file in the same directory; failed downloads or writes do not leave a partial cache file. Existing cached files still undergo checksum verification before any generated source is written.

Exact URLs and hashes live in `sources.json`. ScriptExtensions.txt and PropertyValueAliases.txt supply complete extension sets; IdentifierStatus.txt supplies the Allowed ranges, with Restricted as the default. Changing the data version requires an explicit manifest review; do not replace hashes to accept an unexplained mismatch. Regeneration plus formatting should reproduce committed tables without a diff. See [implementation scope](../../docs/SPECIFICATION.md).
