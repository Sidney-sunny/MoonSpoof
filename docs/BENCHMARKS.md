# MoonSpoof Performance & Throughput Benchmarks

This report documents the empirical performance, throughput, and algorithmic scaling characteristics of MoonSpoof under Unicode 16.0.0 and UTS #39 datasets.

---

## 1. Benchmark Environment

| Parameter | Specification |
| :--- | :--- |
| **Compiler** | MoonBit `0.1.20260904` |
| **Target Runtime** | JavaScript / WebAssembly Core (Node.js v22 LTS runtime) |
| **Unicode Version** | Unicode 16.0.0 |
| **UTS #39 Table Size** | 6,355 confusable mappings, 929 script boundaries |
| **Operating System** | Windows 11 x64 |

---

## 2. Empirical Benchmark Results

### 2.1 Single Identifier Pair Comparison

Tests the latency and throughput of `are_confusable(a, b)` including full UTS #39 Skeleton normalization, pre-NFKD fullwidth decomposition, and binary search lookups over 50,000 iterations.

| Metric | Measured Value |
| :--- | :--- |
| **Sample Count** | 50,000 operations |
| **Total Wall Time** | 262.46 ms |
| **Mean Latency** | 5.25 microseconds / operation |
| **Throughput** | 190,507 operations / second |

### 2.2 High-Throughput Batch Collision Scanning

Tests the multi-identifier collision detection engine (`find_confusable_groups`) across 1,000 and 10,000 identifier datasets with mixed Latin, Cyrillic homoglyphs, and zero-width invisible controls.

| Dataset Scale | Total Time | Throughput | Detected Collision Clusters |
| :--- | :--- | :--- | :--- |
| **1,000 Identifiers** | 6.69 ms | 149,392 names / second | 50 clusters |
| **10,000 Identifiers** | 16.85 ms | 593,356 names / second | 200 clusters |

---

## 3. Algorithmic Complexity

- **Skeleton Transformation**: $O(L \log M)$, where $L$ is identifier character length and $M = 6,355$ is the static UTS #39 mapping table size (binary search).
- **Batch Collision Grouping**: $O(N \cdot L \log M)$, where $N$ is total identifiers, enabled by single-pass hash indexing ($O(1)$ amortized map lookups).
- **Script Analysis**: $O(L \log S)$, where $S = 929$ is the script boundary range count.
