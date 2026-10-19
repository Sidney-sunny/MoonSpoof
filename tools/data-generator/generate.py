#!/usr/bin/env python3
"""
Unicode Data Generator for MoonSpoof
Downloads official Unicode 16.0.0 UCD & UTS #39 tables and emits compact MoonBit source code.
"""

import urllib.request
import os
import re
import json
import hashlib
import tempfile
from pathlib import Path
from functools import lru_cache

UNICODE_VERSION = "16.0.0"
CONFUSABLES_URL = f"https://www.unicode.org/Public/security/{UNICODE_VERSION}/confusables.txt"
SCRIPTS_URL = f"https://www.unicode.org/Public/{UNICODE_VERSION}/ucd/Scripts.txt"
UCD_URL = f"https://www.unicode.org/Public/{UNICODE_VERSION}/ucd"
SOURCE_URLS = {
    "confusables.txt": CONFUSABLES_URL,
    "Scripts.txt": SCRIPTS_URL,
    "UnicodeData.txt": f"{UCD_URL}/UnicodeData.txt",
    "CaseFolding.txt": f"{UCD_URL}/CaseFolding.txt",
    "DerivedCoreProperties.txt": f"{UCD_URL}/DerivedCoreProperties.txt",
    "NormalizationTest.txt": f"{UCD_URL}/NormalizationTest.txt",
    "ScriptExtensions.txt": f"{UCD_URL}/ScriptExtensions.txt",
    "PropertyValueAliases.txt": f"{UCD_URL}/PropertyValueAliases.txt",
    "IdentifierStatus.txt": f"https://www.unicode.org/Public/security/{UNICODE_VERSION}/IdentifierStatus.txt",
}


def load_source_manifest(path):
    # Treat the reviewed manifest as input, never bootstrap hashes from the cache.
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(manifest, dict) or manifest.get("unicode_version") != UNICODE_VERSION:
        raise ValueError("Unicode version changed: review and update sources.json explicitly.")
    sources = manifest.get("sources")
    if not isinstance(sources, dict) or set(sources) != set(SOURCE_URLS):
        raise ValueError("Manifest source files must match the pinned Unicode files.")
    for name, url in SOURCE_URLS.items():
        metadata = sources[name]
        if not isinstance(metadata, dict) or metadata.get("url") != url:
            raise ValueError(f"Source URL mismatch: {name}. Review sources.json explicitly.")
        checksum = metadata.get("sha256")
        if not isinstance(checksum, str) or not re.fullmatch(r"[0-9a-f]{64}", checksum):
            raise ValueError(f"Invalid source checksum: {name}.")
    return manifest

def fetch_file(url, local_path, expected_sha256):
    if not os.path.exists(local_path):
        print(f"Downloading {url} -> {local_path} ...")
        req = urllib.request.Request(url, headers={'User-Agent': 'MoonSpoof-DataGen/1.0'})
        with urllib.request.urlopen(req, timeout=60) as resp:
            content = resp.read()
        destination = Path(local_path)
        if hashlib.sha256(content).hexdigest() != expected_sha256:
            raise ValueError(f"Source checksum mismatch: {destination.name}. Download was not cached; retry with the official pinned source.")
        temporary_path = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="wb", dir=destination.parent,
                prefix=f".{destination.name}.", suffix=".tmp", delete=False,
            ) as temporary:
                temporary_path = Path(temporary.name)
                temporary.write(content)
            os.replace(temporary_path, destination)
        finally:
            if temporary_path is not None:
                temporary_path.unlink(missing_ok=True)
        print(f"Saved {local_path} ({len(content)} bytes)")
    return local_path

