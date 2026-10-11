// One typed serializer for both comparison and detailed diagnostics.

///|
fn report_json(
  rep : @moonspoof.DiagnosticReport,
  detailed? : Bool = false,
) -> Json {
  let fields : Map[String, Json] = {
    "original": rep.original.to_json(),
    "skeleton": rep.skeleton.to_json(),
    "skeleton_case_folded": @moonspoof.skeleton_case_folded(rep.original).to_json(),
    "risk_level": rep.risk_level.to_string().to_json(),
    "primary_script": rep.script_analysis.primary_script.to_string().to_json(),
    "is_mixed": rep.script_analysis.is_mixed.to_json(),
    "restriction_level": rep.script_analysis.level.to_string().to_json(),
    "rules_triggered": rep.rules_triggered.to_json(),
  }
  if detailed {
    let chars = rep.char_diagnostics.map(fn(diag) {
      object_json({
        "char": diag.char.to_string().to_json(),
        "codepoint": diag.codepoint.to_json(),
        "hex": diag.codepoint_hex.to_json(),
        "script": diag.script.to_string().to_json(),
        "is_invisible": diag.is_invisible.to_json(),
        "is_bidi": diag.is_bidi.to_json(),
        "is_confusable": diag.is_confusable.to_json(),
        "confusable_target": diag.confusable_target.to_json(),
      })
    })
    fields.set("chars", chars.to_json())
  }
  object_json(fields)
}
