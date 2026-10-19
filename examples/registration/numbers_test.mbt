///|
fn numbers_syntax(name : String) -> Result[Unit, String] {
  match @moonspoof.validate_number_systems(name) {
    Ok(_) => status_syntax(name)
    Err(issue) =>
      Err(
        "Mixed decimal system at \{issue.codepoint_hex}, scalar \{issue.codepoint_index}",
      )
  }
}

///|
test "registration explicitly opts into decimal mixing rejection" {
  let index = @registration.Registry::new(
    Folded,
    validate_syntax=numbers_syntax,
    application_policy_version="account-syntax-status-numbers-v3",
  )
  assert_true(index.register("account12") is Accepted(_))
  match index.register("user1١") {
    Rejected(reason, _) =>
      assert_eq(reason, "Mixed decimal system at U+0661, scalar 5")
    _ => fail("Expected a mixed-number rejection")
  }
  assert_eq(index.records().length(), 1)
  assert_true(registry(Folded).register("user1١") is Accepted(_))
}

///|
test "enabling decimal mixing checks rebuilds with review and retains the old index" {
  let original = registry(Folded)
  assert_true(original.register("user1١") is Accepted(_))
  assert_true(original.register("account12") is Accepted(_))
  let snapshot = original.snapshot()
  assert_true(
    @registration.Registry::restore(
      snapshot,
      Folded,
      validate_syntax=numbers_syntax,
      application_policy_version="account-syntax-status-numbers-v3",
    )
    is Err(_),
  )
  match
    @registration.Registry::rebuild(
      snapshot,
      Folded,
      validate_syntax=numbers_syntax,
      application_policy_version="account-syntax-status-numbers-v3",
    ) {
    Err(failures) => {
      assert_eq(failures.length(), 1)
      assert_true(failures[0] is Rejected(_, _))
    }
    _ => fail("Expected mixed-number account to require review")
  }
  assert_eq(original.records(), snapshot.records)
}
