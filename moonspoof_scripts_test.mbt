///|
test "full script facade complements the unchanged legacy categories" {
  assert_eq(@moonspoof.get_unicode_script(0x905), "Devanagari")
  assert_eq(@moonspoof.get_unicode_script(0x1E900), "Adlam")
  assert_eq(@moonspoof.get_script_extensions(0x30FC), ["Hiragana", "Katakana"])
  assert_eq(
    @moonspoof.analyze_scripts("अ").level,
    @moonspoof.RestrictionLevel::Unrestricted,
  )
  assert_eq(
    @moonspoof.resolve_script_set("अ"),
    @moonspoof.ScriptSet::Scripts(["Devanagari"]),
  )
}

///|
test "resolved sets augment Japanese Korean and Han with Bopomofo" {
  for
    (name, scripts) in [
      ("ねガ", ["Jpan"]),
      ("中文あア", ["Jpan"]),
      ("中文가", ["Kore"]),
      ("中文ㄅ", ["Hanb"]),
      ("〆切", ["Han", "Hanb", "Jpan", "Kore"]),
    ] {
    assert_eq(
      @moonspoof.resolve_script_set(name),
      @moonspoof.ScriptSet::Scripts(scripts),
    )
    assert_false(@moonspoof.is_mixed_script_resolved(name))
  }
}

///|
test "shared characters constrain script contexts instead of being discarded" {
  assert_eq(
    @moonspoof.resolve_script_set("あー"),
    @moonspoof.ScriptSet::Scripts(["Hiragana", "Jpan"]),
  )
  assert_true(@moonspoof.is_mixed_script_resolved("aー"))
  assert_false(@moonspoof.is_mixed_script("aー"))
  assert_true(@moonspoof.is_mixed_script_resolved("a\u0430"))
  assert_true(@moonspoof.is_mixed_script_resolved("a中"))
  assert_false(@moonspoof.is_mixed_script_resolved("अ१"))
}

///|
test "ALL empty and Unknown sets have distinct semantics" {
  assert_eq(@moonspoof.resolve_script_set(""), @moonspoof.ScriptSet::All)
  assert_eq(@moonspoof.resolve_script_set("123_"), @moonspoof.ScriptSet::All)
  assert_eq(
    @moonspoof.resolve_script_set("\u0378"),
    @moonspoof.ScriptSet::Scripts(["Unknown"]),
  )
  assert_eq(
    @moonspoof.resolve_script_set("a\u0378"),
    @moonspoof.ScriptSet::Scripts([]),
  )
  assert_eq(
    @moonspoof.resolve_script_set("a1_"),
    @moonspoof.ScriptSet::Scripts(["Latin"]),
  )
}

///|
test "combining marks respect their Script_Extensions rather than only Inherited" {
  assert_eq(
    @moonspoof.resolve_script_set("a\u0301"),
    @moonspoof.ScriptSet::Scripts(["Latin"]),
  )
  assert_false(@moonspoof.is_mixed_script_resolved("a\u0301"))
  assert_eq(
    @moonspoof.resolve_script_set("ไทย"),
    @moonspoof.ScriptSet::Scripts(["Thai"]),
  )
}
