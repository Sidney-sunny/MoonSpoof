///|
/// Demonstration syntax only; applications supply their own complete grammar.
fn account_syntax(name : String) -> Result[Unit, String] {
  if name.contains(" ") || name.contains("/") {
    Err("Account syntax rejects spaces and slashes")
  } else {
    Ok(())
  }
}

///|
fn print_decision(name : String, decision : @registration.Decision) -> Unit {
  let quoted = name.to_json().stringify()
  match decision {
    Accepted(record) =>
      println("\{quoted}: ACCEPTED key=\{record.key.to_json().stringify()}")
    Duplicate(existing) =>
      println(
        "\{quoted}: DUPLICATE existing=\{existing.name.to_json().stringify()}",
      )
    Collision(existing, report) => {
      println(
        "\{quoted}: COLLISION existing=\{existing.name.to_json().stringify()}",
      )
      for char in report.char_diagnostics {
        if char.is_confusable {
          println("  evidence: \{char.codepoint_hex} script=\{char.script}")
        }
      }
    }
    Rejected(reason, report) => {
      println("\{quoted}: REJECTED reason=\{reason}")
      for rule in report.rules_triggered {
        println("  rule: \{rule}")
      }
    }
  }
}

///|
fn main {
  let index = @registration.Registry::new(
    Folded,
    validate_syntax=account_syntax,
    application_policy_version="demo-syntax-v1",
  )
  println("Load existing accounts")
  for name in ["paypal", "admin", "用户"] {
    print_decision(name, index.register(name))
  }
  println("Evaluate registration candidates")
  for
    name in ["alice中文", "paypal", "p\u0430ypal", "admin\u200B", "user name"] {
    print_decision(name, index.register(name))
  }
  let snapshot = index.snapshot()
  println(
    "Versioned snapshot: library=\{snapshot.version.library_version} Unicode=\{snapshot.version.unicode_version} application=\{snapshot.version.application_policy_version}",
  )
  match
    @registration.Registry::restore(
      snapshot,
      Folded,
      validate_syntax=account_syntax,
      application_policy_version="demo-syntax-v1",
    ) {
    Ok(restored) =>
      println("Snapshot restored: \{restored.records().length()} accounts")
    Err(reason) => abort(reason)
  }

  // A policy version change requires revalidation, not relabelling old keys.
  match
    @registration.Registry::restore(
      snapshot,
      Folded,
      validate_syntax=account_syntax,
      application_policy_version="demo-syntax-v2",
    ) {
    Err(reason) => println("Policy upgrade: \{reason}")
    Ok(_) => abort("Expected stale snapshot to require rebuilding")
  }
  match
    @registration.Registry::rebuild(
      snapshot,
      Folded,
      validate_syntax=account_syntax,
      application_policy_version="demo-syntax-v2",
    ) {
    Ok(migrated) => {
      println(
        "Rebuilt index: \{migrated.records().length()} accounts; application=\{migrated.version().application_policy_version}",
      )
      print_decision("P\u0430yPal", migrated.register("P\u0430yPal"))
    }
    Err(_) => abort("Unexpected policy migration failure")
  }

  println("Key policy migration with a new conflict")
  let folded = @registration.Registry::new(
    Folded,
    validate_syntax=account_syntax,
    application_policy_version="demo-syntax-v1",
  )
  for name in ["I", "l"] {
    print_decision(name, folded.register(name))
  }
  match
    @registration.Registry::rebuild(
      folded.snapshot(),
      Sensitive,
      validate_syntax=account_syntax,
      application_policy_version="demo-syntax-v1",
    ) {
    Err(failures) => {
      println(
        "Migration stopped: \{failures.length()} conflict(s); original index retains \{folded.records().length()} accounts",
      )
      print_decision("l", failures[0])
    }
    Ok(_) => abort("Expected I/l collision to stop sensitive-policy migration")
  }
}
