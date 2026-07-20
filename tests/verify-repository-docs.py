#!/usr/bin/env python3
"""Verify repository documentation links and committed media without third-party packages."""

from __future__ import annotations

import html
import hashlib
import posixpath
import re
import struct
import subprocess
import sys
import urllib.parse
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MIB = 1024 * 1024
MAX_MARKDOWN_BYTES = MIB
MAX_CONFIG_BYTES = MIB
MAX_PNG_BYTES = 2 * MIB
MAX_GIF_BYTES = 8 * MIB
HASH_CHUNK_BYTES = 64 * 1024
GIF_EXPECTED_DELAY_COUNTS = {12: 29, 13: 30}
GIF_EXPECTED_DURATION_CS = 738
MEDIA = {
    "docs/media/room-407-cover.png": (
        (1280, 640),
        2,
        "58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980",
    ),
    "docs/screenshots/room-407-lobby.png": (
        (960, 540),
        6,
        "5e2b94ab74e8964036cab12f1eca7ac77759e2ca08f294eea0711658257ffed2",
    ),
    "docs/screenshots/room-407-bedroom.png": (
        (960, 540),
        6,
        "0d728fda807963afc35396713f0bc1993a7571ad189a8d00ff3a6a8e588292f4",
    ),
    "docs/screenshots/room-407-chase-entity.png": (
        (960, 540),
        6,
        "f62493b5c96e8853b1e474106dc99a1bb1fde5138ca0a7f68eed452e8d88312b",
    ),
    "docs/screenshots/room-407-ending-reveal.png": (
        (960, 540),
        6,
        "fdbc2f037e2990e2cdcce15390ed96b1a471fb7e4d75149177efa9dcb2aaae24",
    ),
}
GIF_PATH = "docs/screenshots/room-407-gameplay-tour.gif"
GIF_SHA256 = "04f0e5cf355280f4a62d19632803e9e368def752984e0ab4ab987bf2bfe8ac07"
REQUIRED_FILES = (
    ".editorconfig",
    ".github/workflows/ci.yml",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "README.md",
    "SECURITY.md",
    "docs/.gdignore",
    "docs/README.md",
    "docs/asset-credits.md",
    "docs/codebase-summary.md",
    "docs/deployment-guide.md",
    "docs/limitations.md",
    "docs/project-overview-pdr.md",
    "docs/release-v0.9.0.md",
    "docs/testing.md",
    "docs/vi/README.md",
    "tests/prepare-windows-release.ps1",
    "tests/verify-windows-release-packaging.ps1",
    "tests/verify-repository-docs.py",
)
LINK_RE = re.compile(r"\]\((?P<body>[^)\n]+)\)")
REFERENCE_DEFINITION_RE = re.compile(
    r"^\s{0,3}\[(?P<label>[^\]\n]+)\]:\s*(?P<body>.*)$"
)
REFERENCE_LINK_RE = re.compile(
    r"(?<!\\)!?\[(?P<text>(?:\\.|[^\]\n])*)\]"
    r"\[(?P<label>(?:\\.|[^\]\n])*)\]"
)
INLINE_IMAGE_LINK_RE = re.compile(
    r"(?<!\\)!\[[^\]\n]*\]\((?P<body>[^)\n]+)\)"
)
HTML_IMG_TAG_RE = re.compile(r"<img\b[^>]*>", re.IGNORECASE)
URI_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
REGULAR_INDEX_MODES = {"100644", "100755"}


class VerificationError(RuntimeError):
    """A deterministic repository documentation contract failure."""


def _git_index_entries() -> dict[str, tuple[str, str]]:
    output = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-files", "--stage", "-z"]
    )
    entries: dict[str, tuple[str, str]] = {}
    for record in output.split(b"\0"):
        if not record:
            continue
        try:
            metadata, raw_path = record.split(b"\t", 1)
            mode, object_id, stage = metadata.decode("ascii").split()
        except ValueError as error:
            raise VerificationError("malformed git index record") from error
        path = raw_path.decode("utf-8").replace("\\", "/")
        if stage != "0":
            raise VerificationError(f"unmerged git index entry: {path} (stage {stage})")
        if path in entries:
            raise VerificationError(f"duplicate git index entry: {path}")
        entries[path] = (mode, object_id)
    return entries


