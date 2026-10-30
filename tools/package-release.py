"""Package a clean, stamped 0.2.0 build; verify downloaded bundles without Git.

Run with `uv run --no-project python tools/package-release.py --commit HEAD`.
Verification: `uv run --no-project python tools/package-release.py --verify DIR`.
Only Python's standard library is used. No publication or credential access occurs.
"""

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import zipfile


VERSION = "0.2.0"
MODULE = "Sidney-sunny/moonspoof"
LICENSE_PATHS = (
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "licenses/UNICODE-3.0.txt",
    "licenses/Manrope-OFL-1.1.txt",
)
BUILD_INFO = "build-info.json"
SITE_FILES = "site-files.json"
MANIFEST = "RELEASE_MANIFEST.json"
CHECKSUMS = "SHA256SUMS"
FORBIDDEN_PARTS = {
    ".git", ".ssh", ".aws", ".azure", ".config", ".moon", ".mooncakes",
    ".moonagent", "node_modules", "_build", "target", "__pycache__", ".venv",
    "venv", "private", "credentials", "secrets", "buildtemp", "tmp", "temp",
    "dist", "build", ".cache", "coverage",
}
SENSITIVE_NAMES = re.compile(
    r"(?:^\.env(?:\.|$)|(?:^|[._-])(?:credentials?|secrets?|tokens?|apikeys?|"
    r"api[._-]keys?|private[._-]keys?)(?:[._-]|$)|^id_(?:rsa|ed25519)(?:\.|$)|"
    r"\.(?:pem|key|p12|pfx|jks|keystore)$)", re.IGNORECASE,
)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def safe_path(name):
    """Accept portable relative file names, including on Windows extractors."""
    if not isinstance(name, str) or not name or any(
        ord(ch) < 32 or ch in '\\:<>"|?*' for ch in name
    ):
        raise ValueError(f"Unsafe archive path: {name!r}")
    parts = name.split("/")
    if any(part in ("", ".", "..") or part.endswith((" ", ".")) for part in parts):
        raise ValueError(f"Unsafe archive path: {name!r}")
    for part in parts:
        if part.split(".", 1)[0].upper() in {
            "CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)),
            *(f"LPT{i}" for i in range(1, 10)),
        }:
            raise ValueError(f"Unsafe Windows archive path: {name!r}")
    return name


def check_source_path(name):
    safe_path(name)
    path = PurePosixPath(name)
    lowered = [part.lower() for part in path.parts]
    if any(part in FORBIDDEN_PARTS or SENSITIVE_NAMES.search(part) for part in lowered):
        raise ValueError(f"Forbidden source path: {name}")
    if lowered[:2] == ["tools", "data-generator"] and path.suffix.lower() == ".txt":
        raise ValueError(f"Raw Unicode source download is forbidden: {name}")
    if lowered[:2] == ["playground", "dist"] or lowered[:3] == ["playground", "src", "generated"]:
        raise ValueError(f"Build output is forbidden in source archive: {name}")


def license_files(source):
    return {
        name: contents for name, contents in source.items()
        if name in LICENSE_PATHS or name.startswith("licenses/")
    }


def read_zip(data):
    files = {}
    folded = set()
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for entry in archive.infolist():
            name = entry.filename[:-1] if entry.is_dir() else entry.filename
            safe_path(name)
            if name.casefold() in folded:
                raise ValueError(f"Duplicate archive path: {name}")
            folded.add(name.casefold())
            mode = entry.external_attr >> 16
            if stat.S_ISLNK(mode):
                raise ValueError(f"Archive symlink is forbidden: {name}")
            if stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR):
                raise ValueError(f"Archive special file is forbidden: {name}")
            if entry.flag_bits & 1:
                raise ValueError(f"Encrypted archive is forbidden: {name}")
            if not entry.is_dir():
                files[name] = archive.read(entry)
    return files


def write_zip(files):
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_STORED) as archive:
        for name, contents in sorted(files.items()):
            safe_path(name)
            entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            # Stored files avoid zlib-version-dependent compression differences.
            archive.writestr(entry, contents)
    return output.getvalue()


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root)


