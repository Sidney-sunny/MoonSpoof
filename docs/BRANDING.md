# MoonSpoof Brand Identity & Visual Guidelines

This document outlines the visual system, aesthetic standards, and brand assets for MoonSpoof.

---

## 1. Brand Concept & Philosophy

MoonSpoof combines lunar precision with cryptographic security:
- **Lunar Crescent**: Symbolizes the MoonBit ecosystem and clarity.
- **Twin Confusable Loop**: Represents Unicode homoglyphs and optical illusions detected and resolved by UTS #39 algorithms.
- **Architectural Minimalism**: Stark, timeless Swiss modernist aesthetic. Zero cyberpunk effects, zero neon gradients.

---

## 2. Visual Palette & Design Tokens

| Token Name | Hex Value | Semantic Usage |
| :--- | :--- | :--- |
| **Obsidian Dark** | `#0d0d0d` | Primary background, surface canvas |
| **Moon White** | `#ffffff` | Primary emblem glyph, prominent headers |
| **Neutral Slate** | `#71717a` | Secondary text, subtitles, confusable dashed lines |
| **Border Zinc** | `#27272a` | Structural borders, card outlines |

**Strict Aesthetic Constraint**: Cyberpunk blue, green, and purple gradients are explicitly prohibited.

---

## 3. Official Brand Assets

All approved visual assets are located in `docs/assets/`:

- **Banner (16:9)**: `docs/assets/banner.jpg` (and `docs/assets/banner.png`)
- **Logo (1:1)**: `docs/assets/logo.jpg` (and `docs/assets/logo.png`)

---

## 4. Interactive Playground Architecture & Zones

The WebAssembly Playground (`playground/`) implements an interactive visual workbench organized into four purpose-built zones:

- **Zone A: Pair Comparison**: Real-time confusable equivalence verification, standard skeletons, and UTS #39 Section 4 case-folded matching.
- **Zone B: Collision Scanner**: High-throughput $O(N)$ batch identifier collision bucketing across financial, administrative, and developer platform attack pools.
- **Zone C: Glyph Inspector**: Character-level decompilation with decimal/hex codepoints, script resolution, confusable targets, and UTS #39 Section 3 IdentifierProfile validation.
- **Zone D: Trojan Source & Bidi Inspector**: Split visual display vs. physical memory sequence, detecting CVE-2021-42574 Trojan Source code injections and Right-to-Left Override (`RLO`) file extension masquerading.
