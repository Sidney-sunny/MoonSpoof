// Browser ABI: typed JSON serialization around the public MoonBit facade.

///|
fn split_input_lines(input : String) -> Array[String] {
  let names : Array[String] = []
  let mut buf = StringBuilder()
  for ch in input {
    if ch == '\n' || ch == '\r' || ch == ',' {
      let name = buf.to_string().trim().to_owned()
      if name.length() > 0 {
        names.push(name)
      }
      buf = StringBuilder()
    } else {
      buf.write_char(ch)
    }
  }
  let last = buf.to_string().trim().to_owned()
  if last.length() > 0 {
    names.push(last)
  }
  names
}

///|
pub fn spoof_compare(a : String, b : String) -> String {
  let rep_a = @moonspoof.analyze_identifier(a)
  let rep_b = @moonspoof.analyze_identifier(b)
  object_json({
    "are_confusable": (rep_a.skeleton == rep_b.skeleton).to_json(),
    "are_confusable_ignore_case": @moonspoof.are_confusable_ignore_case(a, b).to_json(),
    "a": report_json(rep_a),
    "b": report_json(rep_b),
  }).stringify()
}

///|
pub fn spoof_analyze(input : String) -> String {
  report_json(@moonspoof.analyze_identifier(input), detailed=true).stringify()
}

///|
pub fn spoof_batch_scan(raw_input : String) -> String {
  spoof_batch_scan_with_options(raw_input, false)
}

///|
pub fn spoof_batch_scan_with_options(
  raw_input : String,
  ignore_case : Bool,
) -> String {
  let names = split_input_lines(raw_input)
  let groups = if ignore_case {
    @moonspoof.find_confusable_groups_ignore_case(names)
  } else {
    @moonspoof.find_confusable_groups(names)
  }
  object_json({
    "total_names": names.length().to_json(),
    "group_count": groups.length().to_json(),
    "ignore_case": ignore_case.to_json(),
    "groups": groups
    .map(fn(group) {
      object_json({
        "skeleton": group.skeleton.to_json(),
        "count": group.members.length().to_json(),
        "members": group.members.to_json(),
      })
    })
    .to_json(),
  }).stringify()
}

///|
pub fn spoof_validate_profile(input : String, is_permissive : Bool) -> String {
  let profile = if is_permissive {
    @moonspoof.IdentifierProfile::permissive()
  } else {
    @moonspoof.IdentifierProfile::default()
  }
  let error = match @moonspoof.validate_identifier(input, profile~) {
    Ok(_) => ""
    Err(message) => message
  }
  object_json({ "valid": (error == "").to_json(), "error": error.to_json() }).stringify()
}

///|
pub fn spoof_skeleton(input : String) -> String {
  @moonspoof.skeleton(input)
}

///|
pub fn spoof_skeleton_case_folded(input : String) -> String {
  @moonspoof.skeleton_case_folded(input)
}

///|
pub fn spoof_get_restriction_info(input : String) -> String {
  let sa = @moonspoof.analyze_scripts(input)
  object_json({
    "restriction_level": sa.level.to_string().to_json(),
    "primary_script": sa.primary_script.to_string().to_json(),
    "is_mixed": sa.is_mixed.to_json(),
    "is_single_script": (sa.level == @moonspoof.RestrictionLevel::SingleScript).to_json(),
    "scripts": sa.scripts.map(fn(script) { script.to_string() }).to_json(),
  }).stringify()
}

///|
pub fn spoof_normalize_nfd(input : String) -> String {
  @unicode.normalize_nfd(input)
}

///|
pub fn spoof_unicode_script(cp : Int) -> String {
  @moonspoof.get_unicode_script(cp)
}

///|
pub fn spoof_script_extensions(cp : Int) -> String {
  @moonspoof.get_script_extensions(cp).to_json().stringify()
}

///|
pub fn spoof_identifier_status_allowed(cp : Int) -> Bool {
  @moonspoof.get_identifier_status(cp) == @moonspoof.IdentifierStatus::Allowed
}
