# Account-registration reference integration

[Chinese](README_zh.md)

This application example imports the public `Sidney-sunny/moonspoof` API. It is a single-process in-memory reference store, not an account service or evidence of external adoption.

## Run acceptance tests

From the repository root, with the compiler version in [`.moon-version`](../../.moon-version):

```powershell
moon test -p Sidney-sunny/moonspoof/examples/registration
```

## Registration call site

Create a `Registry` with a sensitive or folded key policy, an application-owned syntax validator, and an application policy version. Call `Registry::register` at the registration decision point. The permissive Unicode profile is the default; a caller can explicitly select a stricter profile.

`Decision` distinguishes `Accepted`, `Duplicate`, `Collision`, and `Rejected`. A collision returns the existing identifier and candidate diagnostics. A policy rejection returns its reason and diagnostics. Rejected requests do not reserve a name or key. Risk levels do not independently reject names.

`Registry::records` returns a copy of versioned records in registration order. Each record includes the original name, computed key, library/data versions, key policy, application policy version, and Unicode profile. The example's library version constant must track `moon.mod` when upgrading.

## Application responsibilities

The syntax callback is independent of the Unicode profile. It must be deterministic for the recorded application policy version. The test callback rejects spaces and slashes only; it is deliberately not a complete account-name grammar or Unicode identifier standard.

This store supports sequential calls in one process. A production store must enforce collision uniqueness atomically within the chosen policy/version namespace, and handle exact-name uniqueness separately. A separate lookup followed by an insert is insufficient under concurrent registrations.

See the [roadmap](../../ROADMAP.md) for the complete M1 acceptance criteria. Snapshot validation, migration, and a runnable walkthrough are the remaining integration work.
