// Package confusable: UTS #39 Confusable Skeleton Generation & Comparison

///|
pub fn map_confusable_codepoint(cp : Int) -> String {
  // Unicode Default_Ignorable_Code_Point, including bidi controls.
  if @unicode.is_default_ignorable(cp) {
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
fn skeleton_pass(input : String) -> String {
  let buf = StringBuilder()
  for ch in @unicode.normalize_nfd(input) {
    let cp = ch.to_int()
    let mapped = map_confusable_codepoint(cp)
    buf.write_string(mapped)
  }
  @unicode.normalize_nfd(buf.to_string())
}

///|
pub fn skeleton(input : String) -> String {
  // Close mappings under NFD: some official prototypes contain composed Hangul
  // whose decomposed trailing Jamo have another confusable mapping.
  let mut current = @unicode.normalize_nfd(input)
  while true {
    let next = skeleton_pass(current)
    if next == current {
      return next
    }
    current = next
  }
  current
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
  // Application key: full default case folding followed by skeleton mapping.
  // Reapply until stable because mapping can introduce a cased prototype.
  let mut current = input
  while true {
    let next = skeleton(@unicode.case_fold(current))
    if next == current {
      return next
    }
    current = next
  }
  current
}

///|
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool {
  skeleton_case_folded(a) == skeleton_case_folded(b)
}
