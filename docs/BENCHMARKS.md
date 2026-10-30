# MoonSpoof 0.2.0 benchmark report

[Chinese](BENCHMARKS_zh.md)

Measured on 2026-10-30 with the prepared 0.2.0 release candidate and pinned compiler 0.10.18. [benchmark-results.json](benchmark-results.json) contains every timed round, environment, corpus and output hashes. This replaces the 2026-10-11 report; its fixtures and compiler differed, so the measurements do not establish a before/after speedup.

## Reproduce

From the repository root, run:

```powershell
pnpm --dir playground run engine
node tools/bench.mjs --check-fixtures
node tools/bench.mjs --output docs/benchmark-results.json
```

The existing `pnpm --dir playground run bench` shortcut rebuilds the release JavaScript engine and prints the report. The direct Node command measures the existing engine and checks the installed compiler against [.moon-version](../.moon-version). Keep CPU-intensive builds and tests stopped during measurement. The script fails if the generated engine changes during the timed run. Results vary with host load, power management, V8 and operating-system scheduling.

## Environment and provenance

| Item | Measured value |
| --- | --- |
| Compiler | `v0.10.18+6c83a7f62 (2026-10-28)` |
| Build tool | `moon 0.1.20261028 (e1e1f15 2026-10-28)` |
| Runtime | Node v22.22.1, no Node options or arguments |
| Host | Windows 10.0.26340, x64, Intel(R) Core(TM) i7-14650HX, 24 logical CPUs, 16,790,925,312 bytes RAM |
| Unicode data | 16.0.0, nine pinned source checksums |

The measured working tree was based on `c9e43b44709b0e6083eb8fa25cd21e4b711df066` and contained the prepared 0.2.0 source changes, including the then-untracked version API and its test. Accordingly, `sourceDiffersFromRevision` is true; the parent Git revision alone does not identify the measured source. The JSON records all 56 non-ignored tracked/untracked MoonBit and package files through a deterministic combined SHA256, plus the benchmark, fixture module and Unicode manifest hashes.

Measured engine SHA256: `fd049c89674d87856bd81a0e63a342a601ea4136cac9dd593699b709949aaf69`.

Measured source SHA256: `bea33b4f6c1d23e0218094080cfd0a9e3d094fbcea1da20e887955ac6049b72d`.

## Method and measured results

[bench.mjs](../tools/bench.mjs) runs eight cases in the displayed order within one process. Each case warms up first, then runs five sequential rounds using `performance.now()`. Key cases warm up 1,000 corpus passes; batches warm up 20 complete scans; report cases warm up 1,000 calls. The JSON preserves the five durations in execution order and their minimum/maximum. The table shows the median round duration and the per-unit mean derived from that round; it is not a percentile of individual identifier latencies.

| Workload | Iterations/round | Units/iteration | Median round ms | Mean microseconds/unit | Units/second |
| --- | --- | --- | --- | --- | --- |
| Direct skeleton key | 1,000 | 32 | 68.5589 | 2.1425 | 466,752 |
| Direct case-folded key | 1,000 | 32 | 122.4928 | 3.8279 | 261,240 |
| 1,000 names, sensitive batch | 20 | 1,000 | 56.7753 | 2.8388 | 352,266 |
| 1,000 names, folded batch | 20 | 1,000 | 93.553 | 4.6776 | 213,783 |
| 10,000 names, sensitive batch | 20 | 10,000 | 702.953 | 3.5148 | 284,514 |
| 10,000 names, folded batch | 20 | 10,000 | 1,148.8396 | 5.7442 | 174,089 |
| Confusable pair JSON report | 10,000 | 1 | 204.5253 | 20.4525 | 48,894 |
| Cyrillic + ZWSP JSON diagnostic | 10,000 | 1 | 414.3281 | 41.4328 | 24,135 |

For key generation, one iteration calls `spoof_skeleton` or `spoof_skeleton_case_folded` on all 32 identifiers: 32,000 key calls per timed round. The timing includes the JavaScript loop and consuming output lengths; it excludes report construction and JSON. Each output policy has a recorded SHA256. A consumed-result guard is checked after every warmup and timed round.

For batches, units are names. Timing includes newline parsing, key generation, hash grouping, JSON serialization and `JSON.parse`. The ordinary and folded strategies scan the same fixture. Comparison and diagnostics use calls as units, including report construction and JSON serialization; they consume the returned string without parsing it. The exact pair and diagnostic input strings and hashes are also recorded in the JSON.

Engine builds, fixture construction, correctness preflight, network/disk I/O, worker transport and DOM rendering are excluded from timing. GC and operating-system scheduling are included. Only release JavaScript on this Node host was measured; native/Wasm runtime costs, browser interaction, allocation/peak memory and registry/database I/O were not measured.

## Corpora and correctness preflight

[benchmark-fixtures.mjs](../tools/benchmark-fixtures.mjs) defines the exact deterministic order. The key corpus spans ASCII, case variants, Greek/Cyrillic confusables, invisible removal, canonical equivalents, combining-mark reordering, case expansion, supplementary characters, CJK, Japanese, Korean, Indic, Thai, Hebrew and Arabic text. It has 32 names and 179 codepoints; individual names contain 2–17 codepoints. Repeated passes exercise this fixed, warm corpus rather than a random production distribution or a long-input stress test.

| Names | UTF-8 bytes including LF separators | Codepoints excluding separators | Input SHA256 |
| --- | --- | --- | --- |
| 32 | 339 | 179 | `58ad4bbbe31d45bd32a744f6c3dcb7dabaf57fe1592da4e851a013029497f8d9` |
| 1,000 | 9,498 | 8,199 | `bb5f4d417cf99a5e1d08933528ee39e1a4f5a17b5f4ae23b534fba3b86c0dd67` |
| 10,000 | 104,898 | 91,899 | `77780123a220686894984fd8103cb95413a56e0cb916123d4d1d71316f95c005` |

Hashes use UTF-8 names joined by LF with no trailing LF. Batch fixtures have no exact duplicate names. Each ten-name cluster contains four PayPal variants, three admin variants, one unique user, and a Team/team pair. The 1,000-name fixture produces 200 ordinary groups/400 colliding names and 300 folded groups/900 colliding names; the 10,000-name fixture produces 2,000/4,000 and 3,000/9,000 respectively. More folded output is part of the measured work.

Before timing, known case/confusable/canonical-equivalence assertions run, and every batch group/member is checked against grouping the direct public key outputs in a separate JavaScript Map. This checks batch ABI consistency; it does not replace the Unicode conformance tests or the pinned ICU differential corpus. The 10,000-name scan calls the unrestricted ABI directly and exceeds the demo worker's 5,000-name cap.

## Scaling and interpretation boundary

On this fixture, raising batch size from 1,000 to 10,000 increases median complete-call duration from 2.84 to 35.15 ms for ordinary keys and from 4.68 to 57.44 ms for folded keys. The larger fixture also has longer numeric suffixes and more/larger returned groups. These observations describe these inputs; they are neither a fixed scaling law nor a service latency guarantee.

Table lookups use binary searches. NFD may expand characters and reorder combining segments; key generation may perform multiple normalization passes. Batch grouping hashes generated keys rather than comparing all pairs. Cost depends on input codepoints, key expansion, output size and runtime behavior. No fixed O(N) throughput guarantee, statistical confidence interval, competitor ranking or full UTS #39 conformance claim follows from this report.
