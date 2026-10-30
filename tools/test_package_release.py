"""Release regressions: no network, real fixture Git commits, standard library only."""

import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile


spec = importlib.util.spec_from_file_location(
    "package_release", Path(__file__).with_name("package-release.py")
)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


def fixture_source():
    return {
        "moon.mod": b'name = "Sidney-sunny/moonspoof"\nversion = "0.2.0"\n',
        ".moon-version": b"0.10.18+6c83a7f62\n",
        "playground/package.json": b'{"version":"0.2.0"}\n',
        "tools/data-generator/sources.json": b'{"unicode_version":"16.0.0"}\n',
        "src/unicode/types.mbt": b"pub let unicode_version : UnicodeVersion = { major: 16, minor: 0, update: 0, }\n",
        "LICENSE": b"Fixture Apache-2.0 notice\n",
        "THIRD_PARTY_NOTICES.md": b"Fixture Unicode and Manrope attribution\n",
        "licenses/UNICODE-3.0.txt": b"Fixture Unicode license\n",
        "licenses/Manrope-OFL-1.1.txt": b"Fixture Manrope license\n",
        "licenses/React-MIT.txt": b"Fixture React MIT license\n",
        ".gitignore": b"playground/src/generated/\nplayground/dist/\n_build/\n",
        "moonspoof.mbt": b"// Fixture source\n",
    }


