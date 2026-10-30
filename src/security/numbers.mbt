///|
pub(all) struct MixedNumberIssue {
  codepoint_index : Int32
  codepoint : Int32
  codepoint_hex : String
  first_decimal_zero : Int32
  decimal_zero : Int32
} derive(Eq, Debug)

///|
pub fn get_decimal_zero(cp : Int32) -> Int32? {
  @unicode.decimal_zero(cp)
}

///|
/// Sorted unique zero representatives of decimal systems in the raw input.
pub fn get_decimal_systems(input : String) -> Array[Int32] {
  let zeros : Array[Int32] = []
  for ch in input {
    if @unicode.decimal_zero(ch.to_int()) is Some(zero) {
      if !zeros.contains(zero) {
        zeros.push(zero)
      }
    }
  }
  zeros.sort()
  zeros
}

///|
/// Checks decimal mixing only; empty and non-decimal input do not fail.
pub fn validate_number_systems(
  input : String,
) -> Result[Unit, MixedNumberIssue] {
  let mut first : Int32? = None
  let mut index = 0
  for ch in input {
    let cp = ch.to_int()
    if @unicode.decimal_zero(cp) is Some(zero) {
      match first {
        None => first = Some(zero)
        Some(initial) =>
          if initial != zero {
            return Err({
              codepoint_index: index,
              codepoint: cp,
              codepoint_hex: @unicode.format_codepoint(cp),
              first_decimal_zero: initial,
              decimal_zero: zero,
            })
          }
      }
    }
    index += 1
  }
  Ok(())
}

///|
pub fn has_mixed_numbers(input : String) -> Bool {
  validate_number_systems(input) is Err(_)
}
