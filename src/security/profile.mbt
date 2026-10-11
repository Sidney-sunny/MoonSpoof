// Package security: Identifier security profiles (UTS #39 Section 3)

///|
pub(all) struct IdentifierProfile {
  allow_mixed_script : Bool
  allow_invisible : Bool
  max_length : Int
} derive(Eq, Debug)

///|
pub fn IdentifierProfile::default() -> IdentifierProfile {
  { allow_mixed_script: false, allow_invisible: false, max_length: 128, }
}

///|
pub fn IdentifierProfile::permissive() -> IdentifierProfile {
  { allow_mixed_script: true, allow_invisible: false, max_length: 256, }
}

///|
pub fn validate_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default(),
) -> Result[Unit, String] {
  if input.length() == 0 {
    return Err("Identifier cannot be empty")
  }
  let mut length = 0
  for ch in input {
    length += 1
    if length > profile.max_length {
      return Err("Identifier length exceeds maximum allowed length")
    }
    let cp = ch.to_int()
    if cp < 0x20 || (cp >= 0x7F && cp <= 0x9F) {
      return Err("Identifier contains disallowed control character")
    }
    if !profile.allow_invisible {
      if @unicode.is_default_ignorable(cp) {
        return Err("Identifier contains disallowed invisible format character")
      }
      if @unicode.is_bidi_control_codepoint(cp) {
        return Err(
          "Identifier contains disallowed bidirectional control character",
        )
      }
    }
  }

  if !profile.allow_mixed_script {
    let script_res = @script.analyze_scripts(input)
    if script_res.is_mixed {
      return Err("Identifier contains disallowed mixed scripts")
    }
  }

  Ok(())
}

///|
pub fn is_allowed_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default(),
) -> Bool {
  match validate_identifier(input, profile~) {
    Ok(_) => true
    Err(_) => false
  }
}
