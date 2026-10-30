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
    def run(command, label):
        result = subprocess.run(
            command, cwd=consumer,
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        details = result.stdout + result.stderr
        (work / f"public-consumer-{label}.log").write_text(details, encoding="utf-8")
        if result.returncode:
            tail = "\n".join(details.splitlines()[-40:])
            raise SystemExit(f"Registry consumer failed ({label}):\n{tail}")

    # A clean CI runner has no registry index; do not depend on the user's cache.
    run(["moon", "update"], "update")
    for target in ("wasm", "js"):
        run(["moon", "run", ".", "--target", target], target)
        print(f"Sidney-sunny/moonspoof@0.1.0: public registry consumer passed ({target})")
