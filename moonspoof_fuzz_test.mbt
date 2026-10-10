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
     "MIXED_\u0430\u03BF\uFF41_TOKEN", "safe_identifier_sample",
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
test "property: confusable implies case-insensitive confusable" {
  let samples = get_fuzz_samples()
  for a in samples {
    for b in samples {
      if are_confusable(a, b) {
        assert_true(are_confusable_ignore_case(a, b))
      }
    }
  }
}

///|
test "fuzzing: security diagnostic never panics on arbitrary input" {
  let samples = get_fuzz_samples()
  for s in samples {
    let report = analyze_identifier(s)
    assert_eq(report.original, s)
    assert_true(report.char_diagnostics.length() == s.length())
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
