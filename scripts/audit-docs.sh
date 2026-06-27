#!/usr/bin/env bash
# Audit markdown documentation across Limerence-Workspace
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Markdown inventory ==="
find docs mobile web -name '*.md' 2>/dev/null | grep -v node_modules | grep -v '.bak' | sort | tee /tmp/limerence-docs-list.txt | wc -l

echo ""
echo "=== MD5 duplicates (same content, different paths) ==="
python3 << 'PY'
import hashlib, os, sys
from collections import defaultdict
root = os.environ.get("ROOT", ".")
paths = open("/tmp/limerence-docs-list.txt").read().splitlines()
by_hash = defaultdict(list)
for p in paths:
    if not os.path.isfile(p):
        continue
    h = hashlib.md5(open(p, "rb").read()).hexdigest()
    by_hash[h].append(p)
for h, ps in sorted(by_hash.items(), key=lambda x: -len(x[1])):
    if len(ps) > 1:
        print(f"\n{h[:8]}... ({len(ps)} files):")
        for p in ps:
            print(f"  {p}")
PY

echo ""
echo "=== Broken relative markdown links in docs/ ==="
python3 << 'PY'
import os, re
root = "docs"
link_re = re.compile(r'\[([^\]]*)\]\(([^)]+)\)')

def resolve(from_file, target):
    if target.startswith("http") or target.startswith("#"):
        return None
    target = target.split("#")[0].split("?")[0]
    if not target or target.startswith("mailto:"):
        return None
    base = os.path.dirname(from_file)
    path = os.path.normpath(os.path.join(base, target))
    return path

broken = []
for dirpath, _, files in os.walk(root):
    for f in files:
        if not f.endswith(".md"):
            continue
        fp = os.path.join(dirpath, f)
        text = open(fp, encoding="utf-8", errors="replace").read()
        for m in link_re.finditer(text):
            t = m.group(2)
            resolved = resolve(fp, t)
            if resolved and not os.path.exists(resolved):
                broken.append((fp, t, resolved))

for fp, t, r in broken[:50]:
    print(f"BROKEN: {fp}\n  link: {t}\n  -> {r}")
print(f"\nTotal broken: {len(broken)}")
PY

echo ""
echo "=== @see Спецификация/ in mobile/src ==="
grep -r "Спецификация/" mobile/src --include='*.ts' --include='*.tsx' 2>/dev/null | wc -l || echo "0"
