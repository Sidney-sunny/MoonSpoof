// MoonSpoof: Public Facade APIs for UTS #39 Unicode Spoof Detection

pub type SecurityRiskLevel = @security.SecurityRiskLevel

pub type DiagnosticReport = @security.DiagnosticReport

pub type CharDiagnostic = @security.CharDiagnostic

pub type ScriptAnalysis = @script.ScriptAnalysis

pub type Script = @script.Script

pub type ConfusableGroup = @batch.ConfusableGroup

pub type UnicodeVersion = @unicode.UnicodeVersion

pub fn skeleton(input : String) -> String {
  @confusable.skeleton(input)
}

pub fn are_confusable(a : String, b : String) -> Bool {
  @confusable.are_confusable(a, b)
}

pub fn analyze_scripts(input : String) -> @script.ScriptAnalysis {
  @script.analyze_scripts(input)
}

pub fn analyze_identifier(input : String) -> @security.DiagnosticReport {
  @security.analyze_identifier(input)
}

pub fn find_confusable_groups(names : Array[String]) -> Array[@batch.ConfusableGroup] {
  @batch.find_confusable_groups(names)
}

pub fn get_unicode_version() -> @unicode.UnicodeVersion {
  @unicode.unicode_version
}
