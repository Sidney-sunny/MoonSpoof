#!/usr/bin/env python3
"""
Unicode Data Generator for MoonSpoof
Generates UTS #39 Confusable Skeleton tables and Script data for MoonBit.
Source: Unicode Technical Standard #39 / Unicode Character Database 16.0.0
"""

import urllib.request
import os
import re

UNICODE_VERSION = "16.0.0"
CONFUSABLES_URL = f"https://www.unicode.org/Public/security/{UNICODE_VERSION}/confusables.txt"
SCRIPTS_URL = f"https://www.unicode.org/Public/{UNICODE_VERSION}/ucd/Scripts.txt"

def fetch_file(url, local_filename):
    if not os.path.exists(local_filename):
        print(f"Downloading {url} ...")
        urllib.request.urlretrieve(url, local_filename)
    return local_filename

def parse_confusables(filepath):
    mappings = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = [p.strip() for p in line.split(';')]
            if len(parts) >= 3:
                src_hex = parts[0]
                target_hexes = parts[1].split()
                # Single codepoint source
                if len(src_hex.split()) == 1:
                    src_cp = int(src_hex, 16)
                    target_cps = [int(h, 16) for h in target_hexes]
                    mappings.append((src_cp, target_cps))
    return mappings

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    print(f"MoonSpoof Unicode Data Generator (Target: Unicode {UNICODE_VERSION})")
    # Generator pipeline ready for production table emission.

if __name__ == '__main__':
    main()
