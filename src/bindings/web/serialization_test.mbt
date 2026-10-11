///|
test "all ASCII controls serialize as valid JSON across the ABI" {
  for cp in 0..<32 {
    let text = "x" + cp.unsafe_to_char().to_string() + "\"\\\u{20000}"
    assert_true(@json.valid(spoof_analyze(text)))
    assert_true(@json.valid(spoof_compare(text, "x")))
    assert_true(@json.valid(spoof_batch_scan(text)))
  }
}

///|
test "detailed and comparison reports share scalar fields" {
  let text = "p\u0430ypal\u0000"
  assert_true(spoof_analyze(text).contains("\"skeleton_case_folded\""))
  assert_true(spoof_analyze(text).contains("RULE_CONTROL_CHARACTER"))
  assert_true(@json.valid(spoof_get_restriction_info(text)))
}
