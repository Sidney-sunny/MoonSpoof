// MoonSpoof Whitebox & Edge Case Test Suite

///|
test "whitebox: codepoint formatting" {
  let cp_null = @unicode.format_codepoint(0)
  assert_eq(cp_null, "U+0000")

  let cp_a = @unicode.format_codepoint(0x61)
  assert_eq(cp_a, "U+0061")

  let cp_cyrillic = @unicode.format_codepoint(0x0430)
  assert_eq(cp_cyrillic, "U+0430")
}

///|
test "whitebox: bidi and invisible control flags" {
  assert_true(@unicode.is_invisible_codepoint(0x200B)) // ZWSP
  assert_true(@unicode.is_invisible_codepoint(0xFEFF)) // BOM
  assert_false(@unicode.is_invisible_codepoint(0x0041)) // 'A'

  assert_true(@unicode.is_bidi_control_codepoint(0x202E)) // RLO
  assert_false(@unicode.is_bidi_control_codepoint(0x0041))
}

///|
test "whitebox: script identification ranges" {
  assert_eq(@script.get_script(0x0041), @script.Script::Latin)
  assert_eq(@script.get_script(0x0430), @script.Script::Cyrillic)
  assert_eq(@script.get_script(0x03B1), @script.Script::Greek)
  assert_eq(@script.get_script(0x4E2D), @script.Script::Han) // 中
  assert_eq(@script.get_script(0x3042), @script.Script::Hiragana) // あ
  assert_eq(@script.get_script(0xAC00), @script.Script::Hangul) // 가
}

///|
test "whitebox: confusable mapping boundary conditions" {
  // Test non-confusable standard Latin character
  assert_eq(@confusable.map_confusable_codepoint(0x007A), "z") // 'z' has no confusable entry
  // Test lower bound ASCII space
  assert_eq(@confusable.map_confusable_codepoint(0x0020), " ")
  // Test out-of-range / non-existent codepoint
  assert_eq(@confusable.map_confusable_codepoint(0x10FFFF), "\u{10FFFF}")
}

///|
test "whitebox: all bidi control codepoints validated" {
  let bidi_list = [
    0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068,
    0x2069,
  ]
  for cp in bidi_list {
    assert_true(@unicode.is_bidi_control_codepoint(cp))
  }
}

///|
test "whitebox: all invisible format control codepoints validated" {
  let inv_list = [0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF, 0x00AD]
  for cp in inv_list {
    assert_true(@unicode.is_invisible_codepoint(cp))
  }
}