def parse_confusables(filepath):
    mappings = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = [p.strip() for p in line.split(';')]
            if len(parts) >= 2:
                src_str = parts[0]
                target_str = parts[1]
                src_hex = src_str.split()
                if len(src_hex) == 1:
                    src_cp = int(src_hex[0], 16)
                    target_cps = [int(h, 16) for h in target_str.split()]
                    target_chars = "".join(chr(c) for c in target_cps)
                    mappings.append((src_cp, target_chars))
    mappings.sort(key=lambda x: x[0])
    return mappings

def parse_scripts(filepath):
    # Maps script name to MoonBit Script enum name
    script_map = {
        'Common': 'Common',
        'Inherited': 'Inherited',
        'Latin': 'Latin',
        'Cyrillic': 'Cyrillic',
        'Greek': 'Greek',
        'Arabic': 'Arabic',
        'Hebrew': 'Hebrew',
        'Han': 'Han',
        'Hiragana': 'Hiragana',
        'Katakana': 'Katakana',
        'Hangul': 'Hangul',
    }
    ranges = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = [p.strip() for p in line.split(';')]
            if len(parts) >= 2:
                range_part = parts[0].strip()
                script_part = parts[1].split('#')[0].strip()
                if '..' in range_part:
                    s_hex, e_hex = range_part.split('..')
                    start = int(s_hex, 16)
                    end = int(e_hex, 16)
                else:
                    start = int(range_part, 16)
                    end = start
                mbt_script = script_map.get(script_part, 'Unknown')
                ranges.append((start, end, mbt_script))
    ranges.sort(key=lambda x: x[0])
    # Merge contiguous ranges with identical script
    merged = []
    for r in ranges:
        if merged and merged[-1][2] == r[2] and merged[-1][1] + 1 == r[0]:
            merged[-1] = (merged[-1][0], r[1], r[2])
        else:
            merged.append(r)
    return merged

def escape_moonbit_string(s):
    res = []
    for ch in s:
        cp = ord(ch)
        if ch == '"':
            res.append('\\"')
        elif ch == '\\':
            res.append('\\\\')
        elif cp == 10:
            res.append('\\n')
        elif cp == 13:
            res.append('\\r')
        elif cp == 9:
            res.append('\\t')
        elif 32 <= cp <= 126:
            res.append(ch)
        elif cp <= 0xFFFF:
            res.append(f"\\u{cp:04x}")
        else:
            # Moonbit unicode escape
            res.append(f"\\u{{{cp:X}}}")
    return "".join(res)


def property_rows(path):
    """Parse exact two-field property rows, failing closed on malformed ranges."""
    rows = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        text = line.split("#", 1)[0].strip()
        if not text:
            continue
        fields = [part.strip() for part in text.split(";")]
        if len(fields) != 2 or not fields[1] or not re.fullmatch(
            r"[0-9A-Fa-f]{4,6}(?:\.\.[0-9A-Fa-f]{4,6})?", fields[0]
        ):
            raise ValueError(f"{path.name}:{number}: malformed property row")
        bounds = fields[0].split("..")
        start, end = int(bounds[0], 16), int(bounds[-1], 16)
        if not 0 <= start <= end <= 0x10FFFF:
            raise ValueError(f"{path.name}:{number}: invalid codepoint range")
        rows.append((start, end, fields[1]))
    if not rows:
        raise ValueError(f"{path.name}: empty property data")
    rows.sort()
    for previous, current in zip(rows, rows[1:]):
        if current[0] <= previous[1]:
            raise ValueError(f"{path.name}: overlapping property ranges")
    return rows


