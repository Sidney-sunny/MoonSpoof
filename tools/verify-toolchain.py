"""Fail CI when moonc does not match the reviewed compiler pin."""

from pathlib import Path
import re
import subprocess
import json

root = Path(__file__).resolve().parent.parent
expected = (root / ".moon-version").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"0\.10\.18\+[0-9a-f]+", expected):
    raise SystemExit("Expected an explicitly reviewed MoonBit 0.10.18 compiler pin")
output = subprocess.check_output(["moonc", "-v"], text=True, encoding="utf-8").strip()
if not re.search(rf"\bv{re.escape(expected)}(?:\s|$)", output):
    raise SystemExit(f"Compiler mismatch: expected {expected}; got {output}")
print(f"Verified moonc {expected}")
module = (root / "moon.mod").read_text(encoding="utf-8")
version = re.search(r'^version\s*=\s*"([^"]+)"', module, re.MULTILINE).group(1)
facade = (root / "version.mbt").read_text(encoding="utf-8")
if f'"{version}"' not in facade:
    raise SystemExit("Public library version differs from moon.mod")
if json.loads((root / "playground/package.json").read_text(encoding="utf-8"))["version"] != version:
    raise SystemExit("Showcase and module versions differ")
print(f"Verified module, facade and showcase release identity {version}")