def _require_regular_index_entry(
    entries: dict[str, tuple[str, str]], relative: str, context: str
) -> tuple[str, str]:
    entry = entries.get(relative)
    if entry is None:
        raise VerificationError(f"required file is not indexed: {relative}")
    mode, object_id = entry
    if mode not in REGULAR_INDEX_MODES:
        raise VerificationError(
            f"{context}: index mode {mode} is not a regular file"
        )
    return mode, object_id


def _read_index_bytes_capped(
    entries: dict[str, tuple[str, str]],
    relative: str,
    limit: int,
    context: str,
) -> bytes:
    _, object_id = _require_regular_index_entry(entries, relative, context)
    raw_size = subprocess.check_output(
        ["git", "-C", str(ROOT), "cat-file", "-s", object_id]
    )
    try:
        size = int(raw_size.strip())
    except ValueError as error:
        raise VerificationError(f"{context}: invalid indexed blob size") from error
    if size > limit:
        raise VerificationError(
            f"{context}: indexed blob exceeds {limit}-byte size cap ({size} bytes)"
        )
    blob = subprocess.check_output(
        ["git", "-C", str(ROOT), "cat-file", "blob", object_id]
    )
    if len(blob) != size or len(blob) > limit:
        raise VerificationError(f"{context}: indexed blob size changed while reading")
    return blob


def _read_index_text_capped(
    entries: dict[str, tuple[str, str]],
    relative: str,
    limit: int,
    context: str,
) -> str:
    return _read_index_bytes_capped(entries, relative, limit, context).decode("utf-8")


def _read_index_hashed_bytes_capped(
    entries: dict[str, tuple[str, str]],
    relative: str,
    limit: int,
    context: str,
) -> tuple[bytes, str]:
    blob = _read_index_bytes_capped(entries, relative, limit, context)
    digest = hashlib.sha256()
    for offset in range(0, len(blob), HASH_CHUNK_BYTES):
        digest.update(blob[offset : offset + HASH_CHUNK_BYTES])
    return blob, digest.hexdigest()


def _verify_index_blob_self_checks(
    entries: dict[str, tuple[str, str]]
) -> None:
    readme_entry = _require_regular_index_entry(entries, "README.md", "README.md")
    editor_entry = _require_regular_index_entry(
        entries, ".editorconfig", ".editorconfig"
    )
    indexed_readme = _read_index_bytes_capped(
        entries, "README.md", MAX_MARKDOWN_BYTES, "README.md self-test"
    )
    indexed_editor = _read_index_bytes_capped(
        entries, ".editorconfig", MAX_CONFIG_BYTES, ".editorconfig self-test"
    )
    aliased_entries = {"README.md": editor_entry}
    aliased_readme = _read_index_bytes_capped(
        aliased_entries,
        "README.md",
        MAX_MARKDOWN_BYTES,
        "aliased README index-blob self-test",
    )
    if aliased_readme != indexed_editor or aliased_readme == indexed_readme:
        raise VerificationError(
            "index-blob self-test did not follow the staged object id"
        )

    symlink_entries = {"README.md": ("120000", readme_entry[1])}
    try:
        _read_index_bytes_capped(
            symlink_entries,
            "README.md",
            MAX_MARKDOWN_BYTES,
            "symlink-mode self-test",
        )
    except VerificationError as error:
        if "index mode 120000 is not a regular file" in str(error):
            return
        raise
    raise VerificationError("index-mode self-test accepted a staged symlink")


def _read_subblocks(blob: bytes, offset: int, context: str) -> int:
    while True:
        if offset >= len(blob):
            raise VerificationError(f"{context}: truncated GIF sub-block stream")
        size = blob[offset]
        offset += 1
        if size == 0:
            return offset
        if offset + size > len(blob):
            raise VerificationError(f"{context}: out-of-bounds GIF sub-block")
        offset += size


