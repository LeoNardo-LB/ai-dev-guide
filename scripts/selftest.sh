#!/usr/bin/env bash
# ============================================================
# selftest.sh — 系统自检：语法 + 敏感扫描 + 十门禁 + 部署演练 + 阶梯演练
# 本地推送前与 GitHub Actions 跑同一条命令（本地过 = CI 过）。
# 部署演练含缺陷回归断言：历史修过的每个缺陷在此留一条会失败的测试。
# 用法：selftest.sh [--quick]   （--quick 跳过两类演练，只跑语法+扫描+门禁）
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
  echo "== 3. 部署演练 + 缺陷回归断言 =="
  TMP="$(mktemp -d)"
  D="$TMP/demo"
  if bash scripts/init.sh "$D" --no-example > "$TMP/init.log" 2>&1; then
    echo '  ✓ init.sh 部署完成'
  else
    echo '  ✗ init.sh 失败'; sed -n '1,20p' "$TMP/init.log"; FAIL=1
  fi
  bash scripts/check.sh --deployed "$D" --only 1,9,10 || FAIL=1

  # R1 [v2.3.1]：--no-ui 裁剪后生成的 AGENTS.md 不得有悬空链接（门禁1在部署模式本就会抓）
  bash scripts/init.sh "$TMP/noui" --no-ui --no-example >/dev/null 2>&1 \
    && bash scripts/check.sh --deployed "$TMP/noui" --only 1 >/dev/null 2>&1 \
    && echo '  ✓ R1 --no-ui 裁剪链接全部可解析' || { echo '  ✗ R1 --no-ui 断链回归'; FAIL=1; }

  # R2 [v2.4.0]：docs/*/README.md 必须是真实换行而非字面 \n
  if grep -q '\\\\n' "$D/docs/journal/README.md" 2>/dev/null; then
    echo '  ✗ R2 登记目录 README 含字面 \\n'; FAIL=1
  else
    echo '  ✓ R2 登记目录 README 真实换行';
  fi

  # R3 [v2.4.0]：check.sh --deployed 指向不存在目录必须拒绝（不得回退扫当前目录）
  bash scripts/check.sh --deployed "$TMP/no-such-dir" --only 1 >/dev/null 2>&1
  [ $? -eq 2 ] && echo '  ✓ R3 不存在目录被拒绝（exit 2）' || { echo '  ✗ R3 未拒绝不存在目录'; FAIL=1; }

  # R4 [v2.4.0]：部署门禁不得扫用户自有 md（用户文件断链不算系统门禁失败）
  printf '# 笔记\n参见 [指南](./nope.md)。\n' > "$D/我的笔记.md"
  bash scripts/check.sh --deployed "$D" --only 1 >/dev/null 2>&1
  [ $? -eq 0 ] && echo '  ✓ R4 用户自有 md 不受门禁误伤' || { echo '  ✗ R4 门禁误伤用户文件'; FAIL=1; }
  rm -f "$D/我的笔记.md"

  # R5 [v2.4.0]：全新部署（零人工修改）upgrade.sh 不得报告「本地化修改」
  bash scripts/upgrade.sh "$(pwd)" "$D" ai-dev-guide > "$TMP/up.log" 2>&1
  if grep -q '本地化修改 0' "$TMP/up.log"; then
    echo '  ✓ R5 全新部署零本地化误报（部署基线生效）'
  else
    echo '  ✗ R5 全新部署被误报本地化修改'; grep -E '本地化|一致' "$TMP/up.log" | head -2; FAIL=1
  fi

  # R6 [v2.4.0]：登记簿四件实例化齐备 + 部署基线存在
  ok6=1
  for f in backlog.md CONTEXT.md docs/ability-domains.md docs/architecture-debt.md ai-dev-guide/.deploy-baseline.txt; do
    [ -f "$D/$f" ] || { echo "  ✗ R6 缺 $f"; ok6=0; FAIL=1; }
  done
  [ $ok6 = 1 ] && echo '  ✓ R6 登记簿四件 + 部署基线齐备'

  # R7 [v2.4.0]：部署侧 new-batch.sh 产物可用（H1 含日期与批次名、无相对 md 链接）
  ( cd "$D" && bash ai-dev-guide/scripts/new-batch.sh selftest-drill >/dev/null 2>&1 )
  JB=$(ls "$D"/docs/journal/*-selftest-drill.md 2>/dev/null | head -1)
  if [ -n "$JB" ] && head -1 "$JB" | grep -qE '^# [0-9]{4}-[0-9]{2}-[0-9]{2} <批次：selftest-drill>' \
     && ! grep -qE '\]\([^)]+\.md\)' "$JB"; then
    echo '  ✓ R7 new-batch 产物结构正确'
  else
    echo '  ✗ R7 new-batch 产物异常'; head -3 "$JB" 2>/dev/null; FAIL=1
  fi
  bash scripts/check.sh --deployed "$D" --only 1,10 >/dev/null 2>&1 \
    && echo '  ✓ R7 部署门禁仍通过' || { echo '  ✗ R7 部署门禁失败'; FAIL=1; }

  # R8 [v2.4.0]：门禁9 计数器识别行尾裸编号（journal 行尾 #N 须计入最大编号）
  printf '# 批次\n完结条目 #999\n' > "$D/docs/journal/2026-01-01-drill.md"
  sed -i 's/下一编号：\\*\\*#[0-9]*\\*\\*/下一编号：**#999**/' "$D/backlog.md"
  bash scripts/check.sh --deployed "$D" --only 9 >/dev/null 2>&1
  [ $? -ne 0 ] && echo '  ✓ R8 行尾编号计入（计数器 #999 被判撞号）' || { echo '  ✗ R8 行尾裸编号漏检'; FAIL=1; }
  rm -f "$D/docs/journal/2026-01-01-drill.md"
  rm -rf "$TMP"

  echo "== 3.5 扫描器回归断言（夹具仓，不触碰真仓库）=="
  FT="$(mktemp -d)"; mkdir -p "$FT/repo/scripts"   # 日志放 $FT 根，避免扫描器自扫自己的输出
  cp scripts/scan-secrets.sh "$FT/repo/scripts/"
  printf 'token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456\n' > "$FT/repo/leak.txt"
  ( cd "$FT/repo" && bash scripts/scan-secrets.sh > "$FT/out1.log" 2>&1 )
  RC=$?
  # R9 [v2.4.0]：发现命中必须 exit 1 且计数 > 0（历史缺陷：管道子shell丢计数 → 命中却报干净）
  if [ $RC -ne 0 ] && grep -q '发现 [1-9]' "$FT/out1.log"; then
    echo '  ✓ R9 命中计数与退出码一致（主shell统计）'
  else
    echo '  ✗ R9 扫描器计数/退出码回归'; head -5 "$FT/out1.log"; FAIL=1
  fi
  # R10 [v2.4.0]：白名单 :字面量 内容豁免只放行命中行，且路径规则不再当内容匹配
  printf 'password = "realtok123"  # 同行提到 scripts/scan-secrets.sh 也不得放行\n' > "$FT/repo/trap.sh"
  printf ':ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456\n' > "$FT/repo/scripts/scan-secrets.allow"
  ( cd "$FT/repo" && bash scripts/scan-secrets.sh > "$FT/out2.log" 2>&1 )
  if ! grep -q 'leak.txt' "$FT/out2.log" && grep -q 'trap.sh' "$FT/out2.log"; then
    echo '  ✓ R10 白名单语义分离（内容豁免生效、路径规则不再当内容误放行）'
  else
    echo '  ✗ R10 白名单语义回归'; head -6 "$FT/out2.log"; FAIL=1
  fi
  rm -rf "$FT"

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
  # R11 [v2.4.0]：杂散位置参数必须被拒（历史缺陷：静默吞掉）
  if bash $RV "$F" next stray --bump patch >/dev/null 2>&1; then
    echo '  ✗ R11 next 吞掉杂散位置参数'; FAIL=1
  else
    echo '  ✓ R11 杂散位置参数被拒'
  fi
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
