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
}


def load_source_manifest(path):
    # Treat the reviewed manifest as input, never bootstrap hashes from the cache.
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(manifest, dict) or manifest.get("unicode_version") != UNICODE_VERSION:
        raise ValueError("Unicode version changed: review and update sources.json explicitly.")
    sources = manifest.get("sources")
    if not isinstance(sources, dict) or set(sources) != set(SOURCE_URLS):
        raise ValueError("Manifest source files must match the six pinned Unicode files.")
    for name, url in SOURCE_URLS.items():
        metadata = sources[name]
        if not isinstance(metadata, dict) or metadata.get("url") != url:
            raise ValueError(f"Source URL mismatch: {name}. Review sources.json explicitly.")
        checksum = metadata.get("sha256")
        if not isinstance(checksum, str) or not re.fullmatch(r"[0-9a-f]{64}", checksum):
            raise ValueError(f"Invalid source checksum: {name}.")
    return manifest

def fetch_file(url, local_path):
    if not os.path.exists(local_path):
        print(f"Downloading {url} -> {local_path} ...")
        req = urllib.request.Request(url, headers={'User-Agent': 'MoonSpoof-DataGen/1.0'})
        with urllib.request.urlopen(req, timeout=60) as resp:
            content = resp.read()
        with open(local_path, 'wb') as f:
            f.write(content)
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

    # Official normalization vectors, covering composition, order, and Hangul.
    vectors = []
    for line in (data_dir / "NormalizationTest.txt").read_text(encoding="utf-8").splitlines():
        fields = line.split("#", 1)[0].strip().split(";")
        if len(fields) >= 5:
            vectors.append(["".join(chr(int(x, 16)) for x in field.split()) for field in fields[:5]])
    (data_dir / "normalization-vectors.json").write_text(json.dumps(vectors, ensure_ascii=True), encoding="utf-8")

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
        fetch_file(url, data_dir / name)

    # A pinned manifest must not silently accept edited or corrupted downloads.
    for name, metadata in manifest["sources"].items():
        actual = hashlib.sha256((data_dir / name).read_bytes()).hexdigest()
        if actual != metadata["sha256"]:
            raise ValueError(f"Source checksum mismatch: {name}. Restore the official pinned file before generating.")

    mappings = parse_confusables(confusables_file)
    ranges = parse_scripts(scripts_file)

    confusable_out = os.path.join(project_root, "src", "confusable", "tables.mbt")
    script_out = os.path.join(project_root, "src", "script", "tables.mbt")

    generate_confusable_tables(mappings, confusable_out)
    generate_script_tables(ranges, script_out)
    generate_unicode_tables(data_dir, Path(project_root) / "src" / "unicode" / "tables.mbt")
    print("Done generating MoonBit static tables!")

if __name__ == '__main__':
    main()
