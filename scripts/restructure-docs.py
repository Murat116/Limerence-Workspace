#!/usr/bin/env python3
"""Restructure Limerence docs to single source of truth."""
from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SPECS_OLD = DOCS / "_legacy_specs_import"


def import_legacy_specs():
    """Copy legacy specs tree before restructure."""
    sources = [
        ROOT / "mobile" / "Спецификация.bak",
        Path("/Users/anmin/iosProject/limerenceProject/LemereceRN/Спецификация"),
    ]
    if SPECS_OLD.exists():
        shutil.rmtree(SPECS_OLD)
    for src in sources:
        if src.exists() and not src.is_symlink():
            shutil.copytree(src, SPECS_OLD)
            return
    raise SystemExit("No legacy specs source found")

# Old path prefix -> new path (relative to workspace root)
PATH_MAPPING: list[tuple[str, str]] = [
    ("Спецификация/Логика геймлея/Сущности/", "docs/specs/gameplay/entities/"),
    ("Спецификация/Логика геймлея/", "docs/specs/gameplay/"),
    ("Спецификация/Логика геймплея/Полное описание геймплея.md", "docs/specs/gameplay/full-description.md"),
    ("Спецификация/Логика геймплея/Реестр файлов геймплея.md", "docs/specs/gameplay/file-registry.md"),
    ("Спецификация/Логика геймплея/Логика геймплея.md", "docs/specs/gameplay/overview.md"),
    ("Спецификация/Монетизация/Paywall.md", "docs/specs/monetization/paywall.md"),
    ("Спецификация/Аналитика события.md", "docs/specs/analytics-events.md"),
    ("Спецификация/Аналитика техническая.md", "docs/specs/analytics-technical.md"),
    ("Спецификация/Аналитика.md", "docs/specs/analytics-events.md"),
    ("Спецификация/Требования к версии приложения.md", "docs/specs/app-version.md"),
    ("Спецификация/Сетевые ошибки.md", "docs/specs/network-errors.md"),
    ("Спецификация/Техническая документация.md", "docs/specs/tech-architecture.md"),
    ("Спецификация/Спецификация проекта.md", "docs/specs/project-overview.md"),
]


def ensure_dirs():
    for d in [
        DOCS / "_meta",
        DOCS / "specs" / "gameplay" / "entities",
        DOCS / "specs" / "monetization",
        DOCS / "web",
    ]:
        d.mkdir(parents=True, exist_ok=True)


def move_if_exists(src: Path, dst: Path):
    if not src.exists():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        dst.unlink()
    shutil.move(str(src), str(dst))
    return True


def restructure():
    ensure_dirs()

    entities_src = SPECS_OLD / "Логика геймлея" / "Сущности"
    entities_dst = DOCS / "specs" / "gameplay" / "entities"
    if entities_src.exists():
        for f in entities_src.iterdir():
            if f.is_file():
                shutil.copy2(f, entities_dst / f.name)

    move_if_exists(
        SPECS_OLD / "Логика геймлея" / "Логика геймплея.md",
        DOCS / "specs" / "gameplay" / "overview.md",
    )
    move_if_exists(
        SPECS_OLD / "Логика геймплея" / "Полное описание геймплея.md",
        DOCS / "specs" / "gameplay" / "full-description.md",
    )
    move_if_exists(
        SPECS_OLD / "Логика геймплея" / "Реестр файлов геймплея.md",
        DOCS / "specs" / "gameplay" / "file-registry.md",
    )

    paywall_src = SPECS_OLD / "Монетизация" / "Paywall.md"
    if paywall_src.exists():
        shutil.copy2(paywall_src, DOCS / "specs" / "monetization" / "paywall.md")

    root_specs = {
        "Аналитика события.md": "analytics-events.md",
        "Аналитика техническая.md": "analytics-technical.md",
        "Требования к версии приложения.md": "app-version.md",
        "Сетевые ошибки.md": "network-errors.md",
        "Техническая документация.md": "tech-architecture.md",
        "Спецификация проекта.md": "project-overview.md",
    }
    for old_name, new_name in root_specs.items():
        src = SPECS_OLD / old_name
        if src.exists():
            shutil.copy2(src, DOCS / "specs" / new_name)

    constructor = DOCS / "constructor"
    web = DOCS / "web"
    if constructor.exists():
        for f in constructor.iterdir():
            if f.is_file():
                shutil.copy2(f, web / f.name)

    story_spec = DOCS / "constructor" / "story-constructor-spec.md"
    if not story_spec.exists():
        bak = ROOT / "web" / "Спецификация.bak" / "Конструктор историй.md"
        if bak.exists():
            shutil.copy2(bak, web / "story-constructor-spec.md")

    # Remove duplicate folders
    for p in [DOCS / "product", DOCS / "gameplay", DOCS / "constructor"]:
        if p.exists():
            shutil.rmtree(p)

    # Remove old legacy import
    if SPECS_OLD.exists():
        shutil.rmtree(SPECS_OLD)

    # Clean obsidian/ds_store from docs
    for p in DOCS.rglob(".obsidian"):
        if p.is_dir():
            shutil.rmtree(p)
    for p in DOCS.rglob(".DS_Store"):
        p.unlink(missing_ok=True)


def fix_doc_links(content: str, file_path: Path) -> str:
    """Fix common broken internal doc links after restructure."""
    rel = lambda t: os.path.relpath(ROOT / t, file_path.parent).replace("\\", "/")

    replacements = [
        (r"\[IOS_IMPL_PLAN\.md\]\(\../../docs/monetization/IOS_IMPL_PLAN\.md\)",
         f"[IOS_IMPL_PLAN.md]({rel('docs/monetization/IOS_IMPL_PLAN.md')})"),
        (r"\[Paywall-UI-UX\.md\]\(\./Paywall-UI-UX\.md\)",
         f"[paywall-ux.md]({rel('docs/specs/monetization/paywall-ux.md')})"),
        (r"\[WebBilling-RU\.md\]\(\./WebBilling-RU\.md\)",
         f"[RUSSIA_BILLING.md]({rel('docs/monetization/RUSSIA_BILLING.md')})"),
        (r"\[Глава\.md\]\(\../Логика%20геймлея/Сущности/Глава\.md\)",
         f"[Глава.md]({rel('docs/specs/gameplay/entities/Глава.md')})"),
        (r"\[Аналитика события\.md\]\(\../Аналитика%20события\.md\)",
         f"[analytics-events.md]({rel('docs/specs/analytics-events.md')})"),
        (r"Спецификация/Монетизация/Entitlements\.md",
         "docs/monetization/ENTITLEMENTS.md"),
        (r"Спецификация/Логика геймлея/", "docs/specs/gameplay/"),
        (r"Спецификация/Логика геймплея/", "docs/specs/gameplay/"),
        (r"`Спецификация/", "`docs/specs/"),
    ]
    for pat, repl in replacements:
        content = re.sub(pat, repl, content)
    return content


def patch_all_docs():
    for md in DOCS.rglob("*.md"):
        text = md.read_text(encoding="utf-8")
        new = fix_doc_links(text, md)
        if new != text:
            md.write_text(new, encoding="utf-8")


if __name__ == "__main__":
    os.chdir(ROOT)
    import_legacy_specs()
    restructure()
    patch_all_docs()
    print("Restructure complete.")
