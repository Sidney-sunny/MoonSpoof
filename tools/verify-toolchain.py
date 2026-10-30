"""Fail CI when moonc does not match the reviewed compiler pin."""

from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parent.parent
expected = (root / ".moon-version").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"0\.10\.18\+[0-9a-f]+", expected):
    raise SystemExit("Expected an explicitly reviewed MoonBit 0.10.18 compiler pin")
output = subprocess.check_output(["moonc", "-v"], text=True, encoding="utf-8").strip()
if not re.search(rf"\bv{re.escape(expected)}(?:\s|$)", output):
    raise SystemExit(f"Compiler mismatch: expected {expected}; got {output}")
print(f"Verified moonc {expected}")
