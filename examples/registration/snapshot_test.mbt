///|
fn restore(
  snapshot : @registration.Snapshot,
  policy : @registration.KeyPolicy,
) -> Result[@registration.Registry, String] {
  @registration.Registry::restore(
    snapshot,
    policy,
    validate_syntax=syntax,
    application_policy_version="account-syntax-v1",
  )
}

///|
fn rebuild(
  snapshot : @registration.Snapshot,
  policy : @registration.KeyPolicy,
) -> Result[@registration.Registry, Array[@registration.Decision]] {
  @registration.Registry::rebuild(
    snapshot,
    policy,
    validate_syntax=syntax,
    application_policy_version="account-syntax-v1",
  )
}

///|
test "restoring recomputes keys and preserves collision enforcement and order" {
  let original = registry(Folded)
  assert_true(original.register("paypal") is Accepted(_))
  assert_true(original.register("用户") is Accepted(_))
  let restored = match restore(original.snapshot(), Folded) {
    Ok(index) => index
    Err(reason) => fail(reason)
  }
  assert_eq(restored.records(), original.records())
  assert_true(restored.register("p\u0430ypal") is Collision(_, _))
  assert_true(restored.register("paypal") is Duplicate(_))
  assert_true(restored.register("alice") is Accepted(_))
  assert_eq(original.records().length(), 2)
}

///|
test "snapshot headers reject every incompatible version field even for empty indexes" {
  let index = registry(Folded)
  let version = index.version()
  let stale = [
    { ..version, library_version: "old-library", },
    { ..version, unicode_version: "old-data", },
    { ..version, key_policy: Sensitive, },
    { ..version, application_policy_version: "old-syntax", },
    { ..version, profile: @moonspoof.IdentifierProfile::default(), },
  ]
  for version in stale {
    assert_true(restore({ version, records: [], }, Folded) is Err(_))
  }
  assert_true(restore(index.snapshot(), Folded) is Ok(_))
}

///|
test "restore rejects record metadata mismatch and tampered keys" {
  let original = registry(Folded)
  assert_true(original.register("paypal") is Accepted(_))
  let record = original.records()[0]
  let wrong_version = { ..record.version, unicode_version: "old-data", }
  let mismatched = { ..record, version: wrong_version, }
  let forged = { ..record, key: "not-the-real-key", }
  for record in [mismatched, forged] {
    assert_true(
      restore({ version: original.version(), records: [record], }, Folded)
      is Err(_),
    )
  }
  assert_true(original.register("p\u0430ypal") is Collision(_, _))
}

///|
test "restore rejects duplicate and colliding accounts instead of silently dropping them" {
  let index = registry(Folded)
  assert_true(index.register("paypal") is Accepted(_))
  let record = index.records()[0]
  let spoof = { ..record, name: "p\u0430ypal", }
  for extra in [record, spoof] {
    assert_true(
      restore({ version: index.version(), records: [record, extra], }, Folded)
      is Err(_),
    )
  }
  assert_eq(index.records().length(), 1)
}

///|
test "restore revalidates syntax and Unicode policy despite matching metadata and keys" {
  let index = registry(Folded)
  for name in ["invalid name", "admin\u200B"] {
    let record : @registration.StoredIdentifier = {
      name,
      key: @moonspoof.skeleton_case_folded(name),
      version: index.version(),
    }
    assert_true(
      restore({ version: index.version(), records: [record], }, Folded)
      is Err(_),
    )
  }
}

///|
test "rebuild uses original names and new metadata instead of old keys" {
  let index = registry(Sensitive)
  assert_true(index.register("PAYPAL") is Accepted(_))
  let old_record = index.records()[0]
  let stale : @registration.Snapshot = {
    version: { ..index.version(), unicode_version: "old-data", },
    records: [{ ..old_record, key: "stale-key", }],
  }
  let migrated = match rebuild(stale, Folded) {
    Ok(index) => index
    Err(_) => fail("Expected successful rebuild from original names")
  }
  assert_eq(
    migrated.records()[0].key,
    @moonspoof.skeleton_case_folded("PAYPAL"),
  )
  assert_eq(migrated.version().unicode_version, "16.0.0")
  assert_eq(migrated.version().key_policy, Folded)
  assert_true(migrated.register("p\u0430ypal") is Collision(_, _))
  assert_eq(index.records()[0], old_record)
}

///|
test "a new collision during migration prevents publishing a partial index" {
  let original = registry(Folded)
  assert_true(original.register("I") is Accepted(_))
  assert_true(original.register("l") is Accepted(_))
  let before = original.records()
  match rebuild(original.snapshot(), Sensitive) {
    Err(failures) => {
      assert_eq(failures.length(), 1)
      assert_true(failures[0] is Collision(_, _))
    }
    Ok(_) => fail("Expected migration to stop for manual collision review")
  }
  assert_eq(original.records(), before)
  assert_true(original.register("l") is Duplicate(_))
}

///|
test "migration collects all failures under a changed application policy" {
  let original = registry(Folded)
  assert_true(original.register("alice中文") is Accepted(_))
  assert_true(original.register("bob中文") is Accepted(_))
  let migrated = @registration.Registry::rebuild(
    original.snapshot(),
    Folded,
    validate_syntax=syntax,
    application_policy_version="account-syntax-v2",
    profile=@moonspoof.IdentifierProfile::default(),
  )
  match migrated {
    Err(failures) => {
      assert_eq(failures.length(), 2)
      assert_true(failures[0] is Rejected(_, _))
      assert_true(failures[1] is Rejected(_, _))
    }
    Ok(_) => fail("Expected both mixed-script names to require review")
  }
  assert_eq(original.records().length(), 2)
}
