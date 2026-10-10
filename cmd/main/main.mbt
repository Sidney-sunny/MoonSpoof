// MoonSpoof Command Line Interface Entry Point
// Unicode Spoof and Homoglyph Detection Engine (UTS #39)

///|
fn print_header(title : String) -> Unit {
  println("")
  println("--- \{title} ---")
}

///|
fn main {
  println("=================================================================")
  println(" MoonSpoof - UTS #39 Unicode Spoof & Homoglyph Detection Engine")
  println(" Specification: Unicode Technical Standard #39 (Unicode 16.0.0)")
  println("=================================================================")

  // 1. Confusable Pair Analysis
  print_header("1. Confusable Equivalence Matching")
  let pairs = [
    ("paypal", "p\u0430ypal", "Cyrillic Small Letter A (U+0430)"),
    ("google", "g\u043E\u043Egle", "Cyrillic Small Letter O (U+043E)"),
    ("micro", "micr\u03BF", "Greek Small Letter Omicron (U+03BF)"),
    ("admin", "\uFF41\uFF44\uFF4D\uFF49\uFF4E", "Fullwidth ASCII"),
    ("service", "service\u200B", "Invisible Zero-Width Space (U+200B)"),
  ]

  for p in pairs {
    let (target, candidate, desc) = p
    let is_conf = @moonspoof.are_confusable(target, candidate)
    let sk = @moonspoof.skeleton(candidate)
    println("[+] Target: '\{target}' | Candidate: '\{candidate}' (\{desc})")
    println("    Confusable: \{is_conf} | Skeleton: '\{sk}'")
  }

  // 2. Case-Insensitive Confusables
  print_header("2. Case-Insensitive Matching (UTS #39 Section 4)")
  let t_caps = "PAYPAL"
  let c_mixed = "P\u0430yPal"
  let is_conf_ci = @moonspoof.are_confusable_ignore_case(t_caps, c_mixed)
  let sk_ci = @moonspoof.skeleton_case_folded(c_mixed)
  println("[+] Target: '\{t_caps}' | Candidate: '\{c_mixed}'")
  println(
    "    Confusable (ignore case): \{is_conf_ci} | Case-folded Skeleton: '\{sk_ci}'",
  )

  // 3. Detailed Diagnostic Report
  print_header("3. Diagnostic Security Report")
  let test_vector = "p\u0430ypal"
  let diag = @moonspoof.analyze_identifier(test_vector)
  println("[+] Analyzed Identifier: '\{test_vector}'")
  println("    Risk Level:        \{diag.risk_level}")
  println("    Primary Script:    \{diag.script_analysis.primary_script}")
  println("    Restriction Level: \{diag.script_analysis.level}")
  println("    Mixed Script:      \{diag.script_analysis.is_mixed}")
  let mut rules_str = ""
  for idx, r in diag.rules_triggered {
    if idx > 0 {
      rules_str = rules_str + ", "
    }
    rules_str = rules_str + r
  }
  println("    Rules Triggered:   [\{rules_str}]")
  println("    Character Diagnostics:")
  for cd in diag.char_diagnostics {
    println(
      "      - '\{cd.char}' (\{cd.codepoint_hex}) Script: \{cd.script} Confusable: \{cd.is_confusable} -> '\{cd.confusable_target}'",
    )
  }

  // 4. Identifier Profile Compliance
  print_header("4. Identifier Security Profile Validation")
  let id_samples = [
    ("valid_user", "Valid single-script identifier"),
    ("p\u0430ypal", "Mixed Latin-Cyrillic spoof"),
    ("admin\u200B", "Trailing invisible zero-width space"),
  ]

  for sample in id_samples {
    let (id, desc) = sample
    let default_val = @moonspoof.validate_identifier(id)
    let permissive_ok = @moonspoof.is_allowed_identifier(
      id,
      profile=@moonspoof.IdentifierProfile::permissive(),
    )
    let status_str = match default_val {
      Ok(_) => "ACCEPTED"
      Err(msg) => "REJECTED (\{msg})"
    }
    println("[+] '\{id}' (\{desc})")
    println("    Default Strict Profile: \{status_str}")
    println("    Permissive Profile:     allowed=\{permissive_ok}")
  }

  // 5. Batch Collision Scanning
  print_header("5. High-Throughput Batch Collision Scanner")
  let user_pool = [
    "admin", "adm\u0456n", // Cyrillic Small Letter Byelorussian-Ukrainian I (U+0456)
     "paypal", "p\u0430ypal", "alice", "bob", "b\u043Eb", // Cyrillic Small Letter O (U+043E)
  ]
  let groups = @moonspoof.find_confusable_groups(user_pool)
  println("[+] Scanned \{user_pool.length()} candidate identifiers in batch.")
  println("    Detected \{groups.length()} confusable collision clusters:")
  for g in groups {
    let mut members_str = ""
    for idx, m in g.members {
      if idx > 0 {
        members_str = members_str + ", "
      }
      members_str = members_str + m
    }
    println("    - Canonical Skeleton: '\{g.skeleton}'")
    println("      Members (\{g.members.length()}): [\{members_str}]")
  }

  println("")
  println("Engine Status: OK | All UTS #39 subsystems operational.")
}
