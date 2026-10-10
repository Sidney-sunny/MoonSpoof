// Package security: Character-level diagnostics and identifier risk modeling

///|
pub(all) enum SecurityRiskLevel {
  Safe
  Low
  Medium
  High
  Critical
} derive(Eq, Debug)

///|
pub impl Show for SecurityRiskLevel with fn output(self, logger) {
  match self {
    Safe => logger.write_string("Safe")
    Low => logger.write_string("Low")
    Medium => logger.write_string("Medium")
    High => logger.write_string("High")
    Critical => logger.write_string("Critical")
  }
}

///|
pub(all) struct CharDiagnostic {
  char : Char
  codepoint : Int
  codepoint_hex : String
  script : @script.Script
  is_invisible : Bool
  is_bidi : Bool
  is_confusable : Bool
  confusable_target : String
} derive(Debug)

///|
pub(all) struct DiagnosticReport {
  original : String
  skeleton : String
  script_analysis : @script.ScriptAnalysis
  risk_level : SecurityRiskLevel
  char_diagnostics : Array[CharDiagnostic]
  rules_triggered : Array[String]
} derive(Debug)

///|
pub fn analyze_identifier(input : String) -> DiagnosticReport {
  let sk = @confusable.skeleton(input)
  let script_res = @script.analyze_scripts(input)
  let char_diags : Array[CharDiagnostic] = []
  let rules : Array[String] = []

  let mut has_invisible = false
  let mut has_bidi = false
  let mut has_cross_script_confusable = false

  for ch in input {
    let cp = ch.to_int()
    let s = @script.get_script(cp)
    let inv = @unicode.is_invisible_codepoint(cp)
    let bidi = @unicode.is_bidi_control_codepoint(cp)
    let mapped = @confusable.map_confusable_codepoint(cp)
    let is_conf = mapped != ch.to_string()

    if inv {
      has_invisible = true
    }
    if bidi {
      has_bidi = true
    }
    if is_conf && s != @script.Script::Latin {
      has_cross_script_confusable = true
    }

    char_diags.push({
      char: ch,
      codepoint: cp,
      codepoint_hex: @unicode.format_codepoint(cp),
      script: s,
      is_invisible: inv,
      is_bidi: bidi,
      is_confusable: is_conf,
      confusable_target: mapped,
    })
  }

  let has_mixed_triad = @script.has_mixed_triad_scripts(script_res.scripts)
  let has_bidi_override = @unicode.has_bidi_override(input)
  let is_file_spoof = has_bidi_override &&
    (
      input.contains(".exe") ||
      input.contains(".pdf") ||
      input.contains(".scr") ||
      input.contains(".com") ||
      input.contains(".bat") ||
      input.contains(".cmd") ||
      input.contains(".sh") ||
      input.contains(".vbs") ||
      input.contains(".js")
    )

  if has_invisible {
    rules.push("RULE_INVISIBLE_OR_FORMAT_CHARACTER")
  }
  if has_bidi {
    rules.push("RULE_BIDI_CONTROL_CHARACTER")
  }
  if has_bidi_override {
    rules.push("RULE_BIDI_OVERRIDE_CHARACTER")
  }
  if is_file_spoof {
    rules.push("RULE_BIDI_FILE_EXTENSION_SPOOF")
  }
  if script_res.is_mixed {
    rules.push("RULE_MIXED_SCRIPT_IDENTIFIER")
  }
  if has_mixed_triad {
    rules.push("RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD")
  }
  if has_cross_script_confusable {
    rules.push("RULE_CROSS_SCRIPT_CONFUSABLE_GLYPH")
  }

  let risk = if has_invisible || has_bidi || has_bidi_override {
    SecurityRiskLevel::Critical
  } else if (has_cross_script_confusable || has_mixed_triad) &&
    script_res.is_mixed {
    SecurityRiskLevel::High
  } else if has_cross_script_confusable || script_res.is_mixed {
    SecurityRiskLevel::Medium
  } else if sk != input {
    SecurityRiskLevel::Low
  } else {
    SecurityRiskLevel::Safe
  }

  {
    original: input,
    skeleton: sk,
    script_analysis: script_res,
    risk_level: risk,
    char_diagnostics: char_diags,
    rules_triggered: rules,
  }
}

///|
pub fn has_bidi_controls(input : String) -> Bool {
  @unicode.has_bidi_controls(input)
}

///|
pub fn has_bidi_override(input : String) -> Bool {
  @unicode.has_bidi_override(input)
}

///|
pub fn has_invisible_characters(input : String) -> Bool {
  @unicode.has_invisible_characters(input)
}
