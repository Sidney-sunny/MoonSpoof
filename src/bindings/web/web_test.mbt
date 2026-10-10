// Web FFI Bindings Unit Tests

///|
test "web bindings: spoof_compare JSON output" {
  let res = spoof_compare("paypal", "p\u0430ypal")
  assert_true(res.contains("\"are_confusable\":true"))
  assert_true(res.contains("\"are_confusable_ignore_case\":true"))
  assert_true(res.contains("\"skeleton\":\"paypal\""))
}

///|
test "web bindings: spoof_analyze JSON output" {
  let res = spoof_analyze("p\u0430ypal")
  assert_true(res.contains("\"original\":\"p\u0430ypal\""))
  assert_true(res.contains("\"risk_level\":\"High\""))
  assert_true(res.contains("\"chars\":["))
}

///|
test "web bindings: spoof_batch_scan JSON output" {
  let raw = "admin, adm\u0456n\nalice"
  let res = spoof_batch_scan(raw)
  assert_true(res.contains("\"total_names\":3"))
  assert_true(res.contains("\"group_count\":1"))
}

///|
test "web bindings: spoof_validate_profile JSON output" {
  let strict_rej = spoof_validate_profile("p\u0430ypal", false)
  assert_true(strict_rej.contains("\"valid\":false"))

  let perm_ok = spoof_validate_profile("p\u0430ypal", true)
  assert_true(perm_ok.contains("\"valid\":true"))
}

///|
test "web bindings: direct skeleton and restriction info" {
  let sk = spoof_skeleton("p\u0430ypal")
  assert_eq(sk, "paypal")

  let sk_cf = spoof_skeleton_case_folded("PAYPAL")
  assert_eq(sk_cf, "paypal")

  let info = spoof_get_restriction_info("p\u0430ypal")
  assert_true(info.contains("\"is_mixed\":true"))
  assert_true(info.contains("\"restriction_level\":\"ModeratelyRestrictive\""))
}
