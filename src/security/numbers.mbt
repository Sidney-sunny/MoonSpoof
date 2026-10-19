///|
pub(all) struct MixedNumberIssue {
  codepoint_index : Int
  codepoint : Int
  codepoint_hex : String
  first_decimal_zero : Int
  decimal_zero : Int
} derive(Eq, Debug)

///|
pub fn get_decimal_zero(cp : Int) -> Int? {
  @unicode.decimal_zero(cp)
}

///|
/// Sorted unique zero representatives of decimal systems in the raw input.
pub fn get_decimal_systems(input : String) -> Array[Int] {
  let zeros : Array[Int] = []
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
  let mut first : Int? = None
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
