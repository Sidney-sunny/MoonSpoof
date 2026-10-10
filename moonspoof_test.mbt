// MoonSpoof Standard Unit Tests & Official UTS #39 Conformance Vectors

///|
test "confusable detection: Latin vs Cyrillic paypal" {
  let authentic = "paypal"
  let spoofed = "p\u0430ypal" // Cyrillic Small Letter A (U+0430)
  assert_true(are_confusable(authentic, spoofed))
}

///|
test "confusable detection: Cyrillic google" {
  let authentic = "google"
  let spoofed = "g\u043E\u043Egle" // Cyrillic Small Letter O (U+043E)
  assert_true(are_confusable(authentic, spoofed))
  assert_eq(skeleton(spoofed), "google")
}

///|
test "confusable detection: Greek micro (m -> rn in UTS #39)" {
  let authentic = "micro"
  let spoofed = "micr\u03BF" // Greek Small Letter Omicron (U+03BF)
  assert_true(are_confusable(authentic, spoofed))
  assert_eq(skeleton(authentic), "rnicro")
  assert_eq(skeleton(spoofed), "rnicro")
}

///|
test "confusable detection: Fullwidth ASCII admin" {
  let fullwidth = "\uFF41\uFF44\uFF4D\uFF49\uFF4E" // ａｄｍｉｎ
  assert_true(are_confusable("admin", fullwidth))
  assert_eq(skeleton(fullwidth), "adrnin")
  assert_eq(skeleton("admin"), "adrnin")
}

///|
test "confusable skeleton equivalence" {
  let spoofed = "p\u0430ypal"
  let sk = skeleton(spoofed)
  assert_eq(sk, "paypal")
}

///|
test "mixed script identifier diagnosis" {
  let spoofed = "p\u0430ypal"
  let report = analyze_identifier(spoofed)
  assert_true(report.script_analysis.is_mixed)
  assert_eq(report.risk_level, @security.SecurityRiskLevel::High)
}

///|
test "invisible zero-width space triggers critical risk" {
  let malicious = "admin\u200B" // U+200B Zero Width Space
  let report = analyze_identifier(malicious)
  assert_eq(report.risk_level, @security.SecurityRiskLevel::Critical)
  assert_true(
    report.rules_triggered.contains("RULE_INVISIBLE_OR_FORMAT_CHARACTER"),
  )
}

///|
test "batch collision scanner groups homoglyphs" {
  let names = ["admin", "adm\u0456n", "alice", "bob"]
  let groups = find_confusable_groups(names)
  assert_eq(groups.length(), 1)
  assert_eq(groups[0].members.length(), 2)
}