def metadata_from_source(files, commit, epoch):
    def required(name):
        if name not in files:
            raise ValueError(f"Source is missing {name}")
        return files[name].decode("utf-8-sig")

    config = required("moon.mod")
    for key, expected in (("name", MODULE), ("version", VERSION)):
        values = re.findall(rf'^\s*{key}\s*=\s*"([^"]+)"\s*$', config, re.MULTILINE)
        if values != [expected]:
            raise ValueError(f"Source {key} must be {expected}")
    if json.loads(required("playground/package.json")).get("version") != VERSION:
        raise ValueError(f"Playground version must be {VERSION}")
    compiler = required(".moon-version").strip()
    if not re.fullmatch(r"0\.10\.18\+[0-9a-f]+", compiler):
        raise ValueError("Source must pin the reviewed 0.10.18 compiler")
    unicode_version = json.loads(required("tools/data-generator/sources.json")).get("unicode_version")
    unicode_source = required("src/unicode/types.mbt")
    runtime_unicode = re.search(
        r"unicode_version\s*:\s*UnicodeVersion\s*=\s*\{\s*major:\s*(\d+),\s*minor:\s*(\d+),\s*update:\s*(\d+),?\s*\}",
        unicode_source,
    )
    if not runtime_unicode or ".".join(runtime_unicode.groups()) != unicode_version:
        raise ValueError("Unicode runtime version does not match the source manifest")
    if not re.fullmatch(r"[0-9a-f]{40,64}", commit):
        raise ValueError("Expected a complete commit hash")
    for name in LICENSE_PATHS:
        if not required(name).strip():
            raise ValueError(f"Empty license file: {name}")
    return {
        "schema": 1, "module": MODULE, "version": VERSION,
        "compiler_pin": compiler, "unicode_version": unicode_version,
        "commit": commit, "source_date_epoch": int(epoch),
    }


def read_source(root, revision):
    if git(root, "status", "--porcelain", "--untracked-files=all").strip():
        raise ValueError("Release requires a clean working tree, including untracked files")
    commit = git(root, "rev-parse", "--verify", "--end-of-options", f"{revision}^{{commit}}").decode().strip()
    head = git(root, "rev-parse", "HEAD").decode().strip()
    if commit != head:
        raise ValueError("Selected commit must equal HEAD; checkout the release commit before building")
    expected = set()
    for row in git(root, "ls-tree", "-r", "-z", commit).split(b"\0"):
        if not row:
            continue
        attributes, raw_name = row.split(b"\t", 1)
        mode, kind, _ = attributes.decode("ascii").split()
        name = raw_name.decode("utf-8")
        check_source_path(name)
        if kind != "blob" or mode not in ("100644", "100755"):
            raise ValueError(f"Source symlinks and submodules are forbidden: {name}")
        expected.add(name)
    files = read_zip(git(root, "archive", "--format=zip", commit))
    if set(files) != expected:
        raise ValueError("git archive differs from the commit tree (check export-ignore attributes)")
    epoch = git(root, "show", "-s", "--format=%ct", commit).decode().strip()
    return files, metadata_from_source(files, commit, epoch)


def validate_stamp(stamp, metadata, engine):
    for key in ("schema", "module", "version", "compiler_pin", "commit"):
        if stamp.get(key) != metadata[key]:
            raise ValueError(f"Build provenance mismatch: {key}")
    if stamp.get("dirty") is not False:
        raise ValueError("Build provenance must report dirty=false")
    compiler = stamp.get("compiler")
    if not isinstance(compiler, str) or not re.search(
        rf"\bv{re.escape(metadata['compiler_pin'])}(?:\s|$)", compiler,
    ):
        raise ValueError("Build compiler does not match the reviewed pin")
    if stamp.get("engine_sha256") != sha256(engine):
        raise ValueError("Build engine SHA-256 does not match its provenance")


def collect_site(directory):
    if not directory.is_dir() or directory.is_symlink():
        raise ValueError("Missing site build directory")
    files = {}
    for path in directory.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"Site symlink is forbidden: {path}")
        if path.is_file():
            name = path.relative_to(directory).as_posix()
            check_source_path(name)
            files[name] = path.read_bytes()
    if "index.html" not in files:
        raise ValueError("Site build is missing index.html")
    return files


