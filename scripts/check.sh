#!/usr/bin/env bash
# ============================================================
# check.sh — ai-dev-guide 机械门禁（10 项；复杂内核在 _gates.py）
# 用法：
#   check.sh                    源仓模式（在本仓库根运行）
#   check.sh --deployed <dir>   部署模式（在已部署的目标项目根运行）
#   check.sh --only 1,5,6       只跑指定门禁
#   check.sh --skip 9,10        跳过指定门禁
# 本脚本编排 + bash 原生门禁（7/8/10）；1/2/4/6/9 的复杂校验在 _gates.py，3 在 _ph_gate.py，5 为 gen-index --check。
# 全部实现无 GNU grep -P 依赖（macOS/BSD 可移植——2026-09-23 审计 U-P0-2）。
# 历史面豁免：specs/、docs/journal/、docs/archive/、docs/adr/、docs/research/、CHANGELOG.md
#   允许出现旧词汇/旧路径/CANON 引用（变更故事的合法归宿）。
# ============================================================
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

MODE="source"; TARGET=""
ONLY=""; SKIP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --deployed)
      [ $# -ge 2 ] || { echo "用法: check.sh --deployed <目标项目根目录>"; exit 2; }
      MODE="deployed"; TARGET="$(cd "$2" 2>/dev/null && pwd)"
      [ -n "$TARGET" ] || { echo "✗ 无法进入目标目录：$2"; exit 2; }
      shift 2 ;;
    --only|--skip)
      [ $# -ge 2 ] || { echo "用法: check.sh $1 <门禁编号列表，如 9,10>"; exit 2; }
      if [ "$1" = "--only" ]; then ONLY="$2"; else SKIP="$2"; fi
      shift 2 ;;
    *) echo "未知参数 $1（见文件头用法注释）"; exit 2 ;;
  esac
done

