// Package script: Unicode Script & Script_Extensions classification and analysis

///|
pub(all) enum Script {
  Common
  Inherited
  Latin
  Cyrillic
  Greek
  Arabic
  Hebrew
  Han
  Hiragana
  Katakana
  Hangul
  Unknown
} derive(Eq, Debug)

///|
pub impl Show for Script with fn output(self, logger) {
  match self {
    Common => logger.write_string("Common")
    Inherited => logger.write_string("Inherited")
    Latin => logger.write_string("Latin")
    Cyrillic => logger.write_string("Cyrillic")
    Greek => logger.write_string("Greek")
    Arabic => logger.write_string("Arabic")
    Hebrew => logger.write_string("Hebrew")
    Han => logger.write_string("Han")
    Hiragana => logger.write_string("Hiragana")
    Katakana => logger.write_string("Katakana")
    Hangul => logger.write_string("Hangul")
    Unknown => logger.write_string("Unknown")
  }
}

///|
pub(all) enum RestrictionLevel {
  SingleScript
  HighlyRestrictive
  ModeratelyRestrictive
  MinimallyRestrictive
  Unrestricted
} derive(Eq, Debug)

///|
pub impl Show for RestrictionLevel with fn output(self, logger) {
  match self {
    SingleScript => logger.write_string("SingleScript")
    HighlyRestrictive => logger.write_string("HighlyRestrictive")
    ModeratelyRestrictive => logger.write_string("ModeratelyRestrictive")
    MinimallyRestrictive => logger.write_string("MinimallyRestrictive")
    Unrestricted => logger.write_string("Unrestricted")
  }
}

///|
pub(all) struct ScriptAnalysis {
  primary_script : Script
  scripts : Array[Script]
  is_mixed : Bool
  level : RestrictionLevel
} derive(Debug)

///|
pub fn get_script(cp : Int) -> Script {
  binary_search_script(cp)
}

///|
pub fn contains_script(arr : Array[Script], s : Script) -> Bool {
  for item in arr {
    if item == s {
      return true
    }
  }
  false
}

///|

///|
pub fn has_mixed_triad_scripts(scripts : Array[Script]) -> Bool {
  let has_lat = contains_script(scripts, Latin)
  let has_cyr = contains_script(scripts, Cyrillic)
  let has_grk = contains_script(scripts, Greek)
  (has_lat && has_cyr) || (has_lat && has_grk) || (has_cyr && has_grk)
}

///|
pub fn is_recommended_script(s : Script) -> Bool {
  match s {
    Latin
    | Cyrillic
    | Greek
    | Arabic
    | Hebrew
    | Han
    | Hiragana
    | Katakana
    | Hangul => true
    Common | Inherited | Unknown => false
  }
}

///|
pub fn analyze_scripts(input : String) -> ScriptAnalysis {
  let found : Array[Script] = []
  let mut primary = Script::Common
  let mut has_disallowed = false

  for ch in input {
    let cp = ch.to_int()
    let s = get_script(cp)
    if s == Unknown {
      has_disallowed = true
    }
    if s != Common && s != Inherited && s != Unknown {
      if !contains_script(found, s) {
        found.push(s)
      }
      if primary == Common {
        primary = s
      }
    }
  }
  let count = found.length()
  let is_mixed = count > 1
  let level = if has_disallowed {
    RestrictionLevel::Unrestricted
  } else if count <= 1 {
    RestrictionLevel::SingleScript
  } else if is_cjk_script_set(found) {
    RestrictionLevel::HighlyRestrictive
  } else if count == 2 &&
    (
      (contains_script(found, Latin) && contains_script(found, Arabic)) ||
      (contains_script(found, Latin) && contains_script(found, Hebrew))
    ) {
    RestrictionLevel::ModeratelyRestrictive
  } else {
    let mut all_rec = true
    for s in found {
      if !is_recommended_script(s) {
        all_rec = false
      }
    }
    if all_rec && count > 0 {
      RestrictionLevel::MinimallyRestrictive
    } else {
      RestrictionLevel::Unrestricted
    }
  }
  { primary_script: primary, scripts: found, is_mixed, level, }
}

///|
fn is_cjk_script_set(scripts : Array[Script]) -> Bool {
  let mut japanese = true
  let mut korean = true
  for script in scripts {
    if script != Latin &&
      script != Han &&
      script != Hiragana &&
      script != Katakana {
      japanese = false
    }
    if script != Latin && script != Han && script != Hangul {
      korean = false
    }
  }
  japanese || korean
}

///|
pub fn is_single_script(input : String) -> Bool {
  let res = analyze_scripts(input)
  res.level == RestrictionLevel::SingleScript
}

///|
pub fn is_mixed_script(input : String) -> Bool {
  let res = analyze_scripts(input)
  res.is_mixed
}

///|
pub fn get_restriction_level(input : String) -> RestrictionLevel {
  let res = analyze_scripts(input)
  res.level
}
