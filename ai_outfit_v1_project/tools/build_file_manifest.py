#!/usr/bin/env python3
"""重新生成 file_manifest.json。

排除生成目录（build / .dart_tool / 平台工程），只记录需要审阅的源码、文档、
测试、工具和验证报告。运行：python tools/build_file_manifest.py
"""

from __future__ import annotations

import hashlib
import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_DIRS = {
    ".git",
    ".dart_tool",
    "build",
    "android",
    "ios",
    "web",
    "__pycache__",
    ".idea",
    ".vscode",
    "coverage",
}
EXCLUDED_FILES = {"file_manifest.json"}
EXTRA_NAMES = {".gitignore", ".metadata", "pubspec.lock"}
EXTRA_SUFFIXES = {".dart", ".md", ".yaml", ".json", ".html", ".mjs", ".py", ".log", ".png"}


def main() -> None:
    files = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        if relative.as_posix() in EXCLUDED_FILES:
            continue
        if any(part in EXCLUDED_DIRS for part in relative.parts):
            continue
        if path.suffix not in EXTRA_SUFFIXES and path.name not in EXTRA_NAMES:
            continue
        data = path.read_bytes()
        files.append(
            {
                "path": relative.as_posix(),
                "bytes": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
            }
        )

    manifest = {
        "project": "ai-outfit-v1",
        "version": "v0.2.0",
        "generated_on": date.today().isoformat(),
        "notes": (
            "路径相对 ai_outfit_v1_project/。已排除 .dart_tool、build 与 "
            "android/ios/web 平台生成目录；Flutter 验证结果见 reports/。"
        ),
        "file_count": len(files),
        "files": files,
    }
    target = ROOT / "file_manifest.json"
    target.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {target} ({len(files)} files)")


if __name__ == "__main__":
    main()
