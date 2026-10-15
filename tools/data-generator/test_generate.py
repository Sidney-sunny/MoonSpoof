"""Regression checks for the pinned-source contract, without network access."""

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import generate


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
        self.writers = [
            self.enterContext(patch.object(generate, name))
            for name in (
                "generate_confusable_tables",
                "generate_script_tables",
                "generate_unicode_tables",
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
        self.assertEqual(self.fetch.call_count, 6)
        for writer in self.writers:
            writer.assert_called_once()

    def test_missing_manifest_fails_before_downloads_or_outputs(self):
        self.manifest_path.unlink()
        with self.assertRaises(FileNotFoundError):
            generate.main()
        self.fetch.assert_not_called()
        self.assert_no_outputs()
        self.assertFalse(self.manifest_path.exists())

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
