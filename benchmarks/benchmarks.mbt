// MoonSpoof Performance Benchmarks: 1,000 & 10,000 identifier scale tests

///|
pub fn benchmark_single_comparison() -> Unit {
  let a = "apple_administrator_service_account"
  let b = "аpple_аdministrаtor_service_аccount"
  for i = 0; i < 1000; i = i + 1 {
    let _ = @moonspoof.are_confusable(a, b)
  }
}

///|
pub fn generate_benchmark_dataset(count : Int) -> Array[String] {
  let list : Array[String] = []
  for i = 0; i < count; i = i + 1 {
    let key = i % 50
    if i % 2 == 0 {
      list.push("p\u0430ypal_user_\{key}")
    } else {
      list.push("paypal_user_\{key}")
    }
  }
  list
}

///|
pub fn benchmark_batch_1000() -> Int {
  let dataset = generate_benchmark_dataset(1000)
  let collisions = @moonspoof.find_confusable_groups(dataset)
  collisions.length()
}

///|
pub fn benchmark_batch_10000() -> Int {
  let dataset = generate_benchmark_dataset(10000)
  let collisions = @moonspoof.find_confusable_groups(dataset)
  collisions.length()
}

///|
pub fn benchmark_case_folded_comparison() -> Unit {
  let a = "PAYPAL_ADMINISTRATOR"
  let b = "p\u0430ypal_аdministrаtor"
  for i = 0; i < 1000; i = i + 1 {
    let _ = @moonspoof.are_confusable_ignore_case(a, b)
  }
}

///|
pub fn benchmark_diagnostic_audit() -> Unit {
  let input = "p\u0430ypal_service_account\u200B"
  for i = 0; i < 1000; i = i + 1 {
    let _ = @moonspoof.analyze_identifier(input)
  }
}

///|
pub fn benchmark_profile_validation() -> Unit {
  let samples = [
    "paypal_service", "p\u0430ypal_service", "admin\u200B", "\u0430\u03BF", "\u4E2D\u6587\u6D4B\u8BD5",
  ]
  for i = 0; i < 500; i = i + 1 {
    for s in samples {
      let _ = @moonspoof.validate_identifier(s)
      let _ = @moonspoof.is_allowed_identifier(
        s,
        profile=@moonspoof.IdentifierProfile::permissive(),
      )
    }
  }
}

///|
pub fn benchmark_mixed_script_analysis() -> Unit {
  let samples = [
    "regular_latin_identifier", "p\u0430ypal_mixed_cyrillic", "\u0430\u03BF_cyrillic_greek",
    "\u65E5\u672C\u8A9E_japanese_text",
  ]
  for i = 0; i < 500; i = i + 1 {
    for s in samples {
      let _ = @moonspoof.analyze_scripts(s)
      let _ = @moonspoof.get_restriction_level(s)
    }
  }
}