def parse_security_properties(data_dir):
    aliases = {}
    for line in (data_dir / "PropertyValueAliases.txt").read_text(encoding="utf-8").splitlines():
        fields = [part.strip() for part in line.split("#", 1)[0].split(";")]
        if fields[0] != "sc":
            continue
        if len(fields) < 3 or not re.fullmatch(r"[A-Za-z_]+", fields[2]):
            raise ValueError("Malformed script alias")
        for alias in fields[1:]:
            if alias in aliases and aliases[alias] != fields[2]:
                raise ValueError("Conflicting script alias")
            aliases[alias] = fields[2]
    if not aliases:
        raise ValueError("Empty script aliases")
    scripts = property_rows(data_dir / "Scripts.txt")
    extensions = property_rows(data_dir / "ScriptExtensions.txt")
    status = property_rows(data_dir / "IdentifierStatus.txt")
    for _, _, name in scripts:
        if name not in aliases or aliases[name] != name:
            raise ValueError(f"Unknown canonical script name: {name}")
    expanded = []
    for start, end, names in extensions:
        tokens = names.split()
        if any(name not in aliases for name in tokens):
            raise ValueError(f"Unknown Script_Extensions alias: {names}")
        expanded.append((start, end, " ".join(sorted({aliases[name] for name in tokens}))))
    if any(value != "Allowed" for _, _, value in status):
        raise ValueError("Unexpected Identifier_Status value")
    return scripts, expanded, status


def generate_security_properties(properties, out_path):
    sections = [
        "// Generated by tools/data-generator/generate.py. DO NOT EDIT.\n"
        f"// Unicode {UNICODE_VERSION}: full Script, Script_Extensions, Identifier_Status.\n"
    ]
    for prefix, rows in zip(("full_script", "script_extension", "identifier_allowed"), properties):
        columns = [("starts", "Int", [f"0x{start:X}" for start, _, _ in rows]),
                   ("ends", "Int", [f"0x{end:X}" for _, end, _ in rows])]
        if prefix != "identifier_allowed":
            columns.append(("values", "String", [json.dumps(value) for _, _, value in rows]))
        for suffix, kind, values in columns:
            lines = [f"let {prefix}_{suffix} : FixedArray[{kind}] = ["]
            lines.extend("  " + ", ".join(values[i:i + 10]) + "," for i in range(0, len(values), 10))
            sections.append("\n".join(lines + ["]\n"]))
    out_path.write_text("\n///|\n".join(sections), encoding="utf-8")


def parse_decimal_systems(path):
    """Require complete contiguous Nd families before emitting numeric tables."""
    digits = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split(";")
        if len(fields) != 15 or not re.fullmatch(r"[0-9A-F]{4,6}", fields[0]):
            raise ValueError(f"{path.name}:{number}: malformed UnicodeData row")
        cp = int(fields[0], 16)
        if cp > 0x10FFFF:
            raise ValueError(f"{path.name}:{number}: invalid codepoint")
        if fields[2] != "Nd":
            if fields[6]:
                raise ValueError(f"{path.name}:{number}: decimal value outside Nd")
            continue
        if not re.fullmatch(r"[0-9]", fields[6]) or cp in digits:
            raise ValueError(f"{path.name}:{number}: invalid or duplicate decimal digit")
        digits[cp] = int(fields[6])
    zeros = sorted({cp - value for cp, value in digits.items()})
    if not zeros:
        raise ValueError(f"{path.name}: empty decimal data")
    for zero in zeros:
        if any(digits.get(zero + value) != value for value in range(10)):
            raise ValueError(f"{path.name}: incomplete decimal system U+{zero:04X}")
    return zeros


def generate_numeric_tables(zeros, out_path):
    lines = [
        "// Generated by tools/data-generator/generate.py. DO NOT EDIT.",
        f"// Unicode {UNICODE_VERSION}: Nd decimal systems from UnicodeData.txt.",
        "///|",
        "let decimal_zeros : FixedArray[Int] = [",
    ]
    lines.extend("  " + ", ".join(f"0x{cp:X}" for cp in zeros[i:i + 10]) + ","
                 for i in range(0, len(zeros), 10))
    out_path.write_text("\n".join(lines + ["]", ""]), encoding="utf-8")