class FixtureTests(unittest.TestCase):
    def setUp(self):
        work = Path(__file__).resolve().parent.parent / "_build" / "release-tool-tests"
        work.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=work)
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.source = fixture_source()
        self.commit = "a" * 40
        self.metadata = release.metadata_from_source(self.source, self.commit, 1793350800)
        self.engine = b"// fixture engine\nexport const version = '0.2.0';\n"
        self.compiler = "moonc v0.10.18+6c83a7f62 (fixture compiler)"
        self.stamp = {
            "schema": 1, "module": release.MODULE, "version": release.VERSION,
            "commit": self.commit, "dirty": False,
            "compiler_pin": self.metadata["compiler_pin"], "compiler": self.compiler,
            "engine_sha256": release.sha256(self.engine),
        }
        self.refresh_site()

    def refresh_site(self):
        self.stamp_bytes = release.json_bytes(self.stamp)
        self.site = {
            "index.html": b"<!doctype html><title>Fixture site</title>\n",
            "assets/app.js": b"// Fixture site bundle\n",
            release.BUILD_INFO: self.stamp_bytes,
            **{name: self.source[name] for name in release.LICENSE_PATHS[2:]},
        }
        self.site[release.SITE_FILES] = release.json_bytes({
            "schema": 1, "commit": self.stamp["commit"],
            "files": {name: release.sha256(contents) for name, contents in self.site.items()},
        })

    def blobs(self):
        return release.assemble(self.source, self.metadata, self.engine, self.stamp_bytes, self.site)

    def save(self, blobs, name="release"):
        directory = self.directory / name
        directory.mkdir()
        for filename, contents in blobs.items():
            (directory / filename).write_bytes(contents)
        return directory

    def test_all_bundles_retain_original_notices_and_per_file_checksums(self):
        blobs = self.blobs()
        directory = self.save(blobs)
        manifest = release.verify_release(directory)
        self.assertEqual(manifest["commit"], self.commit)
        self.assertEqual(manifest["compiler"], self.compiler)
        self.assertEqual(len(manifest["artifacts"]), 3)
        for filename, record in manifest["artifacts"].items():
            with self.subTest(artifact=filename):
                files = release.read_zip(blobs[filename])
                prefix = "moonspoof-0.2.0/" if record["kind"] == "source" else ""
                for name, contents in release.license_files(self.source).items():
                    self.assertEqual(files[prefix + name], contents)
                for name, contents in files.items():
                    self.assertEqual(record["files"][name], release.sha256(contents))

    def test_same_inputs_produce_byte_identical_archives_and_manifest(self):
        self.assertEqual(self.blobs(), self.blobs())
        # Input map insertion order must not affect the artifact bytes.
        reordered = dict(reversed(list(self.source.items())))
        self.assertEqual(self.blobs(), release.assemble(
            reordered, self.metadata, self.engine, self.stamp_bytes,
            dict(reversed(list(self.site.items()))),
        ))

    def test_checksum_failure_detects_corrupt_download_before_opening_zip(self):
        directory = self.save(self.blobs())
        engine = directory / "moonspoof-0.2.0-engine.zip"
        engine.write_bytes(engine.read_bytes() + b"unexpected bytes")
        with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
            release.verify_release(directory)

    def test_old_or_dirty_builds_and_wrong_compiler_are_rejected(self):
        for key, value in (
            ("commit", "b" * 40), ("dirty", True), ("dirty", 0),
            ("version", "0.1.0"), ("compiler_pin", "0.10.16+deadbeef"),
            ("compiler", "moonc v0.10.16+deadbeef"), ("engine_sha256", "0" * 64),
        ):
            with self.subTest(field=key, value=value):
                stamp = {**self.stamp, key: value}
                with self.assertRaises(ValueError):
                    release.assemble(self.source, self.metadata, self.engine,
                                     release.json_bytes(stamp), self.site)

    def test_site_and_engine_must_have_identical_stamps_and_unicode_licenses(self):
        for key, value in (
            (release.BUILD_INFO, self.stamp_bytes + b"\n"),
            ("licenses/UNICODE-3.0.txt", b"altered license"),
            ("licenses/Manrope-OFL-1.1.txt", b"altered license"),
        ):
            with self.subTest(path=key):
                site = {**self.site, key: value}
                with self.assertRaises(ValueError):
                    release.assemble(self.source, self.metadata, self.engine, self.stamp_bytes, site)

    def test_source_versions_must_agree_with_release(self):
        mutations = {
            "moon.mod": b'name = "Sidney-sunny/moonspoof"\nversion = "0.1.0"\n',
            "playground/package.json": b'{"version":"0.1.0"}',
            ".moon-version": b"0.10.16+abcdef\n",
            "src/unicode/types.mbt": b"pub let unicode_version : UnicodeVersion = { major: 17, minor: 0, update: 0, }",
        }
        for name, contents in mutations.items():
            with self.subTest(path=name), self.assertRaises(ValueError):
                release.metadata_from_source({**self.source, name: contents}, self.commit, 1)

    def test_changed_added_deleted_or_old_site_assets_are_rejected(self):
        for mutation in ("changed", "added", "deleted", "old", "missing"):
            with self.subTest(mutation=mutation):
                site = dict(self.site)
                if mutation == "changed":
                    site["assets/app.js"] = b"// Replaced output after build\n"
                elif mutation == "added":
                    site["assets/old-worker.js"] = b"// Previous build\n"
                elif mutation == "deleted":
                    del site["assets/app.js"]
                elif mutation == "old":
                    manifest = json.loads(site[release.SITE_FILES])
                    manifest["commit"] = "b" * 40
                    site[release.SITE_FILES] = release.json_bytes(manifest)
                else:
                    del site[release.SITE_FILES]
                with self.assertRaises(ValueError):
                    release.assemble(self.source, self.metadata, self.engine, self.stamp_bytes, site)

    def test_sensitive_paths_raw_downloads_and_build_temps_are_refused(self):
        for name in (
            ".env", ".env.production", "docs/.env.local", "credentials.json",
            "secret-token.txt", "ssh/id_ed25519", "cert/client.key", "private/file.txt",
            "node_modules/x.js", "_build/package.tar", "buildtemp/file", "temp/log.txt",
            "build/file.bin", "dist/bundle.js", ".cache/download.dat",
            ".mooncakes/credentials.json", "tools/data-generator/Scripts.txt",
            "playground/dist/index.html", "playground/src/generated/moonspoof.js",
        ):
            with self.subTest(path=name), self.assertRaises(ValueError):
                release.check_source_path(name)

    def test_zip_traversal_windows_paths_and_symlinks_are_refused(self):
        for name in ("../escape", "/absolute", "a/../b", "a//b", "C:/escape", "a\\b", "CON.txt", "x.", "x ", "a?b"):
            with self.subTest(path=name), self.assertRaises(ValueError):
                release.safe_path(name)
        data = io.BytesIO()
        with zipfile.ZipFile(data, "w") as archive:
            entry = zipfile.ZipInfo("link")
            entry.create_system = 3
            entry.external_attr = 0o120777 << 16
            archive.writestr(entry, "../../outside")
        with self.assertRaisesRegex(ValueError, "symlink"):
            release.read_zip(data.getvalue())

    def test_zip_case_collisions_are_refused(self):
        data = io.BytesIO()
        with zipfile.ZipFile(data, "w") as archive:
            archive.writestr("LICENSE", "first")
            archive.writestr("license", "second")
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            release.read_zip(data.getvalue())

    def test_independent_verifier_rejects_unsafe_zip_even_with_recomputed_checksums(self):
        blobs = self.blobs()
        name = "moonspoof-0.2.0-engine.zip"
        data = io.BytesIO()
        with zipfile.ZipFile(data, "w") as archive:
            archive.writestr("../escape", "malicious")
        blobs[name] = data.getvalue()
        manifest = json.loads(blobs[release.MANIFEST])
        manifest["artifacts"][name]["sha256"] = release.sha256(blobs[name])
        manifest["artifacts"][name]["size"] = len(blobs[name])
        blobs[release.MANIFEST] = release.json_bytes(manifest)
        blobs[release.CHECKSUMS] = "".join(
            f"{release.sha256(contents)}  {filename}\n"
            for filename, contents in sorted(blobs.items()) if filename != release.CHECKSUMS
        ).encode("ascii")
        with self.assertRaisesRegex(ValueError, "Unsafe archive"):
            release.verify_release(self.save(blobs))

    def initialize_git(self):
        self.repo = self.directory / "repo"
        self.repo.mkdir()
        for name, contents in self.source.items():
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(contents)
        self.command("init", "--quiet")
        self.command("config", "user.email", "release-fixture@example.invalid")
        self.command("config", "user.name", "Release fixture")
        self.command("config", "core.autocrlf", "false")
        self.command("add", ".")
        self.command("-c", "commit.gpgsign=false", "commit", "--no-verify", "--quiet", "-m", "Fixture release")
        self.commit = self.command("rev-parse", "HEAD").decode().strip()
        self.stamp["commit"] = self.commit
        self.refresh_site()
        generated = self.repo / "playground/src/generated"
        generated.mkdir(parents=True)
        (generated / "moonspoof.js").write_bytes(self.engine)
        (generated / release.BUILD_INFO).write_bytes(self.stamp_bytes)
        for name, contents in self.site.items():
            path = self.repo / "playground/dist" / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(contents)

    def command(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repo, stderr=subprocess.PIPE)

    def test_actual_git_archive_matches_commit_and_existing_output_is_never_overwritten(self):
        self.initialize_git()
        original_output = subprocess.check_output

        def compiler_or_git(command, **kwargs):
            if command[0] == "moonc":
                return self.compiler
            return original_output(command, **kwargs)

        with patch.object(release.subprocess, "check_output", side_effect=compiler_or_git):
            destination = release.create_release(self.repo)
            manifest = release.verify_release(destination)
            self.assertEqual(manifest["commit"], self.commit)
            before = {path.name: path.read_bytes() for path in destination.iterdir()}
            with self.assertRaises(FileExistsError):
                release.create_release(self.repo)
            self.assertEqual(before, {path.name: path.read_bytes() for path in destination.iterdir()})
        files = release.read_zip((destination / "moonspoof-0.2.0-source.zip").read_bytes())
        for name, contents in self.source.items():
            self.assertEqual(files["moonspoof-0.2.0/" + name], contents)
        self.assertFalse(any("_build" in name or "generated/" in name for name in files))

    def test_modified_and_untracked_source_cannot_be_packaged(self):
        self.initialize_git()
        (self.repo / "moonspoof.mbt").write_bytes(b"// Uncommitted edit\n")
        with self.assertRaisesRegex(ValueError, "clean working tree"):
            release.read_source(self.repo, "HEAD")
        (self.repo / "moonspoof.mbt").write_bytes(self.source["moonspoof.mbt"])
        (self.repo / "untracked.txt").write_bytes(b"Not committed\n")
        with self.assertRaisesRegex(ValueError, "clean working tree"):
            release.read_source(self.repo, "HEAD")

    def test_selected_old_commit_cannot_reuse_current_build(self):
        self.initialize_git()
        old_commit = self.commit
        (self.repo / "moonspoof.mbt").write_bytes(b"// Next committed source\n")
        self.command("add", ".")
        self.command("-c", "commit.gpgsign=false", "commit", "--no-verify", "--quiet", "-m", "Next source")
        with self.assertRaisesRegex(ValueError, "must equal HEAD"):
            release.read_source(self.repo, old_commit)

    def test_tracked_secret_or_export_ignored_source_fails_before_packaging(self):
        self.initialize_git()
        (self.repo / "service.key").write_bytes(b"Do not package\n")
        self.command("add", ".")
        self.command("-c", "commit.gpgsign=false", "commit", "--no-verify", "--quiet", "-m", "Tracked secret fixture")
        with self.assertRaisesRegex(ValueError, "Forbidden source path"):
            release.read_source(self.repo, "HEAD")
        self.command("rm", "service.key")
        (self.repo / ".gitattributes").write_bytes(b"moonspoof.mbt export-ignore\n")
        self.command("add", ".")
        self.command("-c", "commit.gpgsign=false", "commit", "--no-verify", "--quiet", "-m", "Export ignore fixture")
        with self.assertRaisesRegex(ValueError, "differs from the commit tree"):
            release.read_source(self.repo, "HEAD")


if __name__ == "__main__":
    unittest.main()
