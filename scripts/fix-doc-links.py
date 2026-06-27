#!/usr/bin/env python3
"""Fix internal links in docs after restructure."""
from pathlib import Path

DOCS = Path(__file__).resolve().parent.parent / "docs"

REPLACEMENTS = [
    ("./Полное описание геймплея.md", "./full-description.md"),
    ("./Полное%20описание%20геймплея.md", "./full-description.md"),
    ("./Логика геймплея.md", "./overview.md"),
    ("./Логика%20геймплея.md", "./overview.md"),
    ("./Реестр файлов геймплея.md", "./file-registry.md"),
    ("./Сущности/", "./entities/"),
    ("../Монетизация/Paywall.md", "../monetization/paywall.md"),
    ("./Аналитика события.md", "../analytics-events.md"),
    ("./Аналитика%20события.md", "../analytics-events.md"),
    ("./Аналитика техническая.md", "../analytics-technical.md"),
    ("./Аналитика%20техническая.md", "../analytics-technical.md"),
    ("../Аналитика события.md", "../analytics-events.md"),
    ("../Аналитика%20события.md", "../analytics-events.md"),
    ("../Аналитика техническая.md", "../analytics-technical.md"),
    ("../Техническая документация.md", "../tech-architecture.md"),
    ("../Техническая%20документация.md", "../tech-architecture.md"),
    ("../Логика%20геймлея/Сущности/", "./entities/"),
    ("../Логика%20геймлея/", "./"),
    ("../../docs/monetization/", "../../monetization/"),
    ("../../src/", "../../../mobile/src/"),
    ("mobile/src/", "../../../mobile/src/"),
]

for md in DOCS.rglob("*.md"):
    text = md.read_text(encoding="utf-8")
    new = text
    for old, repl in REPLACEMENTS:
        new = new.replace(old, repl)
    if new != text:
        md.write_text(new, encoding="utf-8")

print("Links patched")
