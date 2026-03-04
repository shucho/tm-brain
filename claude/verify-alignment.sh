#!/bin/bash
# claude/verify-alignment.sh - Stigwheel drift detection

echo "=== Stigwheel Alignment Check ==="

echo ""
echo "1. Files missing frontmatter:"
find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | while read f; do
  if ! grep -q "@anchor:" "$f" 2>/dev/null; then
    echo "   MISSING: $f"
  fi
done

echo ""
echo "2. Orphan files (no spec reference):"
find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | while read f; do
  if ! grep -q "@spec:" "$f" 2>/dev/null; then
    echo "   ORPHAN: $f"
  fi
done

echo ""
echo "3. Validation status summary:"
for spec in specs/*.md; do
  [ -f "$spec" ] || continue
  done=$(grep -c "| ✅" "$spec" 2>/dev/null || echo 0)
  partial=$(grep -c "| 🟡" "$spec" 2>/dev/null || echo 0)
  pending=$(grep -c "| 🔴" "$spec" 2>/dev/null || echo 0)
  echo "   $spec: ✅$done 🟡$partial 🔴$pending"
done

echo ""
echo "4. Pattern usage:"
for pattern in .patterns/*.anchor.yaml; do
  [ -f "$pattern" ] || continue
  count=$(grep -c "^  - path:" "$pattern" 2>/dev/null || echo 0)
  echo "   $pattern: $count implementations"
done

echo ""
echo "=== Check complete ==="
