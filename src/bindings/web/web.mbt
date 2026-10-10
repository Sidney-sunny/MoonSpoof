// Web binding API for MoonSpoof Playground & Web Integration

///|
fn escape_json(s : String) -> String {
  let sb = StringBuilder()
  for ch in s {
    if ch == '"' {
      sb.write_string("\\\"")
    } else if ch == '\\' {
      sb.write_string("\\\\")
    } else if ch == '\n' {
      sb.write_string("\\n")
    } else if ch == '\r' {
      sb.write_string("\\r")
    } else if ch == '\t' {
      sb.write_string("\\t")
    } else {
      sb.write_string(ch.to_string())
    }
  }
  sb.to_string()
}

///|
fn split_input_lines(input : String) -> Array[String] {
  let res : Array[String] = []
  let mut sb = StringBuilder()
  for ch in input {
    if ch == '\n' || ch == '\r' || ch == ',' {
      let s = sb.to_string()
      let trimmed = s.trim().to_owned()
      if trimmed.length() > 0 {
        res.push(trimmed)
      }
      sb = StringBuilder()
    } else {
      sb.write_string(ch.to_string())
    }
  }
  let last = sb.to_string().trim().to_owned()
  if last.length() > 0 {
    res.push(last)
  }
  res
}

///|
/// Compare two strings and return JSON diagnostic
pub fn spoof_compare(a : String, b : String) -> String {
  let is_confusable = @moonspoof.are_confusable(a, b)
  let is_confusable_ignore_case = @moonspoof.are_confusable_ignore_case(a, b)
  let rep_a = @moonspoof.analyze_identifier(a)
  let rep_b = @moonspoof.analyze_identifier(b)

  let sb = StringBuilder()
  sb.write_string("{\"are_confusable\":")
  sb.write_string(if is_confusable { "true" } else { "false" })
  sb.write_string(",\"are_confusable_ignore_case\":")
  sb.write_string(if is_confusable_ignore_case { "true" } else { "false" })
  sb.write_string(",\"a\":")
  write_report_json(sb, rep_a)
  sb.write_string(",\"b\":")
  write_report_json(sb, rep_b)
  sb.write_string("}")
  sb.to_string()
}

///|
fn write_report_json(
  sb : StringBuilder,
  rep : @moonspoof.DiagnosticReport,
) -> Unit {
  sb.write_string("{\"original\":\"")
  sb.write_string(escape_json(rep.original))
  sb.write_string("\",\"skeleton\":\"")
  sb.write_string(escape_json(rep.skeleton))
  sb.write_string("\",\"skeleton_case_folded\":\"")
  sb.write_string(escape_json(@moonspoof.skeleton_case_folded(rep.original)))
  sb.write_string("\",\"risk_level\":\"")
  sb.write_string(rep.risk_level.to_string())
  sb.write_string("\",\"primary_script\":\"")
  sb.write_string(rep.script_analysis.primary_script.to_string())
  sb.write_string("\",\"is_mixed\":")
  sb.write_string(if rep.script_analysis.is_mixed { "true" } else { "false" })
  sb.write_string(",\"restriction_level\":\"")
  sb.write_string(rep.script_analysis.level.to_string())
  sb.write_string("\",\"rules_triggered\":[")
  for i in 0..<rep.rules_triggered.length() {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string("\"")
    sb.write_string(escape_json(rep.rules_triggered[i]))
    sb.write_string("\"")
  }
  sb.write_string("]}")
}

///|
/// Detailed diagnostic inspection for a single identifier
pub fn spoof_analyze(input : String) -> String {
  let rep = @moonspoof.analyze_identifier(input)
  let sb = StringBuilder()
  sb.write_string("{\"original\":\"")
  sb.write_string(escape_json(rep.original))
  sb.write_string("\",\"skeleton\":\"")
  sb.write_string(escape_json(rep.skeleton))
  sb.write_string("\",\"risk_level\":\"")
  sb.write_string(rep.risk_level.to_string())
  sb.write_string("\",\"primary_script\":\"")
  sb.write_string(rep.script_analysis.primary_script.to_string())
  sb.write_string("\",\"is_mixed\":")
  sb.write_string(if rep.script_analysis.is_mixed { "true" } else { "false" })
  sb.write_string(",\"restriction_level\":\"")
  sb.write_string(rep.script_analysis.level.to_string())
  sb.write_string("\",\"rules_triggered\":[")
  for i in 0..<rep.rules_triggered.length() {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string("\"")
    sb.write_string(escape_json(rep.rules_triggered[i]))
    sb.write_string("\"")
  }
  sb.write_string("],\"chars\":[")
  for i in 0..<rep.char_diagnostics.length() {
    if i > 0 {
      sb.write_string(",")
    }
    let diag = rep.char_diagnostics[i]
    sb.write_string("{\"char\":\"")
    sb.write_string(escape_json(diag.char.to_string()))
    sb.write_string("\",\"codepoint\":")
    sb.write_string(diag.codepoint.to_string())
    sb.write_string(",\"hex\":\"")
    sb.write_string(escape_json(diag.codepoint_hex))
    sb.write_string("\",\"script\":\"")
    sb.write_string(diag.script.to_string())
    sb.write_string("\",\"is_invisible\":")
    sb.write_string(if diag.is_invisible { "true" } else { "false" })
    sb.write_string(",\"is_bidi\":")
    sb.write_string(if diag.is_bidi { "true" } else { "false" })
    sb.write_string(",\"is_confusable\":")
    sb.write_string(if diag.is_confusable { "true" } else { "false" })
    sb.write_string(",\"confusable_target\":\"")
    sb.write_string(escape_json(diag.confusable_target))
    sb.write_string("\"}")
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
/// Batch collision scan from newline or comma separated usernames
pub fn spoof_batch_scan(raw_input : String) -> String {
  let names = split_input_lines(raw_input)
  let groups = @moonspoof.find_confusable_groups(names)

  let sb = StringBuilder()
  sb.write_string("{\"total_names\":")
  sb.write_string(names.length().to_string())
  sb.write_string(",\"group_count\":")
  sb.write_string(groups.length().to_string())
  sb.write_string(",\"groups\":[")
  for i in 0..<groups.length() {
    if i > 0 {
      sb.write_string(",")
    }
    let g = groups[i]
    sb.write_string("{\"skeleton\":\"")
    sb.write_string(escape_json(g.skeleton))
    sb.write_string("\",\"count\":")
    sb.write_string(g.members.length().to_string())
    sb.write_string(",\"members\":[")
    for j in 0..<g.members.length() {
      if j > 0 {
        sb.write_string(",")
      }
      sb.write_string("\"")
      sb.write_string(escape_json(g.members[j]))
      sb.write_string("\"")
    }
    sb.write_string("]}")
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
/// Validate identifier against UTS #39 Security Profiles
pub fn spoof_validate_profile(input : String, is_permissive : Bool) -> String {
  let profile = if is_permissive {
    @moonspoof.IdentifierProfile::permissive()
  } else {
    @moonspoof.IdentifierProfile::default()
  }
  let res = @moonspoof.validate_identifier(input, profile~)
  let sb = StringBuilder()
  match res {
    Ok(_) => sb.write_string("{\"valid\":true,\"error\":\"\"}")
    Err(msg) => {
      sb.write_string("{\"valid\":false,\"error\":\"")
      sb.write_string(escape_json(msg))
      sb.write_string("\"}")
    }
  }
  sb.to_string()
}