def verify_gif_bytes(
    blob: bytes,
    context: str,
    expected_size: tuple[int, int],
    expected_frames: int,
) -> None:
    if len(blob) < 14 or blob[:6] not in {b"GIF87a", b"GIF89a"}:
        raise VerificationError(f"{context}: invalid GIF header")
    width, height = struct.unpack("<HH", blob[6:10])
    if (width, height) != expected_size:
        raise VerificationError(f"{context}: expected {expected_size}, got {(width, height)}")
    packed = blob[10]
    offset = 13
    if packed & 0x80:
        offset += 3 * (2 ** ((packed & 0x07) + 1))
    frames = 0
    delays: list[int] = []
    while offset < len(blob):
        marker = blob[offset]
        offset += 1
        if marker == 0x3B:
            if offset != len(blob):
                raise VerificationError(f"{context}: trailing bytes after GIF trailer")
            if frames != expected_frames:
                raise VerificationError(
                    f"{context}: expected {expected_frames} frames, got {frames}"
                )
            if len(delays) != expected_frames:
                raise VerificationError(
                    f"{context}: expected a graphics-control delay for every frame"
                )
            delay_counts = {delay: delays.count(delay) for delay in set(delays)}
            if delay_counts != GIF_EXPECTED_DELAY_COUNTS:
                raise VerificationError(
                    f"{context}: unexpected GIF delay distribution {delay_counts}"
                )
            if sum(delays) != GIF_EXPECTED_DURATION_CS:
                raise VerificationError(
                    f"{context}: unexpected GIF duration {sum(delays)} centiseconds"
                )
            return
        if marker == 0x21:
            if offset >= len(blob):
                raise VerificationError(f"{context}: truncated GIF extension")
            extension_label = blob[offset]
            offset += 1
            if extension_label == 0xFF:
                raise VerificationError(
                    f"{context}: must not contain a GIF application extension"
                )
            if extension_label == 0xF9:
                if offset + 6 > len(blob):
                    raise VerificationError(
                        f"{context}: truncated graphics-control extension"
                    )
                if blob[offset] != 4 or blob[offset + 5] != 0:
                    raise VerificationError(
                        f"{context}: invalid graphics-control extension"
                    )
                delays.append(struct.unpack("<H", blob[offset + 2 : offset + 4])[0])
                offset += 6
                continue
            offset = _read_subblocks(blob, offset, context)
            continue
        if marker != 0x2C or offset + 9 > len(blob):
            raise VerificationError(f"{context}: invalid or truncated GIF block")
        image_packed = blob[offset + 8]
        offset += 9
        if image_packed & 0x80:
            offset += 3 * (2 ** ((image_packed & 0x07) + 1))
        if offset >= len(blob):
            raise VerificationError(f"{context}: missing GIF LZW code size")
        offset += 1
        offset = _read_subblocks(blob, offset, context)
        frames += 1
    raise VerificationError(f"{context}: missing GIF trailer")