def validate_site_files(site, metadata, added_licenses=()):
    if SITE_FILES not in site:
        raise ValueError("Site build is missing its stamped file manifest")
    manifest = json.loads(site[SITE_FILES])
    if manifest.get("schema") != 1 or manifest.get("commit") != metadata["commit"]:
        raise ValueError("Site file manifest must reference the release commit")
    hashes = manifest.get("files")
    if not isinstance(hashes, dict) or SITE_FILES in hashes:
        raise ValueError("Site file manifest must list files without a self-reference")
    for name, digest in hashes.items():
        safe_path(name)
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError(f"Invalid stamped site SHA-256: {name}")
        if name not in site or sha256(site[name]) != digest:
            raise ValueError(f"Stamped site SHA-256 mismatch: {name}")
    extra = set(site) - set(hashes) - {SITE_FILES}
    if extra - set(added_licenses):
        raise ValueError("Site contains files absent from its stamped manifest")


def assemble(source, metadata, engine, stamp_bytes, site):
    stamp = json.loads(stamp_bytes)
    validate_stamp(stamp, metadata, engine)
    if site.get(BUILD_INFO) != stamp_bytes:
        raise ValueError("Site and engine build provenance must be byte-identical")
    validate_site_files(site, metadata)
    for name in LICENSE_PATHS[2:]:
        if site.get(name) != source[name]:
            raise ValueError(f"Site license is missing or differs from source: {name}")
    licenses = license_files(source)
    for name, contents in licenses.items():
        if name in site and site[name] != contents:
            raise ValueError(f"Site notice differs from source: {name}")
    prefix = f"moonspoof-{VERSION}/"
    source_files = {prefix + name: contents for name, contents in source.items()}
    if prefix + BUILD_INFO in source_files:
        raise ValueError("Source already contains a reserved build-info.json")
    source_files[prefix + BUILD_INFO] = stamp_bytes
    engine_files = {"moonspoof.js": engine, BUILD_INFO: stamp_bytes, **licenses}
    site_files = {**site, **licenses}
    payloads = {"source": source_files, "engine": engine_files, "site": site_files}
    artifacts = {}
    blobs = {}
    for kind, files in payloads.items():
        name = f"moonspoof-{VERSION}-{kind}.zip"
        blob = write_zip(files)
        blobs[name] = blob
        artifacts[name] = {
            "kind": kind, "sha256": sha256(blob), "size": len(blob),
            "files": {name: sha256(contents) for name, contents in sorted(files.items())},
        }
    manifest = {
        **metadata,
        "compiler": stamp["compiler"],
        "licenses": {name: sha256(contents) for name, contents in licenses.items()},
        "artifacts": artifacts,
    }
    blobs[MANIFEST] = json_bytes(manifest)
    blobs[CHECKSUMS] = "".join(
        f"{sha256(blob)}  {name}\n" for name, blob in sorted(blobs.items())
    ).encode("ascii")
    return blobs


def create_release(root, revision="HEAD", output=None):
    root = Path(root).resolve()
    source, metadata = read_source(root, revision)
    actual_compiler = subprocess.check_output(["moonc", "-v"], text=True, encoding="utf-8").strip()
    engine_path = root / "playground/src/generated/moonspoof.js"
    stamp_path = engine_path.parent / BUILD_INFO
    if engine_path.is_symlink() or stamp_path.is_symlink():
        raise ValueError("Engine and provenance files cannot be symlinks")
    engine = engine_path.read_bytes()
    stamp_bytes = stamp_path.read_bytes()
    if json.loads(stamp_bytes).get("compiler") != actual_compiler:
        raise ValueError("Current compiler differs from the build provenance")
    blobs = assemble(source, metadata, engine, stamp_bytes, collect_site(root / "playground/dist"))
    # Refuse concurrent edits occurring while the inputs were read.
    _, final_metadata = read_source(root, revision)
    if final_metadata != metadata:
        raise ValueError("Source commit changed while packaging")
    destination = Path(output).resolve() if output else root / "_build/releases" / f"v{VERSION}"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.mkdir()  # Exclusive reservation; never overwrite an earlier release.
    for name, contents in blobs.items():
        with (destination / name).open("xb") as artifact:
            artifact.write(contents)
    verify_release(destination)
    return destination


