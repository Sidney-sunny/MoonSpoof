// MoonSpoof: Public Facade APIs for UTS #39 Unicode Spoof Detection

///|
pub type SecurityRiskLevel = @security.SecurityRiskLevel

///|
pub type DiagnosticReport = @security.DiagnosticReport

///|
pub type CharDiagnostic = @security.CharDiagnostic

///|
pub type ScriptAnalysis = @script.ScriptAnalysis

///|
pub type Script = @script.Script

///|
pub type ScriptSet = @script.ScriptSet

///|
pub fn get_unicode_script(cp : Int) -> String {
  @script.get_unicode_script(cp)
}

///|
pub fn get_script_extensions(cp : Int) -> Array[String] {
  @script.get_script_extensions(cp)
}

///|
pub fn resolve_script_set(input : String) -> @script.ScriptSet {
  @script.resolve_script_set(input)
}

///|
pub fn is_mixed_script_resolved(input : String) -> Bool {
  @script.is_mixed_script_resolved(input)
}

///|
pub type ConfusableGroup = @batch.ConfusableGroup

///|
pub type UnicodeVersion = @unicode.UnicodeVersion

///|
pub type IdentifierProfile = @security.IdentifierProfile

///|
pub type IdentifierStatus = @security.IdentifierStatus

///|
pub type IdentifierStatusIssue = @security.IdentifierStatusIssue

///|
pub type IdentifierStatusError = @security.IdentifierStatusError

///|
pub type MixedNumberIssue = @security.MixedNumberIssue

///|
pub fn get_decimal_zero(cp : Int) -> Int? {
  @security.get_decimal_zero(cp)
}

///|
pub fn get_decimal_systems(input : String) -> Array[Int] {
  @security.get_decimal_systems(input)
}

///|
pub fn validate_number_systems(
  input : String,
) -> Result[Unit, @security.MixedNumberIssue] {
  @security.validate_number_systems(input)
}

///|
pub fn has_mixed_numbers(input : String) -> Bool {
  @security.has_mixed_numbers(input)
}

///|
pub fn get_identifier_status(cp : Int) -> @security.IdentifierStatus {
  @security.get_identifier_status(cp)
}

///|
pub fn validate_identifier_status(
  input : String,
) -> Result[Unit, @security.IdentifierStatusError] {
  @security.validate_identifier_status(input)
}

///|
pub type RestrictionLevel = @script.RestrictionLevel

///|
pub fn is_single_script(input : String) -> Bool {
  @script.is_single_script(input)
}

///|
pub fn is_mixed_script(input : String) -> Bool {
  @script.is_mixed_script(input)
}

///|
pub fn get_restriction_level(input : String) -> @script.RestrictionLevel {
  @script.get_restriction_level(input)
}

///|
pub fn skeleton(input : String) -> String {
  @confusable.skeleton(input)
}

///|
pub fn skeleton_case_folded(input : String) -> String {
  @confusable.skeleton_case_folded(input)
}

///|
pub fn are_confusable(a : String, b : String) -> Bool {
  @confusable.are_confusable(a, b)
}

///|
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool {
  @confusable.are_confusable_ignore_case(a, b)
}

///|
pub fn analyze_scripts(input : String) -> @script.ScriptAnalysis {
  @script.analyze_scripts(input)
}

///|
pub fn analyze_identifier(input : String) -> @security.DiagnosticReport {
  @security.analyze_identifier(input)
}

///|
pub fn validate_identifier(
  input : String,
  profile? : @security.IdentifierProfile = @security.IdentifierProfile::default(),
) -> Result[Unit, String] {
  @security.validate_identifier(input, profile~)
}

///|
pub fn is_allowed_identifier(
  input : String,
  profile? : @security.IdentifierProfile = @security.IdentifierProfile::default(),
) -> Bool {
  @security.is_allowed_identifier(input, profile~)
}

///|
pub fn find_confusable_groups(
  names : Array[String],
) -> Array[@batch.ConfusableGroup] {
  @batch.find_confusable_groups(names)
}

///|
pub fn find_confusable_groups_ignore_case(
  names : Array[String],
) -> Array[@batch.ConfusableGroup] {
  @batch.find_confusable_groups_ignore_case(names)
}

///|
pub fn get_unicode_version() -> @unicode.UnicodeVersion {
  @unicode.unicode_version
}

///|
pub fn has_bidi_controls(input : String) -> Bool {
  @security.has_bidi_controls(input)
}

///|
pub fn has_bidi_override(input : String) -> Bool {
  @security.has_bidi_override(input)
}

///|
pub fn has_invisible_characters(input : String) -> Bool {
  @security.has_invisible_characters(input)
}
