"""Verify the public registry package in a clean consumer module, using no local override."""

from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
work = root / "_build" / "acceptance"
work.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="public-consumer-", dir=work) as directory:
    consumer = Path(directory)
    (consumer / "moon.mod").write_text('''name = "acceptance/consumer"
version = "0.0.0"
import {
  "Sidney-sunny/moonspoof@0.1.0",
}
''', encoding="utf-8")
    (consumer / "moon.pkg").write_text('''import {
  "Sidney-sunny/moonspoof" @moonspoof,
}
pkgtype(kind: "executable")
''', encoding="utf-8")
    (consumer / "main.mbt").write_text('''///|
fn main raise {
  assert_true(@moonspoof.are_confusable("paypal", "p\\u0430ypal"))
  assert_eq(@moonspoof.get_decimal_systems("user1\\u0661"), [0x30, 0x660])
  assert_true(@moonspoof.has_mixed_numbers("user1\\u0661"))
  assert_true(@moonspoof.validate_identifier_status("alice中文") is Ok(_))
  println("Public registry consumer passed")
}
''', encoding="utf-8")
    for target in ("wasm", "js"):
        result = subprocess.run(
            ["moon", "run", ".", "--target", target], cwd=consumer,
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        (work / f"public-consumer-{target}.log").write_text(
            result.stdout + result.stderr, encoding="utf-8"
        )
        if result.returncode:
            raise SystemExit(f"Registry consumer failed ({target}); see {work}")
        print(f"Sidney-sunny/moonspoof@0.1.0: public registry consumer passed ({target})")
