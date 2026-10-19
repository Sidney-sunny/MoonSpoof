///|
test "Identifier_Status is an explicit opt-in filter independent of legacy profiles" {
  assert_true(@moonspoof.validate_identifier("hello😀") is Ok(_))
  assert_true(@moonspoof.validate_identifier_status("hello😀") is Err(_))
  assert_true(@moonspoof.validate_identifier_status("alice中文") is Ok(_))
  assert_true(
    @moonspoof.validate_identifier_status("नमस्ते") is Ok(_),
  )
  assert_true(
    @moonspoof.validate_identifier_status("ผู้ใช้") is Ok(_),
  )
  assert_true(@moonspoof.validate_identifier("alice中文") is Err(_))
}

///|
test "Identifier_Status failures give the first scalar index and codepoint" {
  match @moonspoof.validate_identifier_status("a😀") {
    Err(@moonspoof.IdentifierStatusError::RestrictedCharacter(issue)) => {
      assert_eq(issue.codepoint_index, 1)
      assert_eq(issue.codepoint, 0x1F600)
      assert_eq(issue.codepoint_hex, "U+1F600")
    }
    _ => fail("Expected a restricted supplementary codepoint")
  }
  // Supplementary Han is Allowed; the following space is scalar index one.
  match @moonspoof.validate_identifier_status("\u{20000} ") {
    Err(@moonspoof.IdentifierStatusError::RestrictedCharacter(issue)) => {
      assert_eq(issue.codepoint_index, 1)
      assert_eq(issue.codepoint, 0x20)
    }
    _ => fail("Expected a restricted space after supplementary Han")
  }
}

///|
test "restricted status covers ignored controls private use and unassigned characters" {
  for name in ["a\u200B", "a\u0000", "a\uE000", "a\u0378", "a\u202E"] {
    assert_true(@moonspoof.validate_identifier_status(name) is Err(_))
  }
  assert_true(
    @moonspoof.validate_identifier_status("")
    is Err(@moonspoof.IdentifierStatusError::Empty),
  )
  for cp in [-1, 0x110000, 0xD800, 0xE000, 0x378] {
    assert_eq(
      @moonspoof.get_identifier_status(cp),
      @moonspoof.IdentifierStatus::Restricted,
    )
  }
}

///|
test "Allowed property is neither identifier syntax nor a no-collision guarantee" {
  for name in ["123", "-", "é", "e\u0301", "paypal", "p\u0430ypal"] {
    assert_true(@moonspoof.validate_identifier_status(name) is Ok(_))
  }
  assert_true(@moonspoof.are_confusable("paypal", "p\u0430ypal"))
  assert_eq(
    @moonspoof.get_identifier_status(0x27),
    @moonspoof.IdentifierStatus::Allowed,
  )
}

///|
test "literal status filtering does not claim canonical-equivalence closure" {
  assert_true(@moonspoof.validate_identifier_status("\u01EE") is Ok(_))
  assert_true(@moonspoof.validate_identifier_status("\u01B7\u030C") is Err(_))
  assert_eq(@moonspoof.skeleton("\u01EE"), @moonspoof.skeleton("\u01B7\u030C"))
}
