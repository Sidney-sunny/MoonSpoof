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
  if (cp >= 0x0041 && cp <= 0x005A) ||
    (cp >= 0x0061 && cp <= 0x007A) ||
    (cp >= 0x00C0 && cp <= 0x024F) ||
    (cp >= 0x1E00 && cp <= 0x1EFF) {
    Latin
  } else if (cp >= 0x0400 && cp <= 0x04FF) || (cp >= 0x0500 && cp <= 0x052F) {
    Cyrillic
  } else if (cp >= 0x0370 && cp <= 0x03FF) || (cp >= 0x1F00 && cp <= 0x1FFF) {
    Greek
  } else if (cp >= 0x0600 && cp <= 0x06FF) || (cp >= 0x0750 && cp <= 0x077F) {
    Arabic
  } else if cp >= 0x0590 && cp <= 0x05FF {
    Hebrew
  } else if (cp >= 0x4E00 && cp <= 0x9FFF) || (cp >= 0x3400 && cp <= 0x4DBF) {
    Han
  } else if cp >= 0x3040 && cp <= 0x309F {
    Hiragana
  } else if cp >= 0x30A0 && cp <= 0x30FF {
    Katakana
  } else if (cp >= 0xAC00 && cp <= 0xD7AF) || (cp >= 0x1100 && cp <= 0x11FF) {
    Hangul
  } else if (cp >= 0x0020 && cp <= 0x0040) ||
    (cp >= 0x005B && cp <= 0x0060) ||
    (cp >= 0x007B && cp <= 0x007E) ||
    (cp >= 0x0030 && cp <= 0x0039) {
    Common
  } else {
    Unknown
  }
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