def verify_png_bytes(
    blob: bytes,
    context: str,
    expected_size: tuple[int, int],
    expected_color_type: int,
) -> None:
    signature = b"\x89PNG\r\n\x1a\n"
    if len(blob) < 33 or blob[:8] != signature:
        raise VerificationError(f"{context}: invalid PNG signature or truncated header")

    offset = len(signature)
    ihdr: bytes | None = None
    idat_chunks: list[bytes] = []
    seen_idat = False
    idat_closed = False
    seen_iend = False
    chunk_index = 0
    while offset < len(blob):
        if len(blob) - offset < 12:
            raise VerificationError(f"{context}: truncated PNG chunk")
        length = struct.unpack(">I", blob[offset : offset + 4])[0]
        chunk_type = blob[offset + 4 : offset + 8]
        data_start = offset + 8
        data_end = data_start + length
        chunk_end = data_end + 4
        if chunk_end > len(blob):
            raise VerificationError(f"{context}: out-of-bounds PNG chunk")
        chunk_data = blob[data_start:data_end]
        expected_crc = struct.unpack(">I", blob[data_end:chunk_end])[0]
        actual_crc = zlib.crc32(chunk_data, zlib.crc32(chunk_type)) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            raise VerificationError(f"{context}: bad {chunk_type!r} CRC")

        if chunk_index == 0 and (chunk_type != b"IHDR" or length != 13):
            raise VerificationError(f"{context}: PNG must begin with one 13-byte IHDR")
        if chunk_type == b"IHDR":
            if chunk_index != 0 or ihdr is not None or length != 13:
                raise VerificationError(f"{context}: invalid IHDR layout")
            ihdr = chunk_data
        elif chunk_type == b"IDAT":
            if ihdr is None or idat_closed:
                raise VerificationError(f"{context}: non-contiguous IDAT stream")
            seen_idat = True
            idat_chunks.append(chunk_data)
        else:
            if seen_idat:
                idat_closed = True
            if chunk_type == b"IEND":
                if length != 0:
                    raise VerificationError(f"{context}: non-empty IEND")
                seen_iend = True
            elif chunk_type != b"PLTE" and (chunk_type[0] & 0x20) == 0:
                raise VerificationError(f"{context}: unknown critical chunk {chunk_type!r}")

        offset = chunk_end
        chunk_index += 1
        if seen_iend:
            if offset != len(blob):
                raise VerificationError(f"{context}: trailing bytes after IEND")
            break

    if ihdr is None or not seen_idat or not seen_iend:
        raise VerificationError(f"{context}: missing IHDR, IDAT, or IEND")
    width, height, depth, color, compression, filtering, interlace = struct.unpack(
        ">IIBBBBB", ihdr
    )
    if (width, height) != expected_size:
        raise VerificationError(f"{context}: expected {expected_size}, got {(width, height)}")
    if (depth, color, compression, filtering, interlace) != (
        8,
        expected_color_type,
        0,
        0,
        0,
    ):
        raise VerificationError(f"{context}: unexpected PNG encoding")

    channels = 3 if color == 2 else 4
    expected_decoded_size = height * (1 + width * channels)
    decoder = zlib.decompressobj()
    decoded = bytearray()
    for compressed in idat_chunks:
        remaining = expected_decoded_size + 1 - len(decoded)
        decoded.extend(decoder.decompress(compressed, remaining))
        if len(decoded) > expected_decoded_size or decoder.unconsumed_tail:
            raise VerificationError(f"{context}: image stream exceeds declared dimensions")
    decoded.extend(decoder.flush(expected_decoded_size + 1 - len(decoded)))
    if not decoder.eof or decoder.unused_data or len(decoded) != expected_decoded_size:
        raise VerificationError(f"{context}: invalid or mismatched image stream")
    row_stride = 1 + width * channels
    if any(decoded[row * row_stride] > 4 for row in range(height)):
        raise VerificationError(f"{context}: invalid PNG row filter")


def _verify_public_media_allowlist(indexed_paths: set[str]) -> None:
    expected_media = set(MEDIA) | {GIF_PATH}
    tracked_media = {
        item
        for item in indexed_paths
        if item.startswith(("docs/media/", "docs/screenshots/"))
    }
    if tracked_media != expected_media:
        missing = sorted(expected_media - tracked_media)
        unbound = sorted(tracked_media - expected_media)
        raise VerificationError(
            f"public media allowlist drift (missing={missing}, unbound={unbound})"
        )


def _verify_media_allowlist_self_checks() -> None:
    expected_media = set(MEDIA) | {GIF_PATH}
    _verify_public_media_allowlist(expected_media)
    try:
        _verify_public_media_allowlist(
            expected_media | {"docs/screenshots/unreviewed.jpg"}
        )
    except VerificationError:
        return
    raise VerificationError(
        "negative media allowlist self-test accepted an unexpected extension"
    )


def verify_media(entries: dict[str, tuple[str, str]]) -> None:
    indexed_paths = set(entries)
    _verify_media_allowlist_self_checks()
    _verify_public_media_allowlist(indexed_paths)

    cover_blob: bytes | None = None
    for relative, (dimensions, color_type, expected_hash) in MEDIA.items():
        blob, actual_hash = _read_index_hashed_bytes_capped(
            entries, relative, MAX_PNG_BYTES, relative
        )
        if actual_hash != expected_hash:
            raise VerificationError(f"{relative}: SHA-256 drift ({actual_hash})")
        verify_png_bytes(blob, relative, dimensions, color_type)
        if relative == "docs/media/room-407-cover.png":
            cover_blob = blob

    gif_blob, gif_hash = _read_index_hashed_bytes_capped(
        entries, GIF_PATH, MAX_GIF_BYTES, GIF_PATH
    )
    if gif_hash != GIF_SHA256:
        raise VerificationError(f"{GIF_PATH}: SHA-256 drift ({gif_hash})")
    verify_gif_bytes(gif_blob, GIF_PATH, (640, 360), 59)

    if cover_blob is None:
        raise VerificationError("cover was not checked by the media allowlist")
    for label, malformed in (
        ("truncated cover", cover_blob[:24]),
        ("trailing cover bytes", cover_blob + b"x"),
        ("bad cover CRC", cover_blob[:20] + bytes([cover_blob[20] ^ 1]) + cover_blob[21:]),
    ):
        try:
            verify_png_bytes(malformed, label, (1280, 640), 2)
        except VerificationError:
            continue
        raise VerificationError(f"negative media self-test unexpectedly accepted {label}")


