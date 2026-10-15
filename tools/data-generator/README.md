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

The generator requires the reviewed `sources.json` manifest before downloading files. It rejects missing or extra source entries, a changed Unicode version or URL, and invalid SHA-256 fields before network access. It then downloads missing Unicode 16.0.0 files, verifies all six recorded checksums before writing source, and emits sorted confusable/script/normalization tables. The manifest is read-only during regeneration; a missing manifest must be restored from version control, not recreated from cached files. Existing downloads are reused. Requests time out after 60 seconds. Raw `.txt` files and normalization vectors are ignored; generated MoonBit tables and `sources.json` are tracked.

| Official file | Purpose |
| --- | --- |
| confusables.txt | Single-codepoint confusable mappings |
| Scripts.txt | Script ranges; eleven named categories plus Unknown |
| UnicodeData.txt | Canonical decomposition and combining classes |
| CaseFolding.txt | Full default C/F folding |
| DerivedCoreProperties.txt | Default_Ignorable_Code_Point ranges |
| NormalizationTest.txt | Official NFD verification vectors |

Exact URLs and hashes live in `sources.json`. ScriptExtensions.txt is not consumed. Changing the data version requires an explicit manifest review; do not replace hashes to accept an unexplained mismatch. Regeneration plus formatting should reproduce committed tables without a diff. See [implementation scope](../../docs/SPECIFICATION.md).
