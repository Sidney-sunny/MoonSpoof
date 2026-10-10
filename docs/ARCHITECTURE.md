# MoonSpoof System Architecture & Design Specification

This document details the internal design, algorithmic pipelines, data representations, and performance characteristics of MoonSpoof.

---

## 1. System Overview & Core Pipeline

MoonSpoof implements a modular pipeline adhering to Unicode Technical Standard #39 (Unicode Security Mechanisms):

```text
[ Raw Input String ]
        │
        ├──▶ [ Unicode Codepoint Scanner ]
        │         │
        │         ├──▶ Category Classification (General Category)
        │         ├──▶ Invisible / Bidi Control Interception
        │         └──▶ Codepoint Formatting (U+XXXX)
        │
        ├──▶ [ Script Analysis Engine ]
        │         │
        │         ├──▶ Script & Script_Extensions Lookup
        │         ├──▶ Mixed-Script Detection
        │         └──▶ Restriction Level Assessment (UTS #39 Section 5)
        │
        ├──▶ [ Confusable Skeleton Engine ]
        │         │
        │         ├──▶ Codepoint Decomposition (NFD equivalence)
        │         ├──▶ UTS #39 Confusable Mapping Lookup
        │         └──▶ Canonical Skeleton Assembly
        │
        └──▶ [ Security Risk & Diagnostic Engine ]
                  │
                  ├──▶ Rule Evaluation Engine
                  ├──▶ Risk Level Assignment (Safe / Low / Medium / High / Critical)
                  └──▶ Structured Diagnostic Report (DiagnosticReport)
```

---

## 2. Subsystem Layout

| Subsystem | Package Path | Primary Responsibility |
| :--- | :--- | :--- |
| **Unicode Core** | `Sidney-sunny/moonspoof/src/unicode` | Codepoint metadata, general categories, invisible char detection |
| **Script Classifier** | `Sidney-sunny/moonspoof/src/script` | Script identification and restriction level determination |
| **Confusable Engine** | `Sidney-sunny/moonspoof/src/confusable` | UTS #39 Confusable Skeleton transformation and comparison |
| **Security Diagnostic**| `Sidney-sunny/moonspoof/src/security` | Character-level explainability, rule evaluation, risk grading |
| **Batch Scanner** | `Sidney-sunny/moonspoof/src/batch` | O(N) collision grouping and bulk identifier auditing |

---

## 3. Algorithmic Design & Optimization

### 3.1 UTS #39 Confusable Skeleton Transformation

According to UTS #39 Section 4, determining whether two strings $S_1$ and $S_2$ are visually confusable requires mapping them to their canonical skeleton:

$$\text{skeleton}(S) = \text{NFD}\left( \bigcup_{c \in \text{NFD}(S)} \text{confusable\_map}(c) \right)$$

MoonSpoof stores compact codepoint mapping tables generated directly from Unicode 16.0.0. When scanning an identifier:
- Characters without confusable entries pass through untouched without redundant string cloning.
- Confusable characters (e.g. Cyrillic `а` U+0430, Greek `ο` U+03BF) map directly to their standardized targets (e.g. `a`, `o`).
- Identifiers $A$ and $B$ are confusable if and only if $\text{skeleton}(A) = \text{skeleton}(B)$.

### 3.2 High-Throughput O(N) Batch Collision Scanning

A naive collision scanner comparing $N$ usernames pairwise requires $O(N^2)$ comparisons, which becomes intractable for 10,000 to 100,000 names:

$$\text{Pairwise Comparisons} = \frac{N(N-1)}{2} \approx 5 \times 10^7 \quad (N = 10,000)$$

MoonSpoof employs **Hash-Indexed Skeleton Bucketing**:
1. For each input name $S_i$, compute $\text{sk}_i = \text{skeleton}(S_i)$ in $O(L)$ time where $L$ is identifier length.
2. Store into hash bucket $\text{Buckets}[\text{sk}_i] \leftarrow \text{append}(S_i)$.
3. Collect all buckets with cardinality $\ge 2$.
4. Total execution time scales linearly at $O(N \cdot L)$ with memory overhead $O(N)$.

---

## 4. WebAssembly Architecture & Boundary

For the WebAssembly Playground:
- **Core Logic in MoonBit**: All Unicode properties, skeleton computation, script parsing, and risk modeling compile into pure WASM.
- **Minimal JavaScript Glue**: JavaScript only manages DOM rendering, text input capture, and UI event binding.
- **Zero Network Egress**: The entire database runs offline within the browser sandbox.