def _markdown_paths(entries: dict[str, tuple[str, str]]) -> list[str]:
    return sorted(item for item in entries if item.lower().endswith(".md"))


def _non_fenced_lines(text: str, context: str):
    fence: tuple[str, int] | None = None
    for line_number, line in enumerate(text.splitlines(), 1):
        match = re.match(r"^\s*(?P<fence>`{3,}|~{3,})(?P<rest>.*)$", line)
        if match:
            token = match.group("fence")
            marker = token[0]
            if fence is None:
                fence = (marker, len(token))
            elif (
                fence[0] == marker
                and len(token) >= fence[1]
                and not match.group("rest").strip()
            ):
                fence = None
            continue
        if fence is None:
            yield line_number, line
    if fence is not None:
        raise VerificationError(f"{context}: unclosed Markdown code fence")


def _extract_link_target(body: str) -> str:
    body = body.strip()
    if body.startswith("<") and ">" in body:
        target = body[1 : body.index(">")]
    else:
        target = body.split(maxsplit=1)[0] if body else ""
    return target.replace("\\ ", " ")


def _is_readme_gif_target(body: str) -> bool:
    target = html.unescape(_extract_link_target(body)).replace("\\", "/")
    parsed = urllib.parse.urlsplit(target)
    if parsed.scheme or parsed.netloc:
        return False
    decoded_path = urllib.parse.unquote(parsed.path).replace("\\", "/")
    normalized = posixpath.normpath(decoded_path)
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized == GIF_PATH


def _normalize_reference_label(label: str) -> str:
    return " ".join(label.split()).casefold()


def _markdown_targets(
    text: str, context: str
) -> tuple[list[tuple[int, str]], list[str]]:
    lines = list(_non_fenced_lines(text, context))
    definitions: dict[str, tuple[int, str]] = {}
    definition_lines: set[int] = set()
    targets: list[tuple[int, str]] = []
    issues: list[str] = []

    for line_number, line in lines:
        definition = REFERENCE_DEFINITION_RE.match(line)
        if definition and not definition.group("label").lstrip().startswith("^"):
            definition_lines.add(line_number)
            label = _normalize_reference_label(definition.group("label"))
            target = _extract_link_target(definition.group("body"))
            if not label:
                issues.append(f"{line_number}: empty reference label")
            elif not target:
                issues.append(
                    f"{line_number}: empty reference definition target: "
                    f"{definition.group('label')}"
                )
            else:
                definitions.setdefault(label, (line_number, target))
                targets.append((line_number, target))
            continue

        for match in LINK_RE.finditer(line):
            target = _extract_link_target(match.group("body"))
            if target:
                targets.append((line_number, target))

    for line_number, line in lines:
        if line_number in definition_lines:
            continue
        for reference in REFERENCE_LINK_RE.finditer(line):
            raw_label = reference.group("label") or reference.group("text")
            label = _normalize_reference_label(raw_label)
            if not label or label not in definitions:
                issues.append(f"{line_number}: undefined reference: {raw_label}")

    return targets, issues


def _target_is_indexed(
    relative: str, is_directory: bool, indexed_paths: set[str]
) -> bool:
    if relative in indexed_paths:
        return True
    if not is_directory:
        return False
    prefix = "" if relative == "." else relative.rstrip("/") + "/"
    return any(item.startswith(prefix) for item in indexed_paths)