def generate_unicode_tables(data_dir, out_path):
    """Use version-pinned UCD, never the host Python Unicode version."""
    decompositions, classes, folds, ignorables = {}, {}, {}, []
    for line in (data_dir / "UnicodeData.txt").read_text(encoding="utf-8").splitlines():
        fields = line.split(";")
        cp = int(fields[0], 16)
        if int(fields[3]):
            classes[cp] = int(fields[3])
        if fields[5] and not fields[5].startswith("<"):
            decompositions[cp] = tuple(int(x, 16) for x in fields[5].split())

    @lru_cache(maxsize=None)
    def decompose(cp):
        if 0xAC00 <= cp <= 0xD7A3:
            index = cp - 0xAC00
            result = [0x1100 + index // 588, 0x1161 + index % 588 // 28]
            if index % 28:
                result.append(0x11A7 + index % 28)
            return tuple(result)
        return tuple(x for child in decompositions.get(cp, (cp,)) for x in decompose(child)) if cp in decompositions else (cp,)

    for line in (data_dir / "CaseFolding.txt").read_text(encoding="utf-8").splitlines():
        fields = line.split("#", 1)[0].strip().split(";")
        if len(fields) >= 3 and fields[1].strip() in ("C", "F"):
            folds[int(fields[0], 16)] = "".join(chr(int(x, 16)) for x in fields[2].split())
    for line in (data_dir / "DerivedCoreProperties.txt").read_text(encoding="utf-8").splitlines():
        fields = line.split("#", 1)[0].strip().split(";")
        if len(fields) >= 2 and fields[1].strip() == "Default_Ignorable_Code_Point":
            bounds = fields[0].strip().split("..")
            ignorables.append((int(bounds[0], 16), int(bounds[-1], 16)))

    def array(name, kind, values, encode):
        lines = [f"let {name} : FixedArray[{kind}] = ["]
        for i in range(0, len(values), 12):
            lines.append("  " + ", ".join(encode(x) for x in values[i:i + 12]) + ",")
        return "\n".join(lines + ["]\n"])

    sections = [f"// Generated by tools/data-generator/generate.py. DO NOT EDIT.\n// Unicode {UNICODE_VERSION}: canonical decomposition, combining classes, full case folding, default ignorables.\n"]
    for prefix, values in (("decomposition", {cp: "".join(chr(x) for x in decompose(cp)) for cp in sorted(decompositions)}), ("casefold", dict(sorted(folds.items())))):
        sections.append(array(prefix + "_keys", "Int", list(values), lambda x: f"0x{x:X}"))
        sections.append(array(prefix + "_values", "String", list(values.values()), lambda x: '"' + escape_moonbit_string(x) + '"'))
    sections.append(array("combining_keys", "Int", sorted(classes), lambda x: f"0x{x:X}"))
    sections.append(array("combining_values", "Int", [classes[x] for x in sorted(classes)], str))
    sections.append(array("ignorable_starts", "Int", [x[0] for x in ignorables], lambda x: f"0x{x:X}"))
    sections.append(array("ignorable_ends", "Int", [x[1] for x in ignorables], lambda x: f"0x{x:X}"))
    out_path.write_text("\n///|\n".join(sections), encoding="utf-8")

def generate_confusable_tables(mappings, out_path):
    print(f"Generating {out_path} ({len(mappings)} entries)...")
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write("// Generated by tools/data-generator/generate.py. DO NOT EDIT.\n")
        f.write("// Source: Unicode Technical Standard #39 (Version 16.0.0)\n\n")
        
        # Keys array
        f.write("let confusable_keys : FixedArray[Int] = [\n")
        for i in range(0, len(mappings), 16):
            chunk = mappings[i:i+16]
            line = ", ".join(f"0x{m[0]:04X}" for m in chunk)
            f.write(f"  {line},\n")
        f.write("]\n\n")

        # Values array
        f.write('let confusable_values : FixedArray[String] = [\n')
        for i in range(0, len(mappings), 12):
            chunk = mappings[i:i+12]
            line = ", ".join(f'"{escape_moonbit_string(m[1])}"' for m in chunk)
            f.write(f"  {line},\n")
        f.write("]\n\n")

        # Binary search lookup
        f.write("""pub fn binary_search_confusable(cp : Int) -> String? {
  let len = confusable_keys.length()
  let mut low = 0
  let mut high = len - 1
  while low <= high {
    let mid = (low + high) / 2
    let key = confusable_keys[mid]
    if key == cp {
      return Some(confusable_values[mid])
    } else if key < cp {
      low = mid + 1
    } else {
      high = mid - 1
    }
  }
  None
}
""")

def generate_script_tables(ranges, out_path):
    print(f"Generating {out_path} ({len(ranges)} merged ranges)...")
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write("// Generated by tools/data-generator/generate.py. DO NOT EDIT.\n")
        f.write("// Source: Unicode Character Database Scripts.txt (Version 16.0.0)\n\n")

        f.write("let script_range_starts : FixedArray[Int] = [\n")
        for i in range(0, len(ranges), 16):
            chunk = ranges[i:i+16]
            line = ", ".join(f"0x{r[0]:04X}" for r in chunk)
            f.write(f"  {line},\n")
        f.write("]\n\n")

        f.write("let script_range_ends : FixedArray[Int] = [\n")
        for i in range(0, len(ranges), 16):
            chunk = ranges[i:i+16]
            line = ", ".join(f"0x{r[1]:04X}" for r in chunk)
            f.write(f"  {line},\n")
        f.write("]\n\n")

        f.write("let script_range_values : FixedArray[Script] = [\n")
        for i in range(0, len(ranges), 12):
            chunk = ranges[i:i+12]
            line = ", ".join(f"{r[2]}" for r in chunk)
            f.write(f"  {line},\n")
        f.write("]\n\n")

        f.write("""pub fn binary_search_script(cp : Int) -> Script {
  let len = script_range_starts.length()
  let mut low = 0
  let mut high = len - 1
  while low <= high {
    let mid = (low + high) / 2
    let s = script_range_starts[mid]
    let e = script_range_ends[mid]
    if cp >= s && cp <= e {
      return script_range_values[mid]
    } else if s < cp {
      low = mid + 1
    } else {
      high = mid - 1
    }
  }
  Script::Unknown
}
""")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))

    confusables_file = os.path.join(script_dir, "confusables.txt")
    scripts_file = os.path.join(script_dir, "Scripts.txt")

    data_dir = Path(script_dir)
    manifest = load_source_manifest(data_dir / "sources.json")
    for name, url in SOURCE_URLS.items():
        fetch_file(url, data_dir / name, manifest["sources"][name]["sha256"])

    # A pinned manifest must not silently accept edited or corrupted downloads.
    for name, metadata in manifest["sources"].items():
        actual = hashlib.sha256((data_dir / name).read_bytes()).hexdigest()
        if actual != metadata["sha256"]:
            raise ValueError(f"Source checksum mismatch: {name}. Restore the official pinned file before generating.")

    mappings = parse_confusables(confusables_file)
    ranges = parse_scripts(scripts_file)
    properties = parse_security_properties(data_dir)
    decimal_systems = parse_decimal_systems(data_dir / "UnicodeData.txt")

    confusable_out = os.path.join(project_root, "src", "confusable", "tables.mbt")
    script_out = os.path.join(project_root, "src", "script", "tables.mbt")

    generate_confusable_tables(mappings, confusable_out)
    generate_script_tables(ranges, script_out)
    generate_unicode_tables(data_dir, Path(project_root) / "src" / "unicode" / "tables.mbt")
    generate_security_properties(properties, Path(project_root) / "src" / "unicode" / "security_tables.mbt")
    generate_numeric_tables(decimal_systems, Path(project_root) / "src" / "unicode" / "numeric_tables.mbt")
    print("Done generating MoonBit static tables!")

if __name__ == '__main__':
    main()
