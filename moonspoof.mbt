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
pub type ConfusableGroup = @batch.ConfusableGroup

///|
pub type UnicodeVersion = @unicode.UnicodeVersion

///|
pub type IdentifierProfile = @security.IdentifierProfile

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
pub fn get_unicode_version() -> @unicode.UnicodeVersion {
  @unicode.unicode_version
}
