// MoonSpoof Whitebox & Edge Case Test Suite

test "whitebox: codepoint formatting" {
  let cp_null = @unicode.format_codepoint(0)
  assert_eq(cp_null, "U+0000")

  let cp_a = @unicode.format_codepoint(0x61)
  assert_eq(cp_a, "U+0061")

  let cp_cyrillic = @unicode.format_codepoint(0x0430)
  assert_eq(cp_cyrillic, "U+0430")
}

test "whitebox: bidi and invisible control flags" {
  assert_true(@unicode.is_invisible_codepoint(0x200B)) // ZWSP
  assert_true(@unicode.is_invisible_codepoint(0xFEFF)) // BOM
  assert_false(@unicode.is_invisible_codepoint(0x0041)) // 'A'

  assert_true(@unicode.is_bidi_control_codepoint(0x202E)) // RLO
  assert_false(@unicode.is_bidi_control_codepoint(0x0041))
}

test "whitebox: script identification ranges" {
  assert_eq(@script.get_script(0x0041), @script.Script::Latin)
  assert_eq(@script.get_script(0x0430), @script.Script::Cyrillic)
  assert_eq(@script.get_script(0x03B1), @script.Script::Greek)
  assert_eq(@script.get_script(0x4E2D), @script.Script::Han) // 中
  assert_eq(@script.get_script(0x3042), @script.Script::Hiragana) // あ
  assert_eq(@script.get_script(0xAC00), @script.Script::Hangul) // 가
}
