// Package confusable: UTS #39 Confusable Skeleton Generation & Comparison

pub fn map_confusable_codepoint(cp : Int) -> String {
  let normalized_cp = if cp >= 0xFF01 && cp <= 0xFF5E {
    cp - 0xFEE0
  } else {
    cp
  }
  match binary_search_confusable(normalized_cp) {
    Some(target) => target
    None => normalized_cp.unsafe_to_char().to_string()
  }
}

pub fn skeleton(input : String) -> String {
  let buf = StringBuilder()
  for ch in input {
    let cp = ch.to_int()
    let mapped = map_confusable_codepoint(cp)
    buf.write_string(mapped)
  }
  buf.to_string()
}

pub fn are_confusable(a : String, b : String) -> Bool {
  skeleton(a) == skeleton(b)
}
