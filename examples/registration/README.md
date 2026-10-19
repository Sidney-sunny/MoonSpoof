# Account-registration reference integration

[Chinese](README_zh.md)

This application example imports the public `Sidney-sunny/moonspoof` API. It is a single-process in-memory reference store, not an account service or evidence of external adoption.

## Run the complete walkthrough

From the repository root, with the compiler version in [`.moon-version`](../../.moon-version):

```powershell
moon run cmd/registration
moon test -p Sidney-sunny/moonspoof/examples/registration
```

The first command loads `paypal`, `admin`, and `用户`, evaluates candidates, restores a snapshot, rebuilds after a policy-version change, and stops a migration that would collide `I` and `l`. It needs no frontend dependencies or account server. CI runs it for WASM, JavaScript, and native.

| Candidate | Expected decision | Evidence |
| --- | --- | --- |
| `alice中文` | Accepted | A mixed-script name allowed by the chosen application policy |
| `paypal` | Duplicate | The exact existing name |
| `p\u0430ypal` | Collision | Existing `paypal`, Cyrillic U+0430 diagnostic |
| `admin\u200B` | Rejected | Invisible-format policy and triggered rule |
| `user name` | Rejected | Application syntax callback |

## Registration call site

Create a `Registry` with a sensitive or folded key policy, an application-owned syntax validator, and an application policy version. Call `Registry::register` at the registration decision point. The permissive Unicode profile is the default; a caller can explicitly select a stricter profile.

`Decision` distinguishes `Accepted`, `Duplicate`, `Collision`, and `Rejected`. A collision returns the existing identifier and candidate diagnostics. A policy rejection returns its reason and diagnostics. Rejected requests do not reserve a name or key. Risk levels do not independently reject names.

`Registry::records` returns a copy of versioned records in registration order. Each record includes the original name, computed key, library/data versions, key policy, application policy version, and Unicode profile. The example's library version constant must track `moon.mod` when upgrading.

The integration lives in [registry.mbt](registry.mbt); [the executable](../../cmd/registration/main.mbt) imports this application example. The example itself imports only the root public MoonSpoof API. It is source to adapt in your application, not a new stable API in the core library.

## Snapshot restore and migration

`Registry::snapshot` returns an independent record array and a version header, including for empty indexes. `Snapshot` and `StoredIdentifier` define the data your persistence adapter must store. This example demonstrates these values in memory; it does not provide disk storage or a serialized file format.

Use `Registry::restore(snapshot, key_policy, validate_syntax=..., application_policy_version=...)` with the current application configuration. Restore compares the complete version header, checks every record's metadata, recomputes each key, and revalidates each original name. It rejects stale versions, forged keys, duplicate records, collisions, and invalid names. A partial index is never returned.

After changing the library, Unicode data, collision policy, syntax rules, or profile, call `Registry::rebuild` with the old snapshot and new configuration. It ignores old keys and metadata and revalidates the original names into a separate index. Replace the active index only on `Ok(new_index)`. `Err(decisions)` contains the duplicate/collision/rejection decisions requiring review; the old index is unchanged. Resolve conflicts explicitly instead of dropping accounts.

For example, `I` and `l` coexist under folded keys but collide under sensitive keys. Rebuilding that pair as sensitive returns a collision and leaves the original two-account index intact. Migration never labels stale keys with a new version without recomputing them.

Acceptance evidence is in [registration tests](registry_test.mbt) and [snapshot/migration tests](snapshot_test.mbt).

## Application responsibilities

The syntax callback is independent of the Unicode profile. It must be deterministic for the recorded application policy version. The test callback rejects spaces and slashes only; it is deliberately not a complete account-name grammar or Unicode identifier standard.

This store supports sequential calls in one process. A production store must enforce collision uniqueness atomically within the chosen policy/version namespace, and handle exact-name uniqueness separately. A separate lookup followed by an insert is insufficient under concurrent registrations.

Mixed scripts are allowed by default in this example so the application can distinguish actual key collisions from otherwise acceptable multilingual names. A stricter profile can reject mixed names before collision lookup. This is a policy choice, not full UTS #39 conformance or a proof that an accepted name is safe.

The callback is not persisted; your application must restore the implementation matching its policy version. Snapshot metadata is a compatibility check, not authentication. Authenticate persisted data separately and coordinate migrations with concurrent writers before switching indexes. A successful in-memory rebuild is not a database transaction.

## Opt into Identifier_Status

The walkthrough also defines `status_checked_syntax`: it calls `@moonspoof.validate_identifier_status` before application syntax and converts typed failures into a codepoint/index reason. It accepts `alice中文` and rejects `hello😀` at U+1F600, scalar index 5. This literal property filter is optional; [its canonical-equivalence and grammar limits](../../docs/UNICODE_PROPERTIES.md) remain explicit.

When enabling it for existing accounts, use a new `application_policy_version`. Restore then rejects the old snapshot; rebuild reports accounts needing review and keeps the original index unchanged. [Integration tests](status_test.mbt) verify this migration.

See the [roadmap](../../ROADMAP.md) for milestone evidence and remaining standard work.

## Opt into decimal mixing checks

The walkthrough's `number_checked_syntax` composes `validate_number_systems` with the status filter and application syntax. `account12` passes; `user1١` fails at U+0661, scalar 5. Use a new application policy version when enabling it. [Migration regressions](numbers_test.mbt) keep old indexes intact and report rejected accounts for review. See [decimal-system contracts and limits](../../docs/NUMBER_SYSTEMS.md), including the exclusion of non-decimal numeric characters from this check.
