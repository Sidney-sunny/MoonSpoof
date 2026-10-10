// Package script: Unicode Script & Script_Extensions classification and analysis

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

pub impl Show for Script with output(self, logger) {
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

pub(all) enum RestrictionLevel {
  SingleScript
  HighlyRestrictive
  ModeratelyRestrictive
  MinimallyRestrictive
  Unrestricted
} derive(Eq, Debug)

pub impl Show for RestrictionLevel with output(self, logger) {
  match self {
    SingleScript => logger.write_string("SingleScript")
    HighlyRestrictive => logger.write_string("HighlyRestrictive")
    ModeratelyRestrictive => logger.write_string("ModeratelyRestrictive")
    MinimallyRestrictive => logger.write_string("MinimallyRestrictive")
    Unrestricted => logger.write_string("Unrestricted")
  }
}

pub(all) struct ScriptAnalysis {
  primary_script : Script
  scripts : Array[Script]
  is_mixed : Bool
  level : RestrictionLevel
} derive(Debug)

pub fn get_script(cp : Int) -> Script {
  binary_search_script(cp)
}

pub fn contains_script(arr : Array[Script], s : Script) -> Bool {
  for item in arr {
    if item == s {
      return true
    }
  }
  false
}

pub fn analyze_scripts(input : String) -> ScriptAnalysis {
  let found : Array[Script] = []
  let mut primary = Script::Common
  for ch in input {
    let cp = ch.to_int()
    let s = get_script(cp)
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
  let level = if count <= 1 {
    RestrictionLevel::SingleScript
  } else if count == 2 &&
    (
      (contains_script(found, Latin) && contains_script(found, Han)) ||
      (contains_script(found, Latin) && contains_script(found, Hiragana)) ||
      (contains_script(found, Latin) && contains_script(found, Katakana)) ||
      (contains_script(found, Latin) && contains_script(found, Hangul))
    ) {
    RestrictionLevel::HighlyRestrictive
  } else if count <= 3 &&
    (
      contains_script(found, Han) &&
      (contains_script(found, Hiragana) || contains_script(found, Katakana))
    ) {
    RestrictionLevel::HighlyRestrictive
  } else if count <= 2 &&
    (
      (contains_script(found, Latin) && contains_script(found, Cyrillic)) ||
      (contains_script(found, Latin) && contains_script(found, Greek))
    ) {
    RestrictionLevel::ModeratelyRestrictive
  } else {
    RestrictionLevel::Unrestricted
  }
  { primary_script: primary, scripts: found, is_mixed, level }
}
