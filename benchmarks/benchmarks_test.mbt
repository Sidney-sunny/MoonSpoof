// MoonSpoof Benchmark Harness Unit Tests

///|
test "benchmarks: single and case-folded comparison execution" {
  benchmark_single_comparison()
  benchmark_case_folded_comparison()
}

///|
test "benchmarks: diagnostic audit and profile validation execution" {
  benchmark_diagnostic_audit()
  benchmark_profile_validation()
  benchmark_mixed_script_analysis()
}

///|
test "benchmarks: batch dataset generation and collision verification" {
  let count_1k = benchmark_batch_1000()
  assert_true(count_1k > 0)
}
