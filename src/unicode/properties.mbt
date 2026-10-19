///|
fn property_range_index(
  starts : FixedArray[Int],
  ends : FixedArray[Int],
  cp : Int,
) -> Int {
  if cp < 0 || cp > 0x10FFFF {
    return -1
  }
  let mut low = 0
  let mut high = starts.length()
  while low < high {
    let mid = low + (high - low) / 2
    if starts[mid] <= cp {
      low = mid + 1
    } else {
      high = mid
    }
  }
  if low > 0 && cp <= ends[low - 1] {
    low - 1
  } else {
    -1
  }
}

///|
/// Complete Script property; invalid inputs use the Unknown fallback.
pub fn unicode_script(cp : Int) -> String {
  let index = property_range_index(full_script_starts, full_script_ends, cp)
  if index < 0 {
    "Unknown"
  } else {
    full_script_values[index]
  }
}

///|
/// Long canonical names; missing extensions inherit Script, per UAX #24.
pub fn script_extensions(cp : Int) -> Array[String] {
  let index = property_range_index(
    script_extension_starts, script_extension_ends, cp,
  )
  if index < 0 {
    [unicode_script(cp)]
  } else {
    script_extension_values[index]
    .split(" ")
    .map(fn(name) { name.to_string() })
    .collect()
  }
}

///|
/// Literal per-codepoint property lookup; absent values are Restricted.
pub fn identifier_status_allowed(cp : Int) -> Bool {
  property_range_index(identifier_allowed_starts, identifier_allowed_ends, cp) >=
  0
}

///|
/// Unique zero representative of an Nd family; no normalization is applied.
pub fn decimal_zero(cp : Int) -> Int? {
  let mut low = 0
  let mut high = decimal_zeros.length()
  while low < high {
    let mid = low + (high - low) / 2
    if decimal_zeros[mid] <= cp {
      low = mid + 1
    } else {
      high = mid
    }
  }
  if low > 0 && cp <= decimal_zeros[low - 1] + 9 {
    Some(decimal_zeros[low - 1])
  } else {
    None
  }
}
