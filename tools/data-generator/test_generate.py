"""Regression checks for the pinned-source contract, without network access."""

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import generate


class DownloadTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.destination = self.directory / "Scripts.txt"
        self.content = b"# pinned Unicode source fixture\n"
        self.checksum = hashlib.sha256(self.content).hexdigest()
        self.urlopen = self.enterContext(patch.object(generate.urllib.request, "urlopen"))
        self.read = self.urlopen.return_value.__enter__.return_value.read
        self.read.return_value = self.content

    def download(self):
        return generate.fetch_file(
            generate.SCRIPTS_URL, self.destination, self.checksum
        )

    def test_valid_download_is_cached_without_temporary_files(self):
        self.download()
        self.assertEqual(self.destination.read_bytes(), self.content)
        self.assertEqual(list(self.directory.iterdir()), [self.destination])

    def test_bad_download_leaves_no_cache_and_can_be_retried(self):
        self.read.return_value = b"truncated or unexpected response"
        with self.assertRaisesRegex(ValueError, "checksum mismatch: Scripts.txt"):
            self.download()
        self.assertEqual(list(self.directory.iterdir()), [])
        self.read.return_value = self.content
        self.download()
        self.assertEqual(self.destination.read_bytes(), self.content)
        self.assertEqual(self.urlopen.call_count, 2)

    def test_interrupted_download_leaves_no_cache(self):
        self.read.side_effect = ConnectionResetError("connection interrupted")
        with self.assertRaises(ConnectionResetError):
            self.download()
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_failed_publish_cleans_up_temporary_file(self):
        with patch.object(generate.os, "replace", side_effect=OSError("write denied")):
            with self.assertRaises(OSError):
                self.download()
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_cached_source_is_reused_without_network_access(self):
        self.destination.write_bytes(self.content)
        self.download()
        self.urlopen.assert_not_called()
        self.assertEqual(self.destination.read_bytes(), self.content)


class SecurityPropertyTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.files = {
            "PropertyValueAliases.txt": "sc ; Latn ; Latin\nsc ; Zyyy ; Common\nsc ; Hira ; Hiragana\nsc ; Kana ; Katakana\n",
            "Scripts.txt": "0041..005A ; Latin\n0030..0039 ; Common\n",
            "ScriptExtensions.txt": "30FC ; Kana Hira\n",
            "IdentifierStatus.txt": "0041..005A ; Allowed\n0030..0039 ; Allowed\n",
        }
        for name, text in self.files.items():
            (self.directory / name).write_text(text, encoding="utf-8")

    def parse(self):
        return generate.parse_security_properties(self.directory)

    def test_sorted_ranges_and_canonical_extension_names(self):
        scripts, extensions, allowed = self.parse()
        self.assertEqual(scripts[0], (0x30, 0x39, "Common"))
        self.assertEqual(extensions, [(0x30FC, 0x30FC, "Hiragana Katakana")])
        self.assertEqual(allowed[1], (0x41, 0x5A, "Allowed"))

    def test_empty_malformed_reversed_out_of_range_and_overlapping_rows_fail(self):
        for text in ("# empty\n", "0041 Latin\n", "005A..0041 ; Latin\n",
                     "110000 ; Latin\n", "0041..005A ; Latin\n005A ; Common\n"):
            with self.subTest(text=text):
                (self.directory / "Scripts.txt").write_text(text, encoding="utf-8")
                with self.assertRaises(ValueError):
                    self.parse()

    def test_unknown_script_and_extension_aliases_fail(self):
        for name, text in (("Scripts.txt", "0041 ; Missing\n"),
                           ("ScriptExtensions.txt", "30FC ; Nope\n")):
            with self.subTest(name=name):
                (self.directory / name).write_text(text, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "Unknown"):
                    self.parse()
                (self.directory / name).write_text(self.files[name], encoding="utf-8")

    def test_unexpected_status_and_empty_aliases_fail(self):
        (self.directory / "IdentifierStatus.txt").write_text("0041 ; Typo\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Identifier_Status"):
            self.parse()
        (self.directory / "PropertyValueAliases.txt").write_text("# empty\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Empty script aliases"):
            self.parse()


class DecimalSystemsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "UnicodeData.txt"

    def fixture(self, zero=0x30):
        return [f"{zero + n:04X};DIGIT;Nd;0;EN;;{n};{n};{n};N;;;;;" for n in range(10)]

    def parse(self, lines):
        self.path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return generate.parse_decimal_systems(self.path)

    def test_complete_sorted_families_include_adjacent_mathematical_styles(self):
        lines = self.fixture(0x1D7D8) + self.fixture(0x30) + self.fixture(0x1D7CE)
        lines.append("00B2;SUPERSCRIPT TWO;No;0;EN;<super> 0032;;2;2;N;;;;;")
        self.assertEqual(self.parse(lines), [0x30, 0x1D7CE, 0x1D7D8])

    def test_incomplete_duplicate_or_invalid_digit_fails(self):
        valid = self.fixture()
        for lines in (valid[:-1], valid + [valid[0]],
                      [valid[0].replace(";;0;", ";;10;")] + valid[1:]):
            with self.subTest(lines=lines):
                with self.assertRaises(ValueError):
                    self.parse(lines)

    def test_empty_malformed_or_non_decimal_value_fails(self):
        for lines in ([], ["0030;broken"],
                      ["110000;DIGIT;Nd;0;EN;;0;0;0;N;;;;;"],
                      ["0030;DIGIT;No;0;EN;;0;0;0;N;;;;;"]):
            with self.subTest(lines=lines):
                with self.assertRaises(ValueError):
                    self.parse(lines)


class PinnedSourcesTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.data_dir = Path(temporary.name) / "tools" / "data-generator"
        self.data_dir.mkdir(parents=True)
        self.manifest_path = self.data_dir / "sources.json"
        self.manifest = json.loads(
            Path(generate.__file__).with_name("sources.json").read_text(encoding="utf-8")
        )
        for name, metadata in self.manifest["sources"].items():
            content = f"fixture: {name}\n".encode()
            (self.data_dir / name).write_bytes(content)
            metadata["sha256"] = hashlib.sha256(content).hexdigest()
        self.write_manifest()
        self.enterContext(patch.object(generate, "__file__", str(self.data_dir / "generate.py")))
        self.fetch = self.enterContext(patch.object(generate, "fetch_file"))
        self.enterContext(patch.object(generate, "parse_confusables", return_value=[]))
        self.enterContext(patch.object(generate, "parse_scripts", return_value=[]))
        self.enterContext(patch.object(generate, "parse_security_properties", return_value=([], [], [])))
        self.decimal_parser = self.enterContext(patch.object(generate, "parse_decimal_systems", return_value=[0x30]))
        self.writers = [
            self.enterContext(patch.object(generate, name))
            for name in (
                "generate_confusable_tables",
                "generate_script_tables",
                "generate_unicode_tables",
                "generate_security_properties",
                "generate_numeric_tables",
            )
        ]

    def write_manifest(self):
        # Non-default formatting makes accidental manifest rewriting observable.
        self.manifest_path.write_text(
            json.dumps(self.manifest, indent=4) + "\n", encoding="utf-8"
        )

    def assert_no_outputs(self):
        for writer in self.writers:
            writer.assert_not_called()

    def test_valid_sources_generate_without_rewriting_manifest(self):
        before = self.manifest_path.read_bytes()
        generate.main()
        self.assertEqual(self.manifest_path.read_bytes(), before)
        self.assertEqual(self.fetch.call_count, len(generate.SOURCE_URLS))
        for writer in self.writers:
            writer.assert_called_once()

    def test_missing_manifest_fails_before_downloads_or_outputs(self):
        self.manifest_path.unlink()
        with self.assertRaises(FileNotFoundError):
            generate.main()
        self.fetch.assert_not_called()
        self.assert_no_outputs()
        self.assertFalse(self.manifest_path.exists())

    def test_invalid_decimal_data_fails_before_any_output(self):
        self.decimal_parser.side_effect = ValueError("incomplete decimal system")
        with self.assertRaisesRegex(ValueError, "incomplete decimal system"):
            generate.main()
        self.assert_no_outputs()

    def test_incomplete_or_unexpected_sources_fail_before_downloads(self):
        for name in ("NormalizationTest.txt", "extra.txt"):
            with self.subTest(name=name):
                sources = self.manifest["sources"]
                original = dict(sources)
                if name in sources:
                    del sources[name]
                else:
                    sources[name] = dict(sources["NormalizationTest.txt"])
                self.write_manifest()
                with self.assertRaisesRegex(ValueError, "source files"):
                    generate.main()
                self.fetch.assert_not_called()
                self.assert_no_outputs()
                self.manifest["sources"] = original

    def test_changed_version_or_url_fails_before_downloads(self):
        for field in ("version", "url"):
            with self.subTest(field=field):
                original = json.loads(json.dumps(self.manifest))
                if field == "version":
                    self.manifest["unicode_version"] = "17.0.0"
                else:
                    self.manifest["sources"]["Scripts.txt"]["url"] = (
                        "https://example.invalid/Scripts.txt"
                    )
                self.write_manifest()
                with self.assertRaises(ValueError):
                    generate.main()
                self.fetch.assert_not_called()
                self.assert_no_outputs()
                self.manifest = original

    def test_corrupt_cached_source_cannot_modify_tables_or_manifest(self):
        before = self.manifest_path.read_bytes()
        (self.data_dir / "Scripts.txt").write_bytes(b"corrupted")
        with self.assertRaisesRegex(ValueError, "checksum mismatch: Scripts.txt"):
            generate.main()
        self.assert_no_outputs()
        self.assertEqual(self.manifest_path.read_bytes(), before)

    def test_invalid_checksums_fail_before_downloads(self):
        for checksum in (None, "", "not-a-sha256", "f" * 63):
            with self.subTest(checksum=checksum):
                self.manifest["sources"]["Scripts.txt"]["sha256"] = checksum
                self.write_manifest()
                with self.assertRaisesRegex(ValueError, "Invalid source checksum"):
                    generate.main()
                self.fetch.assert_not_called()
                self.assert_no_outputs()


if __name__ == "__main__":
    unittest.main()
