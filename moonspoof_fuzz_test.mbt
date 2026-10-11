// Property-based invariants and differential fuzzing test suite

///|
fn get_fuzz_samples() -> Array[String] {
  [
    "", "a", "A", "paypal", "p\u0430ypal", "PAYPAL", "apple", "appIe", "micro", "micr\u03BF",
    "\u03BCicro", "admin", "admin\u200B", "admin\u200C", "admin\u200D", "\uFF41\uFF44\uFF4D\uFF49\uFF4E", // fullwidth admin
     "hello\u3000world", "hello world", "root", "r\u043E\u043Et", "cloudflare", "cloudfl\u0430re",
    "google", "goog1e", "g\u043E\u043Egle", "1234567890", "\uFF11\uFF12\uFF13", "complex_\u0430_test_123",
    "\u4E2D\u6587\u6D4B\u8BD5", // Han
     "\u3042\u3044\u3046\u3048\u304A", // Hiragana
     "\u30A2\u30A4\u30A6\u30A8\u30A4", // Katakana
     "\uAC00\uB098\uB2E4", // Hangul
     "MIXED_\u0430\u03BF\uFF41_TOKEN", "safe_identifier_sample", "invoice\u202Eexe.pdf",
    "script\u202Dcom.bat", "\u{1D400}\u{1D401}\u{1D402}", // Mathematical Bold ABC (Astral plane U+1D400..)
     "\u{1F600}\u{1F680}", // Emoji (Astral plane U+1F600..)
     "\u{20000}\u{20001}", // CJK Extension B (Astral plane U+20000..)
  ]
}

///|
test "property: reflexivity of are_confusable" {
  let samples = get_fuzz_samples()
  for s in samples {
    assert_true(are_confusable(s, s))
    assert_true(are_confusable_ignore_case(s, s))
  }
}

///|
test "property: skeleton transformation idempotency" {
  let samples = get_fuzz_samples()
  for s in samples {
    let sk1 = skeleton(s)
    let sk2 = skeleton(sk1)
    assert_eq(sk1, sk2)
  }
}

///|
test "property: case-folded skeleton idempotency" {
  let samples = get_fuzz_samples()
  for s in samples {
    let sk1 = skeleton_case_folded(s)
    let sk2 = skeleton_case_folded(sk1)
    assert_eq(sk1, sk2)
  }
}

///|
test "property: symmetry of are_confusable" {
  let samples = get_fuzz_samples()
  for a in samples {
    for b in samples {
      let ab = are_confusable(a, b)
      let ba = are_confusable(b, a)
      assert_eq(ab, ba)
    }
  }
}

///|
test "property: case-insensitive comparison uses the same key as grouping" {
  let samples = get_fuzz_samples()
  for a in samples {
    for b in samples {
      assert_eq(
        are_confusable_ignore_case(a, b),
        skeleton_case_folded(a) == skeleton_case_folded(b),
      )
    }
  }
}

///|
test "fuzzing: security diagnostic never panics on arbitrary input" {
  let samples = get_fuzz_samples()
  for s in samples {
    let report = analyze_identifier(s)
    assert_eq(report.original, s)
    let mut char_count = 0
    for _ in s {
      char_count += 1
    }
    assert_eq(report.char_diagnostics.length(), char_count)
  }
}

///|
test "property: script classification consistency" {
  let samples = get_fuzz_samples()
  for s in samples {
    let single = is_single_script(s)
    let mixed = is_mixed_script(s)
    let level = get_restriction_level(s)
    if single {
      assert_false(mixed)
      assert_eq(level, @script.RestrictionLevel::SingleScript)
    }
    if mixed {
      assert_false(single)
      assert_true(level != @script.RestrictionLevel::SingleScript)
    }
    let _ = validate_identifier(s)
    let _ = is_allowed_identifier(s)
  }
}

///|
test "property: bidi and invisible detection invariant" {
  let samples = get_fuzz_samples()
  for s in samples {
    let rep = analyze_identifier(s)
    let has_bidi = has_bidi_controls(s)
    let has_inv = has_invisible_characters(s)
    let has_ovr = has_bidi_override(s)

    if has_ovr {
      assert_true(has_bidi)
      assert_eq(rep.risk_level, @security.SecurityRiskLevel::Critical)
      assert_true(rep.rules_triggered.contains("RULE_BIDI_OVERRIDE_CHARACTER"))
    }
    if has_inv || has_bidi {
      assert_eq(rep.risk_level, @security.SecurityRiskLevel::Critical)
    }
  }
}

///|
test "property: batch confusable clustering invariants" {
  let samples = get_fuzz_samples()
  let groups = find_confusable_groups(samples)
  for g in groups {
    assert_true(g.members.length() >= 2)
    let expected_sk = g.skeleton
    for m in g.members {
      assert_eq(skeleton(m), expected_sk)
    }
    // Mutual confusability
    for i in 0..<g.members.length() {
      for j in 0..<g.members.length() {
        assert_true(are_confusable(g.members[i], g.members[j]))
      }
    }
  }
}

///|
test "property: batch confusable clustering ignore case invariants" {
  let samples = get_fuzz_samples()
  let groups = find_confusable_groups_ignore_case(samples)
  for g in groups {
    assert_true(g.members.length() >= 2)
    let expected_sk = g.skeleton
    for m in g.members {
      assert_eq(skeleton_case_folded(m), expected_sk)
    }
    // Mutual case-insensitive confusability
    for i in 0..<g.members.length() {
      for j in 0..<g.members.length() {
        assert_true(are_confusable_ignore_case(g.members[i], g.members[j]))
      }
    }
  }
}
