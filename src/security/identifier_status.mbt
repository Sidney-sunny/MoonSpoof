///|
pub(all) enum IdentifierStatus {
  Allowed
  Restricted
} derive(Eq, Debug)

///|
pub(all) struct IdentifierStatusIssue {
  codepoint_index : Int
  codepoint : Int
  codepoint_hex : String
} derive(Eq, Debug)

///|
pub(all) enum IdentifierStatusError {
  Empty
  RestrictedCharacter(IdentifierStatusIssue)
} derive(Eq, Debug)

///|
/// Exact Unicode property; this does not validate identifier grammar.
pub fn get_identifier_status(cp : Int) -> IdentifierStatus {
  if @unicode.identifier_status_allowed(cp) {
    Allowed
  } else {
    Restricted
  }
}

///|
/// Opt-in literal-codepoint filter; no normalization or canonical closure.
/// Existing profile defaults are unaffected. Index counts Unicode scalars.
pub fn validate_identifier_status(
  input : String,
) -> Result[Unit, IdentifierStatusError] {
  if input.is_empty() {
    return Err(Empty)
  }
  let mut index = 0
  for ch in input {
    let cp = ch.to_int()
    if !@unicode.identifier_status_allowed(cp) {
      return Err(
        RestrictedCharacter({
          codepoint_index: index,
          codepoint: cp,
          codepoint_hex: @unicode.format_codepoint(cp),
        }),
      )
    }
    index += 1
  }
  Ok(())
}
