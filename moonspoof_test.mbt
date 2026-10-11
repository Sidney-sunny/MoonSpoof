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

///|
test "issue-001: invisible format characters stripped in skeleton" {
  let authentic = "admin"
  let spoofed = "admin\u200B" // U+200B Zero Width Space
  assert_true(are_confusable(authentic, spoofed))
  assert_eq(skeleton(spoofed), skeleton(authentic))
}

///|
test "issue-002: ideographic space U+3000 normalized to ASCII space" {
  let authentic = "hello world"
  let spoofed = "hello\u3000world" // U+3000 Ideographic Space
  assert_true(are_confusable(authentic, spoofed))
  assert_eq(skeleton(spoofed), skeleton(authentic))
}

///|
test "issue-003: general category classifier coverage" {
  assert_eq(@unicode.get_general_category(65), @unicode.GeneralCategory::Letter)
  assert_eq(@unicode.get_general_category(48), @unicode.GeneralCategory::Number)
  assert_eq(
    @unicode.get_general_category(0x200B),
    @unicode.GeneralCategory::Other,
  )
}

///|
test "case-insensitive confusable detection" {
  let authentic_caps = "PAYPAL"
  let spoofed_mixed = "P\u0430yPal" // Cyrillic Small Letter A (U+0430)
  assert_true(are_confusable_ignore_case(authentic_caps, spoofed_mixed))
  assert_eq(skeleton_case_folded(authentic_caps), "paypal")
  assert_eq(skeleton_case_folded(spoofed_mixed), "paypal")
}

///|
test "identifier security profile: reject invisible format controls" {
  let malicious = "admin\u200B"
  let res = validate_identifier(malicious)
  assert_true(res is Err(_))
  assert_false(is_allowed_identifier(malicious))
}

///|
test "identifier security profile: reject mixed script under default profile" {
  let mixed = "p\u0430ypal"
  let res = validate_identifier(mixed)
  assert_true(res is Err(_))
  assert_false(is_allowed_identifier(mixed))
}

///|
test "identifier security profile: accept valid single-script identifier" {
  let valid = "paypal_service"
  let res = validate_identifier(valid)
  assert_true(res is Ok(_))
  assert_true(is_allowed_identifier(valid))
}

///|
test "identifier security profile: permissive allows mixed script" {
  let mixed = "p\u0430ypal"
  let res = validate_identifier(mixed, profile=IdentifierProfile::permissive())
  assert_true(res is Ok(_))
  assert_true(
    is_allowed_identifier(mixed, profile=IdentifierProfile::permissive()),
  )
}

///|
test "mixed script: triad detection flags Latin + Cyrillic spoof" {
  let spoofed = "p\u0430ypal"
  let report = analyze_identifier(spoofed)
  assert_true(
    report.rules_triggered.contains("RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD"),
  )
  assert_true(is_mixed_script(spoofed))
  assert_false(is_single_script(spoofed))
  assert_eq(
    get_restriction_level(spoofed),
    @script.RestrictionLevel::MinimallyRestrictive,
  )
}

///|
test "mixed script: minimally restrictive classification for Cyrillic + Greek" {
  let cyrillic_greek = "\u0430\u03BF" // Cyrillic a + Greek omicron
  assert_eq(
    get_restriction_level(cyrillic_greek),
    @script.RestrictionLevel::MinimallyRestrictive,
  )
  assert_true(is_mixed_script(cyrillic_greek))
}

///|
test "security: bidi override triggers critical risk and file spoof rule" {
  let malicious_filename = "invoice\u202Eexe.pdf" // RLO Trojan Source style spoof
  let report = analyze_identifier(malicious_filename)
  assert_eq(report.risk_level, @security.SecurityRiskLevel::Critical)
  assert_true(report.rules_triggered.contains("RULE_BIDI_CONTROL_CHARACTER"))
  assert_true(report.rules_triggered.contains("RULE_BIDI_OVERRIDE_CHARACTER"))
  assert_true(report.rules_triggered.contains("RULE_BIDI_FILE_EXTENSION_SPOOF"))
  assert_true(has_bidi_controls(malicious_filename))
  assert_true(has_bidi_override(malicious_filename))
}

///|
test "security: character predicate helpers on clean vs malicious strings" {
  assert_true(has_invisible_characters("admin\u200B"))
  assert_false(has_invisible_characters("admin"))
  assert_false(has_bidi_controls("admin"))
  assert_false(has_bidi_override("admin"))
}

///|
test "batch: case-insensitive collision grouping merges mixed-case homoglyphs" {
  let pool = ["PAYPAL", "p\u0430ypal", "Paypal", "alice", "ALICE"]
  let sensitive = find_confusable_groups(pool)
  let insensitive = find_confusable_groups_ignore_case(pool)

  // In sensitive mode, case differences prevent clustering
  assert_eq(sensitive.length(), 0)

  // In insensitive mode, case-folded skeletons cluster together
  assert_eq(insensitive.length(), 2)

  let mut found_paypal = false
  let mut found_alice = false
  for g in insensitive {
    if g.skeleton == "paypal" {
      assert_eq(g.members.length(), 3)
      found_paypal = true
    }
    if g.skeleton == "alice" {
      assert_eq(g.members.length(), 2)
      found_alice = true
    }
  }
  assert_true(found_paypal)
  assert_true(found_alice)
}
