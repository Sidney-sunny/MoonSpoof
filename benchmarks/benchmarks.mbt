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
    if i % 5 == 0 {
      list.push("p\u0430ypal_user_\{i}")
    } else if i % 7 == 0 {
      list.push("admin\u200B_account_\{i}")
    } else {
      list.push("regular_user_\{i}")
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
