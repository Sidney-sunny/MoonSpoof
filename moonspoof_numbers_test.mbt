///|
test "decimal lookup covers Unicode families and invalid inputs" {
  for
    (cp, zero) in [
      (0x39, 0x30),
      (0x665, 0x660),
      (0x6F7, 0x6F0),
      (0x96F, 0x966),
      (0xFF19, 0xFF10),
      (0x1D7D7, 0x1D7CE),
      (0x1D7D8, 0x1D7D8),
      (0x11BF9, 0x11BF0),
    ] {
    assert_eq(@moonspoof.get_decimal_zero(cp), Some(zero))
  }
  for cp in [-1, 0x2F, 0x3A, 0xD800, 0x10FFFF, 0x110000, 2147483647] {
    assert_eq(@moonspoof.get_decimal_zero(cp), None)
  }
}

///|
test "one decimal system can appear with letters and repeated digits" {
  for
    text in [
      "", "alice", "user123321", "١٢٣", "۰۱۲", "१२३", "中文１２３",
      "\u{11BF0}\u{11BF9}",
    ] {
    assert_true(!@moonspoof.has_mixed_numbers(text))
    assert_true(@moonspoof.validate_number_systems(text) is Ok(_))
  }
}

///|
test "different decimal families mix even in the same script" {
  for text in ["1١", "١۲", "1１", "\u{1D7CE}\u{1D7D8}", "१১"] {
    assert_true(@moonspoof.has_mixed_numbers(text))
    assert_true(@moonspoof.validate_number_systems(text) is Err(_))
  }
  assert_eq(@moonspoof.get_unicode_script(0x661), "Arabic")
  assert_eq(@moonspoof.get_unicode_script(0x6F2), "Arabic")
}

///|
test "decimal representatives are sorted unique and returned independently" {
  let zeros = @moonspoof.get_decimal_systems("９۳9١۲٠0")
  assert_eq(zeros, [0x30, 0x660, 0x6F0, 0xFF10])
  zeros.clear()
  assert_eq(@moonspoof.get_decimal_systems("1١"), [0x30, 0x660])
}

///|
test "mixed-number issue preserves first family and Unicode scalar position" {
  match @moonspoof.validate_number_systems("😀\u{1D7CE}1۲") {
    Err(issue) => {
      assert_eq(issue.codepoint_index, 2)
      assert_eq(issue.codepoint, 0x31)
      assert_eq(issue.codepoint_hex, "U+0031")
      assert_eq(issue.first_decimal_zero, 0x1D7CE)
      assert_eq(issue.decimal_zero, 0x30)
    }
    _ => fail("Expected first decimal-family conflict")
  }
}

///|
test "non-decimal numbers are outside the check and defaults remain unchanged" {
  assert_eq(@moonspoof.get_decimal_systems("²Ⅳ½四"), [])
  assert_true(!@moonspoof.has_mixed_numbers("²Ⅳ½四1"))
  for cp in [0xB2, 0x2163, 0xBD, 0x56DB] {
    assert_eq(@moonspoof.get_decimal_zero(cp), None)
  }
  assert_true(@moonspoof.validate_identifier("١۲") is Ok(_))
  assert_true(@moonspoof.has_mixed_numbers("١۲"))
  assert_eq(@moonspoof.skeleton("１"), @moonspoof.skeleton("1"))
  assert_true(@moonspoof.has_mixed_numbers("1１"))
}
