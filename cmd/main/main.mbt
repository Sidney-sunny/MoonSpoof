// MoonSpoof Command Line Interface Entry Point

///|
fn main {
  println("==================================================")
  println(" MoonSpoof - UTS #39 Unicode Spoof Detection Engine")
  println("==================================================")

  let authentic = "paypal"
  let spoofed = "p\u0430ypal" // Cyrillic Small Letter A (U+0430)
  let is_conf = @moonspoof.are_confusable(authentic, spoofed)
  let sk = @moonspoof.skeleton(spoofed)

  println("Target:     \{authentic}")
  println("Candidate:  \{spoofed}")
  println("Confusable: \{is_conf}")
  println("Skeleton:   \{sk}")

  let report = @moonspoof.analyze_identifier(spoofed)
  println("Risk Level: \{report.risk_level}")
  println("Mixed Script: \{report.script_analysis.is_mixed}")
}
