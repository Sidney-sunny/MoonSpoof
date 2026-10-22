///|
test "long combining sequences preserve normalization and stable application keys" {
  let source = StringBuilder()
  let canonical = StringBuilder()
  for _ in 0..<512 {
    source.write_string("a\u0315\u0300")
    canonical.write_string("a\u0300\u0315")
  }
  let original = source.to_string()
  let ordered = canonical.to_string()
  assert_eq(@moonspoof.skeleton(original), @moonspoof.skeleton(ordered))
  let key = @moonspoof.skeleton(original)
  assert_eq(@moonspoof.skeleton(key), key)
  let folded = @moonspoof.skeleton_case_folded(original)
  assert_eq(@moonspoof.skeleton_case_folded(folded), folded)
  assert_true(@moonspoof.validate_identifier(original) is Err(_))
}

///|
test "adversarial pair and batch decisions use identical equivalence policies" {
  let names = [
    "é", "e\u0301", "I", "l", "i", "\u321D", "(\u110B\u1169\u110C\u1165\u11AB)",
    "admin", "ad\u200Bmin", "a\u0000b", "a\u{20000}", "Ａ1", "Al",
  ]
  for folded in [false, true] {
    let groups = if folded {
      @moonspoof.find_confusable_groups_ignore_case(names)
    } else {
      @moonspoof.find_confusable_groups(names)
    }
    for i in 0..<names.length() {
      for j in (i + 1)..<names.length() {
        let mut grouped = false
        for group in groups {
          if group.members.contains(names[i]) &&
            group.members.contains(names[j]) {
            grouped = true
          }
        }
        let paired = if folded {
          @moonspoof.are_confusable_ignore_case(names[i], names[j])
        } else {
          @moonspoof.are_confusable(names[i], names[j])
        }
        assert_eq(grouped, paired)
      }
    }
  }
}

///|
test "supplementary and control input keeps scalar evidence and key stability" {
  let text = "\u{20000}\u{1E900}\u202Ea\u0000"
  let report = @moonspoof.analyze_identifier(text)
  assert_eq(report.char_diagnostics.length(), 5)
  assert_eq(report.char_diagnostics[0].codepoint, 0x20000)
  assert_eq(report.char_diagnostics[1].codepoint, 0x1E900)
  assert_true(@moonspoof.has_bidi_controls(text))
  assert_true(@moonspoof.validate_identifier(text) is Err(_))
  assert_eq(@moonspoof.skeleton(report.skeleton), report.skeleton)
}

///|
test "Hangul closure and folded prototype policies remain explicit" {
  assert_eq(@moonspoof.skeleton("\u321D"), "(\u110B\u1169\u110C\u1165\u1102)")
  assert_eq(@moonspoof.skeleton_case_folded("\u{1D7CE}\u{1D7D8}"), "oo")
  assert_true(@moonspoof.are_confusable("I", "l"))
  assert_false(@moonspoof.are_confusable_ignore_case("I", "l"))
}
