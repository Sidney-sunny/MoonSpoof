// Unicode types, general categories, and codepoint properties

///|
pub(all) struct UnicodeVersion {
  major : Int
  minor : Int
  update : Int
} derive(Eq, Debug)

///|
pub let unicode_version : UnicodeVersion = { major: 16, minor: 0, update: 0, }

///|
pub(all) enum GeneralCategory {
  Letter
  Mark
  Number
  Punctuation
  Symbol
  Separator
  Other
} derive(Eq, Debug)

///|
pub fn get_general_category(cp : Int) -> GeneralCategory {
  if (cp >= 0x0041 && cp <= 0x005A) ||
    (cp >= 0x0061 && cp <= 0x007A) ||
    (cp >= 0x4E00 && cp <= 0x9FFF) {
    Letter
  } else if cp >= 0x0030 && cp <= 0x0039 {
    Number
  } else if cp == 0x0020 || cp == 0x3000 {
    Separator
  } else if is_invisible_codepoint(cp) ||
    is_bidi_control_codepoint(cp) ||
    cp < 0x0020 {
    Other
  } else if cp == 0x002B || cp == 0x003D || cp == 0x0024 {
    Symbol
  } else if cp == 0x002C ||
    cp == 0x002E ||
    cp == 0x003A ||
    cp == 0x003B ||
    cp == 0x0021 ||
    cp == 0x003F {
    Punctuation
  } else {
    Mark
  }
}

///|
pub(all) struct CharInfo {
  codepoint : Int
  char : Char
  name : String
  category : GeneralCategory
  is_invisible : Bool
  is_bidi_control : Bool
} derive(Debug)

///|
pub fn is_ascii(cp : Int) -> Bool {
  cp >= 0 && cp <= 0x7F
}

///|
pub fn is_invisible_codepoint(cp : Int) -> Bool {
  match cp {
    0x200B => true // ZERO WIDTH SPACE
    0x200C => true // ZERO WIDTH NON-JOINER
    0x200D => true // ZERO WIDTH JOINER
    0x2060 => true // WORD JOINER
    0xFEFF => true // ZERO WIDTH NO-BREAK SPACE (BOM)
    0x00AD => true // SOFT HYPHEN
    0x180E => true // MONGOLIAN VOWEL SEPARATOR
    0x200E | 0x200F => true // LRM, RLM
    _ => false
  }
}

///|
pub fn is_bidi_control_codepoint(cp : Int) -> Bool {
  match cp {
    0x200E => true // LEFT-TO-RIGHT MARK
    0x200F => true // RIGHT-TO-LEFT MARK
    0x061C => true // ARABIC LETTER MARK
    0x202A => true // LEFT-TO-RIGHT EMBEDDING
    0x202B => true // RIGHT-TO-LEFT EMBEDDING
    0x202C => true // POP DIRECTIONAL FORMATTING
    0x202D => true // LEFT-TO-RIGHT OVERRIDE
    0x202E => true // RIGHT-TO-LEFT OVERRIDE
    0x2066 => true // LEFT-TO-RIGHT ISOLATE
    0x2067 => true // RIGHT-TO-LEFT ISOLATE
    0x2068 => true // FIRST STRONG ISOLATE
    0x2069 => true // POP DIRECTIONAL ISOLATE
    _ => false
  }
}

///|
pub fn hex_char(digit : Int) -> Char {
  if digit < 10 {
    (48 + digit).unsafe_to_char()
  } else {
    (65 + digit - 10).unsafe_to_char()
  }
}

///|
pub fn format_codepoint(cp : Int) -> String {
  let buf = StringBuilder()
  buf.write_string("U+")
  let mut temp = cp
  let digits : Array[Char] = []
  if temp == 0 {
    digits.push('0')
    digits.push('0')
    digits.push('0')
    digits.push('0')
  } else {
    while temp > 0 {
      let rem = temp % 16
      digits.push(hex_char(rem))
      temp = temp / 16
    }
    while digits.length() < 4 {
      digits.push('0')
    }
  }
  for i = digits.length() - 1; i >= 0; i = i - 1 {
    buf.write_char(digits[i])
  }
  buf.to_string()
}