def verify_release(directory):
    """Verify safe paths, checksums, source metadata and bundled original notices."""
    directory = Path(directory)
    checksums = {}
    for line in (directory / CHECKSUMS).read_text(encoding="ascii").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  ([^/\\]+)", line)
        if not match:
            raise ValueError("Invalid SHA256SUMS entry")
        digest, name = match.groups()
        safe_path(name)
        if name in checksums or name == CHECKSUMS:
            raise ValueError("Duplicate or recursive SHA256SUMS entry")
        checksums[name] = digest
    if MANIFEST not in checksums:
        raise ValueError("SHA256SUMS must cover the release manifest")
    for name, digest in checksums.items():
        path = directory / name
        if path.is_symlink() or sha256(path.read_bytes()) != digest:
            raise ValueError(f"SHA-256 mismatch: {name}")
    manifest = json.loads((directory / MANIFEST).read_bytes())
    if manifest.get("version") != VERSION or manifest.get("module") != MODULE or manifest.get("schema") != 1:
        raise ValueError("Unexpected release manifest metadata")
    artifacts = manifest.get("artifacts", {})
    expected_names = {f"moonspoof-{VERSION}-{kind}.zip" for kind in ("source", "engine", "site")}
    if set(artifacts) != expected_names or set(checksums) != expected_names | {MANIFEST}:
        raise ValueError("Release must contain exactly source, engine, site and manifest checksums")
    if {path.name for path in directory.iterdir()} != expected_names | {MANIFEST, CHECKSUMS}:
        raise ValueError("Release directory contains unexpected files")
    payloads = {}
    for name, record in artifacts.items():
        blob = (directory / name).read_bytes()
        kind = name.removeprefix(f"moonspoof-{VERSION}-").removesuffix(".zip")
        files = read_zip(blob)
        if record.get("kind") != kind or record.get("size") != len(blob) or record.get("sha256") != sha256(blob):
            raise ValueError(f"Artifact metadata mismatch: {name}")
        if record.get("files") != {entry: sha256(contents) for entry, contents in files.items()}:
            raise ValueError(f"Artifact entry hashes mismatch: {name}")
        payloads[kind] = files
    prefix = f"moonspoof-{VERSION}/"
    if not all(name.startswith(prefix) for name in payloads["source"]):
        raise ValueError("Source archive must use the release prefix")
    source = {name.removeprefix(prefix): contents for name, contents in payloads["source"].items()}
    for name in source:
        check_source_path(name)
    metadata = metadata_from_source(source, manifest["commit"], manifest["source_date_epoch"])
    if any(manifest.get(key) != value for key, value in metadata.items()):
        raise ValueError("Manifest disagrees with archived source metadata")
    if manifest.get("licenses") != {name: sha256(contents) for name, contents in license_files(source).items()}:
        raise ValueError("Manifest license hashes disagree with source")
    stamp_bytes = source.get(BUILD_INFO)
    for kind in ("engine", "site"):
        files = payloads[kind]
        if files.get(BUILD_INFO) != stamp_bytes:
            raise ValueError("Build provenance differs between artifacts")
        for name in license_files(source):
            if files.get(name) != source[name]:
                raise ValueError(f"Bundled license mismatch: {kind}/{name}")
    if "moonspoof.js" not in payloads["engine"] or "index.html" not in payloads["site"]:
        raise ValueError("Missing engine or site entry point")
    validate_stamp(json.loads(stamp_bytes), metadata, payloads["engine"]["moonspoof.js"])
    if manifest.get("compiler") != json.loads(stamp_bytes)["compiler"]:
        raise ValueError("Manifest compiler differs from build provenance")
    for name in payloads["site"]:
        check_source_path(name)
    validate_site_files(payloads["site"], metadata, added_licenses=license_files(source))
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--commit", default="HEAD", help="Tag or commit, which must resolve to checked-out HEAD")
    parser.add_argument("--output", type=Path, help="New output directory; existing paths are never overwritten")
    parser.add_argument("--verify", type=Path, metavar="DIR", help="Independently verify an existing release")
    args = parser.parse_args()
    try:
        if args.verify:
            manifest = verify_release(args.verify)
            print(f"Verified MoonSpoof {manifest['version']} ({manifest['commit']})")
        else:
            destination = create_release(Path(__file__).resolve().parent.parent, args.commit, args.output)
            print(f"Created and verified MoonSpoof {VERSION}: {destination}")
    except (ValueError, OSError, KeyError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Release packaging failed: {error}\n")


if __name__ == "__main__":
    main()
