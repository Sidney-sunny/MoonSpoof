///|
/// An application-owned syntax decision, independent of the Unicode profile.
fn syntax(name : String) -> Result[Unit, String] {
  if name.contains(" ") || name.contains("/") {
    Err("Account syntax rejects spaces and slashes")
  } else {
    Ok(())
  }
}

///|
fn registry(policy : @registration.KeyPolicy) -> @registration.Registry {
  @registration.Registry::new(
    policy,
    validate_syntax=syntax,
    application_policy_version="account-syntax-v1",
  )
}

///|
test "registration accepts and reserves an identifier, then distinguishes exact duplicates" {
  let index = registry(Folded)
  assert_true(index.register("paypal") is Accepted(_))
  match index.register("paypal") {
    Duplicate(record) => {
      assert_eq(record.name, "paypal")
      assert_eq(record.key, @moonspoof.skeleton_case_folded("paypal"))
    }
    _ => fail("Expected an exact duplicate")
  }
  assert_eq(index.records().length(), 1)
}

///|
test "registration returns the conflicting account and character evidence" {
  let index = registry(Folded)
  assert_true(index.register("paypal") is Accepted(_))
  match index.register("p\u0430ypal") {
    Collision(existing, report) => {
      assert_eq(existing.name, "paypal")
      assert_eq(report.original, "p\u0430ypal")
      assert_eq(report.char_diagnostics[1].codepoint, 0x0430)
      assert_true(report.rules_triggered.length() > 0)
    }
    _ => fail("Expected a confusable collision")
  }
  assert_eq(index.records().length(), 1)
}

///|
test "registration supports multilingual names without treating risk as a rejection decision" {
  let index = registry(Folded)
  assert_true(index.register("alice中文") is Accepted(_))
  assert_true(index.register("用户") is Accepted(_))
  assert_eq(index.records().length(), 2)
}

///|
test "invisible and control policy failures do not reserve their normalized key" {
  let index = registry(Folded)
  match index.register("admin\u200B") {
    Rejected(reason, report) => {
      assert_eq(
        reason, "Identifier contains disallowed invisible format character",
      )
      assert_true(
        report.rules_triggered.contains("RULE_INVISIBLE_OR_FORMAT_CHARACTER"),
      )
    }
    _ => fail("Expected an invisible-character policy failure")
  }
  assert_true(index.register("admin\u0000") is Rejected(_, _))
  assert_eq(index.records().length(), 0)
  assert_true(index.register("admin") is Accepted(_))
}

///|
test "application syntax and stricter script profiles are independent policies" {
  let index = registry(Folded)
  assert_true(index.register("user name") is Rejected(_, _))
  assert_true(index.register("user/name") is Rejected(_, _))
  assert_true(index.register("") is Rejected(_, _))
  let strict = @registration.Registry::new(
    Folded,
    validate_syntax=syntax,
    application_policy_version="account-syntax-v1",
    profile=@moonspoof.IdentifierProfile::default(),
  )
  assert_true(strict.register("alice中文") is Rejected(_, _))
  assert_eq(index.records().length(), 0)
  assert_eq(strict.records().length(), 0)
}

///|
test "sensitive and folded registries preserve the documented I and l policy difference" {
  let sensitive = registry(Sensitive)
  assert_true(sensitive.register("I") is Accepted(_))
  assert_true(sensitive.register("l") is Collision(_, _))
  let folded = registry(Folded)
  assert_true(folded.register("I") is Accepted(_))
  assert_true(folded.register("l") is Accepted(_))
  assert_true(folded.register("i") is Collision(_, _))
}

///|
test "stored keys carry library, Unicode, syntax, profile and key policy versions" {
  let index = registry(Folded)
  assert_true(index.register("alice") is Accepted(_))
  let record = index.records()[0]
  assert_eq(record.version.library_version, "0.1.0")
  assert_eq(record.version.unicode_version, "16.0.0")
  assert_eq(record.version.application_policy_version, "account-syntax-v1")
  assert_eq(record.version.key_policy, Folded)
  assert_eq(record.version.profile, @moonspoof.IdentifierProfile::permissive())
  assert_eq(record.version, index.version())
  let snapshot = index.records()
  snapshot.clear()
  assert_eq(index.records().length(), 1)
  assert_true(index.register("alice") is Duplicate(_))
}
