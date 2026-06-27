#!/usr/bin/env bash
# Validate documentation links and legacy path references
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ERR=0

echo "=== Legacy Спецификация/ in mobile/src ==="
if grep -r "Спецификация/" mobile/src --include='*.ts' --include='*.tsx' 2>/dev/null | head -5; then
  echo "FAIL: legacy paths found"
  ERR=1
else
  echo "OK"
fi

echo ""
echo "=== Legacy web root docs ==="
for f in web/DOCUMENTATION.md web/ALGORITHM_LOGIC.md; do
  if [ -f "$f" ]; then echo "FAIL: $f exists"; ERR=1; fi
done
[ $ERR -eq 0 ] && echo "OK"

echo ""
echo "=== Required canonical paths ==="
required=(
  docs/README.md
  docs/_meta/conventions.md
  docs/specs/monetization/paywall.md
  docs/monetization/ENTITLEMENTS.md
  docs/monetization/PRODUCT_MODEL.md
  .cursor/rules/documentation.mdc
)
for f in "${required[@]}"; do
  if [ ! -f "$f" ]; then echo "MISSING: $f"; ERR=1; fi
done
[ $ERR -eq 0 ] && echo "OK"

echo ""
echo "=== Broken markdown links in docs/ (sample) ==="
python3 << 'PY'
import os, re, sys
link_re = re.compile(r'\[[^\]]*\]\(([^)]+)\)')
broken = 0
for dirpath, _, files in os.walk("docs"):
    for fn in files:
        if not fn.endswith(".md"): continue
        fp = os.path.join(dirpath, fn)
        for m in link_re.finditer(open(fp, encoding="utf-8").read()):
            t = m.group(1).split("#")[0]
            if not t or t.startswith("http") or t.startswith("mailto:"): continue
            if "/src/" in t or t.startswith("mobile/"): continue
            if t.startswith("docs/"): path = t
            else: path = os.path.normpath(os.path.join(os.path.dirname(fp), t))
            if not os.path.exists(path):
                broken += 1
                if broken <= 10:
                    print(f"BROKEN: {fp} -> {t}")
print(f"Total broken doc links: {broken}")
sys.exit(1 if broken > 20 else 0)
PY
VAL=$?
[ $VAL -ne 0 ] && ERR=1

echo ""
if [ $ERR -eq 0 ]; then echo "VALIDATION PASSED"; else echo "VALIDATION FAILED"; exit 1; fi
