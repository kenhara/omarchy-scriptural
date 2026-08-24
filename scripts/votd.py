#!/usr/bin/env python3
"""Scriptural — Midvash verse of the day (no auth).

CLI for Omarchy / omarchy-shell bar-widget.
User-Agent version is read from manifest.json (fallback 0.1.5).

Unofficial. Not affiliated with Midvash or any Bible publisher.
Copyrighted translations (ESV/NIV/…) are for personal display via public API.
VOTD calendar day is UTC (same verse worldwide for a given UTC date).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

VOTD_URL = "https://api.midvash.com/v1/votd"
VERSIONS_URL = "https://api.midvash.com/v1/versions"
PLUGIN_ID = "kenhara.scriptural"

# Midvash sometimes returns Portuguese error strings — map to English for UI.
_PT_ERROR_MAP = [
    (re.compile(r"vers[aã]o\s+n[aã]o\s+encontrada", re.I), "Version not found"),
    (re.compile(r"idioma\s+n[aã]o\s+encontrad", re.I), "Language not found"),
    (re.compile(r"texto\s+n[aã]o\s+encontrad", re.I), "Text not found"),
    (re.compile(r"n[aã]o\s+encontrad", re.I), "Not found"),
]


def read_manifest_version() -> str:
    try:
        manifest = Path(__file__).resolve().parent.parent / "manifest.json"
        data = json.loads(manifest.read_text(encoding="utf-8"))
        ver = str(data.get("version") or "").strip()
        if ver:
            return ver
    except Exception:
        pass
    return "0.1.6"


VERSION = read_manifest_version()
USER_AGENT = f"Scriptural/{VERSION} (Omarchy unofficial; {PLUGIN_ID})"

COMMON_VERSIONS = ("web", "kjv", "esv", "niv", "nkjv", "nlt", "msg")


def emit(obj: dict[str, Any], exit_code: int = 0) -> None:
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()
    raise SystemExit(exit_code)


def today_iso() -> str:
    """UTC calendar day — Midvash VOTD key; matches ScripturalStore.todayIso()."""
    return datetime.now(timezone.utc).date().isoformat()


def english_error(detail: Any) -> str:
    """Map Portuguese Midvash messages to generic English; keep useful slug suffix."""
    raw = str(detail or "").strip()
    if not raw:
        return "fetch failed"
    for pat, eng in _PT_ERROR_MAP:
        if pat.search(raw):
            if ":" in raw:
                suffix = raw.split(":", 1)[1].strip()
                if suffix and eng.endswith("not found"):
                    return f"{eng}: {suffix}"
            return eng
    # Non-ASCII / likely localized — don't toast Portuguese to English UI
    if any(ord(c) > 127 for c in raw):
        return "Request failed"
    return raw


def http_get_json(url: str, timeout: float = 30.0) -> tuple[int, Any, str]:
    # One HTTP call per CLI process — no inter-call rate limit needed.
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
    }
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            code = getattr(resp, "status", 200) or 200
            try:
                return code, json.loads(raw) if raw else {}, raw
            except json.JSONDecodeError:
                return code, {"_raw": raw}, raw
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace") if e.fp else ""
        try:
            parsed = json.loads(raw) if raw else {"error": str(e.reason)}
        except json.JSONDecodeError:
            parsed = {"_raw": raw or str(e.reason)}
        return int(e.code), parsed, raw
    except Exception as e:
        return 0, {"error": str(e)}, str(e)


def normalize_version(slug: str) -> str:
    s = str(slug or "web").strip().lower()
    return s or "web"


def normalize_language(lang: str) -> str:
    s = str(lang or "en").strip().lower()
    return s or "en"


def sanitize_https_url(url: str) -> str:
    """Only allow https: URLs from remote payload."""
    u = str(url or "").strip()
    if u.lower().startswith("https://"):
        return u
    return ""


def build_ok(payload: dict[str, Any], version: str, language: str) -> dict[str, Any]:
    ref = str(payload.get("reference") or "").strip()
    text = str(payload.get("text") or "").strip()
    ver = str(payload.get("version") or version).strip().lower() or version
    url = sanitize_https_url(payload.get("url") or "")
    return {
        "ok": True,
        "reference": ref,
        "text": text,
        "version": ver,
        "language": language,
        "url": url,
        "date": today_iso(),
        "book_slug": payload.get("book_slug") or "",
        "chapter": payload.get("chapter"),
        "verse_start": payload.get("verse_start"),
        "verse_end": payload.get("verse_end"),
        "fetchedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "error": "",
    }


def fail(
    msg: str,
    *,
    version: str = "web",
    language: str = "en",
    code: int = 1,
    raw: str = "",
) -> None:
    eng = english_error(msg)
    out: dict[str, Any] = {
        "ok": False,
        "reference": "",
        "text": "",
        "version": version,
        "language": language,
        "url": "",
        "date": today_iso(),
        "error": eng,
    }
    detail = str(raw or msg or "").strip()
    if detail and detail != eng:
        out["error_detail"] = detail
    emit(out, exit_code=code)


def fetch_votd(version: str, language: str) -> None:
    qs = urllib.parse.urlencode({"language": language, "version": version})
    url = f"{VOTD_URL}?{qs}"
    code, data, raw = http_get_json(url)
    if code == 0:
        fail(
            f"network error: {data.get('error') if isinstance(data, dict) else data}",
            version=version,
            language=language,
        )
    if code < 200 or code >= 300:
        detail = ""
        if isinstance(data, dict):
            detail = str(data.get("error") or data.get("message") or data.get("_raw") or "")
        fail(
            detail or f"HTTP {code}",
            version=version,
            language=language,
            raw=detail or raw,
        )
    if not isinstance(data, dict):
        fail("unexpected response shape", version=version, language=language)
    if not str(data.get("text") or "").strip() and not str(data.get("reference") or "").strip():
        fail("empty verse payload", version=version, language=language)
    emit(build_ok(data, version=version, language=language), exit_code=0)


def list_versions(language: str) -> None:
    qs = urllib.parse.urlencode({"language": language})
    url = f"{VERSIONS_URL}?{qs}"
    code, data, _raw = http_get_json(url)
    if code == 0 or code < 200 or code >= 300 or not isinstance(data, dict):
        fail(
            f"versions fetch failed (HTTP {code})",
            version="web",
            language=language,
        )
    rows = data.get("data") if isinstance(data.get("data"), list) else []
    out = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        slug = str(row.get("slug") or "").strip().lower()
        if not slug:
            continue
        out.append(
            {
                "slug": slug,
                "name": row.get("name") or slug,
                "shortName": row.get("shortName") or slug.upper(),
                "copyright": row.get("copyright") or "",
            }
        )
    emit(
        {
            "ok": True,
            "language": language,
            "versions": out,
            "common": list(COMMON_VERSIONS),
            "date": today_iso(),
            "error": "",
        },
        exit_code=0,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scriptural — Midvash verse of the day (unofficial, no auth)"
    )
    parser.add_argument(
        "--version",
        default="web",
        help="Bible version slug (default: web)",
    )
    parser.add_argument(
        "--language",
        default="en",
        help="Language code (default: en; MVP English-only)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not call the network; emit structured error JSON",
    )
    parser.add_argument(
        "--list-versions",
        action="store_true",
        help="List English versions from Midvash instead of VOTD",
    )
    args = parser.parse_args()
    version = normalize_version(args.version)
    language = normalize_language(args.language)

    if args.dry_run:
        fail("dry-run: no network", version=version, language=language, code=2)

    if args.list_versions:
        list_versions(language)
        return

    fetch_votd(version, language)


if __name__ == "__main__":
    main()