def _verify_markdown_self_checks() -> None:
    fixture = """[inline](inline.md)
[explicit][report]
[collapsed][]
[report]: staged/report.md "Report"
[collapsed]: <docs/>
"""
    targets, issues = _markdown_targets(fixture, "reference-link self-test")
    if issues or targets != [
        (1, "inline.md"),
        (4, "staged/report.md"),
        (5, "docs/"),
    ]:
        raise VerificationError("Markdown reference-link self-test failed")

    _, missing_issues = _markdown_targets(
        "[missing][not-defined]\n", "undefined-reference self-test"
    )
    if missing_issues != ["1: undefined reference: not-defined"]:
        raise VerificationError(
            "negative Markdown self-test unexpectedly accepted an undefined reference"
        )

    indexed_fixture = {"tracked.md", "docs/child.md"}
    if (
        not _target_is_indexed("tracked.md", False, indexed_fixture)
        or not _target_is_indexed("docs", True, indexed_fixture)
        or _target_is_indexed("untracked.md", False, indexed_fixture)
    ):
        raise VerificationError("Git-index target self-test failed")


def verify_local_links(entries: dict[str, tuple[str, str]]) -> None:
    _verify_markdown_self_checks()
    indexed_paths = set(entries)
    failures: list[str] = []
    for source in _markdown_paths(entries):
        text = _read_index_text_capped(
            entries, source, MAX_MARKDOWN_BYTES, source
        )
        targets, parse_issues = _markdown_targets(text, source)
        failures.extend(f"{source}:{issue}" for issue in parse_issues)
        for line_number, target in targets:
            # Same-document anchors and external URLs are intentionally out of scope.
            if target.startswith("#") or target.startswith("//"):
                continue
            if URI_SCHEME_RE.match(target):
                continue
            path_text = urllib.parse.unquote(target.split("#", 1)[0].split("?", 1)[0])
            if not path_text:
                continue
            path_text = path_text.replace("\\", "/")
            base = "" if path_text.startswith("/") else posixpath.dirname(source)
            relative = posixpath.normpath(
                posixpath.join(base, path_text.lstrip("/"))
            )
            if relative == ".." or relative.startswith("../") or posixpath.isabs(relative):
                failures.append(f"{source}:{line_number}: outside repo: {target}")
                continue
            if relative in entries:
                try:
                    _require_regular_index_entry(entries, relative, target)
                except VerificationError as error:
                    failures.append(f"{source}:{line_number}: {error}")
                continue
            if not _target_is_indexed(relative, True, indexed_paths):
                failures.append(f"{source}:{line_number}: not indexed: {target}")
    if failures:
        raise VerificationError("broken local Markdown links:\n" + "\n".join(failures))


