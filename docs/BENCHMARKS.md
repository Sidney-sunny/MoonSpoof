# MoonSpoof benchmark report

[Chinese](BENCHMARKS_zh.md)

Measured on 2026-10-11 against the refactored release JavaScript JSON ABI. Raw environment and results: [benchmark-results.json](benchmark-results.json). Earlier numbers from the previous implementation are superseded and are not comparable to this measurement.

## Environment and method

Windows x64, Intel(R) Core(TM) i7-14650HX, Node v22.22.1, MoonBit 0.1.20260904. The benchmark is `tools/bench.mjs`; reproduce from the root with `pnpm --dir playground run bench`, which rebuilds the engine before measuring.

Each case warms up first, then runs five rounds. The table reports the median round duration and the per-call mean derived from that round. Pair/diagnostic timings include report creation and JSON serialization. Batch timings include parsing the returned JSON. They exclude worker transport, browser rendering and user input. These are local measurements, not a latency guarantee, a statistical confidence interval or a comparison against ICU/Python.

| JSON ABI workload | Calls per round | Median round ms | Mean microseconds per call | Units per second |
| --- | --- | --- | --- | --- |
| spoof_compare(paypal, pаypal) | 10000 | 256.18 | 25.62 | 39,035 |
| spoof_batch_scan(1000) | 20 | 61.76 | 3088.11 | 323,823 |
| spoof_batch_scan(10000) | 20 | 701.29 | 35064.28 | 285,191 |
| spoof_analyze(pаypal_service+ZWSP) | 10000 | 526.76 | 52.68 | 18,984 |

Units are calls for pair/diagnostics and names for batches. The 1,000-name fixture produces40 collision groups; the 10,000-name fixture produces200. Fixture duplicates intentionally count as collisions. Ten-thousand-name batches measure the unrestricted ABI, exceeding the demo worker's 5,000-name cap.

## Scaling boundary

Tables use binary searches; NFD expands some characters, orders combining segments, and key normalization may take multiple passes. Batch grouping hashes each key once instead of comparing every pair. Costs depend on total codepoints and key expansion, not only the number of names. No fixed O(N) throughput claim or competitor speed ranking follows from these fixtures.
