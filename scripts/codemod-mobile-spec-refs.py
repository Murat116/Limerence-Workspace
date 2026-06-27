#!/usr/bin/env python3
"""Codemod @see Спецификация/ paths to docs/specs/ in mobile/src."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
MOBILE_SRC = ROOT / "mobile" / "src"

REPLACEMENTS = [
    ("Спецификация/Логика геймлея/Сущности/", "docs/specs/gameplay/entities/"),
    ("Спецификация/Логика геймплея/Сущности/", "docs/specs/gameplay/entities/"),
    ("Спецификация/Логика геймплея/Полное описание геймплея.md", "docs/specs/gameplay/full-description.md"),
    ("Спецификация/Логика геймплея/Реестр файлов геймплея.md", "docs/specs/gameplay/file-registry.md"),
    ("Спецификация/Логика геймлея/Логика геймплея.md", "docs/specs/gameplay/overview.md"),
    ("Спецификация/Логика геймлея/", "docs/specs/gameplay/"),
    ("Спецификация/Монетизация/Paywall.md", "docs/specs/monetization/paywall.md"),
    ("Спецификация/Аналитика события.md", "docs/specs/analytics-events.md"),
    ("Спецификация/Аналитика техническая.md", "docs/specs/analytics-technical.md"),
    ("Спецификация/Аналитика.md", "docs/specs/analytics-events.md"),
    ("Спецификация/Требования к версии приложения.md", "docs/specs/app-version.md"),
    ("Спецификация/Сетевые ошибки.md", "docs/specs/network-errors.md"),
    ("Спецификация/Техническая документация.md", "docs/specs/tech-architecture.md"),
    ("Спецификация/Спецификация проекта.md", "docs/specs/project-overview.md"),
]

count_files = 0
count_repl = 0

for path in MOBILE_SRC.rglob("*"):
    if path.suffix not in (".ts", ".tsx"):
        continue
    text = path.read_text(encoding="utf-8")
    new = text
    for old, new_path in REPLACEMENTS:
        if old in new:
            n = new.count(old)
            new = new.replace(old, new_path)
            count_repl += n
    if new != text:
        path.write_text(new, encoding="utf-8")
        count_files += 1

remaining = 0
for path in MOBILE_SRC.rglob("*"):
    if path.suffix in (".ts", ".tsx") and "Спецификация/" in path.read_text(encoding="utf-8"):
        remaining += 1
        print(f"REMAINING: {path}")

print(f"Updated {count_files} files, {count_repl} replacements")
print(f"Files still referencing Спецификация/: {remaining}")
