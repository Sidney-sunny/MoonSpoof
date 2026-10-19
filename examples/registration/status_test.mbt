///|
fn status_syntax(name : String) -> Result[Unit, String] {
  match @moonspoof.validate_identifier_status(name) {
    Ok(_) => syntax(name)
    Err(@moonspoof.IdentifierStatusError::Empty) =>
      Err("Account cannot be empty")
    Err(@moonspoof.IdentifierStatusError::RestrictedCharacter(issue)) =>
      Err(
        "Restricted identifier character \{issue.codepoint_hex} at scalar \{issue.codepoint_index}",
      )
  }
}

///|
test "applications opt into Identifier_Status without changing the legacy profile" {
  let index = @registration.Registry::new(
    Folded,
    validate_syntax=status_syntax,
    application_policy_version="account-syntax-status-v2",
  )
  assert_true(index.register("alice中文") is Accepted(_))
  match index.register("hello😀") {
    Rejected(reason, report) => {
      assert_eq(reason, "Restricted identifier character U+1F600 at scalar 5")
      assert_eq(report.original, "hello😀")
    }
    _ => fail("Expected explicit Identifier_Status rejection")
  }
  assert_eq(index.records().length(), 1)
  assert_true(registry(Folded).register("hello😀") is Accepted(_))
}

///|
test "enabling Identifier_Status requires a versioned rebuild and explicit conflict review" {
  let original = registry(Folded)
  assert_true(original.register("hello😀") is Accepted(_))
  assert_true(original.register("alice中文") is Accepted(_))
  let snapshot = original.snapshot()
  assert_true(
    @registration.Registry::restore(
      snapshot,
      Folded,
      validate_syntax=status_syntax,
      application_policy_version="account-syntax-status-v2",
    )
    is Err(_),
  )
  match
    @registration.Registry::rebuild(
      snapshot,
      Folded,
      validate_syntax=status_syntax,
      application_policy_version="account-syntax-status-v2",
    ) {
    Err(failures) => {
      assert_eq(failures.length(), 1)
      assert_true(failures[0] is Rejected(_, _))
    }
    Ok(_) => fail("Expected existing restricted account to require review")
  }
  assert_eq(original.records(), snapshot.records)
}
