///|
test "complete Script lookup includes scripts absent from the legacy enum" {
  for
    (cp, expected) in [
      (0x905, "Devanagari"),
      (0xE01, "Thai"),
      (0x531, "Armenian"),
      (0x1E900, "Adlam"),
      (0x41, "Latin"),
      (0x30, "Common"),
      (0x378, "Unknown"),
      (0xD800, "Unknown"),
    ] {
    assert_eq(@unicode.unicode_script(cp), expected)
  }
}

///|
test "Script_Extensions resolves aliases, inherits Script, and returns fresh arrays" {
  assert_eq(@unicode.script_extensions(0x30FC), ["Hiragana", "Katakana"])
  assert_eq(@unicode.script_extensions(0x905), ["Devanagari"])
  assert_eq(@unicode.script_extensions(0x30), ["Common"])
  let extensions = @unicode.script_extensions(0x30FC)
  extensions.clear()
  assert_eq(@unicode.script_extensions(0x30FC).length(), 2)
}

///|
test "Identifier_Status defaults to Restricted and does not imply identifier grammar" {
  for cp in [0x41, 0x30, 0x4E2D, 0x27, 0x2D] {
    assert_true(@unicode.identifier_status_allowed(cp))
  }
  for cp in [0x20, 0x200B, 0xE000, 0x1F600, 0x378, 0xD800, -1, 0x110000] {
    assert_false(@unicode.identifier_status_allowed(cp))
  }
  assert_eq(@unicode.unicode_script(-1), "Unknown")
  assert_eq(@unicode.script_extensions(0x110000), ["Unknown"])
}
