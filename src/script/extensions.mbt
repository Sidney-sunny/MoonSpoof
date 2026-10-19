///|
/// ALL is distinct from an empty intersection and from the Unknown property.
pub(all) enum ScriptSet {
  All
  Scripts(Array[String])
} derive(Eq, Debug)

///|
pub fn get_unicode_script(cp : Int) -> String {
  @unicode.unicode_script(cp)
}

///|
pub fn get_script_extensions(cp : Int) -> Array[String] {
  @unicode.script_extensions(cp)
}

///|
/// UTS #39 revision 30 section 5.1, using complete Unicode 16.0 data.
/// Canonical long names are augmented with Hanb, Jpan and Kore writing systems.
pub fn resolve_script_set(input : String) -> ScriptSet {
  let mut resolved : Array[String]? = None
  for ch in input {
    let extensions = get_script_extensions(ch.to_int())
    if extensions.contains("Common") || extensions.contains("Inherited") {
      continue
    }
    if extensions.contains("Han") {
      extensions.push("Hanb")
      extensions.push("Jpan")
      extensions.push("Kore")
    } else {
      if extensions.contains("Hiragana") || extensions.contains("Katakana") {
        extensions.push("Jpan")
      }
      if extensions.contains("Hangul") {
        extensions.push("Kore")
      }
      if extensions.contains("Bopomofo") {
        extensions.push("Hanb")
      }
    }
    resolved = Some(
      match resolved {
        None => extensions
        Some(current) => {
          let intersection : Array[String] = []
          for script in current {
            if extensions.contains(script) {
              intersection.push(script)
            }
          }
          intersection
        }
      },
    )
  }
  match resolved {
    None => All
    Some(scripts) => {
      scripts.sort_by(fn(a, b) { a.lexical_compare(b) })
      Scripts(scripts)
    }
  }
}

///|
/// This does not change the legacy is_mixed_script or restriction estimates.
pub fn is_mixed_script_resolved(input : String) -> Bool {
  match resolve_script_set(input) {
    All => false
    Scripts(scripts) => scripts.is_empty()
  }
}
