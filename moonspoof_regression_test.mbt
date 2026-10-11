///|
test "canonical equivalents share a skeleton including reordered marks and Hangul" {
  assert_eq(skeleton("é"), skeleton("e\u0301"))
  assert_eq(skeleton("a\u0315\u0300"), skeleton("a\u0300\u0315"))
  assert_eq(skeleton("가"), skeleton("\u1100\u1161"))
  assert_eq(skeleton("\u321D"), skeleton("(오전)"))
  assert_eq(skeleton(skeleton("\u321D")), skeleton("\u321D"))
}

///|
test "full default case folding handles sharp s and Greek sigma" {
  assert_true(are_confusable_ignore_case("Straße", "STRASSE"))
  assert_true(are_confusable_ignore_case("σ", "ς"))
  assert_true(are_confusable_ignore_case("ALICE", "alice"))
  assert_eq(
    find_confusable_groups_ignore_case(["I", "l"]).length() > 0,
    are_confusable_ignore_case("I", "l"),
  )
}

///|
test "default ignorables include supplementary variation selectors and bidi overrides" {
  for ch in ["\u034F", "\u061C", "\u202E", "\u2066", "\uFE0F", "\u{E0100}"] {
    assert_eq(skeleton("admin" + ch), skeleton("admin"))
    assert_false(is_allowed_identifier("admin" + ch))
    assert_true(has_invisible_characters(ch))
  }
}

///|
test "identifier limits count codepoints rather than UTF-16 units" {
  let profile : IdentifierProfile = {
    allow_mixed_script: true,
    allow_invisible: false,
    max_length: 2,
  }
  assert_true(validate_identifier("\u{20000}\u{20001}", profile~) is Ok(_))
  assert_true(validate_identifier("\u{20000}\u{20001}a", profile~) is Err(_))
  assert_true(validate_identifier("a\u0000", profile~) is Err(_))
}

///|
test "CJK restriction allows whole Japanese and Korean sets without unrelated scripts" {
  assert_eq(
    get_restriction_level("a中あア"),
    RestrictionLevel::HighlyRestrictive,
  )
  assert_eq(
    get_restriction_level("a中가"),
    RestrictionLevel::HighlyRestrictive,
  )
  assert_eq(
    get_restriction_level("中あα"),
    RestrictionLevel::MinimallyRestrictive,
  )
  assert_eq(
    get_restriction_level("aα"),
    RestrictionLevel::MinimallyRestrictive,
  )
  assert_eq(
    get_restriction_level("aع"),
    RestrictionLevel::ModeratelyRestrictive,
  )
  assert_true(
    analyze_identifier("a中あア").risk_level != SecurityRiskLevel::High,
  )
}

///|
test "batch groups preserve first occurrence order and duplicate multiplicity" {
  let groups = find_confusable_groups([
    "paypal", "admin", "p\u0430ypal", "admin", "p\u0430ypal",
  ])
  assert_eq(groups.length(), 2)
  assert_eq(groups[0].skeleton, "paypal")
  assert_eq(groups[0].members.length(), 3)
  assert_eq(groups[1].skeleton, skeleton("admin"))
}
