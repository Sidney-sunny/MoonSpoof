# MoonSpoof product

<!-- impeccable:product-schema 1 -->

[Chinese](docs/PRODUCT_zh.md)

## Platform

MoonBit library targeting WASM, JavaScript, and native, with a browser showcase.

## Users

Intended users are MoonBit developers checking account or package identifiers for confusable collisions. Reviewers use the showcase to inspect correctness and integration potential. Actual application adoption has not yet been documented.

## Product Purpose

Provide reusable Unicode confusable keys and diagnostic evidence at identifier registration and batch-review call sites. A runnable account-registration reference integration demonstrates the public API; the showcase makes its underlying mechanisms inspectable.

## Positioning

A dependency-free MoonBit engine with generated Unicode 16.0 data, character diagnostics, configurable identifier policies, and skeleton-indexed batch collision grouping. The browser uses the compiled JavaScript target; WASM and native are separate library targets.

## Operating Context

The [registration integration](examples/registration/README.md) loads existing identifiers, evaluates a candidate through the public library API, and distinguishes exact duplicates, confusable collisions, and policy failures. Versioned snapshots support validated restoration and rebuilding with conflict review. Applications choose their syntax and collision policy. Developers can inspect pair and batch results in the showcase without transmitting inputs.

## Development Priorities

The owner reports that preliminary review has passed. The [roadmap](ROADMAP.md) records M1 reference-integration evidence and remaining acceptance criteria: script and identifier-status support, numeric mixing and reference comparisons, then integration review and release. Preliminary review does not establish final acceptance or production readiness.

## Capabilities and Constraints

Preserve the public library API where practical. Unicode security analysis is a signal, not proof of malicious intent. Full UTS #39 compliance must not be claimed without implementation and conformance evidence. Browser execution does not transmit entered text. User authorized architecture and implementation refactoring.

## Brand Commitments

MoonSpoof name and the new sculpted MS identity in docs/assets/logo.png, with its matching README banner in docs/assets/banner.png. The owner authorized a new brand after rejecting a vermilion concept that matched another project. The brand uses a deep-grape and pearl-white visual direction; the showcase retains its ink-blue and ice-cyan interface. English technical artifacts; Chinese conversation; bilingual website; matte, minimal presentation. Avoid decorative starter chips and fabricated benchmark claims.

## Evidence on Hand

MoonBit source and tests, a runnable registration integration with acceptance tests, Unicode data generator, Apache-2.0 license, existing architecture and API documentation. Official ICU and confusable_homoglyphs APIs support feature comparisons. No controlled competitor performance benchmark or documented real application adoption is available. The reference integration must not be reported as external adoption.

## Product Principles

1. Demonstrate working code before making claims.
2. Show codepoints and rules behind every diagnostic.
3. Describe supported behavior and remaining standard gaps precisely.
4. Keep user input on the device.