if [ "$MODE" = "source" ]; then ROOT="$HERE/.."; else ROOT="$TARGET"; fi
if [ "$MODE" = "deployed" ] && { [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; }; then
  echo "✗ --deployed 目标目录不存在或不可进入——拒绝回退到当前目录扫描"
  exit 2
fi
cd "$ROOT" || { echo "✗ 无法进入 $ROOT"; exit 2; }
if [ "$MODE" = "deployed" ]; then
  SYS_DIR="$(basename "$(dirname "$HERE")")"
else
  SYS_DIR=""
fi
export DSH_GATE_MODE="$MODE" DSH_SYS_DIR="$SYS_DIR"
FAIL=0; WARN=0; RAN=""

want() {
  if [ -n "$ONLY" ] && ! echo ",$ONLY," | grep -q ",$1,"; then return 1; fi
  if [ -n "$SKIP" ] && echo ",$SKIP," | grep -q ",$1,"; then return 1; fi
  return 0
}
mark() { RAN="$RAN $1"; }
bad()  { echo "✗ [$1] $2"; FAIL=1; }
ok()   { echo "✓ [$1] $2"; }
warn() { echo "⚠ [$1] $2"; WARN=1; }

# ---------- 门禁 1：链接 + 文档结构（{{SYS}} 规则；H1/表格完整） ----------
if want 1; then mark 1
  if [ "$MODE" = "source" ]; then
    python3 "$HERE/_gates.py" links source || FAIL=1
    python3 "$HERE/_gates.py" structure source || FAIL=1
  else
    python3 "$HERE/_gates.py" links deployed || FAIL=1
    python3 "$HERE/_gates.py" structure deployed || FAIL=1
  fi
fi

# ---------- 门禁 2：行数预算（manifest 驱动） ----------
if want 2; then mark 2
  if [ "$MODE" = "source" ]; then
    python3 "$HERE/_gates.py" budget || FAIL=1
  else
    ok 2 "部署模式跳过（预算属源仓门禁）"
  fi
fi

# ---------- 门禁 3：占位符残留 ----------
if want 3; then mark 3
  if [ "$MODE" = "source" ]; then
    python3 "$HERE/_ph_gate.py" || FAIL=1
  else
    ok 3 "部署模式：项目占位符由 init 首检报告"
  fi
fi

# ---------- 门禁 4：MUST 稀缺性 + L0 ≤200 行（源仓与部署面同查） ----------
if want 4; then mark 4
  if [ "$MODE" = "source" ]; then
    python3 "$HERE/_gates.py" must source || FAIL=1
  else
    python3 "$HERE/_gates.py" must deployed || FAIL=1
  fi
fi

# ---------- 门禁 5：生成物幂等 ----------
if want 5; then mark 5
  if [ "$MODE" = "source" ]; then
    if python3 "$HERE/gen-index.py" --check >/dev/null 2>&1; then ok 5 "GEN 段与 manifest 一致（幂等）"
    else bad 5 "GEN 段漂移——运行 python3 scripts/gen-index.py 同步"; fi
  else
    ok 5 "部署模式不适用（无 manifest）"
  fi
fi

# ---------- 门禁 6：§引用可解析（多链接逐一尝试 + 子节号） ----------
if want 6; then mark 6
  python3 "$HERE/_gates.py" sections || FAIL=1
fi

# ---------- 门禁 7：唯一归宿表指纹（历史面豁免：见文件头） ----------
if want 7; then mark 7
  for KEY in priority status-flow patch-three human-four; do
    N=$(grep -rl "CANON:$KEY" --include='*.md' \
        --exclude-dir=journal --exclude-dir=archive --exclude-dir=adr \
        --exclude-dir=research --exclude-dir=specs --exclude=CHANGELOG.md \
        . 2>/dev/null | wc -l)
    if [ "$N" -eq 1 ]; then ok 7 "CANON:$KEY 唯一归宿"
    elif [ "$N" -eq 0 ]; then
      if [ "$KEY" = "human-four" ]; then ok 7 "CANON:$KEY 未标记（2.6.0 起要求——见 verify 第 8 节）"
      else warn 7 "CANON:$KEY 未标记（迁移期允许）"; fi
    else bad 7 "CANON:$KEY 出现 $N 处——唯一归宿被破坏（正本见 requirements/verify/bug.md）"; fi
  done
fi

# ---------- 门禁 8：术语与禁用词 ----------
if want 8; then mark 8
  BANNED=$(grep -rn '维度[ ]*[1-5]' --include='*.md' --include='*.md.template' . 2>/dev/null | grep -vE 'specs/|docs/journal/|docs/archive/|docs/adr/|docs/research/|CHANGELOG' | head -5 || true)
  BANNED2=$(grep -rn 'D[0-4][ ]*维度' --include='*.md' --include='*.md.template' . 2>/dev/null | grep -vE 'specs/|docs/journal/|docs/archive/|docs/adr/|docs/research/|CHANGELOG' | head -5 || true)
  BANNED3=$(grep -rn 'ai-spec/ai-dev-docs' --include='*.md' --include='*.md.template' . 2>/dev/null | grep -vE 'specs/|docs/journal/|docs/archive/|docs/adr/|docs/research/|CHANGELOG' | head -5 || true)
  BANNED4=$(grep -rnE 'used-to|no-longer' --include='*.md' --include='*.md.template' . 2>/dev/null | grep -vE 'specs/|docs/journal/|docs/archive/|docs/adr/|docs/research/|CHANGELOG|doc-writing-standards|doc-governance' | head -5 || true)
  if [ -n "$BANNED$BANNED2$BANNED3$BANNED4" ]; then
    bad 8 "退役词汇/变更叙事词残留（历史叙事唯一合法归宿：journal/archive/CHANGELOG）"
    echo "$BANNED"; echo "$BANNED2"; echo "$BANNED3"; echo "$BANNED4"
  else ok 8 "零退役词汇与变更叙事词"; fi
  if [ "$MODE" = "source" ]; then
    MISS=""
    for T in 铁律 红线 门禁 承重规则; do
      grep -q "$T" meta/system-design.md 2>/dev/null || MISS="$MISS $T"
    done
    if [ -n "$MISS" ]; then bad 8 "术语表缺：$MISS"
    else ok 8 "承重术语已定义于 meta/system-design.md"; fi
    DUP=$(grep '^## \[' CHANGELOG.md 2>/dev/null | sort | uniq -d | head -3)
    if [ -n "$DUP" ]; then bad 8 "CHANGELOG 版本标题重复：$DUP"
    else ok 8 "CHANGELOG 版本标题唯一"; fi
    MV=$(grep -m1 '^  version:' manifest.yaml | sed 's/[^:]*: *//')
    CV=$(grep -m1 '^## \[' CHANGELOG.md | sed 's/## \[//;s/\].*//')
    if [ -n "$MV" ] && [ "$MV" != "$CV" ]; then
      bad 8 "manifest version $MV ≠ CHANGELOG 最新条目 $CV"
    else ok 8 "manifest 版本与 CHANGELOG 一致（$MV）"; fi
  fi
fi

# ---------- 门禁 9：backlog 不变量（部署模式；python 内核 _gates.py backlog） ----------
if want 9; then mark 9
  if [ "$MODE" = "deployed" ]; then
    python3 "$HERE/_gates.py" backlog || FAIL=1
  else
    ok 9 "源仓模式跳过（项目 backlog 门禁）"
  fi
fi

# ---------- 门禁 10：journal/specs/acceptance 命名规约（部署模式） ----------
if want 10; then mark 10
  if [ "$MODE" = "deployed" ]; then
    BADN=$(ls docs/journal/*.md docs/specs/*.md docs/acceptance/*.md 2>/dev/null | grep -v 'README.md' | grep -vE '[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$' | head -5 || true)
    if [ -n "$BADN" ]; then bad 10 "命名不符 YYYY-MM-DD-<kebab>.md：$BADN"; else ok 10 "journal/specs/acceptance 命名合规"; fi
  else
    ok 10 "源仓模式跳过"
  fi
fi

echo "---"
echo "已运行门禁:$RAN"
if [ "$FAIL" -eq 0 ]; then
  echo "结果：通过$([ $WARN -eq 1 ] && echo '（含警告）')"
else
  echo "结果：不通过"
fi
exit $FAIL
