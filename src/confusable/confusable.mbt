// Package confusable: UTS #39 Confusable Skeleton Generation & Comparison

///|
pub fn map_confusable_codepoint(cp : Int) -> String {
  // Strip default ignorable / invisible format characters (UTS #39 Section 4)
  if @unicode.is_invisible_codepoint(cp) {
    return ""
  }
  // Normalize Ideographic Space U+3000 to standard ASCII space 0x0020
  let normalized_cp = if cp == 0x3000 {
    0x0020
  } else if cp >= 0xFF01 && cp <= 0xFF5E {
    cp - 0xFEE0
  } else {
    cp
  }
  match binary_search_confusable(normalized_cp) {
    Some(target) => target
    None => normalized_cp.unsafe_to_char().to_string()
  }
}

///|
pub fn skeleton(input : String) -> String {
  let buf = StringBuilder()
  for ch in input {
    let cp = ch.to_int()
    let mapped = map_confusable_codepoint(cp)
    buf.write_string(mapped)
  }
  buf.to_string()
}

///|
pub fn are_confusable(a : String, b : String) -> Bool {
  skeleton(a) == skeleton(b)
}

///|
pub fn to_lower_ascii(s : String) -> String {
  let buf = StringBuilder()
  for ch in s {
    let cp = ch.to_int()
    if cp >= 65 && cp <= 90 {
      buf.write_string((cp + 32).unsafe_to_char().to_string())
    } else {
      buf.write_string(ch.to_string())
    }
  }
  buf.to_string()
}

///|
pub fn skeleton_case_folded(input : String) -> String {
  to_lower_ascii(skeleton(to_lower_ascii(input)))
}

///|
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool {
  are_confusable(a, b) || skeleton_case_folded(a) == skeleton_case_folded(b)
}
