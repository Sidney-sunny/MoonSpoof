// Package confusable: UTS #39 Confusable Skeleton Generation & Comparison

pub fn map_confusable_codepoint(cp : Int) -> String {
  match cp {
    // Cyrillic Lowercase to Latin equivalents
    0x0430 => "a" // Cyrillic Small Letter A
    0x0441 => "c" // Cyrillic Small Letter Es
    0x0435 => "e" // Cyrillic Small Letter Ie
    0x0456 => "i" // Cyrillic Small Letter Byelorussian-Ukrainian I
    0x0458 => "j" // Cyrillic Small Letter Je
    0x043E => "o" // Cyrillic Small Letter O
    0x0440 => "p" // Cyrillic Small Letter Er
    0x0455 => "s" // Cyrillic Small Letter Dze
    0x0445 => "x" // Cyrillic Small Letter Ha
    0x0443 => "y" // Cyrillic Small Letter U

    // Cyrillic Uppercase to Latin equivalents
    0x0410 => "A" // Cyrillic Capital Letter A
    0x0412 => "B" // Cyrillic Capital Letter Ve
    0x0421 => "C" // Cyrillic Capital Letter Es
    0x0415 => "E" // Cyrillic Capital Letter Ie
    0x041D => "H" // Cyrillic Capital Letter En
    0x0406 => "I" // Cyrillic Capital Letter Byelorussian-Ukrainian I
    0x0408 => "J" // Cyrillic Capital Letter Je
    0x041A => "K" // Cyrillic Capital Letter Ka
    0x041C => "M" // Cyrillic Capital Letter Em
    0x041E => "O" // Cyrillic Capital Letter O
    0x0420 => "P" // Cyrillic Capital Letter Er
    0x0422 => "T" // Cyrillic Capital Letter Te
    0x0425 => "X" // Cyrillic Capital Letter Ha

    // Greek Lowercase to Latin equivalents
    0x03BF => "o" // Greek Small Letter Omicron
    0x03BD => "v" // Greek Small Letter Nu
    0x03C1 => "p" // Greek Small Letter Rho

    // Greek Uppercase to Latin equivalents
    0x0391 => "A" // Greek Capital Letter Alpha
    0x0392 => "B" // Greek Capital Letter Beta
    0x0395 => "E" // Greek Capital Letter Epsilon
    0x0397 => "H" // Greek Capital Letter Eta
    0x0399 => "I" // Greek Capital Letter Iota
    0x039A => "K" // Greek Capital Letter Kappa
    0x039C => "M" // Greek Capital Letter Mu
    0x039D => "N" // Greek Capital Letter Nu
    0x039F => "O" // Greek Capital Letter Omicron
    0x03A1 => "P" // Greek Capital Letter Rho
    0x03A4 => "T" // Greek Capital Letter Tau
    0x03A7 => "X" // Greek Capital Letter Chi
    0x03A9 => "O" // Greek Capital Letter Omega

    // Fullwidth ASCII (U+FF01 to U+FF5E)
    _ =>
      if cp >= 0xFF01 && cp <= 0xFF5E {
        let ascii_code = cp - 0xFEE0
        let ch = ascii_code.unsafe_to_char()
        ch.to_string()
      } else {
        cp.unsafe_to_char().to_string()
      }
  }
}

pub fn skeleton(input : String) -> String {
  let buf = StringBuilder()
  for ch in input {
    let cp = ch.to_int()
    let mapped = map_confusable_codepoint(cp)
    buf.write_string(mapped)
  }
  buf.to_string()
}

pub fn are_confusable(a : String, b : String) -> Bool {
  skeleton(a) == skeleton(b)
}