def verify_document_contracts(entries: dict[str, tuple[str, str]]) -> None:
    for relative in REQUIRED_FILES:
        limit = MAX_MARKDOWN_BYTES if relative.lower().endswith(".md") else MAX_CONFIG_BYTES
        blob = _read_index_bytes_capped(entries, relative, limit, relative)
        if not blob:
            raise VerificationError(f"missing or empty required file: {relative}")
    readme = _read_index_text_capped(
        entries, "README.md", MAX_MARKDOWN_BYTES, "README.md"
    )
    credits = _read_index_text_capped(
        entries,
        "docs/asset-credits.md",
        MAX_MARKDOWN_BYTES,
        "docs/asset-credits.md",
    )
    presets = _read_index_text_capped(
        entries,
        "export_presets.cfg",
        MAX_CONFIG_BYTES,
        "export_presets.cfg",
    )
    docs_hub = _read_index_text_capped(
        entries, "docs/README.md", MAX_MARKDOWN_BYTES, "docs/README.md"
    )
    release_guide = _read_index_text_capped(
        entries,
        "docs/release-v0.9.0.md",
        MAX_MARKDOWN_BYTES,
        "docs/release-v0.9.0.md",
    )
    vietnamese_guide = _read_index_text_capped(
        entries,
        "docs/vi/README.md",
        MAX_MARKDOWN_BYTES,
        "docs/vi/README.md",
    )
    for required_reference in (
        "SECURITY.md",
        "CONTRIBUTING.md",
        "docs/media/room-407-cover.png",
        "docs/README.md",
        "docs/release-v0.9.0.md",
        "docs/vi/README.md",
        "PDR-07",
    ):
        if required_reference not in readme:
            raise VerificationError(f"README is missing required reference: {required_reference}")
    for screenshot_path in (
        path for path in MEDIA if path.startswith("docs/screenshots/")
    ):
        if screenshot_path not in readme:
            raise VerificationError(
                f"README is missing staged screenshot reference: {screenshot_path}"
            )
    required_gif_link = (
        "[Open the 7.38-second visual-reference tour (GIF; plays once)]"
        f"({GIF_PATH})"
    )
    if required_gif_link not in readme:
        raise VerificationError("README is missing the finite visual-reference GIF link")
    readme_lines = list(_non_fenced_lines(readme, "README.md"))
    readme_body = "\n".join(line for _, line in readme_lines)
    reference_targets = {
        _normalize_reference_label(definition.group("label")): _extract_link_target(
            definition.group("body")
        )
        for _, line in readme_lines
        if (definition := REFERENCE_DEFINITION_RE.match(line))
        and not definition.group("label").lstrip().startswith("^")
    }
    for _, line in readme_lines:
        if any(
            _is_readme_gif_target(match.group("body"))
            for match in INLINE_IMAGE_LINK_RE.finditer(line)
        ):
            raise VerificationError(
                "README must link to, not autoplay-embed, the visual-reference GIF"
            )
        for reference in REFERENCE_LINK_RE.finditer(line):
            if not reference.group(0).startswith("!"):
                continue
            raw_label = reference.group("label") or reference.group("text")
            target = reference_targets.get(_normalize_reference_label(raw_label))
            if target and _is_readme_gif_target(target):
                raise VerificationError(
                    "README must not reference-style embed the visual-reference GIF"
                )
    if HTML_IMG_TAG_RE.search(readme_body):
        raise VerificationError(
            "README must use Markdown images rather than HTML image tags"
        )
    if "plays once" not in readme:
        raise VerificationError("README does not disclose finite visual-reference GIF playback")
    cover_hash = MEDIA["docs/media/room-407-cover.png"][2]
    if "docs/media/room-407-cover.png" not in credits or cover_hash not in credits:
        raise VerificationError("asset credits do not bind the repository cover path and hash")
    if "docs/*" not in presets:
        raise VerificationError("export preset no longer excludes documentation media")
    for required_reference in (
        "release-v0.9.0.md",
        "vi/README.md",
        "Treat English technical documents",
    ):
        if required_reference not in docs_hub:
            raise VerificationError(
                f"documentation hub is missing required release/i18n reference: {required_reference}"
            )
    for required_release_detail in (
        "room-407-the-last-shift-windows-x86_64-v0.9.0.zip",
        "room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt",
        "Get-FileHash",
        "SmartScreen",
        "unsigned",
        "pre-release",
        "ROOM-407-THE-LAST-SHIFT-v0.9.0",
    ):
        if required_release_detail not in release_guide:
            raise VerificationError(
                f"release guide is missing required distribution detail: {required_release_detail}"
            )
    for required_vietnamese_detail in (
        "Hướng dẫn tiếng Việt",
        "GitHub Release v0.9.0",
        "Get-FileHash",
        "SmartScreen",
        "human physical/perceptual playtest",
    ):
        if required_vietnamese_detail not in vietnamese_guide:
            raise VerificationError(
                f"Vietnamese guide is missing required player-facing detail: {required_vietnamese_detail}"
            )


def main() -> int:
    try:
        entries = _git_index_entries()
        _verify_index_blob_self_checks(entries)
        verify_document_contracts(entries)
        verify_media(entries)
        print("REPOSITORY_MEDIA_OK")
        verify_local_links(entries)
        print("MARKDOWN_LOCAL_LINKS_OK")
        print("MARKDOWN_INDEXED_LOCAL_LINKS_OK")
    except (
        OSError,
        UnicodeDecodeError,
        subprocess.CalledProcessError,
        VerificationError,
        zlib.error,
    ) as error:
        print(f"REPOSITORY_DOCS_VERIFY_FAILED: {error}", file=sys.stderr)
        return 1
    print("PRO_DOCS_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
