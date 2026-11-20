"""Check maintained Markdown, relative links and a few source-backed project facts.

Runs offline by default. Historical backups, caches and isolated test copies are
excluded. --external also reports HTTP reachability; it cannot validate content.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".godot", ".test-runs", "_archive", "node_modules", ".venv",
        "__pycache__", "build", "dist", "exports"}
FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})(.*)$")
HEADING = re.compile(r"^(#{1,6})\s+(.+?)\s*#*\s*$")
LINK = re.compile(r"!?\[[^\]\n]*\]\((<[^>]+>|[^\s)]+)(?:\s+[\"'][^)]*[\"'])?\)")
HTML_LINK = re.compile(r"(?:src|href)=[\"']([^\"']+)[\"']", re.I)


def documents() -> list[Path]:
    found = []
    for base, folders, files in os.walk(ROOT):
        folders[:] = [name for name in folders if name not in SKIP]
        found.extend(Path(base) / name for name in files if name.lower().endswith(".md"))
    return sorted(found)


def slug(text: str) -> str:
    text = re.sub(r"<[^>]*>", "", text).lower().replace("`", "")
    return re.sub(r"[^\w\-\s]", "", text, flags=re.UNICODE).replace(" ", "-")


def inspect(path: Path) -> tuple[list[str], list[tuple[int, str]], set[str]]:
    errors, links, anchors = [], [], set()
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        errors.append("UTF-8 BOM: normalize to UTF-8 without BOM")
    text = raw.decode("utf-8-sig")
    lines = text.splitlines()
    fence_char, fence_size, titles, previous_level = "", 0, 0, 0
    frontmatter = bool(lines and lines[0] == "---")
    heading_counts: dict[str, int] = {}
    for number, line in enumerate(lines, 1):
        if line.rstrip() != line:
            errors.append(f"{number}: trailing whitespace")
        if "\ufffd" in line:
            errors.append(f"{number}: Unicode replacement character")
        if frontmatter:
            if number > 1 and line == "---":
                frontmatter = False
            continue
        match = FENCE.match(line)
        if fence_char:
            if match and match[1][0] == fence_char and len(match[1]) >= fence_size and not match[2].strip():
                fence_char = ""
            continue
        if match:
            fence_char, fence_size = match[1][0], len(match[1])
            continue
        heading = HEADING.match(line)
        if heading:
            level = len(heading[1])
            titles += level == 1
            if previous_level and level > previous_level + 1:
                errors.append(f"{number}: heading level jumps from {previous_level} to {level}")
            previous_level = level
            if number > 1 and lines[number - 2].strip():
                errors.append(f"{number}: blank line required before heading")
            if number < len(lines) and lines[number].strip():
                errors.append(f"{number}: blank line required after heading")
            base = slug(heading[2])
            count = heading_counts.get(base, 0)
            anchors.add(base if count == 0 else f"{base}-{count}")
            heading_counts[base] = count + 1
        if re.match(r"^[-*+]\s+|^\d+\.\s+", line):
            prev = lines[number - 2] if number > 1 else ""
            if prev.strip() and not re.match(r"^\s*(?:[-*+]\s+|\d+\.\s+)", prev) and not prev.startswith(" "):
                errors.append(f"{number}: blank line required before list")
        without_code = re.sub(r"`+[^`]*`+", "", line)
        links.extend((number, m[1].strip("<>")) for m in LINK.finditer(without_code))
        links.extend((number, m[1]) for m in HTML_LINK.finditer(without_code))
    if fence_char:
        errors.append("unclosed fenced code block")
    if frontmatter:
        errors.append("unclosed YAML frontmatter")
    if titles != 1:
        errors.append(f"expected one H1, found {titles}")
    if not text.endswith("\n"):
        errors.append("missing final newline")
    if path.name == "SKILL.md":
        header = text.split("---", 2)[1] if lines and lines[0] == "---" else ""
        for key in ("name", "description"):
            if not re.search(rf"^{key}:\s*\S", header, re.M):
                errors.append(f"skill frontmatter missing {key}")
    return errors, links, anchors


def source_facts() -> list[str]:
    """Narrow drift guards; semantic claims still need human/code review."""
    errors = []
    game = (ROOT / "godot/scripts/GameData.gd").read_text(encoding="utf-8-sig")
    main = (ROOT / "godot/scripts/Main.gd").read_text(encoding="utf-8-sig")
    art = (ROOT / "godot/scripts/GuArt.gd").read_text(encoding="utf-8-sig")
    home = (ROOT / "README.md").read_text(encoding="utf-8-sig")
    details = (ROOT / "godot/README.md").read_text(encoding="utf-8-sig")
    width = re.search(r"const MAP_W := (\d+)", game)
    height = re.search(r"const MAP_H := (\d+)", game)
    version = re.search(r'"version":(\d+)', main)
    if not all((width, height, version)):
        return ["source facts: could not locate map dimensions or save version"]
    for name, body in (("README.md", home), ("godot/README.md", details)):
        if f"{width[1]}×{height[1]}" not in body:
            errors.append(f"{name}: map dimensions differ from source")
        if f"version {version[1]}" not in body:
            errors.append(f"{name}: save version differs from source")
    order = re.search(r"const GU_ORDER := \[([^\]]+)\]", game)
    if order is None:
        errors.append("source facts: could not locate GU_ORDER")
    else:
        for gu in re.findall(r'"([^"]+)"', order[1]):
            if not re.search(r'"'+re.escape(gu)+r'"\s*:\s*preload\s*\(',art):
                errors.append(f"GuArt missing formal Gu {gu}")
            if not (ROOT / f"godot/assets/gu/painted/{gu}.png").is_file():
                errors.append(f"painted PNG missing for {gu}")
    return errors


def remote_status(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 GudaoDocCheck/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            response.read(256)
            return {"url": url, "status": response.status, "reachable": True}
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        return {"url": url, "reachable": False, "error": str(exc)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--external", action="store_true", help="also check HTTP URLs (network reachability only)")
    parser.add_argument("--report", type=Path, help="write a JSON audit report")
    args = parser.parse_args()
    errors, catalog, external = [], {}, set()
    link_count = 0
    for path in documents():
        try:
            issues, links, anchors = inspect(path)
            catalog[path.resolve()] = (links, anchors)
            errors.extend(f"{path.relative_to(ROOT)}:{issue}" for issue in issues)
        except UnicodeError as exc:
            errors.append(f"{path.relative_to(ROOT)}: invalid UTF-8: {exc}")
    for path, (links, _) in catalog.items():
        for line, target in links:
            link_count += 1
            split = urllib.parse.urlsplit(target)
            if split.scheme in {"https", "http"}:
                external.add(urllib.parse.urldefrag(target)[0])
                continue
            if split.scheme:
                if split.scheme != "mailto":
                    errors.append(f"{path.relative_to(ROOT)}:{line}: nonportable link {target}")
                continue
            if target.startswith("/"):
                errors.append(f"{path.relative_to(ROOT)}:{line}: absolute local link {target}")
                continue
            dest = (path.parent / urllib.parse.unquote(split.path)).resolve() if split.path else path
            if not dest.exists():
                errors.append(f"{path.relative_to(ROOT)}:{line}: missing target {target}")
            elif dest.suffix.lower() == ".md" and split.fragment and dest in catalog:
                fragment = urllib.parse.unquote(split.fragment)
                if fragment not in catalog[dest][1]:
                    errors.append(f"{path.relative_to(ROOT)}:{line}: missing anchor {target}")
    errors.extend(source_facts())
    remote = []
    if args.external:
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            remote = list(pool.map(remote_status, sorted(external)))
    result = {"checked_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
              "documents": len(catalog), "links": link_count, "external_urls": len(external),
              "errors": errors, "remote": remote}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for error in errors:
        print("ERROR " + error)
    unreachable = [entry for entry in remote if not entry["reachable"]]
    for entry in unreachable:
        print("UNVERIFIED " + entry["url"] + " " + entry["error"])
    print(f"DOCS checked={len(catalog)} links={link_count} errors={len(errors)} external_unverified={len(unreachable)}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
