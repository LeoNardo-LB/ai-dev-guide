#!/usr/bin/env bash
# ============================================================
# selftest.sh — 系统自检：语法 + 十门禁 + 部署演练 + 版本阶梯演练
# 本地推送前与 GitHub Actions 跑同一条命令（本地过 = CI 过）。
# 用法：selftest.sh [--quick]   （--quick 跳过部署与阶梯演练，只跑语法+门禁）
# ============================================================
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/.."
FAIL=0
QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

echo "== 1. 脚本语法 =="
for f in scripts/*.sh; do
  if bash -n "$f" 2>/dev/null; then echo "  ✓ $(basename "$f")"; else echo "  ✗ $(basename "$f") 语法错误"; FAIL=1; fi
done
python3 - <<'EOF'
import ast, glob, sys
bad = []
for f in sorted(glob.glob('scripts/*.py')):
    try:
        ast.parse(open(f, encoding='utf-8').read())
        print('  ✓ ' + f)
    except SyntaxError as e:
        print('  ✗ %s: %s' % (f, e)); bad.append(f)
sys.exit(1 if bad else 0)
EOF
[ $? -ne 0 ] && FAIL=1

echo "== 2. 源仓十项门禁 =="
bash scripts/check.sh || FAIL=1

echo "== 2.5 敏感信息扫描（公开仓库强制）=="
bash scripts/scan-secrets.sh || FAIL=1

if [ "$QUICK" = 0 ]; then
  echo "== 3. 部署演练（init --no-example + 部署门禁）=="
  TMP="$(mktemp -d)"
  if bash scripts/init.sh "$TMP/demo" --no-example >/dev/null 2>&1; then
    echo '  ✓ init.sh 部署完成'
  else
    echo '  ✗ init.sh 失败'; FAIL=1
  fi
  bash scripts/check.sh --deployed "$TMP/demo" --only 1,9,10 || FAIL=1
  rm -rf "$TMP"

  echo "== 4. 版本阶梯演练 =="
  VT="$(mktemp -d)"; F="$VT/version.properties"
  RV=scripts/release-version.sh
  ok=1
  bash $RV "$F" init 1.0.1               >/dev/null 2>&1 || ok=0
  bash $RV "$F" next --bump patch        >/dev/null 2>&1 || ok=0   # → 1.0.2-dev.1
  bash $RV "$F" dev                      >/dev/null 2>&1 || ok=0   # → dev.2
  bash $RV "$F" beta                     >/dev/null 2>&1 || ok=0   # → beta
  bash $RV "$F" dev                      >/dev/null 2>&1 || ok=0   # 退回 dev.3（n 续增）
  bash $RV "$F" beta                     >/dev/null 2>&1 || ok=0
  bash $RV "$F" stable                   >/dev/null 2>&1 || ok=0   # → 1.0.2
  END_VN=$(grep '^VERSION_NAME=' "$F" | cut -d= -f2)
  if [ "$ok" = 1 ] && [ "$END_VN" = "1.0.2" ]; then
    echo "  ✓ 全阶梯走通（终点 $END_VN）"
  else
    echo "  ✗ 阶梯走通失败（终点 ${END_VN:-空}）"; FAIL=1
  fi
  for BAD in beta stable dev; do
    if bash $RV "$F" "$BAD" >/dev/null 2>&1; then
      echo "  ✗ 正式版状态下 $BAD 未被拒绝"; FAIL=1
    fi
  done
  echo '  ✓ 非法转移（stable→beta/stable/dev）全部被拒'
  bash $RV "$F" validate >/dev/null 2>&1 && echo '  ✓ validate' || { echo '  ✗ validate 失败'; FAIL=1; }
  rm -rf "$VT"
fi

echo "---"
if [ "$FAIL" -eq 0 ]; then
  echo "自检结果：通过"
else
  echo "自检结果：不通过"
  exit 1
fi